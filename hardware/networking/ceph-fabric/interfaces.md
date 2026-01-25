# Ceph Fabric

## /etc/network/interfaces

```txt
auto eno2
iface eno2 inet manual
# PVE Ceph Fabric

auto vmbr-ceph
iface vmbr-ceph inet static
	address 10.50.0.40/24
	bridge-ports eno2
	bridge-stp off
	bridge-fd 0
#Ceph (Fabric)
```