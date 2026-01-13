# Hardware

This directory documents the **physical infrastructure** used in the homelab.

The focus is on **real hardware in use**, including capabilities, limitations, and operational trade-offs discovered through hands-on deployment — not just vendor marketing claims.

---

## Scope

Hardware documentation includes:

- Model and platform details
- Management capabilities (iLO, IPMI, AMT, or none)
- Known limitations and quirks
- Selection rationale and trade-offs
- Role within the overall homelab architecture

Where relevant, capabilities are **verified from Linux** and documented explicitly.

---

## Structure

```text
hardware/
├── servers/       # Server-class hardware (IPMI / iLO / BMC-backed)
├── networking/    # Switches, firewalls, routers, optics
└── mini-pcs/      # Client-class nodes (EliteDesk, OptiPlex, Minisforum etc.)
```

Each hardware model should have its **own directory** containing a `README.md` that clearly states:
- What the hardware supports
- What it does not support
- Operational implications

---

## Design Philosophy

- Evidence-based documentation
- Clear separation of **in-band vs out-of-band** management
- Client hardware treated as **compute**, not lights-out infrastructure
- Mitigations documented where enterprise features are absent

---

## Related Documentation

- Architecture and design decisions: `../design/`
- Operational procedures: `../operations/`
- Vendor-agnostic concepts and patterns: `safesploitOrg/docs`
