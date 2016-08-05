###################################
#
# This method creates an additional disk and attaches it to the VM
#
# install xmlsimple with "gem install xml-simple"
#
###################################

def attachnic(rhevmhost,rhevmuser,rhevmpass,vmuid,networkid,nicname)
  require 'rubygems'
  require 'rest_client'
  require 'xmlsimple'

  htmlhd = "<nic><vnic_profile>#{networkid}</vnic_profile><name>#{nicname}</name></nic>"

  $evm.log("info", "html = #{htmlhd}")
  resource = RestClient::Resource.new(rhevmhost, :user => rhevmuser, :password => rhevmpass, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
  data = XmlSimple.xml_in(resource["/api/vms/" + vmuid + "/nics/"].post(htmlhd, :content_type => 'application/xml', :accept => 'application/xml').body, {'ForceArray' => false})
  $evm.log("info", "Return: #{data.inspect}")
  diskid = data['id']


  # # Only needed for RHEV 3.3 - After Updating to 3.4 we dont need this anymore
  # sleep(30)
  #
  # htmlactivatehd = "<action/>"
  # $evm.log("info", "htmlactivatehd = #{htmlactivatehd}")
  # resource = RestClient::Resource.new(rhevmhost, :user => rhevmuser, :password => rhevmpass, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
  # data = XmlSimple.xml_in(resource["/api/vms/" + vmuid + "/disks/" + diskid + "/activate"].post(htmlactivatehd, :content_type => 'application/xml', :accept => 'application/xml').body, {'ForceArray' => false})
  # # - - - - -
  return data
end

begin
  @method = 'attachnic'
  $evm.log("info", "#{@method} - EVM Automate Method: <#{@method}> Started")

  ext_mgt_system = $evm.root['vm'].ext_management_system

  rhevmhost = "https://#{ext_mgt_system[:hostname]}"
  rhevmuser = ext_mgt_system.authentication_userid
  rhevmpass = ext_mgt_system.authentication_password

  vm=$evm.root['vm']
  vmuid=vm.uid_ems
  vmtype=vm.type

  unless vmtype == "ManageIQ::Providers::Redhat::InfraManager::Vm"
    $evm.log("info", "#{@method} - VM Type != RHEV")
    $evm.log("info", "#{@method} - EVM Automate Method: <#{@method}> Ended")
    exit MIQ_OK
  end
  networkid = $evm.root['dialog_network']
  nicname = $evm.root['dialog_nicname']
  $evm.log("info", "#{@method} - network = #{networkid}")
  $evm.log("info", "#{@method} - vmuid = #{vmuid}")
  $evm.log("info", "#{@emthod} - nic name: #{nicname}")
  tmp=attachnic(rhevmhost,rhevmuser,rhevmpass,vmuid,networkid,nicname)

  $evm.log("info", "#{@method} - tmp = #{tmp}")

  #
  # Exit method
  #
  $evm.log("info", "#{@method} - EVM Automate Method: <#{@method}> Ended")
  exit MIQ_OK

  #
  # Set Ruby rescue behavior
  #
rescue => err
  $evm.log("error", "#{@method} - [#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
