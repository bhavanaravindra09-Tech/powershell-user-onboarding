# Password Strength Auditor

An educational Python tool that scores a password on length, character
variety, and common weakness patterns (dictionary words, keyboard
sequences like `qwerty`, sequential runs like `abcd`, repeated
characters), then gives an illustrative crack-time estimate and
concrete improvement suggestions.

## Why this exists

Weak and reused passwords cause a huge share of account-compromise
tickets. This tool teaches the *why* behind password policy — useful
for user education during support calls and for security-awareness work.

## Run it

```bash
python audit.py                        # secure hidden prompt
python audit.py --password "Tr0ub4dor&3"   # demo only
```

## Sample output

```
Score: 52/100 [##########----------] Fair
Illustrative crack time: ~16,054.6 years
Findings & suggestions:
  - No obvious weaknesses found. Prefer a unique passphrase per account plus MFA.
```

## Ethics & scope

- **Educational only.** Test passwords you invent, never real credentials.
- Nothing is transmitted anywhere; everything runs locally.
- This checks *strength patterns*, it does not crack, recover, or attack
  any account or system.

## Files

- `audit.py` — the auditor (standard library only, no dependencies)

## Interview notes

See `INTERVIEW-GUIDE.md` in the portfolio root for the 30-second pitch,
likely interview questions, and honest framing for this project.
