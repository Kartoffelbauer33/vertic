BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "printer_configurations" (
    "id" bigserial PRIMARY KEY,
    "facilityId" bigint,
    "printerName" text NOT NULL,
    "printerType" text NOT NULL,
    "connectionType" text NOT NULL,
    "connectionSettings" text NOT NULL,
    "paperSize" text NOT NULL,
    "isDefault" boolean NOT NULL,
    "isActive" boolean NOT NULL,
    "testPrintEnabled" boolean NOT NULL,
    "createdBy" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "printer_facility_idx" ON "printer_configurations" USING btree ("facilityId");
CREATE INDEX "printer_default_idx" ON "printer_configurations" USING btree ("isDefault");
CREATE INDEX "printer_active_idx" ON "printer_configurations" USING btree ("isActive");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ticket_visibility_settings" (
    "id" bigserial PRIMARY KEY,
    "ticketTypeId" bigint NOT NULL,
    "isVisibleToClients" boolean NOT NULL,
    "displayOrder" bigint NOT NULL,
    "customDescription" text,
    "isPromoted" boolean NOT NULL,
    "availableFrom" timestamp without time zone,
    "availableUntil" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "ticket_visibility_type_idx" ON "ticket_visibility_settings" USING btree ("ticketTypeId");
CREATE INDEX "ticket_visibility_order_idx" ON "ticket_visibility_settings" USING btree ("displayOrder");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_purchase_statuses" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "ticketTypeId" bigint NOT NULL,
    "lastPurchaseDate" timestamp without time zone NOT NULL,
    "isPrintingPending" boolean NOT NULL,
    "printJobId" text,
    "printedAt" timestamp without time zone,
    "ticketCount" bigint NOT NULL,
    "canPurchaseAgain" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "user_purchase_user_type_idx" ON "user_purchase_statuses" USING btree ("userId", "ticketTypeId");
CREATE INDEX "user_purchase_pending_idx" ON "user_purchase_statuses" USING btree ("isPrintingPending");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250607184822220', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250607184822220', "timestamp" = now();

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
