#
# create_snapshot.rb
# Description: create a snapshot of the selected VM
#
require 'rest-client'
require 'json'
require 'openssl'

def call_rhevm(ext_mgt_system, uri, type=:get, payload=nil)
  params = {
    :method => type,
    :url => "https://#{ext_mgt_system[:hostname]}#{uri}",
    :user => ext_mgt_system.authentication_userid,
    :password => ext_mgt_system.authentication_password,
    :headers => { :accept => :json, :content_type => :json },
    :verify_ssl => OpenSSL::SSL::VERIFY_NONE
  }
  params[:payload] = JSON.generate(payload) if payload
  return JSON.parse(RestClient::Request.new(params).execute)
end

$evm.log("info", "Begin Automate Method")

ext_mgt_system = $evm.root['vm'].ext_management_system

$evm.log("info", "Got ext_management_system #{ext_mgt_system.name}")

vm=$evm.root["vm"]
vmuuid=vm["uid_ems"]
$evm.log("info", "RHEV UUID: #{vmuuid}")

payload = {
	:description => $evm.root["dialog_snapshot_name"]
}

$evm.log("info", "Calling /api/vms/#{vmuuid}/snapshots/ with payload #{payload}")
create_snapshot = call_rhevm(ext_mgt_system, "/api/vms/#{vmuuid}/snapshots/", :post, payload)

$evm.log("info", "End Automate Method")
