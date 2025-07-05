-- Repair Migration: Close all active sessions before adding required deviceId field
-- Datum: 2025-07-05
-- Grund: deviceId-Feld wird als required hinzugefügt, bestehende Sessions haben keine deviceId

-- Alle aktiven POS-Sessions schließen
UPDATE pos_sessions 
SET 
    status = 'completed',
    completedAt = NOW()
WHERE 
    status = 'active' 
    AND completedAt IS NULL;

-- Bestätigung der Änderungen
SELECT 
    COUNT(*) as completed_sessions,
    'Sessions erfolgreich geschlossen' as message
FROM pos_sessions 
WHERE status = 'completed' 
    AND completedAt >= NOW() - INTERVAL '1 minute'; 