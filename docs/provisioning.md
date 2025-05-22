# ⚙️ Provisioning & Automation Guide

This document outlines how infrastructure within the homelab is provisioned, configured, and managed. It follows a modular, secure-by-default approach using multiple tools depending on environment and target system.

---

## 🔧 Provisioning Tools Overview

| Tool       | Purpose                                           | Scope                     |
|------------|---------------------------------------------------|----------------------------|
| **Kickstart (GitLab)** | Bootstrap LXC containers without cloud-init | On-prem LXC / Proxmox nodes |
| **Ansible**  | Idempotent configuration management             | All nodes (LXC, KVM, Pi)  |
| **Terraform**| Infrastructure-as-code for cloud and VMs        | Cloud (AWS, test GCP), optional local VMs |
| **Packer**   | Image building (for LXC base images, KVM VMs)   | Optional base OS images    |
| **CI/CD**    | GitHub Actions, Jenkins                         | Code validation + deployment pipelines |
| **GitLab (Self-Hosted)** | Secondary GitOps repo & LXC bootstrap | Private LXC-specific workflows |

---

## 🚀 Kickstart Bootstrap for LXC Containers

Due to limitations with LXC (no cloud-init support, no console injection), all LXC containers are bootstrapped using a GitLab-hosted script:

- GitLab Repo: `https://gitlab.safesploit.com/root/kickstart`
- Script: `kickstart-el9.sh`
- Delivery: CURL-executed in container post-deployment
- What it does:
  - Creates a user with `SSH` key
  - Installs `sudo`, `openssh-server`
  - Enables `systemd`-based services for Ansible to use

This process ensures containers are **reachable by Ansible** for role application.

---

## 🛠️ Ansible Roles & Inventory

Ansible is the primary configuration tool for the entire homelab. The approach is modular, with roles such as:

- `common` – SSH, timezone, sudoers, monitoring agent
- `dnsmasq` – DNS + DHCP config
- `vault-client` – Vault agent templates
- `docker` – Docker engine install + socket hardening
- `prometheus-exporters` – Node, Ceph, and K8s exporters
- `kube-node` – K8s kubelet, CRI install, firewall config
- `automatic updates` - dnf-automatic, unattended-upgrades,

Inventories are split by environment:

```
inventories/
production/
hosts.yml
staging/
hosts.yml
test/
hosts.yml
```

> All nodes must have SSH (port 22) open and a reachable `ansible_user`.

---

## ☁️ Terraform Usage

Terraform is used for:

- Cloud environments (AWS EC2, S3 buckets, Route53 records)
- Occasionally: creating CTs/VMs on Proxmox via `Telmate/proxmox` provider
- Declaring firewall rules, IAM policies, or DNS records

---

## 📦 Image Creation (Packer) (WIP)

For creating base images:

- LXC: Preseeded templates that are pushed to Proxmox storage
- KVM: AlmaLinux and Debian VM images preconfigured with QEMU Guest Agent and SSH

These are tagged and reused by Terraform or manually provisioned through Proxmox UI.

---

## 🧠 Provisioning Flow Summary

1. **LXC/VM is created** in Proxmox with IP from DHCP (or static)
  - **Manual**: Being replaced with Terraform
2. **Kickstart script is run** (LXC only) to enable SSH
3. **Ansible applies roles** based on group and host vars
4. **Monitoring** configured as part of final role
