-- Leere ALLE Serverpod Auth-Tabellen
DELETE FROM serverpod_user_info;
DELETE FROM serverpod_auth_key;
DELETE FROM serverpod_email_auth;
DELETE FROM serverpod_email_create_request;
DELETE FROM serverpod_email_reset;
DELETE FROM serverpod_email_failed_sign_in;

-- Leere deine eigenen Tabellen
DELETE FROM app_users;
DELETE FROM user_identities;
-- etc...