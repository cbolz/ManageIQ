# READ

This directory contains a couple of example Control Policies to be used in CloudForms or ManageIQ.

* VM-Security-Profile.yaml: Runs a Compliance Check after Smart State Analysis completed. Checking for SELinux to be configured in enforcing mode. Check this blog post for more details: [SELinux Compliance Policy](http://www.jung-christian.de/post/2017/10/control-policy-selinux/)
* VM-Security-Profile-with-Ansible-Action.yaml: extension of the previous example, this time with Ansible action to fix the configuration error. A new blog post can be found with the title [Enforce SELinux Compliance Policy with Ansible](http://www.jung-christian.de/post/2017/12/enforce-selinux-with-ansible/)
