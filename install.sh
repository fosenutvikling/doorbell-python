#!/bin/bash

# Oppdater systemet
sudo apt update && sudo apt upgrade -y

# Installer nødvendige pakker
sudo apt install -y python3 python3-pip python3-venv git

# Lag et virtuelt miljø
python3 -m venv ringeklokke_env
source ringeklokke_env/bin/activate

# Installer Python-avhengigheter
pip install -r requirements.txt

# Sett opp systemd-tjeneste for ringeklokke.py
SERVICE_FILE=/etc/systemd/system/ringeklokke.service

sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=Ringeklokke Service
After=network.target

[Service]
User=pi
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/ringeklokke_env/bin/python3 $(pwd)/ringeklokke.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start og aktiver tjenesten
sudo systemctl daemon-reload
sudo systemctl enable ringeklokke.service
sudo systemctl start ringeklokke.service

echo "Ringeklokke service er installert og startet."

# Start webapp.py manuelt (kan også settes opp som egen tjeneste)
echo "Starter webapp.py..."
source ringeklokke_env/bin/activate
python3 webapp.py
