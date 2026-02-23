-- Syslog table for Vector sink (see docs/SYSLOG-DESIGN.md).
-- Run once when ClickHouse is up (e.g. via clickhouse-init service).
CREATE TABLE IF NOT EXISTS default.syslog
(
    timestamp   DateTime64(3),
    host        String,
    facility    String,
    severity    String,
    program     String,
    message     String,
    raw         String,
    received_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = MergeTree()
ORDER BY (host, timestamp)
TTL toDateTime(timestamp) + INTERVAL 30 DAY;
