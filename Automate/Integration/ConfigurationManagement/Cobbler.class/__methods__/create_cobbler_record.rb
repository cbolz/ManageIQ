###################################
#
# This method creates a cobbler record for the given VM
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
require 'xmlrpc/client'

@method = 'create_cobbler_record'
$evm.log("info", "#{@method} - Starting")

# get provision object
prov = $evm.root['miq_provision'] || $evm.root['miq_provision_request'] || $evm.root['miq_provision_request_template']

# print all root objects
$evm.root.attributes.sort.each { |k, v| $evm.log("info", "@{method} Root:<$evm.root> Attribute - #{k}: #{v}")}

cobbler_host = $evm.object["cobbler_host"]
$evm.log("info", "#{@method} - Cobbler Server: #{cobbler_host}")
cobbler_user = $evm.object["cobbler_user"]
$evm.log("info", "#{@method} - Cobbler User: #{cobbler_user}")
cobbler_password = $evm.object.decrypt("cobbler_password")
$evm.log("info", "#{@method} - Cobbler Password: < intentionally not written to the log >")
cobbler_profile = $evm.object["cobbler_profile"]
$evm.log("info", "#{@method} - Cobbler Kickstart: #{cobbler_profile}")

vm = prov.vm

# we have to check the MAC address of the new VM, if it doesn't have one, we have to wait
if vm.mac_addresses != nil and vm.mac_addresses!=[]
	$evm.log("info", "#{@method} - MacAddresses found: #{vm.mac_addresses.inspect}")

	# create Cobbler record
	interfaces = {}
	interfaces["static-eth0"]=false
	interfaces["macaddress-eth0"]=vm.mac_addresses[0]
	$evm.log("info", "#{@method} - Connecting to Cobbler:")
	begin
		$evm.log("info", "#{@method} Creating #{vm.name} in Cobbler")
		connection = XMLRPC::Client.new(cobbler_host, '/cobbler_api')
		token = connection.call('login', cobbler_user, cobbler_password)
		system_id = connection.call('new_system', token)
		$evm.log("info", "#{@method} - Setting name to #{vm.name}")
		connection.call('modify_system', system_id, 'name', vm.name, token)
		$evm.log("info", "#{@method} - Setting hostname to #{vm.name}")
		hostname=prov.get_option(:vm_target_hostname)
		connection.call('modify_system', system_id, 'hostname', hostname, token)
		$evm.log("info", "#{@method} - Setting network interfaces to #{interfaces}")
		connection.call('modify_system', system_id, 'modify_interface', interfaces, token)
		$evm.log("info", "#{@method} - Setting kickstart profile to #{cobbler_profile}")
		connection.call('modify_system', system_id, 'profile', cobbler_profile, token)
		$evm.log("info", "#{@method} - Saving system")
		connection.call('save_system', system_id, token)
	rescue XMLRPC::FaultException => err
		$evm.log("error", "#{@method} - [#{err}]\n#{err.faultString}")
		exit MIQ_ABORT
	end
	$evm.log("info", "#{@method} - Cobbler record created, starting VM")
  vm.start
else
	$evm.log("info", "#{@method} - No Mac Address found - Waiting 20 sconds")
  $evm.root['ae_result'] = 'retry'
  $evm.root['ae_retry_interval'] = '20.seconds'
  exit MIQ_OK
end

#
# Exit method
#
$evm.log("info", "#{@method} -EVM Automate Method Ended")
exit MIQ_OK
