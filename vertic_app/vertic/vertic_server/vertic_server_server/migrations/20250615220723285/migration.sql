BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "app_users" ADD COLUMN "userInfoId" bigint;
CREATE UNIQUE INDEX "app_user_userinfo_idx" ON "app_users" USING btree ("userInfoId");
--
-- ACTION ALTER TABLE
--
ALTER TABLE "staff_users" ADD COLUMN "userInfoId" bigint;
CREATE UNIQUE INDEX "staff_user_userinfo_idx" ON "staff_users" USING btree ("userInfoId");

--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250615220723285', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250615220723285', "timestamp" = now();

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
