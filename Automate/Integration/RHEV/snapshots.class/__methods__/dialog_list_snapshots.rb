#
# dialog_list_snapshots.rb
# Description: Retrieve a list of available snapshots for the selected VM
# 		To be used in a dynamic dropdown list
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

snapshots = call_rhevm(ext_mgt_system, "/api/vms/#{vmuuid}/snapshots/", :get)

dialog_field = $evm.object
# sort_by: value / description / none
dialog_field["sort_by"] = "description"
# sort_order: ascending / descending
dialog_field["sort_order"] = "ascending"
# data_type: string / integer
dialog_field["data_type"] = "string" 
# required: true / false
dialog_field["required"] = "true"

snapshotlist={}
snapshots["snapshot"].each do |snapshot| 
  $evm.log("info", "Current snapshot: #{snapshot["description"]}")
  description=snapshot["description"]
  id=snapshot["id"]
  snapshotlist[id]=description
end

$evm.log("info", "Liste: #{snapshotlist}")

dialog_field["values"]=snapshotlist

#$evm.log("info", "Response: #{import_response.inspect}")
#import_job = import_response["job"]["href"]

$evm.log("info", "End Automate Method")
