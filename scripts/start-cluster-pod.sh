#!/bin/bash

podman pod create \
--publish 2181:2181 \
--publish 9092:9092 \
--publish 18080:18080 \
--publish 28080:28080 \
--infra \
--replace \
--name demo-cluster