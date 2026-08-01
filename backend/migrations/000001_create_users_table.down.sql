-- Rollback for 000001_create_users_table
-- Note: intentionally does NOT drop the pgcrypto/citext extensions,
-- since every future table in this schema also depends on
-- gen_random_uuid(). Extensions are created once and left in place.

DROP INDEX IF EXISTS idx_users_email;
DROP INDEX IF EXISTS idx_users_phone;
DROP TABLE IF EXISTS users;
