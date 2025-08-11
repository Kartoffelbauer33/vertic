BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_verification_tokens" (
    "id" bigserial PRIMARY KEY,
    "staffUserId" bigint NOT NULL,
    "email" text NOT NULL,
    "token" text NOT NULL,
    "tokenType" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "isUsed" boolean NOT NULL,
    "usedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "staff_verification_tokens_staff_user_id_idx" ON "staff_verification_tokens" USING btree ("staffUserId");
CREATE INDEX "staff_verification_tokens_email_idx" ON "staff_verification_tokens" USING btree ("email");
CREATE UNIQUE INDEX "staff_verification_tokens_token_idx" ON "staff_verification_tokens" USING btree ("token");
CREATE INDEX "staff_verification_tokens_email_token_composite_idx" ON "staff_verification_tokens" USING btree ("email");


--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250808193907676', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250808193907676', "timestamp" = now();

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
