#
#            Automate Method
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

require 'rubygems'
require 'rest_client'
require 'xmlsimple'

@debug = false

def getdatacentername(rhevmhost,rhevmuser,rhevmpass,href)
  resource = RestClient::Resource.new(rhevmhost, :user => rhevmuser, :password => rhevmpass, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
  datacenter_data = XmlSimple.xml_in(resource[href].get.body, {'ForceArray' => false})
  $evm.log("info", "raw datacenter_data: #{datacenter_data}") if @debug == true
  $evm.log("info", "Data Center Name: #{datacenter_data['name']}")
  return datacenter_data['name']
end

def getnetworks(rhevmhost,rhevmuser,rhevmpass)
  networks = Array.new{Array.new}

  resource = RestClient::Resource.new(rhevmhost, :user => rhevmuser, :password => rhevmpass, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
  network_data = XmlSimple.xml_in(resource["/api/networks/"].get.body, {'ForceArray' => false})
  $evm.log("info", "network_data: #{network_data}") if @debug == true
  network_data['network'] = [network_data['network']] if network_data['network'].class == Hash
  $evm.log("info", "network data after hash: #{network_data}") if @debug == true
  network_data['network'].each do |st|
    $evm.log("info", "going through each st: #{st}") if @debug == true
    network_uid = st['id']
    $evm.log("info", "Network ID: #{network_uid}")
    datacenter_href=st['data_center']['href']
    $evm.log("info", "datacenter_href: #{datacenter_href}") if @debug == true
    datacenter_name = getdatacentername(rhevmhost,rhevmuser,rhevmpass,datacenter_href)
    $evm.log("info", "datacenter_name: #{datacenter_name}") if @debug == true
    # we build an array of network name and data center name, value will be the UID of the network
    # this is necessary because a netowrk name (like rhevm) might exist multiple times
    desc="#{st['name']} - #{datacenter_name}"
    networks.push [network_uid, desc]
  end
  return networks
end

begin
  @method = 'dialog_add_nic'
  $evm.log("info", "#{@method} - EVM Automate Method: <#{@method}> Started")

  ext_mgt_system = $evm.root['vm'].ext_management_system

  rhevmhost = "https://#{ext_mgt_system[:hostname]}"
  rhevmuser = ext_mgt_system.authentication_userid
  rhevmpass = ext_mgt_system.authentication_password

  vm=$evm.root['vm']
  vmuid=vm.uid_ems
  vmtype=vm.type

  $evm.log("info"," #{@method} - vm: #{vm}")
  $evm.log("info"," #{@method} - vmuid: #{vmuid}")
  $evm.log("info"," #{@method} - vmtype: #{vmtype}")

  unless vmtype == "ManageIQ::Providers::Redhat::InfraManager::Vm"
    # this will populate the dialog in case we are not on RHEV
    networks = Array.new{Array.new}
    networks.push ["No Valid","No Valid"]
    dialog_field = $evm.object
    dialog_field["sort_by"] = "value"
    dialog_field["data_type"] = "string"
    dialog_field["required"] = "true"
    dialog_field["values"] = networks
    dialog_field["default_value"] = "No Valid"
    $evm.log("info", "#{@method} - VM Type != RHEV")
    $evm.log("info", "#{@method} - EVM Automate Method: <#{@method}> Ended")
    exit MIQ_OK
  end

  networks=getnetworks(rhevmhost,rhevmuser,rhevmpass)
  $evm.log("info"," #{@method} - networks: #{networks}")

  dialog_field = $evm.object

  # sort_by: value / description / none
  dialog_field["sort_by"] = "value"

  # sort_order: ascending / descending
  dialog_field["sort_order"] = "ascending"

  # data_type: string / integer
  dialog_field["data_type"] = "string"

  # required: true / false
  dialog_field["required"] = "true"

  dialog_field["values"] = networks

  dialog_field["default_value"] = networks.first.first

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
