-- =====================================================
-- FIND & FIX INVALID STAFF LEVEL VALUES
-- Findet und korrigiert alle Staff-User mit ungültigen staffLevel Werten
-- ✅ UMFASSENDES REPARATUR-TOOL FÜR STAFFUSERTYPE ENUM
-- =====================================================
-- 
-- 🔧 StaffUserType Enum Werte:
-- 0 = staff
-- 1 = hallAdmin  
-- 2 = facilityAdmin
-- 3 = superUser
-- 
-- ❌ Alle anderen Werte (99, NULL, etc.) sind ungültig!
-- =====================================================

-- 1. Alle Staff-User anzeigen
SELECT 
    '👥 ALL STAFF USERS' as info,
    id,
    "firstName",
    "lastName", 
    email,
    "employeeId",
    "staffLevel",
    "employmentStatus",
    "userInfoId",
    CASE 
        WHEN "staffLevel" IN (0,1,2,3) THEN '✅ Gültig'
        ELSE '❌ UNGÜLTIG'
    END as level_status
FROM staff_users 
ORDER BY id;

-- 2. Finde Staff-User mit ungültigen staffLevel (nicht 0,1,2,3)
SELECT 
    '❌ INVALID STAFF LEVELS' as info,
    id,
    "firstName",
    "lastName", 
    email,
    "employeeId",
    "staffLevel",
    "employmentStatus",
    "userInfoId",
    CASE 
        WHEN "staffLevel" = 99 THEN 'Legacy superUser (99) → sollte 3 sein'
        WHEN "staffLevel" IS NULL THEN 'NULL Wert → sollte 0 (staff) sein'
        ELSE 'Unbekannter Wert → sollte 0-3 sein'
    END as problem_description
FROM staff_users 
WHERE "staffLevel" NOT IN (0, 1, 2, 3)
ORDER BY id;

-- 3. Statistik der ungültigen Werte
SELECT 
    '📊 INVALID VALUES STATISTICS' as info,
    "staffLevel",
    COUNT(*) as count,
    CASE 
        WHEN "staffLevel" = 99 THEN 'Legacy superUser → Fix: 3'
        WHEN "staffLevel" IS NULL THEN 'NULL → Fix: 0'
        ELSE 'Unbekannt → Fix: 0'
    END as recommended_fix
FROM staff_users 
WHERE "staffLevel" NOT IN (0, 1, 2, 3)
GROUP BY "staffLevel"
ORDER BY count DESC;

-- 4. KORREKTUR: Alle ungültigen staffLevel reparieren
-- Spezielle Behandlung für verschiedene Fälle:

-- 4a. Legacy superUser (99) → superUser (3)
UPDATE staff_users 
SET "staffLevel" = 3
WHERE "staffLevel" = 99;

-- 4b. NULL Werte → staff (0)
UPDATE staff_users 
SET "staffLevel" = 0
WHERE "staffLevel" IS NULL;

-- 4c. Alle anderen ungültigen Werte → staff (0)
UPDATE staff_users 
SET "staffLevel" = 0
WHERE "staffLevel" NOT IN (0, 1, 2, 3);

-- 5. Prüfe das Ergebnis nach Korrektur
SELECT 
    '✅ AFTER CORRECTION' as info,
    id,
    "firstName",
    "lastName", 
    email,
    "employeeId",
    "staffLevel",
    CASE 
        WHEN "staffLevel" = 0 THEN 'staff'
        WHEN "staffLevel" = 1 THEN 'hallAdmin'
        WHEN "staffLevel" = 2 THEN 'facilityAdmin'
        WHEN "staffLevel" = 3 THEN 'superUser'
        ELSE '❌ IMMER NOCH UNGÜLTIG!'
    END as level_name,
    "employmentStatus",
    "userInfoId"
FROM staff_users 
ORDER BY id;

-- 6. Final Verification - sollte keine ungültigen Werte mehr geben
SELECT 
    '🎯 FINAL VERIFICATION' as info,
    COUNT(*) as total_staff_users,
    COUNT(CASE WHEN "staffLevel" IN (0,1,2,3) THEN 1 END) as valid_levels,
    COUNT(CASE WHEN "staffLevel" NOT IN (0,1,2,3) THEN 1 END) as invalid_levels,
    CASE 
        WHEN COUNT(CASE WHEN "staffLevel" NOT IN (0,1,2,3) THEN 1 END) = 0 
        THEN '✅ ALLE STAFF LEVELS SIND JETZT GÜLTIG!'
        ELSE '❌ FEHLER: Immer noch ungültige Werte vorhanden!'
    END as status
FROM staff_users;

-- 7. Zeige Verteilung der korrigierten Werte
SELECT 
    '📈 STAFF LEVEL DISTRIBUTION' as info,
    "staffLevel",
    CASE 
        WHEN "staffLevel" = 0 THEN 'staff'
        WHEN "staffLevel" = 1 THEN 'hallAdmin'
        WHEN "staffLevel" = 2 THEN 'facilityAdmin'
        WHEN "staffLevel" = 3 THEN 'superUser'
        ELSE 'UNGÜLTIG'
    END as level_name,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM staff_users), 2) as percentage
FROM staff_users 
GROUP BY "staffLevel"
ORDER BY "staffLevel"; 