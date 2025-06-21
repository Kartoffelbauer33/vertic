BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "app_users" ADD COLUMN "parentEmail" text;
ALTER TABLE "app_users" ADD COLUMN "parentNotified" boolean NOT NULL DEFAULT false;
ALTER TABLE "app_users" ADD COLUMN "parentApproved" boolean NOT NULL DEFAULT false;
CREATE INDEX "app_user_parent_email_idx" ON "app_users" USING btree ("parentEmail");

--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250605141907388', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250605141907388', "timestamp" = now();

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
