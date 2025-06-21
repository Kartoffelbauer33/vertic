BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "app_users" (
    "id" bigserial PRIMARY KEY,
    "firstName" text NOT NULL,
    "lastName" text NOT NULL,
    "email" text NOT NULL,
    "gender" text,
    "address" text,
    "city" text,
    "postalCode" text,
    "phoneNumber" text,
    "birthDate" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "app_user_email_unique_idx" ON "app_users" USING btree ("email");


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250516225602069-create-app-users-table', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250516225602069-create-app-users-table', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20240516151843329', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
