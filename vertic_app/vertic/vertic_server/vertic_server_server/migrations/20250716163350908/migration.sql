BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "product_categories" ADD COLUMN "parentCategoryId" bigint;
ALTER TABLE "product_categories" ADD COLUMN "level" bigint NOT NULL DEFAULT 0;
ALTER TABLE "product_categories" ADD COLUMN "hasChildren" boolean NOT NULL DEFAULT false;
CREATE INDEX "categories_parent_idx" ON "product_categories" USING btree ("parentCategoryId");
CREATE INDEX "categories_level_idx" ON "product_categories" USING btree ("level");
CREATE INDEX "categories_has_children_idx" ON "product_categories" USING btree ("hasChildren");
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "product_categories"
    ADD CONSTRAINT "product_categories_fk_0"
    FOREIGN KEY("parentCategoryId")
    REFERENCES "product_categories"("id")
    ON DELETE SET NULL
    ON UPDATE NO ACTION;

--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250716163350908', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250716163350908', "timestamp" = now();

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
