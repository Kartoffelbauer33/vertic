BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tickets" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "ticketType" text NOT NULL,
    "price" double precision NOT NULL,
    "purchaseDate" timestamp without time zone NOT NULL,
    "validDate" timestamp without time zone NOT NULL,
    "isUsed" boolean NOT NULL,
    "qrCodeData" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "ticket_user_idx" ON "tickets" USING btree ("userId");
CREATE INDEX "ticket_validdate_idx" ON "tickets" USING btree ("validDate");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250517160439905', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250517160439905', "timestamp" = now();

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
