BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "countries" (
    "id" bigserial PRIMARY KEY,
    "code" text NOT NULL,
    "name" text NOT NULL,
    "displayName" text NOT NULL,
    "currency" text NOT NULL DEFAULT 'EUR'::text,
    "locale" text NOT NULL,
    "requiresTSE" boolean NOT NULL DEFAULT false,
    "requiresRKSV" boolean NOT NULL DEFAULT false,
    "vatRegistrationThreshold" double precision,
    "isActive" boolean NOT NULL DEFAULT true,
    "isDefault" boolean NOT NULL DEFAULT false,
    "supportLevel" text NOT NULL DEFAULT 'basic'::text,
    "taxSystemType" text NOT NULL,
    "receiptRequirements" text,
    "exportFormats" text,
    "createdAt" timestamp without time zone,
    "updatedAt" timestamp without time zone,
    "createdByStaffId" bigint
);

-- Indexes
CREATE UNIQUE INDEX "countries_code_unique" ON "countries" USING btree ("code");
CREATE INDEX "countries_active_idx" ON "countries" USING btree ("isActive");
CREATE INDEX "countries_default_idx" ON "countries" USING btree ("isDefault");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "products" ADD COLUMN "taxClassId" bigint;
ALTER TABLE "products" ADD COLUMN "defaultCountryId" bigint;
ALTER TABLE "products" ADD COLUMN "complianceSettings" text;
ALTER TABLE "products" ADD COLUMN "requiresTSESignature" boolean NOT NULL DEFAULT false;
ALTER TABLE "products" ADD COLUMN "requiresAgeVerification" boolean NOT NULL DEFAULT false;
ALTER TABLE "products" ADD COLUMN "isSubjectToSpecialTax" boolean NOT NULL DEFAULT false;
CREATE INDEX "products_tax_class_idx" ON "products" USING btree ("taxClassId");
CREATE INDEX "products_country_idx" ON "products" USING btree ("defaultCountryId");
CREATE INDEX "products_tse_required_idx" ON "products" USING btree ("requiresTSESignature");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "tax_classes" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "internalCode" text NOT NULL,
    "countryId" bigint NOT NULL,
    "taxRate" double precision NOT NULL,
    "taxType" text NOT NULL,
    "productCategory" text NOT NULL,
    "requiresTSESignature" boolean NOT NULL DEFAULT false,
    "requiresRKSVChain" boolean NOT NULL DEFAULT false,
    "isDefault" boolean NOT NULL DEFAULT false,
    "appliesToMemberships" boolean NOT NULL DEFAULT false,
    "appliesToOneTimeEntries" boolean NOT NULL DEFAULT true,
    "appliesToProducts" boolean NOT NULL DEFAULT true,
    "isActive" boolean NOT NULL DEFAULT true,
    "effectiveFrom" timestamp without time zone,
    "effectiveTo" timestamp without time zone,
    "displayOrder" bigint NOT NULL DEFAULT 0,
    "colorHex" text NOT NULL DEFAULT '#607D8B'::text,
    "iconName" text NOT NULL DEFAULT 'receipt'::text,
    "createdAt" timestamp without time zone,
    "updatedAt" timestamp without time zone,
    "createdByStaffId" bigint
);

-- Indexes
CREATE INDEX "tax_classes_country_idx" ON "tax_classes" USING btree ("countryId");
CREATE INDEX "tax_classes_active_idx" ON "tax_classes" USING btree ("isActive");


--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250706163907161', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250706163907161', "timestamp" = now();

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
