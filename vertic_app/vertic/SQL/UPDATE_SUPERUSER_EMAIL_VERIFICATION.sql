-- =====================================================
-- UPDATE SUPERUSER FÜR E-MAIL-VERIFICATION SYSTEM
-- =====================================================
-- 
-- Dieses Script aktualisiert den bestehenden Superuser
-- für das neue E-Mail-Bestätigungssystem
--

-- 1. Superuser auf "aktiv" und "E-Mail bestätigt" setzen
UPDATE staff_users 
SET 
    employment_status = 'active',
    email_verified_at = NOW()
WHERE 
    employee_id = 'superuser'
    AND email = 'superuser@staff.vertic.local';

-- 2. Bestätigung der Änderung
SELECT 
    id,
    first_name,
    last_name,
    email,
    employee_id,
    employment_status,
    email_verified_at,
    created_at
FROM staff_users 
WHERE employee_id = 'superuser';

-- =====================================================
-- HINWEIS:
-- =====================================================
-- Der Superuser wurde für das neue E-Mail-System aktualisiert:
-- - employment_status: 'active' (kann sich anmelden)
-- - email_verified_at: NOW() (E-Mail als bestätigt markiert)
-- 
-- Neue Staff-User benötigen E-Mail-Bestätigung, aber der
-- bestehende Superuser bleibt voll funktionsfähig.
-- ===================================================== 