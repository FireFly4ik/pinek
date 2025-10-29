CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT NOT NULL,
    login TEXT NOT NULL UNIQUE,
    hashed_password TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    token_hash BYTEA,
    user_id UUID NOT NULL REFERENCES registrations(id) ON DELETE CASCADE,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    revoked_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (token_hash, created_at)
)
PARTITION BY RANGE (created_at);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_active
    ON refresh_tokens (user_id)
    WHERE revoked_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash
    ON refresh_tokens USING btree (token_hash);

DO $$
DECLARE
curr_month DATE := date_trunc('month', now());
    next_month DATE := curr_month + INTERVAL '1 month';
    next2_month DATE := next_month + INTERVAL '1 month';
BEGIN
EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF refresh_tokens FOR VALUES FROM (%L) TO (%L);',
        'refresh_tokens_' || to_char(curr_month, 'YYYY_MM'),
        curr_month, next_month
        );

EXECUTE format(
        'CREATE TABLE IF NOT EXISTS %I PARTITION OF refresh_tokens FOR VALUES FROM (%L) TO (%L);',
        'refresh_tokens_' || to_char(next_month, 'YYYY_MM'),
        next_month, next2_month
        );
END $$;