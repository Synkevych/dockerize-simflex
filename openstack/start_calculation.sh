#!/bin/bash

# exit on the first error
set -e

DIR_NAME=calculation_path
SERIES_PATH=series_path
NFS_SERVER=$(hostname -I)
uid=$(id username)
export LD_LIBRARY_PATH=/home/ubuntu/flexpart_lib/lib:$LD_LIBRARY_PATH

# mount DIR_NAME folder to /data
sudo mount $NFS_SERVER:$DIR_NAME /data
sudo mount $NFS_SERVER:$SERIES_PATH /series
# could be removed in production
sudo mount $NFS_SERVER:/home/flexpart/series/grid_data /grid_data

echo "FLEXPART on $(hostname) uses $(nproc) cores, $(free -h | awk '/^Mem:/ {print $2}') RAM for calculation ${DIR_NAME}" >> /data/calculations_server.log

sudo chown -R ubuntu /data/ /series /grid_data

su -c "cd /home/ubuntu/calculation && python3.6 parser.py" ubuntu

echo "FLEXPART on $(hostname) uses $(nproc) cores, $(free -h | awk '/^Mem:/ {print $2}') RAM for calculation ${DIR_NAME}" >> /data/calculations_server.log

# Change ownership recursively to the specified user
sudo chown -R "$uid:$uid" /data /series /grid_data
sudo umount /data /series /grid_data

exit 0
