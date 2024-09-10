#!/bin/bash
# Script to start webapp.py

# Naviger til prosjektmappen
cd /home/pi/doorbell-python

# Aktiver det virtuelle miljøet
source ringeklokke_env/bin/activate

# Start webapp.py i bakgrunnen
nohup python3 webapp.py &
