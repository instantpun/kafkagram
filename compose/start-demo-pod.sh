podman pod create \
--publish 2181:2181 \
--publish 9092:9092 \
--infra \
--name demo-cluster