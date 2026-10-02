# Network Diagnostic Toolkit

One command that runs the standard first-response connectivity checks a
support tech would run manually: **ping, DNS resolution, TCP port tests,
and traceroute** — then saves a timestamped JSON report with a plain-English
verdict.

## Why this exists

"Is it the network or the application?" is the first question in half of
all connectivity tickets. This toolkit answers it in seconds and produces
a report you can attach to the ticket.

## Run it

```bash
python netdiag.py --target example.com
python netdiag.py --target 192.168.1.1 --ports 80,443,3389
python netdiag.py --target example.com --ports 22,80,443 --out report.json
```

## Sample output

```
Diagnosis for 127.0.0.1 -> netdiag_127.0.0.1_20260929_131500.json
  DNS:  OK ['127.0.0.1']
  Ping: OK (loss 0%, avg 0.05 ms)
  Port 80: CLOSED
  Port 443: CLOSED

Verdict: Host is up but port(s) 80, 443 are closed — likely a service or firewall issue.
```

## Files

- `netdiag.py` — the toolkit (standard library only, no dependencies)

## Interview notes

See `INTERVIEW-GUIDE.md` in the portfolio root for the 30-second pitch,
likely interview questions, and honest framing for this project.

> Built as a learning/lab project. Run only against systems you own or
> are authorized to test.
