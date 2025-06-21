BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "user_status_types" ADD COLUMN "gymId" bigint;
ALTER TABLE "user_status_types" ADD COLUMN "isVerticUniversal" boolean NOT NULL DEFAULT false;
CREATE INDEX "user_status_type_gym_idx" ON "user_status_types" USING btree ("gymId");
CREATE INDEX "user_status_type_vertic_idx" ON "user_status_types" USING btree ("isVerticUniversal");

--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250601175950723', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250601175950723', "timestamp" = now();

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
