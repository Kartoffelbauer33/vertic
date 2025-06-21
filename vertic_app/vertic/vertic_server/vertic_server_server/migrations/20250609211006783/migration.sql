BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "staff_roles" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "staff_role_permissions" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "staff_permissions" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "permissions" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "displayName" text NOT NULL,
    "description" text,
    "category" text NOT NULL,
    "isSystemCritical" boolean NOT NULL DEFAULT false,
    "iconName" text,
    "color" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "permission_name_unique_idx" ON "permissions" USING btree ("name");
CREATE INDEX "permission_category_idx" ON "permissions" USING btree ("category");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "role_permissions" (
    "id" bigserial PRIMARY KEY,
    "roleId" bigint NOT NULL,
    "permissionId" bigint NOT NULL,
    "assignedAt" timestamp without time zone NOT NULL,
    "assignedBy" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "role_permission_unique_idx" ON "role_permissions" USING btree ("roleId", "permissionId");
CREATE INDEX "role_permissions_idx" ON "role_permissions" USING btree ("roleId");
CREATE INDEX "permission_roles_idx" ON "role_permissions" USING btree ("permissionId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "roles" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "displayName" text NOT NULL,
    "description" text,
    "color" text,
    "iconName" text,
    "isSystemRole" boolean NOT NULL DEFAULT false,
    "isActive" boolean NOT NULL DEFAULT true,
    "sortOrder" bigint NOT NULL DEFAULT 0,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "createdBy" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "role_name_unique_idx" ON "roles" USING btree ("name");
CREATE INDEX "role_active_sort_idx" ON "roles" USING btree ("isActive", "sortOrder");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_user_permissions" (
    "id" bigserial PRIMARY KEY,
    "staffUserId" bigint NOT NULL,
    "permissionId" bigint NOT NULL,
    "grantedAt" timestamp without time zone NOT NULL,
    "grantedBy" bigint NOT NULL,
    "expiresAt" timestamp without time zone,
    "isActive" boolean NOT NULL DEFAULT true,
    "reason" text,
    "notes" text
);

-- Indexes
CREATE UNIQUE INDEX "staff_permission_unique_idx" ON "staff_user_permissions" USING btree ("staffUserId", "permissionId");
CREATE INDEX "staff_user_permission_idx" ON "staff_user_permissions" USING btree ("staffUserId");
CREATE INDEX "permission_staff_idx" ON "staff_user_permissions" USING btree ("permissionId");
CREATE INDEX "active_staff_permissions_idx" ON "staff_user_permissions" USING btree ("isActive", "expiresAt");

--
-- ACTION ALTER TABLE
--
DROP INDEX "staff_user_role_user_idx";
DROP INDEX "staff_user_role_role_idx";
DROP INDEX "staff_user_role_facility_idx";
DROP INDEX "staff_user_role_gym_idx";
DROP INDEX "staff_user_role_active_idx";
DROP INDEX "staff_user_role_valid_from_idx";
DROP INDEX "staff_user_role_valid_until_idx";
DROP INDEX "staff_user_role_assigned_idx";
ALTER TABLE "staff_user_roles" DROP COLUMN "facilityId";
ALTER TABLE "staff_user_roles" DROP COLUMN "gymId";
ALTER TABLE "staff_user_roles" DROP COLUMN "validFrom";
ALTER TABLE "staff_user_roles" DROP COLUMN "validUntil";
ALTER TABLE "staff_user_roles" DROP COLUMN "revokedBy";
ALTER TABLE "staff_user_roles" DROP COLUMN "revokedAt";
ALTER TABLE "staff_user_roles" DROP COLUMN "revokeReason";
ALTER TABLE "staff_user_roles" DROP COLUMN "notes";
ALTER TABLE "staff_user_roles" ADD COLUMN "expiresAt" timestamp without time zone;
ALTER TABLE "staff_user_roles" ADD COLUMN "reason" text;
CREATE UNIQUE INDEX "staff_role_unique_idx" ON "staff_user_roles" USING btree ("staffUserId", "roleId");
CREATE INDEX "staff_user_roles_idx" ON "staff_user_roles" USING btree ("staffUserId");
CREATE INDEX "role_staff_users_idx" ON "staff_user_roles" USING btree ("roleId");
CREATE INDEX "active_staff_roles_idx" ON "staff_user_roles" USING btree ("isActive", "expiresAt");
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "role_permissions"
    ADD CONSTRAINT "role_permissions_fk_0"
    FOREIGN KEY("roleId")
    REFERENCES "roles"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "role_permissions"
    ADD CONSTRAINT "role_permissions_fk_1"
    FOREIGN KEY("permissionId")
    REFERENCES "permissions"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "role_permissions"
    ADD CONSTRAINT "role_permissions_fk_2"
    FOREIGN KEY("assignedBy")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "roles"
    ADD CONSTRAINT "roles_fk_0"
    FOREIGN KEY("createdBy")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "staff_user_permissions"
    ADD CONSTRAINT "staff_user_permissions_fk_0"
    FOREIGN KEY("staffUserId")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "staff_user_permissions"
    ADD CONSTRAINT "staff_user_permissions_fk_1"
    FOREIGN KEY("permissionId")
    REFERENCES "permissions"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "staff_user_permissions"
    ADD CONSTRAINT "staff_user_permissions_fk_2"
    FOREIGN KEY("grantedBy")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "staff_user_roles"
    ADD CONSTRAINT "staff_user_roles_fk_0"
    FOREIGN KEY("staffUserId")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "staff_user_roles"
    ADD CONSTRAINT "staff_user_roles_fk_1"
    FOREIGN KEY("roleId")
    REFERENCES "roles"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "staff_user_roles"
    ADD CONSTRAINT "staff_user_roles_fk_2"
    FOREIGN KEY("assignedBy")
    REFERENCES "staff_users"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250609211006783', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250609211006783', "timestamp" = now();

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
