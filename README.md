# IT Support Runbooks

Concise, field-tested-style runbooks for the most common L1 support tickets.
Each runbook follows the same structure so any technician can pick one up
mid-shift:

- **Symptoms** — how the issue presents
- **Quick checks** — 60-second triage questions that isolate the cause
- **Step-by-step fix** — the actual resolution, in order
- **Escalation criteria** — exactly when to stop and escalate (and to whom)

## Index

| # | Runbook | Typical ticket |
|---|---------|----------------|
| 1 | [Account Unlock / Password Reset](account-unlock-password-reset.md) | Locked out after too many attempts |
| 2 | [VPN Won't Connect](vpn-wont-connect.md) | Remote user can't reach the office network |
| 3 | [Printer Not Responding](printer-not-responding.md) | Jobs stuck, printer "offline" |
| 4 | [Outlook Not Syncing](outlook-not-syncing.md) | "Disconnected", mail not arriving |
| 5 | [Slow Windows PC](slow-windows-pc.md) | Everything crawls, disk at 100% |
| 6 | [Wi-Fi Connected but No Internet](wifi-connected-no-internet.md) | Globe icon, browser dead |
| 7 | [New-Laptop Setup Checklist](new-laptop-setup-checklist.md) | Onboarding a new hire's machine |
| 8 | [Suspicious Phishing Email Triage](phishing-email-triage.md) | "Is this email legit?" |

## How to use these

1. **Triage first** — the Quick checks exist so you ask three questions
   before touching anything. Most tickets are solved or correctly routed
   in the first two minutes.
2. **Work top to bottom** — steps are ordered cheapest-first (toggle,
   reboot, re-authenticate) before destructive ones (profile rebuild,
   reimage).
3. **Log as you go** — every runbook ends with what to record. Good logs
   are what turn repeat issues into trend data (see the
   [help-desk KPI dashboard](../helpdesk-kpi-dashboard/) project).
4. **Know the escalation line** — escalating with the quick-check answers
   and the exact error message is what separates L1 from "have you tried
   turning it off and on again".

> **Note:** commands reference Windows 10/11 and Active Directory. Group
> names, server paths, and the security mailbox are placeholders — adapt
> them to your environment.
