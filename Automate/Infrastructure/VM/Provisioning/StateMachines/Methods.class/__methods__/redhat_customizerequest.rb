#
# Description: This method is used to Customize the RHEV, RHEV PXE, and RHEV ISO Provisioning Request
#

# hello Victor

# Get provisioning object
prov = $evm.root["miq_provision"]

$evm.log("info", "Disabling VM Autostart")
prov.set_option(:vm_auto_start,[false,0])

dialog_vmname = prov.get_option(:dialog_vmname)
if not dialog_vmname.nil?
  $evm.log("info", "Setting VM name to: #{dialog_vmname}")
  prov.set_option(:vm_target_name,dialog_vmname)
end

dialog_fqdn = prov.get_option(:dialog_fqdn)
if not dialog_fqdn.nil?
  $evm.log("info", "Setting FQDN to: #{dialog_fqdn}")
  prov.set_option(:vm_target_hostname,dialog_fqdn)
end

$evm.log("info", "Provisioning ID:<#{prov.id}> Provision Request ID:<#{prov.miq_provision_request.id}> Provision Type: <#{prov.provision_type}>")
