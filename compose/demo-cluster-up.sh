#!/bin/bash

echo "==========================="
echo "Creating infrastructure pod"
./start-cluster-pod.sh
echo "Container ID for infra pod: $(podman pod list | grep "demo-cluster" | awk '{ print $1 }')"

#############################
echo "Starting Zookeeper in pod"
./start-zookeeper.sh
sleep 3
podman container exists zookeeper
ZK_UP=$?
if [ $ZK_UP == 0 ]; then
    echo "Zookeeper container started successfully"
else
    echo "Zookeeper container failed to start. Check the logs"
    echo "terminating..."
    exit 1
fi

#############################
echo "Starting Kafka in pod"
./start-kafka.sh
sleep 3
podman container exists kafka
KF_UP=$?
if [ $KF_UP == 0 ]; then
    echo "Kafka container started successfully"
else
    echo "Kafka container failed to start. Check the logs"
    echo "terminating..."
    exit 1
fi

#############################
./start-provisioner.sh
sleep 3
./start-consumers.sh 2
./start-producer.sh

