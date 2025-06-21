BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "account_cleanup_logs" (
    "id" bigserial PRIMARY KEY,
    "cleanupDate" timestamp without time zone NOT NULL,
    "accountsDeleted" bigint NOT NULL,
    "criteriaUsed" text NOT NULL,
    "detailsJson" text,
    "triggeredBy" text NOT NULL
);

-- Indexes
CREATE INDEX "cleanup_log_date_idx" ON "account_cleanup_logs" USING btree ("cleanupDate");

--
-- ACTION ALTER TABLE
--
DROP INDEX "app_user_email_unique_idx";
DROP INDEX "app_user_verification_idx";
ALTER TABLE "app_users" ADD COLUMN "accountStatus" text NOT NULL DEFAULT 'pending_verification'::text;
ALTER TABLE "app_users" ADD COLUMN "verificationCode" text;
ALTER TABLE "app_users" ADD COLUMN "verificationAttempts" bigint NOT NULL DEFAULT 0;
ALTER TABLE "app_users" ADD COLUMN "passwordHash" text;
ALTER TABLE "app_users" ADD COLUMN "isManuallyApproved" boolean NOT NULL DEFAULT false;
ALTER TABLE "app_users" ADD COLUMN "approvedBy" bigint;
ALTER TABLE "app_users" ADD COLUMN "approvedAt" timestamp without time zone;
ALTER TABLE "app_users" ADD COLUMN "approvalReason" text;
ALTER TABLE "app_users" ADD COLUMN "isMinor" boolean NOT NULL DEFAULT false;
ALTER TABLE "app_users" ADD COLUMN "requiresParentalConsent" boolean NOT NULL DEFAULT false;
ALTER TABLE "app_users" ADD COLUMN "lastLoginAt" timestamp without time zone;
ALTER TABLE "app_users" ALTER COLUMN "email" DROP NOT NULL;
CREATE INDEX "app_user_email_idx" ON "app_users" USING btree ("email");
CREATE INDEX "app_user_verification_code_idx" ON "app_users" USING btree ("verificationCode");
CREATE INDEX "app_user_manual_approval_idx" ON "app_users" USING btree ("isManuallyApproved");
CREATE INDEX "app_user_minor_idx" ON "app_users" USING btree ("isMinor");
CREATE INDEX "app_user_created_idx" ON "app_users" USING btree ("createdAt");
CREATE INDEX "app_user_primary_status_idx" ON "app_users" USING btree ("primaryStatusId");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_relationships" (
    "id" bigserial PRIMARY KEY,
    "parentUserId" bigint NOT NULL,
    "childUserId" bigint NOT NULL,
    "relationshipType" text NOT NULL DEFAULT 'parent'::text,
    "canPurchaseTickets" boolean NOT NULL DEFAULT true,
    "canCancelSubscriptions" boolean NOT NULL DEFAULT true,
    "canManagePayments" boolean NOT NULL DEFAULT true,
    "canViewHistory" boolean NOT NULL DEFAULT true,
    "isActive" boolean NOT NULL DEFAULT true,
    "approvedBy" bigint,
    "approvedAt" timestamp without time zone,
    "approvalReason" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "user_rel_parent_idx" ON "user_relationships" USING btree ("parentUserId");
CREATE INDEX "user_rel_child_idx" ON "user_relationships" USING btree ("childUserId");
CREATE UNIQUE INDEX "user_rel_parent_child_unique_idx" ON "user_relationships" USING btree ("parentUserId", "childUserId");
CREATE INDEX "user_rel_active_idx" ON "user_relationships" USING btree ("isActive");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250605134943263', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250605134943263', "timestamp" = now();

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
