BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "facility_module_configs" (
    "id" bigserial PRIMARY KEY,
    "facilityId" bigint NOT NULL,
    "moduleKey" text NOT NULL,
    "isEnabled" boolean NOT NULL DEFAULT true,
    "configData" text,
    "subscriptionType" text,
    "validFrom" timestamp without time zone NOT NULL,
    "validUntil" timestamp without time zone,
    "maxUsers" bigint,
    "maxTransactions" bigint,
    "notes" text,
    "createdBy" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "facility_module_facility_idx" ON "facility_module_configs" USING btree ("facilityId");
CREATE INDEX "facility_module_key_idx" ON "facility_module_configs" USING btree ("moduleKey");
CREATE INDEX "facility_module_enabled_idx" ON "facility_module_configs" USING btree ("isEnabled");
CREATE UNIQUE INDEX "facility_module_unique_idx" ON "facility_module_configs" USING btree ("facilityId", "moduleKey");
CREATE INDEX "facility_module_subscription_idx" ON "facility_module_configs" USING btree ("subscriptionType");
CREATE INDEX "facility_module_valid_from_idx" ON "facility_module_configs" USING btree ("validFrom");
CREATE INDEX "facility_module_valid_until_idx" ON "facility_module_configs" USING btree ("validUntil");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_permissions" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "displayName" text NOT NULL,
    "description" text,
    "category" text NOT NULL,
    "permissionType" text NOT NULL,
    "level" text,
    "moduleKey" text,
    "isSystemPermission" boolean NOT NULL DEFAULT false,
    "isActive" boolean NOT NULL DEFAULT true,
    "sortOrder" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "staff_permission_name_idx" ON "staff_permissions" USING btree ("name");
CREATE INDEX "staff_permission_category_idx" ON "staff_permissions" USING btree ("category");
CREATE INDEX "staff_permission_type_idx" ON "staff_permissions" USING btree ("permissionType");
CREATE INDEX "staff_permission_level_idx" ON "staff_permissions" USING btree ("level");
CREATE INDEX "staff_permission_module_idx" ON "staff_permissions" USING btree ("moduleKey");
CREATE INDEX "staff_permission_system_idx" ON "staff_permissions" USING btree ("isSystemPermission");
CREATE INDEX "staff_permission_active_idx" ON "staff_permissions" USING btree ("isActive");
CREATE INDEX "staff_permission_sort_idx" ON "staff_permissions" USING btree ("sortOrder");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_role_permissions" (
    "id" bigserial PRIMARY KEY,
    "roleId" bigint NOT NULL,
    "permissionId" bigint NOT NULL,
    "grantedBy" bigint NOT NULL,
    "grantedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "staff_role_permission_role_idx" ON "staff_role_permissions" USING btree ("roleId");
CREATE INDEX "staff_role_permission_permission_idx" ON "staff_role_permissions" USING btree ("permissionId");
CREATE UNIQUE INDEX "staff_role_permission_unique_idx" ON "staff_role_permissions" USING btree ("roleId", "permissionId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_roles" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "facilityId" bigint,
    "gymId" bigint,
    "isSystemRole" boolean NOT NULL DEFAULT false,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdBy" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "staff_role_name_idx" ON "staff_roles" USING btree ("name");
CREATE INDEX "staff_role_facility_idx" ON "staff_roles" USING btree ("facilityId");
CREATE INDEX "staff_role_gym_idx" ON "staff_roles" USING btree ("gymId");
CREATE INDEX "staff_role_system_idx" ON "staff_roles" USING btree ("isSystemRole");
CREATE INDEX "staff_role_active_idx" ON "staff_roles" USING btree ("isActive");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_user_roles" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "roleId" bigint NOT NULL,
    "facilityId" bigint,
    "gymId" bigint,
    "validFrom" timestamp without time zone NOT NULL,
    "validUntil" timestamp without time zone,
    "isActive" boolean NOT NULL DEFAULT true,
    "assignedBy" bigint NOT NULL,
    "assignedAt" timestamp without time zone NOT NULL,
    "revokedBy" bigint,
    "revokedAt" timestamp without time zone,
    "revokeReason" text,
    "notes" text
);

-- Indexes
CREATE INDEX "staff_user_role_user_idx" ON "staff_user_roles" USING btree ("userId");
CREATE INDEX "staff_user_role_role_idx" ON "staff_user_roles" USING btree ("roleId");
CREATE INDEX "staff_user_role_facility_idx" ON "staff_user_roles" USING btree ("facilityId");
CREATE INDEX "staff_user_role_gym_idx" ON "staff_user_roles" USING btree ("gymId");
CREATE INDEX "staff_user_role_active_idx" ON "staff_user_roles" USING btree ("isActive");
CREATE INDEX "staff_user_role_valid_from_idx" ON "staff_user_roles" USING btree ("validFrom");
CREATE INDEX "staff_user_role_valid_until_idx" ON "staff_user_roles" USING btree ("validUntil");
CREATE INDEX "staff_user_role_assigned_idx" ON "staff_user_roles" USING btree ("assignedAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "status_hierarchy_response" (
    "id" bigserial PRIMARY KEY,
    "success" boolean NOT NULL,
    "totalStatusTypes" bigint NOT NULL,
    "totalGyms" bigint NOT NULL,
    "totalFacilities" bigint NOT NULL,
    "universalStatusCount" bigint NOT NULL,
    "facilitiesJson" text,
    "statusTypesJson" text,
    "gymsJson" text,
    "error" text
);


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250609154658427', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250609154658427', "timestamp" = now();

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
