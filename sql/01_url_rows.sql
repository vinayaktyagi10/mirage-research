
-- 01_url_rows.sql

WITH decoded AS (
    SELECT
        c.*,
        convert_from(decode(c.raw_input_b64, 'base64'), 'UTF8')
            AS decoded_input
    FROM commands AS c
)
SELECT
    d.*,
    ARRAY(
        SELECT m[1]
        FROM regexp_matches(
            d.decoded_input,
            $re$(https?://[^[:space:]'"<>);]+)$re$,
            'gi'
        ) AS matches(m)
    ) AS extracted_urls
FROM decoded AS d
WHERE d.decoded_input ~* $re$https?://[^[:space:]'"<>);]+$re$
ORDER BY d.session_id;
