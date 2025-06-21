BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "purchase_status_response" (
    "id" bigserial PRIMARY KEY,
    "hasPurchased" boolean NOT NULL,
    "canPurchaseAgain" boolean NOT NULL,
    "isPrintingPending" boolean NOT NULL,
    "lastPurchaseDate" timestamp without time zone,
    "ticketId" bigint,
    "qrCodeData" text
);


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250608162951465', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250608162951465', "timestamp" = now();

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
