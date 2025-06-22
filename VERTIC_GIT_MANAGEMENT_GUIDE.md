# 🚀 VERTIC GIT MANAGEMENT GUIDE

**Vollständige Git-Verwaltung für das Vertic-Projekt**  
*Sicheres Repository-Management mit Force-Push-Strategien*

---

## 📋 ÜBERSICHT

Dieses Dokument erklärt die **komplette Git-Verwaltung** für das Vertic-Projekt, mit besonderem Fokus auf:
- **Sichere Force-Push-Strategien**
- **Korrekte Terminal-Pfade**
- **Repository-Überschreibung ohne Pull**
- **Sicherheitsrichtlinien**

---

## 🗂️ REPOSITORY STRUKTUR

### **HAUPTVERZEICHNIS**
```
Leon_vertic/                           # 📁 Repository-Root (GIT-ROOT)
├── .git/                             # 🔧 Git-Metadaten
├── .gitignore                        # 🚫 Ignorierte Dateien
├── VERTIC_*.md                       # 📚 Dokumentation
├── archive/                          # 📦 Archivierte Dateien
├── pubspec.yaml                      # 📄 Flutter-Workspace
└── vertic_app/                       # 🏗️ Hauptanwendung
    └── vertic/
        ├── SQL/                      # 🗄️ Datenbank-Scripts
        ├── vertic_project/           # 📱 Flutter Apps
        │   ├── vertic_client_app/    # 👤 Kunden-App
        │   └── vertic_staff_app/     # 👨‍💼 Personal-App
        └── vertic_server/            # 🖥️ Backend-Server
```

### **WICHTIGE GIT-PFADE**
- **Repository-Root:** `C:\Users\guntr\Desktop\Leon_vertic\`
- **Git-Befehle ausführen:** Immer vom Repository-Root!
- **Niemals Git-Befehle aus Unterverzeichnissen!**

---

## 🖥️ TERMINAL ÖFFNEN - KORREKTE PFADE

### **WINDOWS POWERSHELL**

#### **Methode 1: Direkt in Verzeichnis navigieren**
```powershell
# Terminal öffnen (Windows + X → PowerShell)
cd C:\Users\guntr\Desktop\Leon_vertic

# Prüfen ob im Git-Repository
git status
```

#### **Methode 2: Aus VS Code**
```powershell
# VS Code öffnen im Repository-Root
code C:\Users\guntr\Desktop\Leon_vertic

# Terminal in VS Code: Strg + Shift + `
# Automatisch im korrekten Pfad
```

#### **Methode 3: Aus Datei-Explorer**
```powershell
# Im Windows Explorer zu Leon_vertic navigieren
# Rechtsklick → "In Terminal öffnen"
# Oder Adresszeile: cmd / powershell eingeben
```

### **PFAD VERIFIZIERUNG**
```powershell
# Aktueller Pfad anzeigen
pwd
# Sollte zeigen: C:\Users\guntr\Desktop\Leon_vertic

# Git-Status prüfen
git status
# Sollte Repository-Status zeigen, nicht "not a git repository"

# Repository-Root finden
git rev-parse --show-toplevel
```

---

## 🚨 FORCE-PUSH STRATEGIEN

### **WARUM FORCE-PUSH?**
- **Lokale Entwicklung überschreibt Server**
- **Keine Merge-Konflikte durch Pull**
- **Saubere Git-History**
- **Sicherheit vor ungewollten Änderungen**

### **SICHERE FORCE-PUSH BEFEHLE**

#### **1. STANDARD FORCE-PUSH**
```powershell
# Vom Repository-Root (Leon_vertic/)
git add .
git commit -m "feat: Beschreibung der Änderungen"
git push origin main --force
```

#### **2. FORCE-PUSH MIT LEASE (SICHERER)**
```powershell
# Sicherer Force-Push (prüft ob Remote geändert wurde)
git push origin main --force-with-lease
```

#### **3. KOMPLETTE REPOSITORY-ÜBERSCHREIBUNG**
```powershell
# Wenn du das komplette Remote-Repository überschreiben willst
git push origin main --force --no-verify
```

#### **4. BRANCH KOMPLETT ERSETZEN**
```powershell
# Remote-Branch löschen und neu erstellen
git push origin :main                    # Remote-Branch löschen
git push origin main                     # Neuen Branch pushen
```

---

## 🔒 SICHERHEITSRICHTLINIEN

### **⚠️ KRITISCHE REGELN**

#### **1. NIEMALS PASSWÖRTER COMMITTEN**
```powershell
# VOR JEDEM COMMIT PRÜFEN:
git diff --cached | grep -i password
git diff --cached | grep -i secret
git diff --cached | grep -i key

# .gitignore erweitern
echo ".env" >> .gitignore
echo "*.key" >> .gitignore
echo "config/secrets.yaml" >> .gitignore
```

#### **2. SENSITIVE DATEIEN ENTFERNEN**
```powershell
# Datei aus Git-History entfernen (GEFÄHRLICH!)
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch pfad/zur/datei' --prune-empty --tag-name-filter cat -- --all

# Sicherer: Nur aus aktuellem Commit entfernen
git rm --cached pfad/zur/datei
git commit -m "Remove sensitive file"
```

#### **3. FORCE-PUSH SICHERHEITSCHECK**
```powershell
# Vor Force-Push: Prüfen was gepusht wird
git log --oneline origin/main..HEAD
git diff origin/main..HEAD

# Nur force-pushen wenn sicher!
git push origin main --force-with-lease
```

---

## 📝 STANDARD WORKFLOWS

### **WORKFLOW 1: NORMALE ENTWICKLUNG**
```powershell
# 1. Terminal im Repository-Root öffnen
cd C:\Users\guntr\Desktop\Leon_vertic

# 2. Aktuelle Änderungen anzeigen
git status
git diff

# 3. Dateien hinzufügen
git add .
# Oder spezifische Dateien:
git add vertic_app/vertic/vertic_server/

# 4. Commit erstellen
git commit -m "feat: Neue Funktionalität hinzugefügt"

# 5. Force-Push (überschreibt Remote)
git push origin main --force-with-lease
```

### **WORKFLOW 2: NACH GRÖSSEREN ÄNDERUNGEN**
```powershell
# 1. Alle Änderungen prüfen
git status
git log --oneline -10

# 2. Sensitive Daten prüfen
git diff --cached | findstr /i "password secret key"

# 3. Commit mit detaillierter Nachricht
git add .
git commit -m "feat: Überarbeitung der Authentifikation

- RBAC-System auf 53 Permissions erweitert
- Superuser-Erstellung automatisiert
- Staff-App Permissions-Handling verbessert
- Client-App E-Mail-Verification-Bypass hinzugefügt"

# 4. Force-Push
git push origin main --force
```

### **WORKFLOW 3: NOTFALL-REPOSITORY-RESET**
```powershell
# Wenn das Remote-Repository komplett überschrieben werden soll
# VORSICHT: Löscht alle Remote-Änderungen!

# 1. Lokalen Status prüfen
git status
git log --oneline -5

# 2. Remote-Branch komplett ersetzen
git push origin main --force --no-verify

# 3. Oder Remote-Branch löschen und neu erstellen
git push origin :main
git push origin main
```

---

## 🔍 GIT STATUS & DEBUGGING

### **REPOSITORY-STATUS PRÜFEN**
```powershell
# Detaillierter Status
git status --porcelain
git status --short

# Änderungen anzeigen
git diff                    # Unstaged changes
git diff --cached          # Staged changes
git diff HEAD              # Alle Änderungen

# Commit-History
git log --oneline -10
git log --graph --oneline -10
```

### **REMOTE-REPOSITORY PRÜFEN**
```powershell
# Remote-URLs anzeigen
git remote -v

# Remote-Branch Status
git branch -r
git branch -a

# Unterschiede zu Remote
git log --oneline origin/main..HEAD    # Lokale Commits
git log --oneline HEAD..origin/main    # Remote Commits
```

### **GIT PROBLEME LÖSEN**
```powershell
# Git-Repository reparieren
git fsck
git gc

# Merge-Konflikte vermeiden (Force-Push)
git reset --hard HEAD
git clean -fd
git push origin main --force

# Repository-Status zurücksetzen
git reset --hard origin/main
```

---

## 🚀 DEPLOYMENT-INTEGRATION

### **LOKALE ENTWICKLUNG → SERVER DEPLOYMENT**
```powershell
# 1. Lokale Änderungen committen und pushen
cd C:\Users\guntr\Desktop\Leon_vertic
git add .
git commit -m "feat: Server-Updates"
git push origin main --force

# 2. Auf Server deployen (separates Terminal/SSH)
# ssh root@159.69.144.208
# cd /opt/vertic
# git pull origin main
# cd vertic_app/vertic/vertic_server/vertic_server_server
# serverpod generate
# docker-compose -f docker-compose.staging.yaml up -d --build
```

### **DEPLOYMENT-SCRIPT ERSTELLEN**
```powershell
# deploy.ps1 im Repository-Root erstellen
@"
# Vertic Deployment Script
Write-Host "🚀 Vertic Deployment gestartet..." -ForegroundColor Green

# Git Push
Write-Host "📤 Pushing to Git..." -ForegroundColor Yellow
git add .
git status
$commitMsg = Read-Host "Commit Message"
git commit -m "$commitMsg"
git push origin main --force-with-lease

Write-Host "✅ Deployment abgeschlossen!" -ForegroundColor Green
Write-Host "🔗 Nächster Schritt: SSH zum Server für Docker-Deployment" -ForegroundColor Cyan
"@ | Out-File -FilePath deploy.ps1 -Encoding UTF8

# Script ausführen
.\deploy.ps1
```

---

## 📊 BRANCH-MANAGEMENT

### **BRANCH-STRATEGIEN**
```powershell
# Aktueller Branch
git branch
git branch -a

# Neuen Branch erstellen (optional)
git checkout -b feature/neue-funktion
git push origin feature/neue-funktion

# Zurück zu main
git checkout main
git push origin main --force
```

### **BRANCH CLEANUP**
```powershell
# Lokale Branches löschen
git branch -d feature/alte-funktion

# Remote-Branches löschen
git push origin --delete feature/alte-funktion

# Alle merged Branches löschen
git branch --merged | grep -v main | xargs git branch -d
```

---

## 🔧 ADVANCED GIT TRICKS

### **COMMIT-HISTORY BEREINIGEN**
```powershell
# Letzten Commit ändern
git commit --amend -m "Neue Commit-Nachricht"
git push origin main --force

# Mehrere Commits zusammenfassen (Interactive Rebase)
git rebase -i HEAD~3
# Dann "squash" für Commits die zusammengefasst werden sollen
git push origin main --force
```

### **DATEI-SPEZIFISCHE OPERATIONEN**
```powershell
# Nur bestimmte Dateien committen
git add vertic_app/vertic/vertic_server/
git commit -m "feat: Nur Server-Änderungen"

# Datei aus Git entfernen (aber lokal behalten)
git rm --cached datei.txt
git commit -m "Remove file from Git"

# Datei komplett löschen
git rm datei.txt
git commit -m "Delete file"
```

### **STASH-MANAGEMENT**
```powershell
# Änderungen temporär speichern
git stash push -m "WIP: Zwischenspeichern"
git stash list
git stash pop
```

---

## 🚨 NOTFALL-PROCEDURES

### **REPOSITORY KOMPLETT ZURÜCKSETZEN**
```powershell
# VORSICHT: Löscht alle lokalen Änderungen!
git reset --hard HEAD
git clean -fd

# Repository auf Remote-Stand zurücksetzen
git reset --hard origin/main
```

### **FORCE-PUSH RÜCKGÄNGIG MACHEN**
```powershell
# Wenn Force-Push schief gelaufen ist
git reflog                    # Commit-History anzeigen
git reset --hard HEAD@{1}     # Zu vorherigem Zustand zurück
git push origin main --force  # Korrektur pushen
```

### **REPOSITORY NEU KLONEN**
```powershell
# Als letzter Ausweg: Repository neu klonen
cd C:\Users\guntr\Desktop\
git clone https://github.com/Kartoffelbauer33/vertic.git Leon_vertic_backup
# Dann lokale Änderungen manuell übertragen
```

---

## 📞 QUICK REFERENCE

### **HÄUFIGSTE BEFEHLE**
```powershell
# Repository-Root
cd C:\Users\guntr\Desktop\Leon_vertic

# Standard-Workflow
git status
git add .
git commit -m "feat: Beschreibung"
git push origin main --force-with-lease

# Sicherheitscheck
git diff --cached | findstr /i "password"
git log --oneline -5

# Notfall-Reset
git reset --hard HEAD
git clean -fd
```

### **TERMINAL-SHORTCUTS**
```powershell
# PowerShell-Shortcuts
cd C:\Users\guntr\Desktop\Leon_vertic  # Repository-Root
pwd                                    # Aktueller Pfad
ls                                     # Dateien anzeigen
cls                                    # Terminal leeren
```

### **WICHTIGE PFADE**
- **Repository-Root:** `C:\Users\guntr\Desktop\Leon_vertic\`
- **Git-Befehle:** Immer vom Repository-Root ausführen!
- **VS Code:** `code .` vom Repository-Root

---

## 🎯 KRITISCHE ERINNERUNGEN

### ⚠️ **NIEMALS VERGESSEN:**
1. **Immer vom Repository-Root** (`Leon_vertic/`) Git-Befehle ausführen
2. **Force-Push überschreibt Remote** - keine Rückfrage!
3. **Niemals Passwörter committen** - vor jedem Commit prüfen
4. **`--force-with-lease` ist sicherer** als `--force`
5. **Git-Status vor jedem Commit** prüfen

### ✅ **BEWÄHRTE PRAKTIKEN:**
1. **Regelmäßige Commits** mit aussagekräftigen Nachrichten
2. **Force-Push nur bei Sicherheit** verwenden
3. **Sensitive Daten in .gitignore** aufnehmen
4. **Repository-Status regelmäßig prüfen**
5. **Bei Unsicherheit: Backup erstellen**

---

**🚀 MIT DIESEM GUIDE HAST DU:**
- ✅ **Vollständige Kontrolle** über das Git-Repository
- ✅ **Sichere Force-Push-Strategien** ohne Datenverlust
- ✅ **Klare Terminal-Befehle** für alle Situationen
- ✅ **Sicherheitsrichtlinien** für sensible Daten
- ✅ **Notfall-Procedures** für kritische Situationen

**🔒 SICHERHEIT GEHT VOR - FORCE-PUSH MIT BEDACHT!** 