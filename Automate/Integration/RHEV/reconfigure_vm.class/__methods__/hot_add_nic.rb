###################################
#
# This method creates an additional network interface and attaches it to the VM
#
# Copyright (C) 2016, Christian Jung
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###################################

def getprofileid(rhevmhost,rhevmuser,rhevmpass,networkid)
  require 'rubygems'
  require 'rest_client'
  require 'nokogiri'

  $evm.log("info", "#{@method} - Retrieve Profile ID for Network ID: #{networkid}")

  resource = RestClient::Resource.new(rhevmhost, :user => rhevmuser, :password => rhevmpass, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
  profile_id = Nokogiri::XML(resource["/api/networks/" + networkid + "/vnicprofiles/"].get.body)
  id = profile_id.xpath("//vnic_profile").attr('id')
  return id
end

def attachnic(rhevmhost,rhevmuser,rhevmpass,vmuid,networkid,nicname)
  require 'rubygems'
  require 'rest_client'
  require 'nokogiri'

  profile_id = getprofileid(rhevmhost,rhevmuser,rhevmpass,networkid)

  nicdata = "<nic><vnic_profile>#{profile_id}</vnic_profile><name>#{nicname}</name></nic>"

  $evm.log("info", "#{@method} - html = #{nicdata}")
  resource = RestClient::Resource.new(rhevmhost, :user => rhevmuser, :password => rhevmpass, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
  Nokogiri::XML(resource["/api/vms/" + vmuid + "/nics/"].post(nicdata, :content_type => 'application/xml', :accept => 'application/xml').body)
  return
end

begin
  @method = 'attachnic'
  $evm.log("info", "#{@method} - EVM Automate Method: <#{@method}> Started")

  vm=$evm.root['vm']
  ext_mgt_system = vm.ext_management_system

  rhevmhost = "https://#{ext_mgt_system.hostname}"
  rhevmuser = ext_mgt_system.authentication_userid
  rhevmpass = ext_mgt_system.authentication_password

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
  $evm.log("info", "#{@method} - nic name: #{nicname}")
  attachnic(rhevmhost,rhevmuser,rhevmpass,vmuid,networkid,nicname)

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
