BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "qr_rotation_policies" (
    "id" bigserial PRIMARY KEY,
    "policyName" text NOT NULL,
    "rotationMode" text NOT NULL,
    "rotationIntervalHours" bigint,
    "requiresUsageForRotation" boolean NOT NULL,
    "maxUsageBeforeRotation" bigint,
    "isDefault" boolean NOT NULL,
    "description" text,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "qr_policy_name_idx" ON "qr_rotation_policies" USING btree ("policyName");
CREATE INDEX "qr_policy_default_idx" ON "qr_rotation_policies" USING btree ("isDefault");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "system_settings" (
    "id" bigserial PRIMARY KEY,
    "settingKey" text NOT NULL,
    "settingValue" text NOT NULL,
    "settingType" text NOT NULL,
    "description" text,
    "isUserConfigurable" boolean NOT NULL,
    "isSuperAdminOnly" boolean NOT NULL,
    "lastModifiedBy" bigint,
    "lastModifiedAt" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "system_setting_key_idx" ON "system_settings" USING btree ("settingKey");
CREATE INDEX "system_setting_type_idx" ON "system_settings" USING btree ("settingType");

--
-- ACTION DROP TABLE
--
DROP TABLE "user_identities" CASCADE;

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
    "rotationPolicyId" bigint,
    "nextRotationDue" timestamp without time zone,
    "forceRotationAfterUsage" boolean NOT NULL,
    "unlockExpiry" timestamp without time zone,
    "requiresUnlock" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_identity_user_idx" ON "user_identities" USING btree ("userId");
CREATE INDEX "user_identity_active_idx" ON "user_identities" USING btree ("isActive");
CREATE INDEX "user_identity_rotation_due_idx" ON "user_identities" USING btree ("nextRotationDue");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250607175021412', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250607175021412', "timestamp" = now();

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
