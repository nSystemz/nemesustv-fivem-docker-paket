#!/bin/bash
set -e
set -o noglob

# Env Variablen
LICENSE_KEY="${LICENSE_KEY:?Please set LICENSE_KEY in .env}"
SERVER_NAME="${SERVER_NAME:-Mein FiveM Server}"

# Basis-Ordner
BASE_DIR="/opt/fivem"
ARTIFACT_DIR="$BASE_DIR/server"
SERVER_DATA="$BASE_DIR/server-data"
TXADMIN_DATA="$BASE_DIR/txData"
mkdir -p "$ARTIFACT_DIR" "$SERVER_DATA" "$TXADMIN_DATA/default"

# --- Auto-Updater für FiveM Artifacts ---
ARTIFACT_BASE="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master"

# HTML der Artifact-Seite abrufen und neueste Version extrahieren
# Format auf der Seite: 12345-abcdef1234567890/
ARTIFACT_HTML=$(curl -s "$ARTIFACT_BASE/")
LATEST_VERSION=$(echo "$ARTIFACT_HTML" | grep -Eo '[0-9]+-[0-9a-f]+/' | sed 's|/||' | sort -t'-' -k1 -n | tail -n 1)

echo "DEBUG: Gefundene Version: '$LATEST_VERSION'"

if [ -z "$LATEST_VERSION" ]; then
    echo "FEHLER: Konnte aktuelle Artifact-Version nicht ermitteln!"
    echo "DEBUG: Erste 500 Zeichen der Seite:"
    echo "$ARTIFACT_HTML" | head -c 500
    exit 1
fi

VERSION_FILE="$ARTIFACT_DIR/.version"
CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "")

if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ] || [ ! -f "$ARTIFACT_DIR/run.sh" ]; then
    echo "Downloading FiveM artifacts version: $LATEST_VERSION"
    wget "$ARTIFACT_BASE/$LATEST_VERSION/fx.tar.xz" -O fx.tar.xz

    echo "DEBUG: Archiv-Struktur (erste 20 Einträge):"
    tar -tf fx.tar.xz | head -20

    echo "DEBUG: Entpacke nach $ARTIFACT_DIR ..."
    tar -xf fx.tar.xz -C "$ARTIFACT_DIR"
    rm fx.tar.xz

    echo "DEBUG: Inhalt von $ARTIFACT_DIR:"
    ls -la "$ARTIFACT_DIR"

    echo "$LATEST_VERSION" > "$VERSION_FILE"
    echo "Download abgeschlossen."
else
    echo "Artifacts bereits aktuell: $LATEST_VERSION"
fi

# --- server-data klonen oder aktualisieren ---
if [ ! "$(ls -A "$SERVER_DATA")" ]; then
    echo "Cloning cfx-server-data..."
    git clone https://github.com/citizenfx/cfx-server-data.git "$SERVER_DATA"
else
    echo "Updating cfx-server-data..."
    git -C "$SERVER_DATA" pull --ff-only || true
fi

# --- Alle fxmanifest.lua ohne fx_version patchen ---
echo "Patche fxmanifest.lua Dateien ohne fx_version..."
find "$SERVER_DATA/resources" -name "fxmanifest.lua" | while read -r MANIFEST; do
    if ! grep -q "fx_version" "$MANIFEST"; then
        echo "  Patching: $MANIFEST"
        cp "$MANIFEST" "${MANIFEST}.bak"
        { echo 'fx_version "cerulean"'; echo 'game "gta5"'; echo ''; cat "${MANIFEST}.bak"; } > "$MANIFEST"
    fi
done

# --- server.cfg nur beim ersten Start schreiben ---
if [ ! -f "$SERVER_DATA/server.cfg" ]; then
    echo "Schreibe initiale server.cfg..."
    cat > "$SERVER_DATA/server.cfg" <<EOL
sv_hostname "$SERVER_NAME"
sv_licenseKey "$LICENSE_KEY"

endpoint_add_tcp "0.0.0.0:30120"
endpoint_add_udp "0.0.0.0:30120"

set resources_path "$SERVER_DATA/resources"

start mapmanager
start chat
start spawnmanager
start basic-gamemode
start hardcap
start rconlog
EOL
else
    echo "  server.cfg existiert bereits, wird nicht überschrieben."
fi

# --- txAdmin config schreiben ---
# txAdmin v8 liest aus txData/default/config.json (nicht txData/config.json!)
CONFIG_FILE="$TXADMIN_DATA/default/config.json"
mkdir -p "$TXADMIN_DATA/default"

write_txadmin_config() {
    python3 - <<PYEOF
import json
config = {
    "version": 2,
    "general": {
        "serverName": "$SERVER_NAME",
        "language": "en"
    },
    "webServer": {
        "listenAddress": "0.0.0.0",
        "listenPort": 40120
    },
    "fxRunner": {
        "serverDataPath": "$SERVER_DATA",
        "cfgPath": "$SERVER_DATA/server.cfg",
        "autostart": True
    }
}
with open("$CONFIG_FILE", "w") as f:
    json.dump(config, f, indent=4)
print("  Config geschrieben (v2).")
PYEOF
}

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Schreibe initiale txAdmin config..."
    write_txadmin_config
    echo "  txAdmin wird beim Start einen PIN ausgeben!"
else
    CONFIG_VERSION=$(python3 -c "import json; print(json.load(open('$CONFIG_FILE')).get('version',0))" 2>/dev/null || echo "0")
    echo "  Vorhandene Config-Version: $CONFIG_VERSION"
    if [ "$CONFIG_VERSION" != "2" ]; then
        echo "  Inkompatible Config-Version, schreibe neu..."
        write_txadmin_config
    else
        echo "  txAdmin config ist aktuell, wird nicht überschrieben."
    fi
fi

# --- run.sh prüfen ---
RUN_SH="$ARTIFACT_DIR/run.sh"

if [ ! -f "$RUN_SH" ]; then
    echo "FEHLER: run.sh nicht gefunden: $RUN_SH"
    exit 1
fi

echo ""
echo "============================================"
echo "  Starting FiveM Server..."
echo "  txAdmin UI : http://localhost:40120"
echo "  --> PIN im Log beachten!"
echo "============================================"
echo ""

cd "$SERVER_DATA"

exec bash "$RUN_SH" \
    +set sv_licenseKey "$LICENSE_KEY" \
    +set sv_hostname "$SERVER_NAME"