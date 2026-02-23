-- TimeSeries table for Prometheus remote-read/remote-write (https://clickhouse.com/docs/interfaces/prometheus)
-- Requires: SET allow_experimental_time_series_table = 1
SET allow_experimental_time_series_table = 1;
CREATE TABLE IF NOT EXISTS default.prometheus_ts ENGINE = TimeSeries;
