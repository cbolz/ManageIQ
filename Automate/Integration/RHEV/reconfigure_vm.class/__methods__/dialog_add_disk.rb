###################################
#
# This method returns the list of data stores to be used in a dynamic drop down list
#
# install xmlsimple with "gem install xml-simple"
#
###################################
def getstorages(rhevmhost,rhevmuser,rhevmpass)
  require 'rubygems'
  require 'rest_client'
  require 'nokogiri'

  storages = Array.new{Array.new}

  resource = RestClient::Resource.new(rhevmhost, :user => rhevmuser, :password => rhevmpass, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
  storage_data = Nokogiri::XML(resource["/api/storagedomains/"].get.body)
  storage_data.xpath("//storage_domain").each do |storage_domain|
    if storage_domain.xpath('type').text == "data"
      name=storage_domain.xpath('name').text
      $evm.log("info", "Name: #{name}")
      storages.push [name, name]
    end
  end

  return storages
end

begin
  @method = 'dialog_add_disk'
  $evm.log("info", "#{@method} - EVM Automate Method: <#{@method}> Started")

  vm=$evm.root['vm']
  ext_mgt_system = vm.ext_management_system

  rhevmhost = "https://#{ext_mgt_system.hostname}"
  rhevmuser = ext_mgt_system.authentication_userid
  rhevmpass = ext_mgt_system.authentication_password

  vmuid=vm.uid_ems
  vmtype=vm.type

  $evm.log("info","#{@method} - ext_mgt_system: #{ext_mgt_system.hostname}")
  $evm.log("info","#{@method} - vm: #{vm}")
  $evm.log("info","#{@method} - vmuid: #{vmuid}")
  $evm.log("info","#{@method} - vmtype: #{vmtype}")

  unless vmtype == "ManageIQ::Providers::Redhat::InfraManager::Vm"
    # this will populate the dialog in case we are not on RHEV
    storages = Array.new{Array.new}
    storages.push ["No Valid","No Valid"]
    dialog_field = $evm.object
    dialog_field["sort_by"] = "value"
    dialog_field["data_type"] = "string"
    dialog_field["required"] = "true"
    dialog_field["values"] = storages
    dialog_field["default_value"] = "No Valid"
    $evm.log("info", "#{@method} - VM Type != RHEV")
    $evm.log("info", "#{@method} - EVM Automate Method: <#{@method}> Ended")
    exit MIQ_OK
  end

  storages=getstorages(rhevmhost,rhevmuser,rhevmpass)
  $evm.log("info","#{@method} - storages: #{storages}")

  dialog_field = $evm.object

  # sort_by: value / description / none
  dialog_field["sort_by"] = "value"

  # sort_order: ascending / descending
  dialog_field["sort_order"] = "ascending"

  # data_type: string / integer
  dialog_field["data_type"] = "string"

  # required: true / false
  dialog_field["required"] = "true"

  dialog_field["values"] = storages

  dialog_field["default_value"] = storages.first.first

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
