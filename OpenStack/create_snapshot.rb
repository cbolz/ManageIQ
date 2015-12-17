#
# Description: Create snapshot of currently selected instance
#

@method = 'create_snapshot'

$evm.log("info", "#{@method} - EVM Automate Method Started")

require 'rest-client'
require 'json'
require 'fog'

vm = $evm.root['vm']

ext_mgt_system=vm.ext_management_system

# get the MAC address directly from OSP
# make sure to adjust the openstack_tenant or make it dynamic
credentials={
  :provider => "OpenStack",
  :openstack_api_key => ext_mgt_system.authentication_password,
  :openstack_username => ext_mgt_system.authentication_userid,
  :openstack_auth_url => "http://#{ext_mgt_system[:hostname]}:#{ext_mgt_system[:port]}/v2.0/tokens",
  :openstack_tenant => "admin"
}

$evm.log("info", "#{@method} - Logging into to http://#{ext_mgt_system[:hostname]}:#{ext_mgt_system[:port]}/v2.0/tokens as #{ext_mgt_system.authentication_userid}")

compute = Fog::Compute.new(credentials)

server = compute.servers.get(vm.ems_ref)

response = server.create_image "snapshot-#{server.name}", :metadata => { :environment => 'development' }

image_id = response.body["image"]["id"]

$evm.log("info", "#{@method} - Created Snapshot named snapshot-#{server.name} with ID #{image_id}")

vm.custom_set("Snapshot ID",image_id)
vm.custom_set("Snapshot Name","snapshot-#{server.name}")

exit MIQ_OK
