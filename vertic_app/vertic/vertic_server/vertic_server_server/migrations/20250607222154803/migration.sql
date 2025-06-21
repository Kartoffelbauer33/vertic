BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "hall_info" (
    "id" bigserial PRIMARY KEY,
    "hallName" text NOT NULL,
    "isVisible" boolean NOT NULL,
    "einzeltickets" json NOT NULL,
    "punktekarten" json NOT NULL,
    "zeitkarten" json NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "hierarchical_ticket_response" (
    "id" bigserial PRIMARY KEY,
    "vertic" json NOT NULL,
    "bregenz" json NOT NULL,
    "friedrichshafen" json NOT NULL
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "staff_auth_response" (
    "id" bigserial PRIMARY KEY,
    "success" boolean NOT NULL,
    "token" text,
    "user" json
);

--
-- ACTION CREATE TABLE
--
CREATE TABLE "ticket_category_info" (
    "id" bigserial PRIMARY KEY,
    "categoryName" text NOT NULL,
    "isVisible" boolean NOT NULL,
    "ticketCount" bigint NOT NULL,
    "tickets" json NOT NULL
);


--
-- MIGRATION VERSION FOR test_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('test_server', '20250607222154803', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250607222154803', "timestamp" = now();

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
