# 🎮 NemesusTV FiveM Docker Paket 🎮

Ein vollständiger FiveM Gameserver mit txAdmin, MariaDB und phpMyAdmin – alles in Docker.

Homepage: [https://nemesus.de](https://nemesus.de)
YouTube: [https://yt.nemesus.de](https://yt.nemesus.de)
Forum: [https://forum.nemesus.de](https://forum.nemesus.de)
Discord: [https://discord.nemesus.de](https://discord.nemesus.de)

☕ Ihr wollt uns unterstützen? [https://ko-fi.com/nemesustv](https://ko-fi.com/nemesustv)

---

## 📋 Voraussetzungen

* [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac/Linux)
* [VS Code](https://code.visualstudio.com/) *(optional, für einfache Bearbeitung)*
* FiveM License Key → [https://keymaster.fivem.net](https://keymaster.fivem.net)

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

```
# FiveM
LICENSE_KEY=dein_license_key_hier
SERVER_NAME=Mein FiveM Server

# MariaDB
MYSQL_ROOT_PASSWORD=sicheresPasswort
MYSQL_DATABASE=fivem
MYSQL_USER=fivem
MYSQL_PASSWORD=fivemPasswort
```

> ⚠️ Niemals die `.env` Datei in Git committen! Füge `.env` zu `.gitignore` hinzu.

---

### 2. Server starten

```
docker compose up --build
```

Beim ersten Start wird automatisch:

* Die neueste FiveM Artifact Version heruntergeladen
* Das cfx-server-data Repository geklont
* Die txAdmin Konfiguration erstellt

---

## 🔑 txAdmin einrichten

### PIN ermitteln

Nach dem Start erscheint in den Logs ein Setup-Link mit PIN:

```
[tx] Use this link to configure txAdmin:
[tx] > http://localhost:40120/auth?pin=1234
```

Logs beobachten (Windows):

```
docker compose logs -f fivem | findstr /i "pin txadmin http"
```

Oder alle Logs:

```
docker compose logs -f fivem
```

---

### txAdmin öffnen

Browser öffnen:

```
http://localhost:40120
```

PIN eingeben → Account erstellen → fertig ✅

---

## 🗄️ Datenbank Verbindungsdaten

Wenn txAdmin nach Datenbankdaten fragt (z.B. bei ESX/QBCore Installation):

| Feld              | Wert                        |
| ----------------- | --------------------------- |
| Database Host     | mariadb                     |
| Database Port     | 3306                        |
| Database Username | root                        |
| Database Password | Dein `MYSQL_ROOT_PASSWORD`  |
| Database Name     | frei wählbar (z.B. `fivem`) |

---

### phpMyAdmin

Datenbankverwaltung im Browser:

```
http://localhost:8080
```

Login:

* Server: `mariadb`
* Benutzer: `root`
* Passwort: Dein `MYSQL_ROOT_PASSWORD`

---

## 📂 Ressourcen & server.cfg bearbeiten

### Option A: VS Code mit Dev Containers (empfohlen)

1. VS Code öffnen
2. `Strg + Shift + X` → Suche: **Dev Containers** (Microsoft) → Installieren
3. Links unten auf **><** klicken → **Attach to Running Container...** → `fivem-server` auswählen
4. Ordner öffnen: `/opt/fivem/server-data`

Ordnerstruktur:

```
server-data/
├── resources/       ← Ressourcen hier reinkopieren
└── server.cfg       ← direkt bearbeiten
```

---

### Option B: Bind Mount (lokaler Ordner)

In `docker-compose.yml`:

```
- ./server-data:/opt/fivem/server-data
```

Der Ordner liegt dann lokal neben der Compose Datei.

> ⚠️ Beim ersten Start muss der Ordner leer sein.

---

### Option C: Kommandozeile

Ressource kopieren:

```
docker cp C:\pfad\zu\ressource fivem-server:/opt/fivem/server-data/resources/
```

Server.cfg bearbeiten:

```
docker exec -it fivem-server bash
nano /opt/fivem/server-data/server.cfg
```

---

## 📦 Ressource installieren (Beispiel)

1. Ressource herunterladen (z.B. `es_extended`)
2. In den `resources` Ordner kopieren
3. In `server.cfg` eintragen:

```
ensure es_extended
```

4. In txAdmin Server neu starten

---

## 🔄 Nützliche Docker Befehle

```
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

| Port            | Dienst                |
| --------------- | --------------------- |
| 30120 (TCP+UDP) | FiveM Spielserver     |
| 40120 (TCP)     | txAdmin Weboberfläche |
| 3306 (TCP)      | MariaDB Datenbank     |
| 8080 (TCP)      | phpMyAdmin            |

---

## 💾 Automatische Backups

Das Setup enthält einen optionalen **Backup-Container**, der automatisch:

* 📂 FiveM Serverdaten (`server-data`)
* ⚙️ txAdmin Daten (`txData`)
* 🗄️ MariaDB Datenbank

sichert.

### Backup Ordner erstellen

Windows Beispiel:

```
C:\fivem-backups
```

Linux Beispiel:

```
/opt/fivem-backups
```

### Backup Container in `docker-compose.yml`

```
backup:
  image: alpine
  container_name: fivem-backup
  depends_on:
    - mariadb
  environment:
    - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
  volumes:
    - fivem_data:/volumes/fivem_data:ro
    - fivem_artifacts:/volumes/fivem_artifacts:ro
    - fivem_txdata:/volumes/fivem_txdata:ro
    - C:/fivem-backups:/backups
  entrypoint: >
    sh -c "
    apk add --no-cache mariadb-client tar;
    while true; do
      DATE=$$(date +%Y-%m-%d_%H-%M);

      echo 'Starting backup...';

      mysqldump -h mariadb -u root -p$$MYSQL_ROOT_PASSWORD --all-databases > /backups/db_$$DATE.sql;

      tar -czf /backups/fivem_server-data_$$DATE.tar.gz /volumes/fivem_data;
      tar -czf /backups/fivem_artifacts_$$DATE.tar.gz /volumes/fivem_artifacts;
      tar -czf /backups/fivem_txdata_$$DATE.tar.gz /volumes/fivem_txdata;

      find /backups -type f -mtime +7 -delete;

      echo 'Backup finished';

      sleep 86400;
    done
    "
  restart: unless-stopped
```

### Backup Zeitplan

* Standard: **alle 24 Stunden** (`sleep 86400`)
* Alle 12 Stunden: `sleep 43200`
* Alle 6 Stunden: `sleep 21600`

### Backup Dateien

Beispiel Windows:

```
C:\fivem-backups
```

Dateien:

```
db_2026-04-03_03-00.sql
fivem_server-data_2026-04-03_03-00.tar.gz
fivem_artifacts_2026-04-03_03-00.tar.gz
fivem_txdata_2026-04-03_03-00.tar.gz
```

### Alte Backups

Backups älter als 7 Tage werden automatisch gelöscht:

```
find /backups -type f -mtime +7 -delete
```

### Restore

**Datenbank wiederherstellen:**

```
docker exec -i fivem-db mysql -u root -p < backup.sql
```

**Serverdaten wiederherstellen:**

```
tar -xzf fivem_server-data_2026-04-03_03-00.tar.gz
```

### Backup Logs anzeigen

```
docker logs -f fivem-backup
```

---

## ❓ Troubleshooting

* **txAdmin PIN erscheint nicht:**

```
docker compose down -v
docker compose up --build
```

* **Port bereits belegt:**
  In `docker-compose.yml` linken Port ändern, z.B. `"40121:40120"`

* **Container startet nicht:**

```
docker compose logs fivem
```

* **Ressource wird nicht geladen:**
  Prüfe `server.cfg` → `ensure ressourcen-name` und Ordnername exakt übereinstimmend.

---

✅ Fertig! Dein FiveM Docker Server läuft nun stabil mit **automatischem Backup-System**.
