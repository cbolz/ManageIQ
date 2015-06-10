#
# Description: Wait for Puppet to report that configuration is complete
# before reporting the provisioning is complete.
# 

require 'json'
require 'rest-client'
require 'uri'
require 'openssl'
require 'base64'

def retry_method(msg, retry_interval = 60)
	$evm.log("info", "Retrying current state: [#{msg}]")
	$evm.root['ae_result'] = 'retry'
	$evm.root['ae_reason'] = msg.to_s
	$evm.root['ae_retry_interval'] = retry_interval
	exit MIQ_OK
end

def invoke_foreman_api(uri, foreman_user, foreman_password)
	@headers = {
		:content_type => 'application/json',
		:accept => 'application/json;version=2',
		:authorization => "Basic #{Base64.strict_encode64("#{foreman_user}:#{foreman_password}")}"
	}

	request = RestClient::Request.new(
		method: :get,
		url: uri,
		headers: @headers,
		verify_ssl: OpenSSL::SSL::VERIFY_NONE
	)

	rest_result=request.execute
	json_parse=JSON.parse(rest_result)
	return json_parse
end

begin

	prov = $evm.root['miq_provision']
	#request = prov.miq_provision_request
	unless prov.source.nil?
		unless prov.source.platform == "linux"
			$evm.log("info", "Request is #{prov.source.platform}, not Linux, skipping foreman registration.")
			exit MIQ_OK
		end
	end

	foreman_host = $evm.object['foreman_host']
	foreman_user = $evm.object['foreman_user']
	foreman_password = $evm.object.decrypt('foreman_password')
	base_url           = "https://#{foreman_host}/api/hosts/"
	foreman_host_id  = prov.get_option(:hostid)
	url                = "#{base_url}/#{foreman_host_id}/status"
	api_timeout        = 60
	http_method        = :get

	result = invoke_foreman_api(url, foreman_user,foreman_password)
	status = result['status']

	$evm.log("info", "Status for VM #{prov.vm.name}: #{status}")

	case status.downcase
	when 'no changes'
		$evm.root['ae_result'] = 'ok'
		$evm.log("info", "Puppet Configuration Complete")
		exit MIQ_OK
	when 'error'
		# in many environments the first puppet run will always fail
		# in this case you might want to treat the error as a non critical event instead
		$evm.log("error", "Puppet reported an error")
		$evm.root['ae_result'] = 'error'
		$evm.root['ae_reason'] = "Puppet reported an error"
	else
		retry_method("Waiting for Puppet Report")
	end
end

