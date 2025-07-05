BEGIN;


--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250622230632803', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250622230632803', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth', '20240520102713718', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240520102713718', "timestamp" = now();

--
-- Add emailVerifiedAt column to staff_users table
--
ALTER TABLE "staff_users" ADD COLUMN "emailVerifiedAt" timestamp without time zone;

COMMIT;
