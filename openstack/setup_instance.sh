#!/bin/bash

HASH=`date --utc +%Y%m%d%H%M`; FLAVOR="m1.2xlarge"; VMNAME="flexpart_${FLAVOR/./_}_${HASH}";
TIME=$(date "+%d.%m.%Y-%H:%M:%S"); TIMER=30; KEY_PATH=.ssh/"${VMNAME}.key"

openstack keypair create $VMNAME >> $KEY_PATH; chmod 600 .ssh/"${VMNAME}.key"

nova boot --flavor $FLAVOR\
        --image cb3c7000-ed38-4e9d-a726-4d648dcbc9c9\
        --key-name $VMNAME\
        --security-groups d134acb2-e6bc-4c82-a294-9617fdf7bf07\
        $VMNAME

echo -e "$TIME start creating VM $VMNAME, status - $STATUS\n" >> vm_launching.log

for i in `seq 1 3`; do
        echo -ne "$i attempt to start VM \033[0K\r"
	sleep $TIMER & wait

  	STATUS=`openstack server list | grep $VMNAME | awk '{ print $6 }'`
  	IP=`openstack server list | grep $VMNAME | awk '{ split($8, v, "="); print v[2]}'`
  	SYSTEM=`openstack server list | grep $VMNAME | awk '{ print $10 $11 }'`

  	if [ "x$STATUS" = "xACTIVE" ]; then
		printf "VM $VMNAME is $STATUS, IP address $IP, system $SYSTEM\n"
    		echo "$TIME VM $VMNAME is $STATUS, IP address $IP, system $SYSTEM" >> vm_launching.log
		printf "To connect use: ssh -i $KEY_PATH ubuntu@$IP\n"
		echo -e "To connect use: ssh -i $KEY_PATH ubuntu@$IP\n" >> vm_launching.log
		exit 0
	fi
done

if test -z "$STATUS"; then
	echo "Launching $VMNAME failed"
	echo -e "$TIME Launching VM $VMNAME failed\n" >> vm_launching.log
else
	printf "Launching $VMNAME failed with status: $STATUS"
	echo -e "$TIME Launching VM $VMNAME failed\n" >> vm_launching.log
fi

private_key=".ssh/${VMNAME}.key"
if [ -f $private_key ]; then
	rm $private_key
        echo "Private key file '$private_key' has been removed."
else
	echo "Private key file '$private_key' not found."
fi

# remove keypair if it exists
if openstack keypair show $VMNAME > /dev/null 2>&1; then
  openstack keypair delete $VMNAME
  echo "Keypair ${VMNAME} has been deleted."
else
  echo "Keypair ${VMNAME} does not exist"
fi

# check if it the instance exists
if openstack server show $VMNAME > /dev/null 2>&1; then
  openstack server stop $VMNAME && openstack server delete $VMNAME
  echo "Instance ${VMNAME} has been deleted."
else
  echo "Instance ${VMNAME} does not exist."
fi
