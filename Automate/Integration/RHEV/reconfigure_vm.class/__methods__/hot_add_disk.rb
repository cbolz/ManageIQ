###################################
#
# This method creates an additional disk and attaches it to the VM
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

def attachhd(rhevmhost,rhevmuser,rhevmpass,vmuid,storage,size,allocpolicy)
  require 'rubygems'
  require 'rest_client'
  require 'nokogiri'

  size = (size.to_i * 1024 * 1024 * 1024)
  $evm.log("info", "#{@method} - size = #{size}")

  storageid=""

  resource = RestClient::Resource.new(rhevmhost, :user => rhevmuser, :password => rhevmpass, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
  storage_data = Nokogiri::XML(resource["/api/storagedomains/?search=name=#{storage}"].get.body)
  $evm.log("info", "#{@method} - storage_data: #{storage_data}")
  storage_data.xpath("//storage_domain").each do |storage_domain|
    storageid=storage_domain.to_h['id']
    $evm.log("info", "ID: #{storageid}")
  end

  sparse=""
  if allocpolicy == "thick"
    sparse="false"
  elsif allocpolicy == "thin"
    sparse="true"
  else
    $evm.log("info", "#{@method} - Allocation Policy unknown, using thin provisioning")
    sparse="true"
  end

  htmlhd = "<disk><storage_domains><storage_domain id='#{storageid}'/></storage_domains><size>#{size}</size><interface>virtio</interface><format>raw</format><bootable>false</bootable><sparse>#{sparse}</sparse></disk>"

  $evm.log("info", "html = #{htmlhd}")
  data = Nokogiri::XML(resource["/api/vms/" + vmuid + "/disks"].post(htmlhd, :content_type => 'application/xml', :accept => 'application/xml'))
  $evm.log("info", "VMs = #{data}")

  diskid = ""
  data.xpath("//storage_domain").each do |storage_domain|
    diskid=storage_domain.to_h['id']
    $evm.log("info", "#{@method} - disk id: #{diskid}")
  end

  # # Only needed for RHEV 3.3 - After Updating to 3.4 we dont need this anymore
  # sleep(30)
  #
  # htmlactivatehd = "<action/>"
  # $evm.log("info", "htmlactivatehd = #{htmlactivatehd}")
  # resource = RestClient::Resource.new(rhevmhost, :user => rhevmuser, :password => rhevmpass, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
  # data = Nokogiri::XML(resource["/api/vms/" + vmuid + "/disks/" + diskid + "/activate"].post(htmlactivatehd, :content_type => 'application/xml', :accept => 'application/xml'))
  # return data
end

begin
  @method = 'attachhd'
  $evm.log("info", "#{@method} - EVM Automate Method: <#{@method}> Started")

  vm=$evm.root['vm']
  ext_mgt_system = vm.ext_management_system

  rhevmhost = "https://#{ext_mgt_system.hostname}"
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
  storage = $evm.root['dialog_datastore']
  size = $evm.root['dialog_size']
  allocpolicy = $evm.root['dialog_allocpolicy']
  $evm.log("info", "#{@method} - storage = #{storage}")
  $evm.log("info", "#{@method} - size = #{size}")
  $evm.log("info", "#{@method} - vmuid = #{vmuid}")
  $evm.log("info", "#{@method} - Allocation Policy = #{allocpolicy}")
  attachhd(rhevmhost,rhevmuser,rhevmpass,vmuid,storage,size,allocpolicy)

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
