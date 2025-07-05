BEGIN;

--
-- VORBEREITUNG: Alle POS-Sessions ohne deviceId löschen
-- (Da wir das deviceId-Feld als required einführen)
--
DELETE FROM "pos_sessions" WHERE "deviceId" IS NULL;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "pos_sessions" ALTER COLUMN "deviceId" SET NOT NULL;

--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250705170649864', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250705170649864', "timestamp" = now();

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
