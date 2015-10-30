#
# This script runs a command inside the virtual machine
#
# The command is executed by utilizing the VMware Tools running on the VM
# If the tools are not running, this will fail.
# One advantage of using this method to execute a command within the VM,
# is that it does not a require a network connection between CF and the VM.
#

begin
  @method = 'runProgramInGuest'
  $evm.log("info", "#{@method} - EVM Automate Method Started")

  require 'rbvmomi'

  def exec_command(vim, vm_ref, guest_user, guest_pass, command, arguments, workdir)
    auth = RbVmomi::VIM::NamePasswordAuthentication({:username => guest_user, :password => guest_pass, :interactiveSession => false})

    guest_op_managers = vim.serviceContent.guestOperationsManager

    vm = vim.searchIndex.FindByUuid(uuid: vm_ref, vmSearch: true)

    prog_spec = RbVmomi::VIM::GuestProgramSpec(
    :programPath => command,
    :arguments => arguments,
    :workingDirectory => workdir)

    res = guest_op_managers.processManager.StartProgramInGuest(
    :vm => vm,
    :auth => auth,
    :spec => prog_spec)

  end

  guest_user = nil
  guest_pass = nil
  guest_user ||= $evm.object['guest_user']
  guest_pass ||= $evm.object.decrypt('guest_pass')
  command    ||= $evm.object['command']
  arguments  ||= $evm.object['arguments']
  workdir    ||= $evm.object['workdir']

  vm = $evm.root['vm']
  $evm.log("error", "#{@method} - Missing $evm.root['vm'] object") if vm.nil?
  vm_ref = vm.uid_ems

  VIM = RbVmomi::VIM

  # Check to ensure that the VM in question is vmware
  vendor = vm.vendor.downcase rescue nil
  $evm.log("info", "#{@method} - Invalid vendor detected: #{vendor}" unless vendor == 'vmware'

  # retrieve Provider URL and credentials from the VMDB
  servername = vm.ext_management_system.hostname
  username = vm.ext_management_system.authentication_userid
  password = vm.ext_management_system.authentication_password

  # open connection to vCenter
  vim = RbVmomi::VIM.connect host: servername, user: username, password: password, insecure: true

  # execute command inside the VM
  exec_command(vim, vm_ref, guest_user, guest_pass, command, arguments, workdir)

  #
  # Exit method
  #
  $evm.log("info", "#{@method} - EVM Automate Method Ended")
  exit MIQ_OK

  #
  # Set Ruby rescue behavior
  #
rescue => err
  $evm.log("error", "#{@method} - [#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_ABORT
end
