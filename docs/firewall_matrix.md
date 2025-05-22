# 🔐 Firewall Matrix (WIP)

This document defines the allowed traffic between VLANs and key services in the `172.16.0.0/16` lab network.  
It follows Zero Trust and least privilege principles, enabling per-role enforcement using Proxmox VE firewall, `iptables`, or overlay tooling (e.g. Firezone, Traefik, Calico).

---

## 🔰 Access Between VLANs

| Source Subnet      | Destination Subnet   | Ports / Protocols           | Purpose                                        |
|--------------------|----------------------|------------------------------|------------------------------------------------|
| `82.0` GitOps       | `85.0` Kubernetes     | TCP 6443 (HTTPS)             | Apply manifests, secrets injection             |
| `82.0` GitOps       | `83.0` Proxmox MGMT   | TCP 8006, 22                 | Update VM configs, trigger pipelines           |
| `83.0` Admin        | `5.0` Vault/DB        | TCP 8200, 5432               | Secure secrets, DB mgmt                        |
| `90.0` Laptops      | `83.0` Proxmox        | TCP 8006, 22                 | Admin panel and SSH                            |
| `90.0` Laptops      | `84.0` VMware         | TCP 443                      | vSphere access                                 |
| `91.0` Jumpboxes    | `All`                 | TCP 22, 443, 8006, ICMP      | Controlled admin access                         |
| `45.0` Setup        | `6.0`, `83.0`, `5.0`  | DHCP, PXE, web API          | Temporary boot/install access                  |
| `85.0` Kubernetes   | `5.0` Vault           | TCP 8200                     | Pull secrets for workloads                     |
| `85.0` Kubernetes   | `120.0` Monitoring    | TCP 9100, 10250              | Exporter metrics                               |
| `120.0` Monitoring  | `All`                 | TCP 9100, 9090, ICMP         | Metrics scraping (node-exporter, K8s)          |
| `121.0` Logging     | `All`                 | TCP 514, TCP 1514, UDP 514   | Central syslog receiver                        |
| `123.0` Backup      | `All`                 | TCP 22, 873 (rsync)          | PBS, Bareos pull jobs                          |
| `185.0` VPN         | `83.0`, `85.0`, `82.0`| TCP 443, 8006, 22            | Remote admin & GitOps access                   |
| `175.0` Runners     | `85.0`, `82.0`        | TCP 443                      | CI/CD communication (k8s, GitOps)              |

---

## 🔒 Restricted / Blocked Paths

| Source        | Destination      | Action     | Reason                              |
|---------------|------------------|------------|-------------------------------------|
| `160.0` IoT    | `5.0` Vault       | ❌ Block    | Untrusted segment                   |
| `45.0` Setup   | `120.0` Prometheus| ❌ Block    | Prevent setup from hitting metrics  |
| `200.0` DMZ    | `111.0` Ceph CL   | ❌ Block    | DMZ should never hit Ceph internal  |
| `191.0` Lab    | `6.0` Core infra  | ❌ Block    | Prevent AD lab talking to prod AD   |

---

## ✅ Required Internal Traffic

| Subnet             | Ports / Purpose                         |
|--------------------|------------------------------------------|
| `3.0` Proxmox nodes| UDP 5404–5405 (Corosync), TCP 8006/22    |
| `110.0` ↔ `111.0`   | TCP 6789, TCP 3300, TCP 6800–7300 (Ceph) |
| `6.0` Infra core   | DNS (53), DHCP (67/68), NTP (123), LDAP  |
| `5.0` Vault        | 8200 (Vault), DB 5432/3306               |

---

## 📦 Port Reference

| Service         | Port(s) Used   | Protocol      |
|------------------|----------------|---------------|
| SSH              | 22             | TCP           |
| Proxmox Web UI   | 8006           | TCP           |
| Kubernetes API   | 6443           | TCP           |
| Vault            | 8200           | TCP           |
| PostgreSQL       | 5432           | TCP           |
| MySQL            | 3306           | TCP           |
| Ceph Public      | 6789, 3300     | TCP           |
| Ceph OSD         | 6800–7300      | TCP           |
| DNS              | 53             | TCP/UDP       |
| DHCP             | 67/68          | UDP           |
| NTP              | 123            | UDP           |
| Syslog (rsyslog) | 514, 1514      | UDP/TCP       |
| Prometheus       | 9090           | TCP           |
| Node Exporter    | 9100           | TCP           |
| Kubelet Metrics  | 10250          | TCP           |

---

## 🧠 Notes

- All outbound access from VPN, Setup VLAN, and CI runners should be **logged**
- Consider `group_vars/firewall_matrix.yml` to enforce this as code
- Alerts should trigger on traffic **outside this matrix**

