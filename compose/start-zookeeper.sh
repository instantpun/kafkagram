#!/bin/bash
podman stop zookeeper || echo "No zookeeper container found"

podman volume prune --force

podman run \
--volume "zookeeper_data:/bitnami" \
--env ALLOW_ANONYMOUS_LOGIN=yes \
--env JVMFLAGS="-Dlog4j.logger.org.apache.zookeeper=DEBUG -Dlog4j.logger.zookeeper=DEBUG" \
--pod demo-cluster \
--replace \
--detach \
--name zookeeper \
bitnami/zookeeper:3.8 

# -p 2181:2181 \