BEGIN;

-- Add missing columns to external_providers table
ALTER TABLE "external_providers" 
ADD COLUMN IF NOT EXISTS "reEntryWindowType" text NOT NULL DEFAULT 'hours',
ADD COLUMN IF NOT EXISTS "reEntryWindowDays" bigint NOT NULL DEFAULT 1;

-- Make apiCredentialsJson nullable for Friction compatibility
ALTER TABLE "external_providers" 
ALTER COLUMN "apiCredentialsJson" DROP NOT NULL;

-- Add missing columns to app_users table  
ALTER TABLE "app_users"
ADD COLUMN IF NOT EXISTS "preferredHallId" bigint,
ADD COLUMN IF NOT EXISTS "lastKnownHallId" bigint,
ADD COLUMN IF NOT EXISTS "registrationHallId" bigint;

-- Add foreign key constraints if not exist
DO $$
BEGIN
    -- Add FK for preferredHallId if constraint doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'app_users_preferredHallId_fkey'
    ) THEN
        ALTER TABLE "app_users" ADD CONSTRAINT "app_users_preferredHallId_fkey" 
        FOREIGN KEY ("preferredHallId") REFERENCES "gyms"("id");
    END IF;

    -- Add FK for lastKnownHallId if constraint doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'app_users_lastKnownHallId_fkey'
    ) THEN
        ALTER TABLE "app_users" ADD CONSTRAINT "app_users_lastKnownHallId_fkey" 
        FOREIGN KEY ("lastKnownHallId") REFERENCES "gyms"("id");
    END IF;

    -- Add FK for registrationHallId if constraint doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'app_users_registrationHallId_fkey'
    ) THEN
        ALTER TABLE "app_users" ADD CONSTRAINT "app_users_registrationHallId_fkey" 
        FOREIGN KEY ("registrationHallId") REFERENCES "gyms"("id");
    END IF;
END$$;

-- Create indexes for the new columns if they don't exist
CREATE INDEX IF NOT EXISTS "app_user_preferred_hall_idx" ON "app_users" USING btree ("preferredHallId");
CREATE INDEX IF NOT EXISTS "app_user_last_known_hall_idx" ON "app_users" USING btree ("lastKnownHallId");
CREATE INDEX IF NOT EXISTS "app_user_registration_hall_idx" ON "app_users" USING btree ("registrationHallId");

-- Add External Provider permissions if they don't exist
INSERT INTO "permissions" (name, description, category, created_at) VALUES
('can_validate_external_providers', 'Externe Provider QR-Codes scannen und validieren', 'external_providers', NOW()),
('can_manage_external_providers', 'Externe Provider konfigurieren und verwalten', 'external_providers', NOW()),
('can_view_provider_stats', 'Provider-Statistiken und Analytics anzeigen', 'external_providers', NOW())
ON CONFLICT (name) DO NOTHING;

-- Assign permissions to roles
-- Staff role gets validation permission
INSERT INTO "role_permissions" (role_id, permission_id, created_at)
SELECT 
    r.id as role_id,
    p.id as permission_id,
    NOW() as created_at
FROM "roles" r, "permissions" p 
WHERE r.name = 'staff' 
  AND p.name = 'can_validate_external_providers'
  AND NOT EXISTS (
    SELECT 1 FROM "role_permissions" rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Hall admin gets all external provider permissions
INSERT INTO "role_permissions" (role_id, permission_id, created_at)
SELECT 
    r.id as role_id,
    p.id as permission_id,
    NOW() as created_at
FROM "roles" r, "permissions" p 
WHERE r.name = 'hall_admin' 
  AND p.name IN ('can_validate_external_providers', 'can_manage_external_providers', 'can_view_provider_stats')
  AND NOT EXISTS (
    SELECT 1 FROM "role_permissions" rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

-- Superuser gets all external provider permissions
INSERT INTO "role_permissions" (role_id, permission_id, created_at)
SELECT 
    r.id as role_id,
    p.id as permission_id,
    NOW() as created_at
FROM "roles" r, "permissions" p 
WHERE r.name = 'superuser' 
  AND p.name IN ('can_validate_external_providers', 'can_manage_external_providers', 'can_view_provider_stats')
  AND NOT EXISTS (
    SELECT 1 FROM "role_permissions" rp 
    WHERE rp.role_id = r.id AND rp.permission_id = p.id
  );

--
-- MIGRATION VERSION FOR vertic_server
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('vertic_server', '20250623172157940-manual-schema-fix', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250623172157940-manual-schema-fix', "timestamp" = now();

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
    DO UPDATE SET "version" = '20240516151843329', "timestamp" = now();


COMMIT;
