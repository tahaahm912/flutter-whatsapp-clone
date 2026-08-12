-- Rollback for 000004_create_signal_keys

DROP TABLE IF EXISTS signal_one_time_prekeys;
DROP TABLE IF EXISTS signal_signed_prekeys;
DROP TABLE IF EXISTS signal_identity_keys;
