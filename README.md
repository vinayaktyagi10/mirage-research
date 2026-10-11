# mirage-research

Analysis of what the [Mirage](https://github.com/Mirage-Source/mirage-core) SSH and Telnet honeypot captured, from a payload URL in the logs to a Monero miner taken apart in an isolated VM.

## What is here

- `sql/`: the queries behind the numbers.
  - `01_url_rows.sql`: every command row containing a URL, with the extracted URLs.
  - `02_url_inventory.sql`: payload hosts with URL mentions, distinct sessions and distinct source IPs.
  - `03_source_ips.sql`: per payload host, which source IPs mentioned it and how many sessions each made.
- `results/`: saved output of queries 02 and 03 on the two datasets.
- `iocs.md`: file hashes, defanged payload servers and behaviours.

## What is not here, and why

- No malware samples. Hashes only.
- No raw datasets. They contain attacker-supplied keys and credentials and every source IP. Hashes of the exported files are listed below.
- The write-up itself lives on my website.

## Reproducing

The queries expect two tables, `sessions` and `commands`, in the Mirage schema (`commands.raw_input_b64` holds the command line, base64-encoded). Run them against a database loaded with your own Mirage data. Counts are by source IP wherever the question is "how many attackers", because a few bots make most of the sessions.

Datasets used (all times UTC):

- Frankfurt-era backup, 2026-06-16 to 2026-07-29: 154,806 sessions, 9,555 command rows.
- Nuremberg export, sessions starting before 2026-10-10T22:54:06Z: 261,266 sessions, 76,603 command rows.
  - `nuremberg-slice-20261011-sessions.csv.gz` sha256 `0ab1015338f4896cfd87695fa6d27cfd2db7fce923e5ecc74ce37184f89b6e72`
  - `nuremberg-slice-20261011-commands.csv.gz` sha256 `54cc21ac87f8d2813b478733968d4d1ca7ff47c4bfab72899cbf7d573d9bece9`

## Licence

Code: MIT. Text and results: CC BY 4.0.
