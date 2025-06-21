BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "staff_auth_response" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "client_document_agreements" (
    "id" bigserial PRIMARY KEY,
    "clientId" bigint NOT NULL,
    "documentId" bigint NOT NULL,
    "agreedAt" timestamp without time zone NOT NULL,
    "ipAddress" text,
    "userAgent" text,
    "documentVersion" text,
    "isRevoked" boolean NOT NULL,
    "revokedAt" timestamp without time zone
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "document_display_rules" (
    "id" bigserial PRIMARY KEY,
    "documentId" bigint NOT NULL,
    "ruleName" text NOT NULL,
    "description" text,
    "minAge" bigint,
    "maxAge" bigint,
    "gymId" bigint,
    "isRequired" boolean NOT NULL,
    "isActive" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "registration_documents" (
    "id" bigserial PRIMARY KEY,
    "title" text NOT NULL,
    "description" text,
    "documentType" text NOT NULL,
    "pdfData" bytea NOT NULL,
    "fileName" text NOT NULL,
    "fileSize" bigint NOT NULL,
    "uploadedByStaffId" bigint,
    "isActive" boolean NOT NULL,
    "sortOrder" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone
);


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250608110709889', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250608110709889', "timestamp" = now();

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
