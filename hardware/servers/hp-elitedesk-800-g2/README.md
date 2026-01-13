# HP EliteDesk 800 G2 Mini

## Key Takeaways

  - [✅ What the EliteDesk 800 G2 Mini *Does* Support](#-what-the-elitedesk-800-g2-mini-does-support)
  - [❌ What the EliteDesk 800 G2 Mini *Does NOT* Support (by default)](#-what-the-elitedesk-800-g2-mini-does-not-support-by-default)
  - [⚠️ Conditional Support: Intel AMT (vPro)](#-conditional-support-intel-amt-vpro)
  - [🧪 Verifying AMT Support from Linux (Debian / Proxmox)](#-verifying-amt-support-from-linux-debian--proxmox)
  - [📌 Real-World Example (Non-vPro Unit)](#-real-world-example-non-vpro-unit)

## Out-of-Band Management Capabilities & Limitations

### Model Scope
- **Model:** HP EliteDesk 800 G2 Mini  
- **Platform:** Intel 6th Gen (Skylake)  
- **Common Use Cases:** Homelab nodes, Proxmox VE, lightweight compute, edge workloads

This document clarifies **out-of-band (OOB) management support**, including **Intel AMT (vPro)**, and how to **verify capabilities from Linux**.

---

## 🔍 Executive Summary

| Feature | Supported? | Notes |
|------|-----------|------|
| Intel Management Engine (ME) | ✅ Yes | Present on all modern Intel systems |
| Intel AMT (vPro) | ⚠️ *Conditional* | **CPU + firmware dependent** |
| Remote Power Control | ⚠️ vPro only | Requires AMT |
| Remote KVM (BIOS-level) | ⚠️ vPro only | Via Intel AMT |
| Dedicated Management NIC | ❌ No | Client-class hardware |
| HP iLO | ❌ No | Server-only (ProLiant) |

> 👉 **Most EliteDesk 800 G2 Minis in the wild do *not* support AMT**, due to non-vPro CPUs.

---

## ✅ What the EliteDesk 800 G2 Mini *Does* Support

### 1. Intel Management Engine (ME)
- Present on **all** G2 Minis
- Exposed via Linux `mei` drivers
- Used for:
  - Power management
  - Firmware security
  - DRM / HDCP
  - Platform telemetry

**Linux confirmation:**
```bash
lsmod | grep mei
```

Expected:
```text
mei_me
mei
```

> ⚠️ Intel ME ≠ Intel AMT  
> ME alone does **not** provide out-of-band access.

---

### 2. Virtualisation & In-Band Management
- VT-x / EPT supported
- Suitable for:
  - Proxmox VE
  - KVM / LXC
  - Ceph OSD nodes
- Standard Linux tooling applies (SSH, monitoring, agents)

---

## ❌ What the EliteDesk 800 G2 Mini *Does NOT* Support (by default)

### 1. HP iLO
- ❌ Not available
- iLO is exclusive to **HP ProLiant servers**

---

### 2. Guaranteed Out-of-Band Management
- No dedicated BMC
- No independent management NIC
- No always-on KVM unless **Intel AMT is present**

---

## ⚠️ Conditional Support: Intel AMT (vPro)

### When AMT *is* supported
AMT is available **only if all of the following are true**:

1. **vPro-capable CPU installed**
   - Examples:
     - `i5-6500T vPro`
     - `i7-6700T vPro`
   - ❌ `i5-6600T` (non-vPro) does **not** qualify
2. AMT enabled in firmware (MEBx)
3. Wired Ethernet in use (AMT does not work over Wi-Fi)

---

### When AMT is *not* supported (most common)
- Non-vPro CPU installed
- OEM firmware disables AMT entirely
- Refurbished units missing AMT provisioning

This is **extremely common** in second-hand / eBay units.

---

## 🧪 Verifying AMT Support from Linux (Debian / Proxmox)

### 1. Check CPU SKU
```bash
lscpu | grep "Model name"
```

Compare against Intel ARK for **vPro support**.

---

### 2. Check for Intel MEI device
```bash
lspci | grep -i "management engine"
```

Expected on AMT systems:
```text
00:16.0 Communication controller: Intel Corporation Management Engine Interface
```

Absence → **no AMT endpoint exposed**.

---

### 3. Check MEI kernel drivers
```bash
lsmod | grep mei
```

Presence alone is **not sufficient** for AMT.

---

### 4. Definitive test (if supported)
```bash
apt install intel-amt-tools
sudo amtinfo
```

Possible results:

| Output | Meaning |
|----|----|
| `AMT is enabled` | ✅ True OOB management |
| `AMT not enabled` | ⚠️ vPro CPU but disabled in firmware |
| Tool fails / no output | ❌ No AMT support |

---

## 📌 Real-World Example (Non-vPro Unit)

**System:**
```text
Intel Core i5-6600T
```

**Findings:**
- Intel ME present ✅
- MEI drivers loaded ✅
- No vPro flag ❌
- No AMT PCI device ❌

**Conclusion:**
> This EliteDesk 800 G2 Mini **does NOT support Intel AMT or out-of-band management**.

---

## 🧠 Operational Guidance (Homelab / Infra)

### Treat EliteDesk Minis as:
- **In-band managed compute nodes**
- Not lights-out infrastructure

### Recommended mitigations
- Wake-on-LAN
- Smart PDU
- **PiKVM** for true OOB access

### If OOB is a hard requirement
Prefer:
- HP MicroServer (iLO)
- Supermicro (IPMI)
- Dell OptiPlex **with confirmed vPro**

---

## ✅ Final Takeaway

> The **HP EliteDesk 800 G2 Mini *can* support out-of-band management**,  
> **but only with rare vPro-enabled SKUs**.  
>  
> **Most units do not**, and this must be assumed unless proven otherwise.

This makes it a **great homelab workhorse**, but **not a substitute for server-class OOB management**.
