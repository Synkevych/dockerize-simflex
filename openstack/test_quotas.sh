#!/bin/bash

if [ $# -ne 1 ]; then echo "Usage: $0 flavor_name"; exit 1; fi

set -e

flavor_info=`openstack flavor list --all | grep $1`

flavor_cores=`echo $flavor_info | awk '{ print $12 }'`
flavor_ram=`echo $flavor_info | awk '{ print $6 }'`

limits=`nova limits 2>/dev/null | grep 'Cores\|Instances\|RAM'`

all_cores=`echo $limits | awk '{ print $6 }'`
used_cores=`echo $limits | awk '{ print $4 }'`

all_instances=`echo $limits | awk '{ print $13 }'`
used_instances=`echo $limits | awk '{ print $11 }'`

all_ram=`echo $limits | awk '{ print $20 }'`
used_ram=`echo $limits | awk '{ print $18 }'`
TIME=$(date "+%d.%m.%Y-%H:%M:%S")

if (( $used_cores + $flavor_cores > $all_cores )); then
        echo "Core limit was reached! Your need to fire $(expr $all_cores - $used_cores + $flavor_cores ) cores or change the flavor. Canceling ..."
        echo -e "$TIME Core limit was reached! Your need to fire $(expr $used_cores + $flavor_cores - $all_cores) cores." >> vm_launching.log;
	exit 1
fi

if (( $used_instances + 1 >= $all_instances )); then
	echo "Instance limit was reached. You need to delete one of the instances. Canceling ...";
	echo -e "$TIME Instance limit was reached." >> vm_launching.log
	exit 1
fi

if (( $used_ram + $flavor_ram > $all_ram )); then
  echo "RAM limit was reached. You need to delete one of the instances or change the flavor. Canceling ...";
  echo -e "$TIME RAM limit was reached." >> vm_launching.log
  exit 1
fi
