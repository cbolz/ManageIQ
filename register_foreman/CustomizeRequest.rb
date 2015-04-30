#
# Description: This method is used to Customize the RHEV, RHEV PXE, and RHEV ISO Provisioning Request
#
@method = 'CustomizeRequest'
$evm.log("info", "#{@method} - EVM Automate Method Started")

# Get provisioning object
prov = $evm.root["miq_provision"]

$evm.log("info", "Provisioning ID:<#{prov.id}> Provision Request ID:<#{prov.miq_provision_request.id}> Provision Type: <#{prov.provision_type}>")

# Dump all of root's attributes to the log
$evm.root.attributes.sort.each { |k, v| $evm.log("info", "#{@method} Root:<$evm.root> Attribute - #{k}: #{v}")}

fqdn=prov.get_option(:dialog_fqdn)
if fqdn.nil? or fqdn.blank?
	$evm.log("info", "No FQDN in dialog specified, keeping default auto name")
else
	$evm.log("info", "FQDN from Dialog: #{fqdn}")
	shortname=fqdn.split('.')[0]
	$evm.log("info", "Using short name #{shortname}>")
	prov.set_option(:vm_target_name,shortname)
	prov.set_option(:vm_target_hostname,fqdn)
end

