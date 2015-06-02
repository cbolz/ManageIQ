#
# Description: Create configured host record in Foreman
#

@method = 'DeleteFromForeman'

$evm.log("info", "#{@method} - EVM Automate Method Started")

require 'rest-client'
require 'json'
require 'openssl'
require 'base64'

foreman_host = $evm.object['foreman_host']
foreman_user = $evm.object['foreman_user']
foreman_password = $evm.object.decrypt('foreman_password')
hostgroup_name = $evm.object['hostgroup_name']
organization_name = $evm.object['organization_name']
location_name = $evm.object['location_name']

vm = $evm.root['vm']
vmname=vm.hostnames[0]
$evm.log("info", "Deleting VM #{vm.name} with Hostname #{vmname} from Foreman.")

if vm.platform != "linux" then
  $evm.log("info","This is not a Linux VM, skipping deletion of foreman records")
  exit MIQ_OK
end

@uri_base = "https://#{foreman_host}/api/v2/hosts"
@headers = {
	:content_type => 'application/json',
	:accept => 'application/json;version=2',
	:authorization => "Basic #{Base64.strict_encode64("#{foreman_user}:#{foreman_password}")}"
}

uri = "#{@uri_base}/#{vmname}"
$evm.log("info", "uri => #{uri}")

request = RestClient::Request.new(
	method: :delete,
	url: uri,
	headers: @headers,
	verify_ssl: OpenSSL::SSL::VERIFY_NONE
)

rest_result = request.execute
$evm.log("info", "Rest result: #{rest_result}")

exit MIQ_OK
