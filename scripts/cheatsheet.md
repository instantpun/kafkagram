### Cheatsheet for admin commands

Use to cleanup leftover containers
```
for ID in $(podman ps -a --log-level error | grep bitnami | awk '{ print $1 }' 2>/dev/null); do podman rm $ID; done
```