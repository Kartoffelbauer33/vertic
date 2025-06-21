BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "app_users" ADD COLUMN "isStaff" boolean NOT NULL DEFAULT false;
ALTER TABLE "app_users" ADD COLUMN "isHallAdmin" boolean NOT NULL DEFAULT false;
ALTER TABLE "app_users" ADD COLUMN "isSuperUser" boolean NOT NULL DEFAULT false;
ALTER TABLE "app_users" ADD COLUMN "hallId" bigint;
CREATE INDEX "app_user_hall_idx" ON "app_users" USING btree ("hallId");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "billing_configurations" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "billingType" text NOT NULL,
    "billingDay" bigint NOT NULL,
    "billingDayOfYear" bigint,
    "customIntervalDays" bigint,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "billing_config_name_unique_idx" ON "billing_configurations" USING btree ("name");
CREATE INDEX "billing_config_active_idx" ON "billing_configurations" USING btree ("isActive");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "gyms" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "shortCode" text NOT NULL,
    "city" text NOT NULL,
    "address" text,
    "description" text,
    "isActive" boolean NOT NULL DEFAULT true,
    "isVerticLocation" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "gym_short_code_unique_idx" ON "gyms" USING btree ("shortCode");
CREATE INDEX "gym_name_idx" ON "gyms" USING btree ("name");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "ticket_types" ADD COLUMN "gymId" bigint;
ALTER TABLE "ticket_types" ADD COLUMN "isVerticUniversal" boolean NOT NULL DEFAULT false;
CREATE INDEX "ticket_type_gym_idx" ON "ticket_types" USING btree ("gymId");
CREATE INDEX "ticket_type_vertic_idx" ON "ticket_types" USING btree ("isVerticUniversal");

--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250601174245667', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250601174245667', "timestamp" = now();

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
