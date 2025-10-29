#!/bin/bash
set -e

echo "[cron] Checking partitions rotation..."

psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h postgres <<'SQL'
DO $$
DECLARE
    curr_month date := date_trunc('month', now());
    next_month date := curr_month + interval '1 month';
    next2_month date := next_month + interval '1 month';
    old_month date := curr_month - interval '1 month';

    new_partition text := 'refresh_tokens_' || to_char(next_month, 'YYYY_MM');
    old_partition text := 'refresh_tokens_' || to_char(old_month, 'YYYY_MM');
BEGIN
    -- Удаляем партицию, которая на два месяца старше текущей
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = old_partition) THEN
        RAISE NOTICE 'Dropping old partition: %', old_partition;
        EXECUTE format('DROP TABLE IF EXISTS %I;', old_partition);
    END IF;

    -- Создаём новую партицию для следующего месяца, если её нет
    IF NOT EXISTS (SELECT 1 FROM pg_tables WHERE tablename = new_partition) THEN
        RAISE NOTICE 'Creating new partition: %', new_partition;
        EXECUTE format(
            'CREATE TABLE %I PARTITION OF refresh_tokens FOR VALUES FROM (%L) TO (%L);',
            new_partition, next_month, next2_month
        );
    END IF;
END $$;
SQL