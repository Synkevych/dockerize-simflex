#!/bin/bash

HASH=`date --utc +%Y%m%d%H%M`; FLAVOR="d1.xlarge"; VMNAME="flexpart_${FLAVOR/./_}_${HASH}";
TIME=$(date "+%d.%m.%Y-%H:%M:%S"); TIMER=30; KEY_PATH=.ssh/"${VMNAME}.key"
calculation_dir=$(pwd)
done_file="$calculation_dir/done.txt"

echo "calculation dir: $calculation_dir"
cd ~/ || exit
echo "home dir: $(pwd)"

# Ensure calculation folder exists
if [[ ! -d "$calculation_dir" ]]; then
    echo "Error: Calculation folder '$calculation_dir' does not exist." >&2
    exit 1
fi

# execute the test_quotas.sh script and provide the flavor name as an argument
if ! ./test_quotas.sh $FLAVOR; then
  echo "Error: Quotas are exceeded, canceling ..."
  echo -e "$TIME Quotas are exceeded, canceling ...\n" >> vm_launching.log
  exit 1
fi

# create a series dir if not exist
xml_file="$calculation_dir/input/options.xml"
if [ ! -f "$xml_file" ]; then
    echo "Error: Input file options.xml does not exist: $xml_file"
    exit 1
fi
series_id=$(grep -oP '<id_series>\K[0-9]+' "$xml_file" | sed 's/^0*//')
series_path="/home/flexpart/series/$series_id"

mkdir -p "$series_path"
echo "Series path: $series_path"
sed -i "7s@.*@SERIES_PATH=$series_path@" start_calculation.sh
# provide the calculation directory name to the VM
echo "Calculation path: $calculation_dir"
sed -i "6s@.*@DIR_NAME=$calculation_dir@" start_calculation.sh

openstack keypair create $VMNAME >> $KEY_PATH; chmod 600 .ssh/"${VMNAME}.key"

nova boot --flavor $FLAVOR\
        --image 77a8fe4c-c0ea-4ec1-9723-11c8876325e7\
        --key-name $VMNAME\
        --security-groups d134acb2-e6bc-4c82-a294-9617fdf7bf07\
	      --user-data start_calculation.sh\
        $VMNAME

echo -e "$TIME start creating VM $VMNAME, status - $STATUS\n" >> vm_launching.log
total_iterations=$(wc -l < "$xml_file")

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

    # Main loop to check for done.txt creation
    while [[ ! -f "$done_file" ]]; do
        echo "Waiting for 'done.txt' file in '$calculation_dir'..." >&2
        sleep "$TIMER"
    done
    echo "File 'done.txt' detected! Removing the VM $VMNAME" >&2
    # TODO: add argument -test=true as a value from output to make it easy while testing
	 ./delete_instance.sh $VMNAME
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
  echo "Instance ${VMNAME} does not exist, canceling."
fi
