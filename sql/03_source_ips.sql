-- 03_source_ips.sql
WITH decoded AS (
    SELECT
        c.session_id,
        convert_from(decode(c.raw_input_b64, 'base64'), 'UTF8')
            AS decoded_input
    FROM commands AS c
),
extracted AS (
    SELECT
        d.session_id,
        m[1] AS url,
        substring(
            m[1] FROM '^https?://([^/:?#]+)'
        ) AS host
    FROM decoded AS d
    CROSS JOIN LATERAL regexp_matches(
        d.decoded_input,
        $re$(https?://[^[:space:]'"<>);]+)$re$,
        'gi'
    ) AS matches(m)
),
enriched AS (
    SELECT
        e.host,
        e.url,
        e.session_id,
        s.client_ip,
        to_timestamp(s.start_ms / 1000.0) AS seen_at
    FROM extracted AS e
    JOIN sessions AS s USING (session_id)
)
SELECT
    host,
    client_ip AS source_ip,
    COUNT(*) AS url_mentions,
    COUNT(DISTINCT url) AS distinct_urls,
    COUNT(DISTINCT session_id) AS distinct_sessions,
    MIN(seen_at) AS first_seen,
    MAX(seen_at) AS last_seen
FROM enriched
GROUP BY host, client_ip
ORDER BY host, distinct_sessions DESC, source_ip;
