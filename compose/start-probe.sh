#!/bin/bash
podman stop probe || echo "No probe container found"

podman run \
--pod demo-cluster \
--replace \
--detach \
--name probe \
bitnami/kafka:3.1 /bin/bash -c '/opt/bitnami/kafka/bin/kafka-topics.sh --create --topic topic1 --partitions 2 --bootstrap-server localhost:9092'

# 'while true; do sleep 2; done'
# podman exec -it probe /bin/bash -c '/opt/bitnami/kafka/bin/kafka-topics.sh --create --topic topic1 --partitions 2 --bootstrap-server localhost:9092'