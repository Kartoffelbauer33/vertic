BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "staff_user_roles" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_user_roles" (
    "id" bigserial PRIMARY KEY,
    "staffUserId" bigint NOT NULL,
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
CREATE INDEX "staff_user_role_user_idx" ON "staff_user_roles" USING btree ("staffUserId");
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
CREATE TABLE "staff_users" (
    "id" bigserial PRIMARY KEY,
    "firstName" text NOT NULL,
    "lastName" text NOT NULL,
    "email" text NOT NULL,
    "phoneNumber" text,
    "employeeId" text,
    "socialSecurityNumber" text,
    "birthDate" timestamp without time zone,
    "contractType" text,
    "hourlyRate" double precision,
    "monthlySalary" double precision,
    "contractStartDate" timestamp without time zone,
    "contractEndDate" timestamp without time zone,
    "workingHours" bigint,
    "shiftModel" text,
    "availabilityData" text,
    "qualifications" text,
    "certifications" text,
    "languages" text,
    "bankIban" text,
    "bankBic" text,
    "bankAccountHolder" text,
    "taxId" text,
    "taxClass" text,
    "address" text,
    "city" text,
    "postalCode" text,
    "emergencyContact" text,
    "staffLevel" bigint NOT NULL,
    "departmentId" bigint,
    "hallId" bigint,
    "facilityId" bigint,
    "passwordHash" text,
    "lastLoginAt" timestamp without time zone,
    "loginAttempts" bigint NOT NULL DEFAULT 0,
    "isAccountLocked" boolean NOT NULL DEFAULT false,
    "lockoutUntil" timestamp without time zone,
    "employmentStatus" text NOT NULL DEFAULT 'active'::text,
    "terminationDate" timestamp without time zone,
    "terminationReason" text,
    "createdBy" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "updatedBy" bigint,
    "notes" text,
    "documentsJson" text
);

-- Indexes
CREATE UNIQUE INDEX "staff_user_email_idx" ON "staff_users" USING btree ("email");
CREATE UNIQUE INDEX "staff_user_employee_id_idx" ON "staff_users" USING btree ("employeeId");
CREATE INDEX "staff_user_level_idx" ON "staff_users" USING btree ("staffLevel");
CREATE INDEX "staff_user_department_idx" ON "staff_users" USING btree ("departmentId");
CREATE INDEX "staff_user_hall_idx" ON "staff_users" USING btree ("hallId");
CREATE INDEX "staff_user_facility_idx" ON "staff_users" USING btree ("facilityId");
CREATE INDEX "staff_user_status_idx" ON "staff_users" USING btree ("employmentStatus");
CREATE INDEX "staff_user_created_idx" ON "staff_users" USING btree ("createdAt");
CREATE INDEX "staff_user_login_idx" ON "staff_users" USING btree ("lastLoginAt");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250609175459084', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250609175459084', "timestamp" = now();

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
