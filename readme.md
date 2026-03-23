![output](https://github.com/user-attachments/assets/ce850b90-fc6a-45a7-b29d-6654b99c6d58)

# 使い方

```
bash ./get-availability-html.sh
source .env
export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD
node import_courts.js #DB INSERT
```

# 動作確認環境
- Ubuntu 24
- Nodejs 24
- PostgreSQL 18

# メモ

## 検索用SQL

```
WITH base AS (
  SELECT *
  FROM court_availability
  WHERE status = 'available'
    AND EXTRACT(DOW FROM play_date) IN (6, 0)
    AND fetched_at >= NOW() - INTERVAL '10 minutes'
    AND (play_date + start_time) >= (NOW() AT TIME ZONE 'Asia/Tokyo')
),
grp AS (
  SELECT
    source_site,
    facility_name,
    court_name,
    play_date,
    start_time,
    end_time,
    start_time
      - (ROW_NUMBER() OVER (
          PARTITION BY source_site, facility_name, court_name, play_date
          ORDER BY start_time
        ) * INTERVAL '15 minutes') AS g
  FROM base
)
SELECT
  source_site,
  facility_name,
  court_name,
  play_date,
  MIN(start_time) AS range_start,
  MAX(end_time)   AS range_end,
  COUNT(*) * 15   AS total_minutes
FROM grp
GROUP BY
  source_site,
  facility_name,
  court_name,
  play_date,
  g
ORDER BY
  play_date,
  facility_name,
  court_name,
  range_start;
```

<img width="739" height="712" alt="image" src="https://github.com/user-attachments/assets/e5e3570a-0943-4447-acce-6ee241486da6" />

