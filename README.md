# 🎮 NemesusTV FiveM Docker Paket 🎮

Ein vollständiger FiveM Gameserver mit txAdmin, MariaDB und phpMyAdmin – alles in Docker.

Homepage: https://nemesus.de

Youtube: https://yt.nemesus.de

Forum: https://forum.nemesus.de

Discord: https://discord.nemesus.de

☕ Ihr wollt uns unterstützen? https://ko-fi.com/nemesustv ☕

---

## 📋 Voraussetzungen

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac/Linux)
- [VS Code](https://code.visualstudio.com/) *(optional, für einfache Bearbeitung)*
- FiveM License Key → [keymaster.fivem.net](https://keymaster.fivem.net)

---

## 📁 Projektstruktur

```
fivem-docker/
├── fivem/
│   ├── Dockerfile
│   └── startup.sh
├── docker-compose.yml
├── .env
└── README.md
```

---

## ⚙️ Einrichtung

### 1. `.env` Datei erstellen

Erstelle eine `.env` Datei im Hauptverzeichnis (neben `docker-compose.yml`):

```env
# FiveM
LICENSE_KEY=dein_license_key_hier
SERVER_NAME=Mein FiveM Server

# MariaDB
MYSQL_ROOT_PASSWORD=sicheresPasswort
MYSQL_DATABASE=fivem
MYSQL_USER=fivem
MYSQL_PASSWORD=fivemPasswort
```

> ⚠️ **Niemals** die `.env` Datei in Git committen! Füge `.env` zu deiner `.gitignore` hinzu.

### 2. Server starten

```cmd
docker compose up --build
```

Beim ersten Start wird automatisch:
- Die neueste FiveM Artifact Version heruntergeladen
- Das cfx-server-data Repository geklont
- Die txAdmin Konfiguration erstellt

---

## 🔑 txAdmin einrichten

### PIN ermitteln

Nach dem Start erscheint in den Logs ein Setup-Link mit PIN:

```
[tx] Use this link to configure txAdmin:
[tx] > http://localhost:40120/auth?pin=1234
```

**Logs beobachten (Windows):**
```cmd
docker compose logs -f fivem | findstr /i "pin txadmin http"
```

Oder alle Logs:
```cmd
docker compose logs -f fivem
```

### txAdmin öffnen

Browser öffnen: **http://localhost:40120**

PIN eingeben → Account erstellen → fertig! ✅

---

## 🗄️ Datenbank Verbindungsdaten

Wenn txAdmin nach Datenbankdaten fragt (z.B. bei ESX/QBCore Installation):

| Feld | Wert |
|------|------|
| **Database Host** | `mariadb` |
| **Database Port** | `3306` |
| **Database Username** | `root` |
| **Database Password** | Dein `MYSQL_ROOT_PASSWORD` aus `.env` |
| **Database Name** | frei wählbar, z.B. `fivem` |

> ℹ️ Der Host ist `mariadb` (nicht `localhost`), da die Datenbank in einem eigenen Container läuft.

### phpMyAdmin

Datenbank-Verwaltung im Browser: **http://localhost:8080**

- **Server:** mariadb
- **Benutzer:** root
- **Passwort:** Dein `MYSQL_ROOT_PASSWORD`

---

## 📂 Ressourcen & server.cfg bearbeiten

Du hast zwei Möglichkeiten:

---

### Option A: VS Code mit Dev Containers *(empfohlen)*

1. **Extension installieren:**
   - VS Code öffnen
   - `Strg+Shift+X` → Suche: `Dev Containers` (von Microsoft) → Installieren

2. **Mit Container verbinden:**
   - Links unten auf das grüne **`><`** Symbol klicken
   - `Attach to Running Container...` wählen
   - `fivem-server` auswählen

3. **Ordner öffnen:**
   - `File` → `Open Folder`
   - Pfad eingeben: `/opt/fivem/server-data`
   - `OK` klicken

4. **Fertig!** Du siehst jetzt im Explorer:
   ```
   server-data/
   ├── resources/       ← Ressourcen hier reinkopieren
   └── server.cfg       ← Direkt bearbeiten
   ```

---

### Option B: Bind Mount (Ordner lokal auf Windows)

In `docker-compose.yml` das Volume für server-data ersetzen:

```yaml
volumes:
  - ./server-data:/opt/fivem/server-data   # ← lokaler Ordner
  - fivem_artifacts:/opt/fivem/server
  - fivem_txdata:/opt/fivem/txData
```

Dann liegt der `server-data` Ordner direkt neben deiner `docker-compose.yml` und du kannst ihn normal in VS Code öffnen – ohne Extension.

> ⚠️ Beim ersten Start muss der `server-data` Ordner leer sein, damit das Git-Repo geklont werden kann.

---

### Option C: Kommandozeile

**Ressource reinkopieren:**
```cmd
docker cp C:\pfad\zu\ressource fivem-server:/opt/fivem/server-data/resources/ressourcen-name
```

**server.cfg direkt bearbeiten:**
```cmd
docker exec -it fivem-server bash
nano /opt/fivem/server-data/server.cfg
```

---

## 📦 Ressource installieren (Beispiel)

1. Ressource herunterladen und entpacken (z.B. `es_extended`)
2. In den `resources` Ordner kopieren (via VS Code oder `docker cp`)
3. In `server.cfg` eintragen:
   ```
   ensure es_extended
   ```
4. In txAdmin: **Server neu starten**

---

## 🔄 Nützliche Docker Befehle

```cmd
# Server starten
docker compose up -d

# Server stoppen
docker compose down

# Logs anzeigen
docker compose logs -f fivem

# Server neu bauen (nach Änderungen an Dockerfile/startup.sh)
docker compose up --build

# In Container einloggen
docker exec -it fivem-server bash

# Alle Volumes löschen (ACHTUNG: löscht alle Daten!)
docker compose down -v
```

---

## 🔁 Auto-Update

Der Server lädt beim Start automatisch die neueste empfohlene FiveM Artifact Version herunter. Bereits installierte Versionen werden nicht neu heruntergeladen.

---

## 🌐 Ports

| Port | Dienst |
|------|--------|
| `30120` (TCP+UDP) | FiveM Spielserver |
| `40120` (TCP) | txAdmin Weboberfläche |
| `3306` (TCP) | MariaDB Datenbank |
| `8080` (TCP) | phpMyAdmin |

---

## ❓ Troubleshooting

**txAdmin PIN erscheint nicht:**
```cmd
docker compose down -v
docker compose up --build
```

**Port bereits belegt:**
In `docker-compose.yml` den linken Port ändern, z.B. `"40121:40120"`.

**Container startet nicht:**
```cmd
docker compose logs fivem
```
Fehlermeldung aus den Logs hier nachschlagen.

**Ressource wird nicht geladen:**
Sicherstellen dass in `server.cfg` `ensure ressourcen-name` eingetragen ist und der Ordnername exakt übereinstimmt.