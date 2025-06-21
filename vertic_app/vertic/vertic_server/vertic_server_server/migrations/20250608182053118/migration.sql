BEGIN;

--
-- ACTION ALTER TABLE
--
DROP INDEX "ticket_user_idx";
DROP INDEX "ticket_type_idx";
DROP INDEX "ticket_expiry_idx";
DROP INDEX "subscription_status_idx";
DROP INDEX "next_billing_date_idx";
ALTER TABLE "tickets" ADD COLUMN "activatedDate" timestamp without time zone;
ALTER TABLE "tickets" ADD COLUMN "activatedForDate" timestamp without time zone;
ALTER TABLE "tickets" ADD COLUMN "currentUsageCount" bigint NOT NULL DEFAULT 0;
CREATE INDEX "tickets_user_idx" ON "tickets" USING btree ("userId");
CREATE INDEX "tickets_type_idx" ON "tickets" USING btree ("ticketTypeId");
CREATE INDEX "tickets_expiry_idx" ON "tickets" USING btree ("expiryDate");
CREATE INDEX "tickets_activated_idx" ON "tickets" USING btree ("activatedForDate");
CREATE INDEX "tickets_qr_idx" ON "tickets" USING btree ("qrCodeData");

--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250608182053118', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250608182053118', "timestamp" = now();

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
