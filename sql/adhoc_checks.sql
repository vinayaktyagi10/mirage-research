-- adhoc_checks.sql
-- Written by an AI assistant (Claude), not by me, to recompute numbers in the write-up.
-- My own queries are 01 to 03 in this folder. Every query here is a read-only SELECT.
-- Run on two scratch Postgres copies: the Frankfurt-era backup, and the Nuremberg export of
-- sessions that started before 2026-10-10T22:54:06Z. Sections I and J ran on the live
-- database, bounded by the timestamps shown. Sections A to H assume the sessions and
-- commands tables of the Mirage schema.

-- A. Dataset summary (both scratch DBs)
select (select count(*) from sessions) sessions,
       (select to_timestamp(min(start_ms)/1000.0) from sessions) s_first,
       (select to_timestamp(max(start_ms)/1000.0) from sessions) s_last,
       (select count(*) from commands) cmd_rows,
       (select count(distinct session_id) from commands) sess_with_cmds,
       (select count(distinct s.client_ip) from sessions s join commands c using(session_id)) ips_with_cmds,
       (select count(distinct client_ip) from sessions) ips_all;

-- B. Split by protocol (Nuremberg slice; Frankfurt is all ssh)
select s.protocol, count(distinct s.session_id) sess_with_cmds,
       count(distinct s.client_ip) ips_with_cmds, count(*) cmd_rows
from sessions s join commands c using(session_id) group by 1;

-- C. URL-bearing sessions and IPs, by protocol
with u as (select distinct c.session_id from commands c
           where convert_from(decode(c.raw_input_b64,'base64'),'UTF8') ~* $re$https?://[^[:space:]'"<>);]+$re$)
select s.protocol, count(*) url_sessions, count(distinct s.client_ip) url_ips
from u join sessions s using(session_id) group by 1;

-- D. SSH URL IPs that never mentioned the one dominant host (154.70.152.216)
with e as (
  select distinct c.session_id,
         substring((regexp_matches(convert_from(decode(c.raw_input_b64,'base64'),'UTF8'),
                    $re$(https?://[^[:space:]'"<>);]+)$re$, 'i'))[1] from '^https?://([^/:?#]+)') host
  from commands c)
select count(distinct s.client_ip)
from e join sessions s using(session_id)
where s.protocol='ssh'
  and s.client_ip not in (select s2.client_ip from e e2 join sessions s2 using(session_id)
                          where e2.host='154.70.152.216');

-- E. Per payload host, with how many sessions came over telnet (Nuremberg)
with e as (
  select c.session_id, substring(m[1] from '^https?://([^/:?#]+)') host
  from commands c,
       regexp_matches(convert_from(decode(c.raw_input_b64,'base64'),'UTF8'),
                      $re$(https?://[^[:space:]'"<>);]+)$re$, 'gi') m)
select e.host, count(*) mentions, count(distinct e.session_id) sessions, count(distinct s.client_ip) ips,
       min(to_timestamp(s.start_ms/1000.0))::date first, max(to_timestamp(s.start_ms/1000.0))::date last,
       count(distinct s.session_id) filter (where s.protocol='telnet') telnet_sessions
from e join sessions s using(session_id)
group by 1 order by 4 desc, 3 desc limit 12;

-- F. "<name>: command not found" by name (Nuremberg slice, ssh only)
select substring(c.response_text from '(?:bash|sh): (?:line [0-9]+: )?([^: ]+): command not found') as missing,
       count(*) rows, count(distinct c.session_id) sessions, count(distinct s.client_ip) ips,
       min(to_timestamp(s.start_ms/1000.0))::date first, max(to_timestamp(s.start_ms/1000.0))::date last
from commands c join sessions s using(session_id)
where s.protocol='ssh' and c.response_text ~ 'command not found'
group by 1
having substring(c.response_text from '(?:bash|sh): (?:line [0-9]+: )?([^: ]+): command not found')
       in ('sh','bash','rm','chmod','wget','curl','case','esac','{','}','if','for','kill','nohup','mkdir','touch','ping','perl')
order by 3 desc;

-- G. The UserKnownHostsFile rows, by protocol (Nuremberg slice)
select s.protocol, count(distinct c.session_id), count(distinct s.client_ip)
from commands c join sessions s using(session_id)
where c.response_text ilike '%UserKnownHostsFile%' group by 1;

-- H. echo -e printed literally (starts with "-e " or "-ne ")
select count(*) rows, count(distinct c.session_id) sessions, count(distinct s.client_ip) ips
from commands c join sessions s using(session_id)
where s.protocol='ssh' and (c.response_text like '-e %' or c.response_text like '-ne %');

-- I. LIVE, v2 window (2026-10-10T22:54:06Z <= t < 2026-10-11T07:57:17Z); ms bounds 1791672846000 .. 1791705437000
select s.protocol, count(*) cmd_rows, count(distinct s.session_id) sess_with_cmds,
       count(distinct s.client_ip) ips, count(c.command_chain) chain_filled
from commands c join sessions s using(session_id)
where c.timestamp_ms >= 1791672846000 and c.timestamp_ms < 1791705437000 group by 1;

-- J. LIVE, v2 window: remaining "not found" names
select s.protocol,
       substring(c.response_text from '(?:bash|sh): (?:line [0-9]+: )?([^: ]+): command not found') missing,
       count(*) rows, count(distinct c.session_id) sessions
from commands c join sessions s using(session_id)
where c.timestamp_ms >= 1791672846000 and c.timestamp_ms < 1791705437000 and c.response_text ~ 'command not found'
group by 1,2 order by 3 desc limit 10;

-- K. Source-IP overlap between the datasets (shell, not SQL), ssh only:
--   for each DB: psql -Atc "select distinct client_ip from sessions where protocol='ssh'" | sort > ips_<db>.txt
--   comm -12 ips_5433.txt ips_5434.txt | wc -l
--   (IPs with commands: join sessions to commands first)

-- L. Denominator for the "without the dominant campaign" rate (Nuremberg, ssh only):
--    SSH IPs with a command, minus the IPs that mentioned the dominant host, and how many of
--    the remaining IPs mentioned any URL. Expected: 43 of 456.
with e as (
  select distinct c.session_id,
         substring((regexp_matches(convert_from(decode(c.raw_input_b64,'base64'),'UTF8'),
                    $re$(https?://[^[:space:]'"<>);]+)$re$, 'i'))[1] from '^https?://([^/:?#]+)') host
  from commands c),
dominant as (select distinct s.client_ip from e join sessions s using(session_id) where e.host='154.70.152.216'),
ssh_ips   as (select distinct s.client_ip from sessions s join commands c using(session_id) where s.protocol='ssh'),
url_ips   as (select distinct s.client_ip from e join sessions s using(session_id) where s.protocol='ssh')
select (select count(*) from ssh_ips where client_ip not in (select client_ip from dominant)) as ips_without_dominant,
       (select count(*) from url_ips where client_ip not in (select client_ip from dominant)) as url_ips_without_dominant;
