#!/bin/bash

HASH=`date --utc +%Y%m%d%H%M`; FLAVOR="d1.xlarge"; VMNAME="flexpart_${FLAVOR/./_}_${HASH}";
TIME=$(date "+%d.%m.%Y-%H:%M:%S"); TIMER=30; KEY_PATH="/home/flexpart/.ssh/${VMNAME}.key"
calculation_dir=$(pwd)
done_file="$calculation_dir/done.txt"

log_message() {
  local message="$1"
  local calc_log="$calculation_dir/calculations_server.log"
  local vm_log="/home/flexpart/vm_launching.log"

  echo "$message"
  echo -e "$TIME $message" | tee -a "$calc_log" >> "$vm_log"
}

remove_vm() {
  log_message "Preparing to remove the virtual machine $VMNAME ..."

  if [ -f $KEY_PATH ]; then
    rm $KEY_PATH
    log_message "Private key file '$KEY_PATH' has been removed."
  else
    log_message "Private key file '$KEY_PATH' not found."
  fi

  # remove keypair if it exists
  if openstack keypair show $VMNAME > /dev/null 2>&1; then
    openstack keypair delete $VMNAME
    log_message "Keypair ${VMNAME} has been deleted."
  else
    log_message "Keypair ${VMNAME} does not exist."
  fi

  # check if it the instance exists
  if openstack server show $VMNAME > /dev/null 2>&1; then
    openstack server stop $VMNAME && openstack server delete $VMNAME
    log_message "Instance ${VMNAME} has been deleted."
  else
    log_message "Instance ${VMNAME} does not exist, canceling."
  fi
}

# Define cleanup function for other errors
cleanup() {
    local vm_created=$1
    local message=$2

    if [[ $# -eq 1 && $1 =~ ^[0-9]+$ ]]; then
      message="Command exited with status $1"
    # Remove VM if it exists
    elif [ "$vm_created" = true ]; then
      remove_vm
    fi
    # Create a done.txt to indicate finishing the calculation
    log_message "launch_error: $message\n"
    touch "$done_file"
    exit 1
}

test_quotas() {
  # Get flavor information
  flavor_info=$(openstack flavor show $FLAVOR)

  if [[ -z "$flavor_info" ]]; then
    cleanup false "Flavor information is empty, can't start instance."
  fi

  # Extract flavor cores and RAM
  flavor_cores=$(echo "$flavor_info" | awk '/vcpus/ { print $4 }')
  flavor_ram=$(echo "$flavor_info" | awk '/ram/ { print $4 }')

  # Get Nova limits
  limits=$(nova limits 2>/dev/null | awk '/Cores|Instances|RAM/')
  # Extract all cores, used cores, all instances, used instances, all RAM, and used RAM
  read all_cores used_cores all_instances used_instances all_ram used_ram <<< $(echo $limits | awk '{ print $6, $4, $13, $11, $20, $18 }')
  if (( $used_cores + $flavor_cores > $all_cores )); then
	  cleanup false "Core limit was reached! Fire $(expr $used_cores + $flavor_cores - $all_cores ) cores or change the flavor. Canceling ..."
  fi

  if (( $used_instances + 1 >= $all_instances )); then
    cleanup false "Instance limit was reached. Delete one of the instances. Canceling ..."
  fi

  if (( $used_ram + $flavor_ram > $all_ram )); then
    cleanup false "RAM limit was reached. Delete one of the instances or change the flavor. Canceling ..."
  fi
}

log_message "Process ID: $$"

# Trap errors and call cleanup function, it will delete VM and create done.txt
trap 'cleanup true' ERR

. /home/flexpart/.WRF-UNG # load openstack environment variables

# Ensure calculation folder exists
if [[ ! -d "$calculation_dir" ]]; then
    cleanup false "Calculation folder '$calculation_dir' does not exist."
fi

# execute the test_quotas.sh script and provide the flavor name as an argument
if ! test_quotas; then
  cleanup false "Quotas are exceeded, Canceling ..."
fi

# create a series dir if not exist
xml_file="$calculation_dir/input/options.xml"
if [ ! -f "$xml_file" ]; then
    cleanup false "File $xml_file does not exist."
fi

series_id=$(grep -oP '<id_series>\K[0-9]+' "$xml_file" | sed 's/^0*//')
series_path="/home/flexpart/series/$series_id"
mkdir -p "$series_path"

# provide the calculation directory name to the VM
sed -i "6s@.*@DIR_NAME=$calculation_dir@" start_calculation.sh
log_message "Calculation path: $calculation_dir"
sed -i "7s@.*@SERIES_PATH=$series_path@" start_calculation.sh
log_message "Series path: $series_path"

openstack keypair create $VMNAME >> $KEY_PATH; chmod 600 .ssh/"${VMNAME}.key"

instance_id=$(nova boot --flavor $FLAVOR\
        --image f7eed42e-266d-4576-8ac6-b6dbbfa53233\
        --key-name $VMNAME\
        --security-groups d134acb2-e6bc-4c82-a294-9617fdf7bf07\
        --user-data /usr/local/bin/start_calculation.sh\
        $VMNAME\
        2>/dev/null | awk '/ id / {print $4}')

# Check if instance creation was successful
if [ -z "$instance_id" ]; then
    cleanup true "Failed to create instance."
fi

log_message "$TIME start creating VM $VMNAME, status - $STATUS."

while true; do
  	STATUS=$(openstack server show --format value -c status $instance_id)

    if [ "$STATUS" == "ACTIVE" ]; then
     	IP=`openstack server show --format value -c addresses $instance_id | awk '{ split($1, v, "="); print v[2]}'`

      log_message "$TIME VM $VMNAME is $STATUS, IP address $IP"
      log_message "To connect use: ssh -i $KEY_PATH ubuntu@$IP\n"

        # Main loop to check for done.txt creation
        log_message "Calculation for '$calculation_dir' and series '$series_path' on VM $VMNAME started."
        log_message "Waiting for 'done.txt' file in '$calculation_dir'..."
        while [[ ! -f "$done_file" ]]; do
          sleep "$TIMER"
        done
        log_message "File 'done.txt' detected! Removing the VM $VMNAME"
        # TODO: add argument -test=true as a value from output to make it easy while testing
        remove_vm
        exit 0
        break
    elif [ "$status" == "ERROR" ]; then
        cleanup true "Instance $VMNAME creation failed."
    fi
    sleep 5
done

trap - ERR
