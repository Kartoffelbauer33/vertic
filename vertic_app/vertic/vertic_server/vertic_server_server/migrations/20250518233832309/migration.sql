BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "app_users" ADD COLUMN "primaryStatusId" bigint;
CREATE INDEX "app_user_status_idx" ON "app_users" USING btree ("primaryStatusId");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "facilities" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "address" text,
    "city" text,
    "postalCode" text,
    "contactEmail" text,
    "contactPhone" text,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "facility_name_unique_idx" ON "facilities" USING btree ("name");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ticket_type_pricing" (
    "id" bigserial PRIMARY KEY,
    "ticketTypeId" bigint NOT NULL,
    "userStatusTypeId" bigint NOT NULL,
    "price" double precision NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "ticket_type_id_idx" ON "ticket_type_pricing" USING btree ("ticketTypeId");
CREATE INDEX "user_status_type_id_idx" ON "ticket_type_pricing" USING btree ("userStatusTypeId");
CREATE UNIQUE INDEX "unique_combination_idx" ON "ticket_type_pricing" USING btree ("ticketTypeId", "userStatusTypeId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ticket_types" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "validityPeriod" bigint NOT NULL,
    "defaultPrice" double precision NOT NULL,
    "isPointBased" boolean NOT NULL,
    "defaultPoints" bigint,
    "isSubscription" boolean NOT NULL,
    "billingInterval" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "ticket_type_name_unique_idx" ON "ticket_types" USING btree ("name");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ticket_usage_log" (
    "id" bigserial PRIMARY KEY,
    "ticketId" bigint NOT NULL,
    "usageDate" timestamp without time zone NOT NULL,
    "pointsUsed" bigint NOT NULL,
    "facilityId" bigint,
    "staffId" bigint,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "ticket_usage_ticket_idx" ON "ticket_usage_log" USING btree ("ticketId");
CREATE INDEX "ticket_usage_date_idx" ON "ticket_usage_log" USING btree ("usageDate");

--
-- ACTION DROP TABLE
--
DROP TABLE "tickets" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "tickets" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "ticketTypeId" bigint NOT NULL,
    "price" double precision NOT NULL,
    "purchaseDate" timestamp without time zone NOT NULL,
    "expiryDate" timestamp without time zone NOT NULL,
    "isUsed" boolean NOT NULL,
    "remainingPoints" bigint,
    "initialPoints" bigint,
    "subscriptionStatus" text,
    "lastBillingDate" timestamp without time zone,
    "nextBillingDate" timestamp without time zone,
    "qrCodeData" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "ticket_user_idx" ON "tickets" USING btree ("userId");
CREATE INDEX "ticket_type_idx" ON "tickets" USING btree ("ticketTypeId");
CREATE INDEX "ticket_expiry_idx" ON "tickets" USING btree ("expiryDate");
CREATE INDEX "subscription_status_idx" ON "tickets" USING btree ("subscriptionStatus");
CREATE INDEX "next_billing_date_idx" ON "tickets" USING btree ("nextBillingDate");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_status" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "statusTypeId" bigint NOT NULL,
    "isVerified" boolean NOT NULL,
    "verifiedById" bigint,
    "verificationDate" timestamp without time zone,
    "expiryDate" timestamp without time zone,
    "documentationPath" text,
    "notes" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "user_status_user_idx" ON "user_status" USING btree ("userId");
CREATE INDEX "user_status_type_idx" ON "user_status" USING btree ("statusTypeId");
CREATE INDEX "is_verified_idx" ON "user_status" USING btree ("isVerified");
CREATE INDEX "verified_status_combined_idx" ON "user_status" USING btree ("userId", "statusTypeId", "isVerified");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_status_types" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "discountPercentage" double precision NOT NULL,
    "requiresVerification" boolean NOT NULL,
    "requiresDocumentation" boolean NOT NULL,
    "validityPeriod" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_status_type_name_unique_idx" ON "user_status_types" USING btree ("name");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250518233832309', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250518233832309', "timestamp" = now();

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
