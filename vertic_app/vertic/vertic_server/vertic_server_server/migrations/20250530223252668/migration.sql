BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_identities" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "qrCodeData" text NOT NULL,
    "qrCodeGenerated" timestamp without time zone NOT NULL,
    "lastUsed" timestamp without time zone,
    "usageCount" bigint NOT NULL,
    "isActive" boolean NOT NULL,
    "unlockExpiry" timestamp without time zone,
    "requiresUnlock" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_identity_user_idx" ON "user_identities" USING btree ("userId");
CREATE INDEX "user_identity_active_idx" ON "user_identities" USING btree ("isActive");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250530223252668', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250530223252668', "timestamp" = now();

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
