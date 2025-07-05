BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "app_users" ADD COLUMN "preferredHallId" bigint;
ALTER TABLE "app_users" ADD COLUMN "lastKnownHallId" bigint;
ALTER TABLE "app_users" ADD COLUMN "registrationHallId" bigint;
CREATE INDEX "app_user_preferred_hall_idx" ON "app_users" USING btree ("preferredHallId");
CREATE INDEX "app_user_last_known_hall_idx" ON "app_users" USING btree ("lastKnownHallId");
CREATE INDEX "app_user_registration_hall_idx" ON "app_users" USING btree ("registrationHallId");
--
-- ACTION ALTER TABLE
--
ALTER TABLE "external_providers" ADD COLUMN "reEntryWindowType" text NOT NULL DEFAULT 'hours'::text;
ALTER TABLE "external_providers" ADD COLUMN "reEntryWindowDays" bigint NOT NULL DEFAULT 1;
ALTER TABLE "external_providers" ALTER COLUMN "apiCredentialsJson" DROP NOT NULL;

--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250623165816442', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250623165816442', "timestamp" = now();

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
