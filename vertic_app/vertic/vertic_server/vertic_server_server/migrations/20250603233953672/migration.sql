BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "app_users" ADD COLUMN "isEmailVerified" boolean NOT NULL DEFAULT false;
ALTER TABLE "app_users" ADD COLUMN "isBlocked" boolean NOT NULL DEFAULT false;
ALTER TABLE "app_users" ADD COLUMN "blockedReason" text;
ALTER TABLE "app_users" ADD COLUMN "blockedAt" timestamp without time zone;
ALTER TABLE "app_users" ADD COLUMN "verificationCodeExpiry" timestamp without time zone;
CREATE INDEX "app_user_blocked_idx" ON "app_users" USING btree ("isBlocked");
CREATE INDEX "app_user_verification_idx" ON "app_users" USING btree ("isEmailVerified");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "email_verification_requests" (
    "id" bigserial PRIMARY KEY,
    "email" text NOT NULL,
    "verificationCode" text NOT NULL,
    "userName" text NOT NULL,
    "passwordHash" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL,
    "isUsed" boolean NOT NULL DEFAULT false,
    "usedAt" timestamp without time zone,
    "attemptsCount" bigint NOT NULL DEFAULT 0,
    "lastAttemptAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "email_verification_email_idx" ON "email_verification_requests" USING btree ("email");
CREATE UNIQUE INDEX "email_verification_code_idx" ON "email_verification_requests" USING btree ("verificationCode");
CREATE INDEX "email_verification_expires_idx" ON "email_verification_requests" USING btree ("expiresAt");
CREATE INDEX "email_verification_active_idx" ON "email_verification_requests" USING btree ("isUsed", "expiresAt");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250603233953672', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250603233953672', "timestamp" = now();

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
