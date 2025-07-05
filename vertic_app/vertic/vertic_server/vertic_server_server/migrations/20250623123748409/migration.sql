BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "external_checkin_logs" (
    "id" bigserial PRIMARY KEY,
    "membershipId" bigint NOT NULL,
    "hallId" bigint NOT NULL,
    "checkinType" text NOT NULL,
    "qrCodeData" text,
    "externalResponse" text,
    "externalStatusCode" bigint,
    "accessGranted" boolean NOT NULL,
    "failureReason" text,
    "staffId" bigint,
    "scannerDeviceId" text,
    "processingTimeMs" bigint,
    "checkinAt" timestamp without time zone NOT NULL,
    "isReEntry" boolean NOT NULL DEFAULT false,
    "originalCheckinId" bigint
);

-- Indexes
CREATE INDEX "external_checkin_membership_idx" ON "external_checkin_logs" USING btree ("membershipId");
CREATE INDEX "external_checkin_hall_idx" ON "external_checkin_logs" USING btree ("hallId");
CREATE INDEX "external_checkin_date_idx" ON "external_checkin_logs" USING btree ("checkinAt");
CREATE INDEX "external_checkin_access_idx" ON "external_checkin_logs" USING btree ("accessGranted");
CREATE INDEX "external_checkin_staff_idx" ON "external_checkin_logs" USING btree ("staffId");
CREATE INDEX "external_checkin_reentry_idx" ON "external_checkin_logs" USING btree ("membershipId", "checkinAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "external_providers" (
    "id" bigserial PRIMARY KEY,
    "providerName" text NOT NULL,
    "displayName" text NOT NULL,
    "hallId" bigint NOT NULL,
    "isActive" boolean NOT NULL DEFAULT true,
    "apiBaseUrl" text,
    "apiCredentialsJson" text NOT NULL,
    "sportPartnerId" text,
    "doorId" text,
    "allowReEntry" boolean NOT NULL DEFAULT true,
    "reEntryWindowHours" bigint NOT NULL DEFAULT 3,
    "requireStaffValidation" boolean NOT NULL DEFAULT false,
    "supportedFeatures" text NOT NULL DEFAULT '["check_in", "re_entry"]'::text,
    "createdBy" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "updatedBy" bigint
);

-- Indexes
CREATE UNIQUE INDEX "external_provider_hall_name_idx" ON "external_providers" USING btree ("hallId", "providerName");
CREATE INDEX "external_provider_active_idx" ON "external_providers" USING btree ("isActive");
CREATE INDEX "external_provider_hall_idx" ON "external_providers" USING btree ("hallId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_external_memberships" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "providerId" bigint NOT NULL,
    "externalUserId" text NOT NULL,
    "membershipEmail" text,
    "membershipData" text,
    "isActive" boolean NOT NULL DEFAULT true,
    "verificationMethod" text NOT NULL DEFAULT 'qr_scan'::text,
    "verifiedAt" timestamp without time zone,
    "lastCheckinAt" timestamp without time zone,
    "totalCheckins" bigint NOT NULL DEFAULT 0,
    "lastSuccessfulCheckin" timestamp without time zone,
    "lastFailedCheckin" timestamp without time zone,
    "failureCount" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "notes" text
);

-- Indexes
CREATE UNIQUE INDEX "user_membership_user_provider_idx" ON "user_external_memberships" USING btree ("userId", "providerId");
CREATE UNIQUE INDEX "user_membership_external_id_idx" ON "user_external_memberships" USING btree ("providerId", "externalUserId");
CREATE INDEX "user_membership_active_idx" ON "user_external_memberships" USING btree ("isActive");
CREATE INDEX "user_membership_provider_idx" ON "user_external_memberships" USING btree ("providerId");
CREATE INDEX "user_membership_user_idx" ON "user_external_memberships" USING btree ("userId");


--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250623123748409', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250623123748409', "timestamp" = now();

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
