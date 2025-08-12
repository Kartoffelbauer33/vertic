BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "pending_staff_users" (
    "id" bigserial PRIMARY KEY,
    "firstName" text NOT NULL,
    "lastName" text NOT NULL,
    "email" text NOT NULL,
    "passwordHash" text NOT NULL,
    "phoneNumber" text,
    "employeeId" text,
    "staffLevel" bigint NOT NULL,
    "hallId" bigint,
    "facilityId" bigint,
    "departmentId" bigint,
    "contractType" text,
    "hourlyRate" double precision,
    "monthlySalary" double precision,
    "workingHours" bigint,
    "roleIds" text,
    "verificationToken" text NOT NULL,
    "tokenExpiresAt" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "pending_staff_users_email_idx" ON "pending_staff_users" USING btree ("email");
CREATE UNIQUE INDEX "pending_staff_users_token_idx" ON "pending_staff_users" USING btree ("verificationToken");
CREATE INDEX "pending_staff_users_expires_idx" ON "pending_staff_users" USING btree ("tokenExpiresAt");


--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250810102346002', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250810102346002', "timestamp" = now();

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
