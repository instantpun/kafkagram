#!/bin/bash
podman run \
--pod demo-cluster \
--replace \
--detach \
--name go-producer \
localhost/go-producer:0.1.1 localhost:9092 topic1 loop

# -p 2181:2181 \