#!/bin/bash
podman stop kafka --ignore && echo "Recycling kafka container"  || echo "No kafka container found"

podman volume prune --force

podman run \
--volume "kafka_data:/bitnami" \
--env ALLOW_ANONYMOUS_LOGIN=yes \
--env KAFKA_CFG_ZOOKEEPER_CONNECT=localhost:2181 \
--env ALLOW_PLAINTEXT_LISTENER=yes \
--env KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
--env KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1 \
--env KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1 \
--env KAFKA_OPTS="-Dlog4j.logger.org.apache.kafka=INFO -Dlog4j.logger.kafka=INFO" \
--pod demo-cluster \
--replace \
--detach \
--name kafka \
bitnami/kafka:3.1

# --env KAFKA_ZOOKEEPER_PROTOCOL=SSL \
# -p 9092:9092 \