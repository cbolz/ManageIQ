#
# Description: Create configured host record in Foreman
#

@method = 'register_foreman'

$evm.log("info", "#{@method} - EVM Automate Method Started")

# Dump all of root's attributes to the log
$evm.root.attributes.sort.each { |k, v| $evm.log("info", "#{@method} Root:<$evm.root> Attribute - #{k}: #{v}")}

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

prov = $evm.root['miq_provision']
vm = prov.vm

@uri_base = "https://#{foreman_host}/api/v2"
@headers = {
	:content_type => 'application/json',
	:accept => 'application/json;version=2',
	:authorization => "Basic #{Base64.strict_encode64("#{foreman_user}:#{foreman_password}")}"
}

def query_id (query,name)
	uri = "#{@uri_base}/#{query}?search=#{name}"
	$evm.log("info", "uri => #{uri}")

	request = RestClient::Request.new(
		method: :get,
		url: uri,
		headers: @headers,
		verify_ssl: OpenSSL::SSL::VERIFY_NONE
	)

	rest_result = request.execute
	json_parse = JSON.parse(rest_result)
	id = json_parse['results'][0]['id'].to_s

	return id
end

# Get the hostgroup id using the supplied name
$evm.log("info", 'Getting hostgroup id from Foreman')
hostgroup_id=query_id("hostgroups",hostgroup_name)
$evm.log("info", "hostgroup_id: #{hostgroup_id}")

# Get the location id using the supplied name
$evm.log("info", 'Getting location id from Foreman')
location_id=query_id("locations",location_name)
$evm.log("info", "location_id: #{location_id}")

# Get the organization id using the supplied name
$evm.log("info", 'Getting organization id from Foreman')
organization_id=query_id("organizations",organization_name)
$evm.log("info", "organization_id: #{organization_id}")


# Create the host via Foreman
uri = "#{@uri_base}"
# Now create the host in Foreman
$evm.log("info", 'Creating host in Foreman')

hostinfo = {
	:name => vm.name,
	:mac => vm.mac_addresses[0],
	:hostgroup_id => hostgroup_id,
	:location_id => location_id,
	:organization_id => organization_id,
	:build => 'true'
}
$evm.log("info", "Sending Host Details: #{hostinfo}")

uri = "#{@uri_base}/hosts"
request = RestClient::Request.new(
	method: :post,
	url: uri,
	headers: @headers,
	verify_ssl: OpenSSL::SSL::VERIFY_NONE,
	payload: { host: hostinfo }.to_json
)

rest_result = request.execute
$evm.log("info", "return code => <#{rest_result.code}>")

$evm.log("info", "Powering on VM")
vm.start

exit MIQ_OK

