BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "pos_cart_items" (
    "id" bigserial PRIMARY KEY,
    "sessionId" bigint NOT NULL,
    "itemType" text NOT NULL,
    "itemId" bigint NOT NULL,
    "itemName" text NOT NULL,
    "quantity" bigint NOT NULL DEFAULT 1,
    "unitPrice" double precision NOT NULL,
    "totalPrice" double precision NOT NULL,
    "discountAmount" double precision NOT NULL DEFAULT 0.0,
    "addedAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "pos_sessions" (
    "id" bigserial PRIMARY KEY,
    "staffUserId" bigint NOT NULL,
    "customerId" bigint,
    "hallId" bigint NOT NULL,
    "status" text NOT NULL DEFAULT 'active'::text,
    "totalAmount" double precision NOT NULL DEFAULT 0.0,
    "discountAmount" double precision NOT NULL DEFAULT 0.0,
    "paymentMethod" text,
    "createdAt" timestamp without time zone NOT NULL,
    "completedAt" timestamp without time zone
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "pos_transactions" (
    "id" bigserial PRIMARY KEY,
    "sessionId" bigint NOT NULL,
    "customerId" bigint,
    "staffUserId" bigint NOT NULL,
    "hallId" bigint NOT NULL,
    "totalAmount" double precision NOT NULL,
    "paymentMethod" text NOT NULL,
    "receiptNumber" text NOT NULL,
    "items" text NOT NULL,
    "completedAt" timestamp without time zone NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "product_categories" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "displayOrder" bigint NOT NULL DEFAULT 0,
    "isActive" boolean NOT NULL DEFAULT true,
    "hallId" bigint
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "products" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "description" text,
    "categoryId" bigint NOT NULL,
    "price" double precision NOT NULL,
    "barcode" text,
    "sku" text,
    "stockQuantity" bigint,
    "isActive" boolean NOT NULL DEFAULT true,
    "hallId" bigint
);


--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250625190739349', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250625190739349', "timestamp" = now();

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
