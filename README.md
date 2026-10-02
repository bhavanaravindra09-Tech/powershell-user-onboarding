# Vulnerability Assessment Lab

> **Educational home-lab exercise.** Everything here was done against
> intentionally vulnerable virtual machines in an isolated lab network.
> This is **not** a real client engagement, and no production or
> third-party systems were touched. Never scan systems you don't own or
> have explicit written permission to test.

## Purpose

To practise the full vulnerability-assessment workflow end to end —
lab setup, reconnaissance, scanning, triage, and remediation
prioritisation — the same workflow a junior security analyst follows
when supporting patch management and audit readiness.

## Lab setup

| Component | Role |
|-----------|------|
| Host: VirtualBox (host-only network, no internet route) | Isolation — lab traffic never leaves the host |
| Attacker: Kali Linux VM | Nmap for recon, OpenVAS for vulnerability scanning |
| Targets: Metasploitable 2 / Metasploitable 3 | Intentionally vulnerable Linux/Windows VMs built for training |

Snapshots were taken of every VM before scanning so the lab can be
reset to a known state.

## Contents

- [`methodology.md`](methodology.md) — recon with Nmap, scanning approach
  with OpenVAS/Nessus Essentials, and how findings were triaged
- [`sample-findings.md`](sample-findings.md) — an **illustrative** findings
  table (5 examples with severity + remediation) and a note on how to
  prioritise remediation

## Skills demonstrated

- Building an isolated virtual lab (VirtualBox host-only networking,
  snapshots)
- Network reconnaissance with Nmap (host discovery, service/version
  detection, OS fingerprinting)
- Vulnerability scanning with OpenVAS / Nessus Essentials
- Triaging findings: separating true positives from noise, mapping to
  severity, and writing remediation guidance
- Communicating risk in plain language for non-security stakeholders
