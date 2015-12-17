#
# Description: Create LBaaS for the selected service
#

@method = 'create_lbaas'

$evm.log("info", "#{@method} - EVM Automate Method Started")

require 'rest-client'
require 'json'
require 'fog'

# hardcoding tenant_id
tenant_id = "1234567890"

# hardcoding subnet_id
subnet_id = "1234567890"

# also the pool ID for the floating IPs is static
floating_pool_id = "1234567890"

# and we also always use the same health monitor
health_monitor_id = "1234567890"

# create the list of VMs
vmlist = []
service = nil

if not $evm.root['service'].nil?
  service = $evm.root['service']
end

if not $evm.root['service_template_provision_task'].nil?
  service = $evm.root['service_template_provision_task'].destination
end

if service.nil?
  $evm.log("info", "#{@method} - unable to find service object")
  exit MIQ_ABORT
end

# if this is a service catalog item, VMs are direct children
if not service.direct_vms.nil?
  if service.direct_vms.length > 0
    vmlist = service.direct_vms
  end
end

# if this is a service catalog bundle, VMs are indirect children
if not service.indirect_vms.nil?
  if service.indirect_vms.length > 0
    vmlist = service.indirect_vms
  end
end

$evm.log("info", "#{@method} - List of VMs found: #{vmlist.inspect}")
vm = vmlist.first

ext_mgt_system=vm.ext_management_system

# get the MAC address directly from OSP
# change the tenant name or make it dynamic
credentials={
  :provider => "OpenStack",
  :openstack_api_key => ext_mgt_system.authentication_password,
  :openstack_username => ext_mgt_system.authentication_userid,
  :openstack_auth_url => "http://#{ext_mgt_system[:hostname]}:#{ext_mgt_system[:port]}/v2.0/tokens",
  :openstack_tenant => "admin"
}

compute = Fog::Compute.new(credentials)
neutron = Fog::Network.new(credentials)

poolname = service.name

# create LB Pool
$evm.log("info", "#{@method} - Creating Load Balancer Pool #{poolname}")
response = neutron.create_lb_pool subnet_id, "HTTP", "ROUND_ROBIN", { :description => poolname , :name => poolname, :tenant_id => tenant_id}
$evm.log("info", "#{@method} - Response: #{response.inspect}")
pool_id = response[:body]['pool']['id']
$evm.log("info", "#{@method} - Pool ID: #{pool_id}")

# create LB members and add to Pool
vmlist.each { |vm|
  # do not add the mysql server to the pool
  if vm.name.include?("mysql")
    next
  end

  vmfloatingip = vm.custom_get("NEUTRON_floating_ip")
  vmipaddress = nil

  vm.ipaddresses.each { |ip|
    if vmfloatingip != ip
      $evm.log("info", "#{@method} - #{vmfloatingip} does not match with #{ip}, so it must be the subnet IP")
      vmipaddress = ip
      break
    else
      $evm.log("info", "#{@method} - #{vmfloatingip} and #{ip} do match, skipping")
    end
  }

  if vmipaddress.nil?
    $evm.log("info", "#{@method} - Did not find floating IP for VM #{vm.name} in custom attribute")
    exit MIQ_ABORT
  end

  $evm.log("info", "#{@method} - Adding Member #{vm.name} with IP #{vmipaddress} to pool with ID #{pool_id}")
  response = neutron.create_lb_member pool_id, vmipaddress, 8080, 200
  $evm.log("info", "#{@method} - Response: #{response.inspect}")
}

# associate health monitor
$evm.log("info", "#{@method} - Associating Health Monitor with ID #{health_monitor_id} to Pool with ID #{pool_id}")
response = neutron.associate_lb_health_monitor pool_id, health_monitor_id
$evm.log("info", "#{@method} - Response: #{response.inspect}")

# create a VIP
$evm.log("info", "#{@method} - Creating VIP")
response = neutron.create_lb_vip subnet_id, pool_id, "HTTP", 8080
$evm.log("info", "#{@method} - Response: #{response.inspect}")
vip_id = response[:body]['vip']['id']
port_id = response[:body]['vip']['port_id']
$evm.log("info", "#{@method} - VIP ID: #{vip_id} and Port ID: #{port_id}")

# allocate floating IP
$evm.log("info", "#{@method} - Allocating Floating IP")
response = compute.allocate_address floating_pool_id
$evm.log("info", "#{@method} - Response: #{response.inspect}")
allocated_ip_id = response[:body]['floating_ip']['id']
allocated_ip = response[:body]['floating_ip']['ip']
service.custom_set('Floating IP',allocated_ip)
$evm.log("info", "#{@method} - Floating IP ID: #{allocated_ip_id}")

# associate floating IP to VIP
$evm.log("info", "#{@method} - Associating Floating IP with ID #{allocated_ip_id} to Port with ID #{port_id}")
response = neutron.associate_floating_ip allocated_ip_id, port_id
$evm.log("info", "#{@method} - Response: #{response.inspect}")

exit MIQ_OK
