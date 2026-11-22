-- Frame pacing for the shade workload, from Perfetto's Choreographer slices.
-- At 120 Hz one vsync is 8.333 ms; an interval of 1.5 periods means a missed frame.
WITH f AS (
  SELECT slice.ts AS ts
  FROM slice
  JOIN thread_track tt ON slice.track_id = tt.id
  JOIN thread USING (utid)
  JOIN process USING (upid)
  WHERE process.name = 'com.android.settings'
    AND slice.name GLOB 'Choreographer#doFrame*'
), g AS (
  SELECT ts, LEAD(ts) OVER (ORDER BY ts) - ts AS interval FROM f
)
SELECT
  COUNT(*)                                                     AS intervals,
  SUM(CASE WHEN interval > 12500000 THEN 1 ELSE 0 END)         AS late,
  ROUND(100.0 * SUM(CASE WHEN interval > 12500000 THEN 1 ELSE 0 END) / COUNT(*), 1) AS late_pct,
  SUM(MAX(0, CAST(ROUND(interval / 8333333.0) AS INTEGER) - 1)) AS dropped,
  ROUND(100.0 * SUM(MAX(0, CAST(ROUND(interval / 8333333.0) AS INTEGER) - 1))
        / (COUNT(*) + SUM(MAX(0, CAST(ROUND(interval / 8333333.0) AS INTEGER) - 1))), 1) AS dropped_pct,
  ROUND(AVG(interval) / 1e6, 2)                                AS avg_ms,
  ROUND(MAX(interval) / 1e6, 1)                                AS max_ms
FROM g WHERE interval IS NOT NULL;
