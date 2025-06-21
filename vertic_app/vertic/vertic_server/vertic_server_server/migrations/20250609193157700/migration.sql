BEGIN;

--
-- ACTION ALTER TABLE
--
DROP INDEX "app_user_hall_idx";
DROP INDEX "app_user_facility_idx";
ALTER TABLE "app_users" DROP COLUMN "isStaff";
ALTER TABLE "app_users" DROP COLUMN "isHallAdmin";
ALTER TABLE "app_users" DROP COLUMN "isFacilityAdmin";
ALTER TABLE "app_users" DROP COLUMN "isSuperUser";
ALTER TABLE "app_users" DROP COLUMN "hallId";
ALTER TABLE "app_users" DROP COLUMN "facilityId";

--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250609193157700', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250609193157700', "timestamp" = now();

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
