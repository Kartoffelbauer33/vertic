BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "facilities" ADD COLUMN "countryId" bigint;
ALTER TABLE "facilities" ADD COLUMN "isCountryLocked" boolean NOT NULL DEFAULT false;
ALTER TABLE "facilities" ADD COLUMN "countryAssignedByStaffId" bigint;
ALTER TABLE "facilities" ADD COLUMN "countryAssignedAt" timestamp without time zone;
CREATE INDEX "facility_country_idx" ON "facilities" USING btree ("countryId");
CREATE INDEX "facility_country_locked_idx" ON "facilities" USING btree ("isCountryLocked");
CREATE INDEX "facility_active_idx" ON "facilities" USING btree ("isActive");

--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250706165846196', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250706165846196', "timestamp" = now();

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
