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

def query_id (queryuri,queryfield,querycontent)
	# queryuri: path name related to @uri_base, where to search (hostgroups, locations, ...)
	# queryfield: which field (as in database row) should be searched
	# querycontent: what the queryfield has to match (exact match)

	# Put the search URL together
	url = URI.escape("#{@uri_base}/#{queryuri}?search=#{queryfield}=\"#{querycontent}\"")
	
	$evm.log("info", "url => #{url}")

	request = RestClient::Request.new(
		method: :get,
		url: url,
		headers: @headers,
		verify_ssl: OpenSSL::SSL::VERIFY_NONE
	)

	rest_result = request.execute
	json_parse = JSON.parse(rest_result)
	
	# The subtotal value is the number of matching results.
	# If it is higher than one, the query got no unique result!
	subtotal = json_parse['subtotal'].to_i
	
	if subtotal == 0
		$evm.log("info", "query failed, no result #{url}")
		return -1
	elsif subtotal == 1
		id = json_parse['results'][0]['id'].to_s
		return id
	elsif subtotal > 1
		$evm.log("info", "query failed, more than one result #{url}")
		return -1
	end

	$evm.log("info", "query failed, unknown condition #{url}")
	return -1
end

# Get the hostgroup id using the supplied name
$evm.log("info", 'Getting hostgroup id from Foreman')
hostgroup_id=query_id("hostgroups","name",hostgroup_name)
$evm.log("info", "hostgroup_id: #{hostgroup_id}")
if hostgroup_id == -1
	$evm.log("info", "Cannot continue without hostgroup_id")
	exit MIQ_ABORT
end

# Get the location id using the supplied name
$evm.log("info", 'Getting location id from Foreman')
location_id=query_id("locations","name",location_name)
$evm.log("info", "location_id: #{location_id}")
if location_id == -1
	$evm.log("info", "Cannot continue without location_id")
	exit MIQ_ABORT
end

# Get the organization id using the supplied name
$evm.log("info", 'Getting organization id from Foreman')
organization_id=query_id("organizations","name",organization_name)
$evm.log("info", "organization_id: #{organization_id}")
if organization_id == -1
	$evm.log("info", "Cannot continue without organization_id")
	exit MIQ_ABORT
end

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

json_parse = JSON.parse(rest_result)
hostid = json_parse['id'].to_s

$evm.log("info", "Storing Foreman host ID of new VM: #{hostid}")
prov.set_option(:hostid,hostid)

$evm.log("info", "Powering on VM")
vm.start

exit MIQ_OK
