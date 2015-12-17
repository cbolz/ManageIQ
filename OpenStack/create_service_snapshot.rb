#
# Description: This method will create a snapshot on OpenStack for each VM belonging to a given service
#

begin
  @method = 'create_service_snapshot'
  $evm.log("info", "#{@method} - EVM Automate Method Started")

  @debug = false

  require 'rest-client'
  require 'json'
  require 'fog'

  # create the list of VMs
  vmlist = []
  # if this is a service catalog item, VMs are direct children
  if $evm.root['service'].direct_vms.length > 0
    vmlist = $evm.root['service'].direct_vms
  end

  # if this is a service catalog bundle, VMs are indirect children
  if $evm.root['service'].indirect_vms.length > 0
    vmlist = $evm.root['service'].indirect_vms
  end

  snapshotlist={}
  credentials=nil
  ext_mgt_system=nil

  vmlist.each { |vm|
    $evm.log("info", "#{@method} - VM Name: #{vm.name}")

    ext_mgt_system=vm.ext_management_system

    # the openstack_tenant might have to be adjusted or be dynamic
    credentials={
      :provider => "OpenStack",
      :openstack_api_key => ext_mgt_system.authentication_password,
      :openstack_username => ext_mgt_system.authentication_userid,
      :openstack_auth_url => "http://#{ext_mgt_system[:hostname]}:#{ext_mgt_system[:port]}/v2.0/tokens",
      :openstack_tenant => "admin"
    }

    compute = Fog::Compute.new(credentials)

    server = compute.servers.get(vm.ems_ref)

    response = server.create_image "snapshot-#{server.name}", :metadata => { :environment => 'development' }

    image_id = response.body["image"]["id"]

    $evm.log("info", "#{@method} - Created Snapshot named snapshot-#{server.name} with ID #{image_id}")

    vm.custom_set("Snapshot ID",image_id)
    vm.custom_set("Snapshot Name","snapshot-#{server.name}")
  }

  #
  # Exit method
  #
  $evm.log("info", "#{@method} - EVM Automate Method Ended")
  exit MIQ_OK

  #
  # Set Ruby rescue behavior
  #
rescue => err
  $evm.log("error", "#{@method} - [#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
