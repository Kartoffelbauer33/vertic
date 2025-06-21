BEGIN;

--
-- ACTION ALTER TABLE
--
DROP INDEX "ticket_visibility_type_idx";
ALTER TABLE "ticket_visibility_settings" ADD COLUMN "facilityId" bigint;
ALTER TABLE "ticket_visibility_settings" ADD COLUMN "categoryType" text;
ALTER TABLE "ticket_visibility_settings" ALTER COLUMN "ticketTypeId" DROP NOT NULL;
CREATE INDEX "ticket_visibility_type_facility_idx" ON "ticket_visibility_settings" USING btree ("ticketTypeId", "facilityId");
CREATE INDEX "ticket_visibility_category_idx" ON "ticket_visibility_settings" USING btree ("categoryType", "facilityId");

--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250607193622536', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250607193622536', "timestamp" = now();

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
