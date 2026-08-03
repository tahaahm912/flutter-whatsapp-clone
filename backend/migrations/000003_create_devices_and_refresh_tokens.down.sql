-- Rollback for 000003_create_devices_and_refresh_tokens
-- Order matters: refresh_tokens references devices, so drop it first.

DROP TABLE IF EXISTS refresh_tokens;
DROP TABLE IF EXISTS devices;
