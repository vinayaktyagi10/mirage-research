# Indicators

Observed by the Mirage SSH/Telnet honeypot and in an isolated analysis VM, 2026-07 to 2026-10. Hosts are defanged (`hxxp`, `[.]`). These are what a Tor exit was served on 2026-10-10; an operator may serve different files to other visitors. An IP address is not an actor: some hosts may be compromised third-party machines.

## File hashes (SHA-256)

| File | Size | SHA-256 |
|---|---|---|
| `/sh` loader script | 2,312 B | `917fcc9131c6e9ca16264a85afc62532297bb39eb9d37765dad536c7c8c7735c` |
| `/clean` script | 1,157 B | `3f3a11bafabb1a35db913cfe51995f2e357d049e268860175876ae5a93d23892` |
| `/x86_64` (UPX-packed, as served) | 1,989,056 B | `f0aa83bbbd2c75e2f71ec16029ee5fcfad59f3a8efa30a500b815f0f6c18d987` |
| `/x86_64` unpacked (`upx -d` 4.2.4) | 5,199,952 B | `a0f85de525c9f1126dd701b4b9a50237ef6dd1605836da64e983e49a2c50d268` |

No samples are stored in this repository.

## Payload servers

Served the loader, cleaner and miner: `217.60.102[.]5` (`hxxps://217.60.102[.]5/sh`, `/clean`, `/x86_64`). Same path family seen on `217.60.103[.]56` and `217.60.195[.]113`.

Other hosts named in download commands: `154.70.152[.]216`, `103.160.59[.]94`, `185.93.89[.]72`, `39.108.50[.]35`, `83.168.69[.]95`, `83.168.69[.]141`, `66.116.196[.]142`, `160.119.66[.]206`, `213.232.114[.]14`, `41.216.189[.]157`, `41.216.189[.]236`, `91.92.42[.]213`.

## Behaviour

- A process titled `nginx: worker process` whose `/proc/PID/exe` is not an nginx binary.
- Outbound TCP 853 (DNS over TLS) to 13 hard-coded public resolvers, retried with no backoff: 1.1.1.1, 1.0.0.1, 8.8.8.8, 8.8.4.4, 9.9.9.9, 9.9.10.10, 95.215.19.53, 217.160.70.42, 213.202.211.221, 81.169.136.222, 80.152.203.134, 185.181.61.24, 109.91.184.21. The resolvers are benign services; alert on the port and the pattern, not the addresses.
- `crontab -r` followed by `crontab -` installing an `@reboot` entry that points into a non-standard directory.
- A script that deletes crontab and profile lines matching `wget|curl|/dev/tcp|/tmp|\.sh|nc|bash -i|sh -i|base64 -d`, stops `c3pool_miner` and `bot.service`, and empties `/tmp`, `/var/tmp` and `/dev/shm`.
