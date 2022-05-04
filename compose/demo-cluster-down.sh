#!/bin/bash

STAGE1_IDS="zookeeper kafka provisioner"
STAGE2_IDS="$(podman ps -a | grep -e "go-consumer\d" | awk '{ $1 }')"
STAGE3_IDS="go-producer"


function container_shutdown {
    local ID=${1:?Must provide a container ID}
    podman stop $ID --ignore
    podman rm $ID --force
}

# Stage 3
# "$(podman ps -a | grep -e "go-producer" | awk '{ $1 }')"
for P_ID in $STAGE3_IDS; do 
    container_shutdown $P_ID
done

# Stage 2 
for C_ID in $STAGE2_IDS; do
    container_shutdown $C_ID
done

# Stage 1
for ID in $STAGE1_IDS; do
    container_shutdown $ID
done