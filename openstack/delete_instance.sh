#!/bin/bash

if [ $# -ne 1 ]; then echo "Usage: $0 VM_name"; exit 1; fi

# exit on the first error
set -e

# should be moved to launch_instance
. .WRF-UNG # load openstack environment variables

VM_NAME=$1
TIME=$(date "+%d.%m.%y-%H:%M:%S")

echo "Preparing to remove the virtual machine $VM_NAME ..."

private_key=".ssh/${VM_NAME}.key"
if [ -f $private_key ]; then
	rm $private_key
        echo "Private key file '$private_key' has been removed."
        echo "$TIME Private key for '$private_key' deleted." >> vm_launching.log
else
	echo "Private key file '$private_key' not found."
fi

# remove keypair if it exists
if openstack keypair show $VM_NAME > /dev/null 2>&1; then
  openstack keypair delete $VM_NAME
  echo "Keypair ${VM_NAME} has been deleted."
  echo "$TIME Keypair $VM_NAME deleted." >> vm_launching.log
else
  echo "Keypair ${VM_NAME} does not exist"
fi

# check if it the instance exists
if openstack server show $VM_NAME > /dev/null 2>&1; then
  openstack server stop $VM_NAME && openstack server delete $VM_NAME
  echo "Instance ${VM_NAME} has been deleted."
  echo -e "$TIME Instance $VM_NAME deleted.\n" >> vm_launching.log
else
  echo "Instance ${VM_NAME} does not exist."
fi
