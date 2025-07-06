BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "open_food_facts_cache" (
    "id" bigserial PRIMARY KEY,
    "barcode" text NOT NULL,
    "cachedData" text NOT NULL,
    "cachedAt" timestamp without time zone NOT NULL,
    "isValid" boolean NOT NULL DEFAULT true,
    "productFound" boolean NOT NULL DEFAULT false,
    "lastApiStatus" bigint
);

-- Indexes
CREATE INDEX "cache_barcode_idx" ON "open_food_facts_cache" USING btree ("barcode");
CREATE INDEX "cache_valid_idx" ON "open_food_facts_cache" USING btree ("isValid");
CREATE INDEX "cache_found_idx" ON "open_food_facts_cache" USING btree ("productFound");
CREATE INDEX "cache_date_idx" ON "open_food_facts_cache" USING btree ("cachedAt");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "product_categories" ADD COLUMN "colorHex" text NOT NULL DEFAULT '#607D8B'::text;
ALTER TABLE "product_categories" ADD COLUMN "iconName" text NOT NULL DEFAULT 'category'::text;
ALTER TABLE "product_categories" ADD COLUMN "isFavorites" boolean NOT NULL DEFAULT false;
ALTER TABLE "product_categories" ADD COLUMN "isSystemCategory" boolean NOT NULL DEFAULT false;
ALTER TABLE "product_categories" ADD COLUMN "createdByStaffId" bigint;
ALTER TABLE "product_categories" ADD COLUMN "createdAt" timestamp without time zone;
ALTER TABLE "product_categories" ADD COLUMN "updatedAt" timestamp without time zone;
CREATE INDEX "categories_active_idx" ON "product_categories" USING btree ("isActive");
CREATE INDEX "categories_favorites_idx" ON "product_categories" USING btree ("isFavorites");
CREATE INDEX "categories_display_order_idx" ON "product_categories" USING btree ("displayOrder");
CREATE INDEX "categories_system_idx" ON "product_categories" USING btree ("isSystemCategory");
CREATE INDEX "categories_hall_idx" ON "product_categories" USING btree ("hallId");
--
-- ACTION ALTER TABLE
--
ALTER TABLE "products" ADD COLUMN "costPrice" double precision;
ALTER TABLE "products" ADD COLUMN "marginPercentage" double precision;
ALTER TABLE "products" ADD COLUMN "minStockThreshold" bigint;
ALTER TABLE "products" ADD COLUMN "isFoodItem" boolean NOT NULL DEFAULT false;
ALTER TABLE "products" ADD COLUMN "openFoodFactsId" text;
ALTER TABLE "products" ADD COLUMN "imageUrl" text;
ALTER TABLE "products" ADD COLUMN "createdByStaffId" bigint;
ALTER TABLE "products" ADD COLUMN "createdAt" timestamp without time zone;
ALTER TABLE "products" ADD COLUMN "updatedAt" timestamp without time zone;
ALTER TABLE "products" ALTER COLUMN "categoryId" DROP NOT NULL;
CREATE INDEX "products_barcode_idx" ON "products" USING btree ("barcode");
CREATE INDEX "products_category_idx" ON "products" USING btree ("categoryId");
CREATE INDEX "products_active_idx" ON "products" USING btree ("isActive");
CREATE INDEX "products_stock_idx" ON "products" USING btree ("stockQuantity");
CREATE INDEX "products_creator_idx" ON "products" USING btree ("createdByStaffId");
CREATE INDEX "products_hall_idx" ON "products" USING btree ("hallId");

--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250706151108114-product-management', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250706151108114-product-management', "timestamp" = now();

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
