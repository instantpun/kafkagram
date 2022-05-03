#!/bin/bash

COUNT=$1
DEFAULT_COUNT=1

if [ -z ${COUNT+x} || ${COUNT} <1 ]; then
    echo "ERROR: Cannot set COUNT to an integer less than 1."
    echo "Setting COUNT to DEFAULT_COUNT."
    COUNT=$DEFAULT_COUNT
fi


for i in {1..$COUNT}; do 
    podman stop go-consumer$i && "Recycling go-consumer$i" || echo "No go-consumer$i container found"

    podman volume prune --force

    podman run \
    --pod demo-cluster \
    --replace \
    --detach \
    --name go-consumer$i \
    localhost/go-consumer:0.1.1 localhost:9092 group1 topic1

done

# -p 2181:2181 \
