#!/bin/bash

COUNT=$1
DEFAULT_COUNT=1

if [[ -z ${COUNT+x} ]] ||[[ ${COUNT} -lt 1 ]]; then
    echo "ERROR: Cannot set COUNT to an integer less than 1."
    echo "Setting COUNT to DEFAULT_COUNT=$DEFAULT_COUNT."
    COUNT=$DEFAULT_COUNT
fi

# echo "$COUNT" > consumers.count
for ((i=1;i<=COUNT;++i)); do
    podman container exists "go-consumer$i"
    EXISTS=$?
    if [ $EXISTS == 0 ]; then
        echo "Recycling container for go-consumer$i"
    else
        echo "No container for go-consumer$i. Starting new container"
    fi

    podman run \
    --pod demo-cluster \
    --replace \
    --detach \
    --name "go-consumer$i" \
    localhost/go-consumer:0.1.1 localhost:9092 group1 "go-consumer$i" topic1

done

# -p 2181:2181 \
