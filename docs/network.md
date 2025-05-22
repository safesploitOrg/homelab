

## 🧱 Network Structure (Legacy)

Current internal networks operate within the `172.16.0.0/16` RFC1918 private range and secured via Proxmox VE’s hypervisor-level firewalling.

|  Subnet              | Purpose                                  |
|----------------------|-------------------------------------------|
| `172.16.0.0/16`      | Core infrastructure / routing             |
| `172.16.1.0/16`      | Test lab / scratch environment            |
| `172.16.2.0/16`      | Development                               |
| `172.16.3.0/16`      | Proxmox cluster communications            |
| `172.16.4.0/16`      | Production services                       |
| `172.16.5.0/16`      | Critical production (e.g., Vault, core DB)|
| `172.16.8.0/16`      | Security stack (Wazuh, PKI, Vault)        |
| `172.16.35.0/16`     | Docker-only workloads                     |
| `172.16.40.0/16`     | Trusted IPs (admin endpoints, jumpboxes)  |
| `172.16.45.0/16`     | 🧰 Setup VLAN — has access to all VLANs   |
| `172.16.81.0/16`     | IPMI                                      |
| `172.16.90.0/16`     | IT endpoints                              |
| `172.16.100.0/16`    | Storage backends (NAS, Ceph)              |
| `172.16.123.0/16`    | Backup systems (PBS, Bareos, rsync)       |
| `172.16.191.0/16`    | Windows lab / AD / GPO testing            |

---

## Redesigning The Subnets

All internal networks operate within the `172.16.0.0/16` RFC1918 private range and are being standardised to `/24` segments based on service role.

| Range     | Purpose Category        |
| --------- | ----------------------- |
| `0–49`    | General infrastructure  |
| `50–99`   | Admin, mgmt, access     |
| `100–149` | Storage, backup, Ceph   |
| `150–199` | Labs & special services |




### 🧱 Network VLAN Structure (New)

VLANs are enforced via L2/L3 switching and Proxmox VE’s hypervisor-level firewalling. This structure supports Zero Trust principles, observability, and secure automation.

| Subnet             | Role / Purpose                                      | Range Category            |
|--------------------|------------------------------------------------------|---------------------------|
| `172.16.0.0/24`     | Core routing / gateway                              | Core infrastructure        |
| `172.16.1.0/24`     | Test lab / scratch systems                          | Core infrastructure        |
| `172.16.2.0/24`     | Development VMs                                     | Core infrastructure        |
| `172.16.3.0/24`     | Proxmox VE cluster comms (corosync, etc)            | Core infrastructure        |
| `172.16.4.0/24`     | Production services (nginx, )                       | Core infrastructure        |
| `172.16.5.0/24`     | Critical production (Vault, DBs, etc.)              | Core infrastructure        |
| `172.16.6.0/24`     | Infra core: DNS, DHCP, NTP, **Prod AD/LDAP**        | Core infrastructure        |
| `172.16.7.0/24`     | Internal mirrors / apt-cache                        | Core infrastructure (optional) |
| `172.16.35.0/24`    | Docker-only network                                 | Core infrastructure        |
| `172.16.55.0/24`    | 🧰 Setup VLAN — unrestricted setup                  | Admin, access              |
| `172.16.81.0/24`    | OOB management (IPMI, BMC, iDRAC)                   | Admin, MGMT                |
| `172.16.82.0/24`    | Ansible, GitOps, Jenkins runners                    | Admin, MGMT                |
| `172.16.83.0/24`    | Proxmox web/API access (admin interface)            | Admin, mgmt, access        |
| `172.16.84.0/24`    | VMware (admin interface)                            | Admin, mgmt, access        |
| `172.16.85.0/24`    | Kubernetes nodes (control plane + workers)          | Admin, MGMT, access        |
| `172.16.90.0/24`    | IT endpoints / admin laptops                        | Admin, access              |
| `172.16.91.0/24`    | Trusted jumpboxes / admin desktops                  | Admin, access              |
| `172.16.100.0/24`   | NAS                                                 | Storage                    |
| `172.16.110.0/24`   | Ceph public network (client-facing)                 | Storage (Ceph)             |
| `172.16.111.0/24`   | Ceph cluster network (OSD/Mon/Mgr)                  | Storage (Ceph)             |
| `172.16.120.0/24`   | Monitoring: Prometheus, Wazuh, CheckMK              | Observability              |
| `172.16.121.0/24`   | Logging / syslog aggregation (optional)             | Observability (optional)   |
| `172.16.123.0/24`   | Backup zone: PBS, Bareos, Restic, rsync             | Backup                     |
| `172.16.160.0/24`   | IoT / untrusted devices (smart plugs, sensors)      | Special services (optional)|
| `172.16.175.0/24`   | Ephemeral runners / GitHub CI agents                | Special services (optional)|
| `172.16.180.0/24`   | Honeypots / deception systems                       | Security testing (optional)|
| `172.16.185.0/24`   | VPN clients / WireGuard / Tailscale ingress         | Remote access (optional)   |
| `172.16.191.0/24`   | Windows lab / AD testing / GPO sandbox              | Labs                       |
| `172.16.200.0/24`   | DMZ: reverse proxies, VPN, Firezone                 | DMZ                        |

> 🔐 VLANs are declared in `dnsmasq` configs and consumed via `host_vars`, `group_vars`, and PVE firewall groups. All policies are enforced as code using Ansible and Proxmox firewall templates.
