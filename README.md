# New-Hire Onboarding Automation (PowerShell)

Automates the repetitive parts of IT onboarding for a new hire in Active
Directory: account creation, department group memberships, home folder with
proper ACLs, and forced password change at next logon. Every action is
written to a timestamped log file, and the whole run supports `-WhatIf`
so it can be previewed safely.

## What it does

1. **Validates input** — first/last name must be alphabetic; department must
   be one of the known values (`IT`, `Finance`, `HR`, `Sales`, `Support`,
   `Operations`).
2. **Generates a unique `sAMAccountName`** — first initial + last name,
   lower-cased, truncated to fit the 20-character limit, with a numeric
   suffix if the name already exists.
3. **Creates the AD user** — enabled, with a random 14-character temporary
   password meeting complexity rules, and `ChangePasswordAtLogon = $true`.
4. **Adds department security groups** — from a lookup table (e.g. Support
   gets `GG_Helpdesk_Agents`, `GG_VPN_Users`, `GG_Ticketing_System`).
   A failure on one group is logged without stopping the rest.
5. **Creates the home folder** — `\\fileserver\home$\<username>`, ACL locked
   down to the user (Full Control, inheritable), mapped as the H: drive on
   the AD account.
6. **Logs everything** — `Logs\Onboarding_yyyyMMdd_HHmmss.log`, colour-coded
   on screen (`INFO` / `SUCCESS` / `WARN` / `ERROR`).

## Prerequisites

- Windows PowerShell 5.1+ with the RSAT **ActiveDirectory** module
- An account with rights to create users, edit group membership, and set
  ACLs on the file share
- Update the placeholder domain (`contoso.local` / `CONTOSO`), the default
  OU, and the group names to match your organisation

## Parameters

| Parameter            | Required | Default                              | Description                              |
|----------------------|----------|--------------------------------------|------------------------------------------|
| `FirstName`          | Yes      | —                                    | New hire's first name (letters only)     |
| `LastName`           | Yes      | —                                    | New hire's last name (letters only)      |
| `Department`         | Yes      | —                                    | One of IT, Finance, HR, Sales, Support, Operations |
| `OrganizationalUnit` | No       | `OU=Users,DC=contoso,DC=local`       | Target OU distinguished name             |
| `HomeFolderRoot`     | No       | `\\fileserver\home$`                 | UNC root for home folders                |
| `LogDirectory`       | No       | `.\Logs`                             | Where the timestamped log is written     |

## Usage examples

```powershell
# 1. Preview everything without changing anything
.\New-HireOnboarding.ps1 -FirstName "Aarav" -LastName "Sharma" -Department "Support" -WhatIf

# 2. Run the full onboarding with defaults
.\New-HireOnboarding.ps1 -FirstName "Aarav" -LastName "Sharma" -Department "IT"

# 3. Custom OU and file server
.\New-HireOnboarding.ps1 -FirstName "Priya" -LastName "Nair" -Department "Finance" `
    -OrganizationalUnit "OU=Finance,OU=Users,DC=contoso,DC=local" `
    -HomeFolderRoot "\\fs02\home$"
```

## Sample log output

```
[2026-09-29 11:02:14] [INFO] Starting onboarding for Aarav Sharma (Department: Support)
[2026-09-29 11:02:15] [INFO] Generated account name: asharma
[2026-09-29 11:02:16] [SUCCESS] Created AD user 'asharma' in OU=Users,DC=contoso,DC=local
[2026-09-29 11:02:17] [SUCCESS] Added 'asharma' to group 'GG_Helpdesk_Agents'
[2026-09-29 11:02:17] [SUCCESS] Added 'asharma' to group 'GG_VPN_Users'
[2026-09-29 11:02:18] [SUCCESS] Added 'asharma' to group 'GG_Ticketing_System'
[2026-09-29 11:02:19] [SUCCESS] Created home folder \\fileserver\home$\asharma and mapped H: drive
[2026-09-29 11:02:19] [SUCCESS] Onboarding complete for Aarav Sharma (asharma).
[2026-09-29 11:02:19] [INFO] Share the temporary password through a secure channel (sealed envelope or password vault) — never by plain email.
[2026-09-29 11:02:19] [INFO] Log file: C:\Scripts\Logs\Onboarding_20260929_110214.log
```

## Design notes

- **Idempotent naming** — re-running for a common name (e.g. a second
  "Aarav Sharma") produces `asharma2` instead of failing.
- **Fail-soft groups** — one missing group doesn't abort the whole onboarding;
  each failure is logged at `ERROR` level for follow-up.
- **Secure by default** — the temp password is never written to the log;
  it is only held in memory and must be handed over out-of-band.
