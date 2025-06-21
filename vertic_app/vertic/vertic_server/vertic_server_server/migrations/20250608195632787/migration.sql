BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_notes" (
    "id" bigserial PRIMARY KEY,
    "userId" bigint NOT NULL,
    "noteType" text NOT NULL,
    "content" text NOT NULL,
    "isInternal" boolean NOT NULL DEFAULT true,
    "priority" text NOT NULL DEFAULT 'normal'::text,
    "createdByStaffId" bigint,
    "createdByName" text,
    "status" text NOT NULL DEFAULT 'active'::text,
    "tags" text,
    "relatedTicketId" bigint,
    "relatedStatusId" bigint,
    "ipAddress" text,
    "userAgent" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone,
    "resolvedAt" timestamp without time zone
);

-- Indexes
CREATE INDEX "user_note_user_idx" ON "user_notes" USING btree ("userId");
CREATE INDEX "user_note_staff_idx" ON "user_notes" USING btree ("createdByStaffId");
CREATE INDEX "user_note_type_idx" ON "user_notes" USING btree ("noteType");
CREATE INDEX "user_note_priority_idx" ON "user_notes" USING btree ("priority");
CREATE INDEX "user_note_status_idx" ON "user_notes" USING btree ("status");
CREATE INDEX "user_note_created_idx" ON "user_notes" USING btree ("createdAt");
CREATE INDEX "user_note_ticket_idx" ON "user_notes" USING btree ("relatedTicketId");
CREATE INDEX "user_note_user_status_idx" ON "user_notes" USING btree ("relatedStatusId");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250608195632787', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250608195632787', "timestamp" = now();

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
