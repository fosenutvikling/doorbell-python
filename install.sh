#!/bin/bash

# Oppdater systemet
sudo apt update && sudo apt upgrade -y

# Installer nødvendige pakker
sudo apt install -y python3 python3-pip python3-venv git

# Klon prosjektet fra GitHub (erstatt URL-en med din repo's URL)
REPO_URL="https://github.com/fosenutvikling/doorbell-python.git"
PROJECT_DIR="doorbell-python"

if [ -d "$PROJECT_DIR" ]; then
    echo "Prosjektmappen finnes allerede. Oppdaterer prosjektet..."
    cd $PROJECT_DIR
    git pull
else
    echo "Klone prosjektet fra GitHub..."
    git clone $REPO_URL
    cd $PROJECT_DIR
fi

# Beskytt eksisterende config.json og unngå overskriving
if [ -f "config.json" ]; then
    echo "config.json finnes allerede og vil ikke bli overskrevet."
else
    # Opprett en tom config.json om den ikke eksisterer fra før
    echo '{"serverUrl": "", "buttons": []}' > config.json
    echo "En tom config.json er opprettet."
fi

# Rydd opp tidligere miljø hvis ønskelig (valgfritt)
# Uncomment de neste linjene hvis du vil slette og sette opp miljøet på nytt
# echo "Sletter gammelt virtuelt miljø..."
# rm -rf ringeklokke_env

# Lag et virtuelt miljø
if [ ! -d "ringeklokke_env" ]; then
    echo "Oppretter virtuelt miljø..."
    python3 -m venv ringeklokke_env
else
    echo "Virtuelt miljø finnes allerede."
fi

# Aktiver det virtuelle miljøet og installer nødvendige Python-pakker
source ringeklokke_env/bin/activate
pip install -r requirements.txt

# Dynamisk finn brukernavnet som kjører skriptet
CURRENT_USER=$(whoami)

# Opprett eller oppdater systemd-tjeneste for ringeklokke.py med dynamisk brukernavn
SERVICE_FILE=/etc/systemd/system/ringeklokke.service

echo "Oppretter eller oppdaterer systemd-tjenesten for ringeklokke.py..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Ringeklokke Service
After=network.target

[Service]
User=$CURRENT_USER
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/ringeklokke_env/bin/python3 $(pwd)/ringeklokke.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Oppdater systemd og aktiver tjenesten
sudo systemctl daemon-reload
sudo systemctl enable ringeklokke.service
echo "Ringeklokke service er installert, men vil ikke bli startet automatisk."

# Opprett systemd-tjeneste for webapp.py
WEBAPP_SERVICE_FILE=/etc/systemd/system/webapp.service

echo "Oppretter systemd-tjenesten for webapp.py..."
sudo bash -c "cat > $WEBAPP_SERVICE_FILE" <<EOF
[Unit]
Description=Web App Service
After=network.target

[Service]
User=$CURRENT_USER
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/ringeklokke_env/bin/python3 $(pwd)/webapp.py
Restart=always
RestartSec=5
Nice=-10

[Install]
WantedBy=multi-user.target
EOF

# Oppdater systemd og start webapp-tjenesten
sudo systemctl daemon-reload
sudo systemctl enable webapp.service
sudo systemctl start webapp.service
echo "Webapp service er installert og startet."

# Opprett start_webapp.sh skriptet
cat <<EOL > start_webapp.sh
#!/bin/bash
# Script to start webapp.py

# Naviger til prosjektmappen
cd $(pwd)

# Aktiver det virtuelle miljøet
source ringeklokke_env/bin/activate

# Start webapp.py i bakgrunnen
nohup python3 webapp.py &

# Åpne nettleseren på port 5000
sleep 2 # Vent litt for å sikre at webappen starter før nettleseren åpnes
xdg-open http://localhost:5000
EOL

# Gjør start_webapp.sh kjørbar
chmod +x start_webapp.sh

# Finn riktig skrivebordskatalog basert på brukerens språkinnstilling
DESKTOP_DIR="$HOME/Desktop"
if [ ! -d "$DESKTOP_DIR" ]; then
    DESKTOP_DIR="$HOME/Skrivebord"
fi

# Sjekk om skrivebordskatalogen finnes, hvis ikke opprett en av dem
if [ ! -d "$DESKTOP_DIR" ]; then
    echo "Oppretter skrivebordskatalogen $DESKTOP_DIR..."
    mkdir -p "$DESKTOP_DIR"
fi

# Opprett en skrivebordssnarvei til start_webapp.sh
DESKTOP_FILE="$DESKTOP_DIR/start_webapp.desktop"

cat <<EOL > $DESKTOP_FILE
[Desktop Entry]
Name=Start Web App
Comment=Start the web application to edit config
Exec=$(pwd)/start_webapp.sh
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Utility;
EOL

# Gjør skrivebordssnarveien kjørbar
chmod +x $DESKTOP_FILE

# Deaktiver sleep og skjermsparer (unattended mode)
gsettings set org.gnome.desktop.session idle-delay 0

# Sjekk om xset fungerer, og deaktiver DPMS bare hvis det er støttet
xset s off
if xset -q | grep -q "DPMS is Enabled"; then
    xset -dpms
else
    echo "DPMS setting is not supported on this system, skipping."
fi

echo "Installasjonen er fullført. En snarvei for å starte webappen er opprettet på skrivebordet."
