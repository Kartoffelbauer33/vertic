-- 🚨 NOTFALL-REPARATUREN - Vertic System
--
-- Verwende diese Scripte nur bei kritischen Problemen
-- Führe IMMER CURRENT_SYSTEM_STATUS.sql ZUERST aus zur Diagnose
-- ========================================================================

-- 🔐 FIX 1: Superuser Password Reset auf "super123"
-- Verwende nur wenn Login nicht funktioniert
DO $$
BEGIN
    -- Update BCrypt Hash für super123 (userInfoId = 4)
    UPDATE serverpod_email_auth 
    SET hash = '$2a$10$UqNRhyZZIb8uYrHzhgwjPOK/2wR70uyi7AR7lwBeEkEVJoSdQfQHG'
    WHERE "userId" = 4 AND email = 'superuser@staff.vertic.local';
    
    RAISE NOTICE '✅ Superuser Password auf "super123" zurückgesetzt';
END $$;

-- 🎭 FIX 2: Deaktiviere verwirrende "Super Administrator" Rolle
-- Verwende nur wenn Duplikat-Superuser-Optionen im UI erscheinen
DO $$
BEGIN
    UPDATE roles 
    SET "isActive" = false, "updatedAt" = NOW()
    WHERE id = 27 AND name = 'super_admin';
    
    RAISE NOTICE '✅ Super Administrator Rolle deaktiviert';
END $$;

-- 🔗 FIX 3: Repariere Staff-User Serverpod-Auth Verknüpfung
-- Verwende nur wenn userInfoId fehlt oder falsch ist
DO $$
DECLARE
    staff_id INT;
    user_info_id INT;
BEGIN
    -- Finde Superuser
    SELECT id INTO staff_id FROM staff_users WHERE "employeeId" = 'superuser';
    
    -- Finde passende serverpod_user_info
    SELECT id INTO user_info_id FROM serverpod_user_info WHERE email = 'superuser@staff.vertic.local';
    
    -- Update Verknüpfung
    UPDATE staff_users 
    SET "userInfoId" = user_info_id
    WHERE id = staff_id;
    
    RAISE NOTICE '✅ Staff-User Auth-Verknüpfung repariert: staff_id=%, userInfoId=%', staff_id, user_info_id;
END $$;

-- 📋 DIAGNOSE: Nach jeder Reparatur ausführen
SELECT 
    '=== POST-REPAIR CHECK ===' as status,
    su."employeeId",
    CASE WHEN ea."userId" IS NOT NULL THEN '✅ Auth OK' ELSE '❌ Auth defekt' END as auth_status,
    CASE WHEN su."staffLevel" = 1 THEN '✅ Superuser' ELSE '⚠️ Nicht Superuser' END as level_status
FROM staff_users su
LEFT JOIN serverpod_user_info ui ON su."userInfoId" = ui.id  
LEFT JOIN serverpod_email_auth ea ON ea."userId" = ui.id
WHERE su."employeeId" = 'superuser';