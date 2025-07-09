-- ═══════════════════════════════════════════════════════════════════════════════
-- 🚫 CRITICAL BUGFIX: Cleanup doppelter AppUser mit derselben E-Mail
-- ═══════════════════════════════════════════════════════════════════════════════
-- 
-- PROBLEM: onUserCreated Callback + completeClientRegistration erstellten 
-- doppelte AppUser für dieselbe E-Mail:
-- - User 31: "Guntram" (OHNE userInfoId) ← ZU LÖSCHEN
-- - User 32: "Guntram Schedler" (MIT userInfoId) ← BEHALTEN
--
-- GEFAHR: Unique-Constraint wurde durch Race Condition umgangen!
-- ═══════════════════════════════════════════════════════════════════════════════

BEGIN;

-- 1. ANALYSE: Finde alle doppelten E-Mail-Adressen
SELECT 
    email, 
    COUNT(*) as duplicate_count,
    STRING_AGG(id::text, ', ') as user_ids,
    STRING_AGG(CASE WHEN "userInfoId" IS NULL THEN 'NO_USER_INFO' ELSE "userInfoId"::text END, ', ') as user_info_ids
FROM app_users 
WHERE email IS NOT NULL
GROUP BY email 
HAVING COUNT(*) > 1;

-- 2. SPEZIFISCHER FALL: guntram@test.at
SELECT 
    id, 
    "firstName", 
    "lastName", 
    email, 
    "userInfoId",
    "createdAt",
    CASE 
        WHEN "userInfoId" IS NULL THEN 'LEGACY (onUserCreated)'
        ELSE 'PROPER (completeClientRegistration)'
    END as source_type
FROM app_users 
WHERE email = 'guntram@test.at'
ORDER BY id;

-- 3. VORSICHTIGE BEREINIGUNG: Lösche nur User OHNE userInfoId
-- (Das sind die vom fehlerhaften onUserCreated Callback erstellten)

-- 3a. Erst prüfen was gelöscht würde:
SELECT 
    id, 
    "firstName", 
    "lastName", 
    email, 
    "userInfoId",
    'WILL BE DELETED' as action
FROM app_users 
WHERE email = 'guntram@test.at' 
AND "userInfoId" IS NULL;

-- 3b. Lösche betroffene UserIdentities (falls vorhanden)
DELETE FROM user_identities 
WHERE "userId" IN (
    SELECT id FROM app_users 
    WHERE email = 'guntram@test.at' 
    AND "userInfoId" IS NULL
);

-- 3c. Lösche den doppelten AppUser
DELETE FROM app_users 
WHERE email = 'guntram@test.at' 
AND "userInfoId" IS NULL;

-- 4. VERIFIKATION: Prüfe dass nur noch einer übrig ist
SELECT 
    id, 
    "firstName", 
    "lastName", 
    email, 
    "userInfoId",
    'REMAINING' as status
FROM app_users 
WHERE email = 'guntram@test.at';

-- 5. ALLGEMEINE BEREINIGUNG: Alle anderen doppelten E-Mails ohne userInfoId
-- (Nur ausführen wenn sicher, dass keine wichtigen Daten verloren gehen)

/*
-- WARNUNG: Nur ausführen nach manueller Überprüfung!
DELETE FROM user_identities 
WHERE "userId" IN (
    SELECT DISTINCT a1.id 
    FROM app_users a1 
    JOIN app_users a2 ON a1.email = a2.email AND a1.id != a2.id
    WHERE a1."userInfoId" IS NULL 
    AND a2."userInfoId" IS NOT NULL
);

DELETE FROM app_users 
WHERE id IN (
    SELECT DISTINCT a1.id 
    FROM app_users a1 
    JOIN app_users a2 ON a1.email = a2.email AND a1.id != a2.id
    WHERE a1."userInfoId" IS NULL 
    AND a2."userInfoId" IS NOT NULL
);
*/

-- 6. BESTÄTIGUNG: Zeige alle übrigen User mit Duplikat-Check
SELECT 
    email, 
    COUNT(*) as count,
    STRING_AGG(id::text, ', ') as remaining_ids
FROM app_users 
WHERE email IS NOT NULL
GROUP BY email 
ORDER BY count DESC, email;

COMMIT;

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🛡️ SICHERHEIT: Nach diesem Script sollten:
-- 1. Keine doppelten E-Mail-Adressen mehr existieren
-- 2. Der onUserCreated Callback ist deaktiviert (server.dart)
-- 3. completeClientRegistration prüft auf E-Mail-Duplikate
-- ═══════════════════════════════════════════════════════════════════════════════ 