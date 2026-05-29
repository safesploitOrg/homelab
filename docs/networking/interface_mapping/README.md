# 🌐 Interface Mapping (WIP)

This document maps physical and virtual interfaces to Proxmox bridge names, VLANs, and assigned roles across the infrastructure.

Each Proxmox and infrastructure node uses a multi-bridge design to segment traffic and align with the VLAN schema in `docs/network.md`.

---

## 🖥️ Proxmox Node: `pve2`

| Bridge   | VLAN Tag | Interface (NIC)   | Subnet            | Purpose                                |
|----------|-----------|------------------|-------------------|----------------------------------------|
| `vmbr0`  | 83        | `eno1`           | `172.16.83.11/24` | Proxmox MGMT / Web UI / SSH            |
| `vmbr1`  | 3         | `eno2.3`         | `172.16.3.11/24`  | Corosync / cluster heartbeat           |
| `vmbr2`  | 110       | `eno2.110`       | `172.16.110.11/24`| Ceph public                            |
| `vmbr3`  | 111       | `eno2.111`       | `172.16.111.11/24`| Ceph cluster (OSD/MON/MGR)             |
| `vmbr4`  | 100       | `eno3.100`       | `172.16.100.11/24`| NAS / NFS / iSCSI                      |
| `vmbr10` | 4         | `eno4.4`         | dynamic via DHCP  | VM workloads (Production services)     |
| `vmbr20` | 2         | `eno4.2`         | dynamic via DHCP  | VM workloads (Development)             |

> All bridges use `bridge_stp off` and `bridge_fd 0`.


---

## 🛠️ Future Enhancements

- Define a template `proxmox-bridges.conf` for automated re-deployment
- Monitor MTU consistency for jumbo frame support (Ceph cluster links)

