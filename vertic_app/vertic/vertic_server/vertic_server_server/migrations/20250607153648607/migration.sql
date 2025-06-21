BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "app_users" ADD COLUMN "profilePhoto" bytea;
ALTER TABLE "app_users" ADD COLUMN "photoUploadedAt" timestamp without time zone;
ALTER TABLE "app_users" ADD COLUMN "photoApprovedBy" bigint;
CREATE INDEX "app_user_photo_idx" ON "app_users" USING btree ("photoUploadedAt");

--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250607153648607', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250607153648607', "timestamp" = now();

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


COMMIT;
