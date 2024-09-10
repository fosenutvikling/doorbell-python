# Raspberry Pi

Trinn 1: Forberedelse på Raspberry Pi
Installer Raspbian (Raspberry Pi OS):

Last ned og installer Raspberry Pi OS fra Raspberry Pi nettstedet.
Følg instruksjonene for å lage et oppstartbart SD-kort.
Konfigurer Raspberry Pi:

Sett opp Wi-Fi og SSH (hvis du vil administrere Pi-en eksternt) ved å legge til en wpa_supplicant.conf og en tom ssh-fil i boot-partisjonen på SD-kortet før første oppstart.
Sett inn SD-kortet i Raspberry Pi, koble til strøm og vent til den starter opp.
Trinn 2: Overfør filer til Raspberry Pi
Bruk SCP for å overføre filene:

På din Windows PC, åpne en terminal (PowerShell eller Command Prompt).
Bruk scp for å overføre filene til Raspberry Pi. For eksempel:
bash
Kopier kode
scp -r ringeklokke pi@<raspberry_pi_ip>:/home/pi/
Erstatt <raspberry_pi_ip> med IP-adressen til Raspberry Pi.

Trinn 3: Installer nødvendige pakker på Raspberry Pi
Koble til Raspberry Pi via SSH:

Åpne en terminal og koble til Pi via SSH:
bash
Kopier kode
ssh pi@<raspberry_pi_ip>
Oppdater systemet og installer Python-pakker:

bash
Kopier kode
sudo apt update
sudo apt upgrade -y
sudo apt install python3-pip -y
pip3 install websockets pygame
Trinn 4: Opprett en systemd-tjeneste for automatisk oppstart
Opprett en systemd-tjenestefil:

bash
Kopier kode
sudo nano /etc/systemd/system/ringeklokke.service
Legg til følgende innhold i tjenestefilen:

ini
Kopier kode
[Unit]
Description=Ringeklokke WebSocket Client
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/pi/ringeklokke/ringeklokke.py
WorkingDirectory=/home/pi/ringeklokke
StandardOutput=inherit
StandardError=inherit
Restart=always
User=pi

[Install]
WantedBy=multi-user.target
Dette vil starte scriptet automatisk ved oppstart og sikre at det kjører i bakgrunnen.

Aktiver og start tjenesten:

bash
Kopier kode
sudo systemctl enable ringeklokke.service
sudo systemctl start ringeklokke.service
Sjekk tjenestestatus:

Du kan sjekke statusen til tjenesten for å sikre at den kjører som forventet:

bash
Kopier kode
sudo systemctl status ringeklokke.service
Trinn 5: Test og bekreft
Test WebSocket-tilkoblingen:

Sørg for at WebSocket-serveren er oppe og kjører.
Trykk på knappen som sender WebSocket-meldingen og sjekk om lyden spilles av på Raspberry Pi.
Feilsøking:

Hvis det oppstår problemer, sjekk loggene ved å bruke journalctl:
bash
Kopier kode
sudo journalctl -u ringeklokke.service
Trinn 6: Kjør headless
Etter at du har fulgt alle trinnene ovenfor, bør Raspberry Pi kunne kjøre applikasjonen din automatisk ved oppstart uten behov for skjerm, mus eller tastatur. Alt du trenger å gjøre er å koble til høyttalere, og Pi-en vil spille av lyden når WebSocket-meldingene mottas.

Dette oppsettet sikrer enkel onboarding og automatisk oppstart, noe som gjør det ideelt for en headless applikasjon som din ringeklokke.


# Development

## Trinn 1: Installer Python (hvis ikke allerede installert)
Hvis du ikke allerede har Python installert på din Windows PC, kan du laste det ned og installere det fra python.org.

## Trinn 2: Åpne en terminal/kommandolinje
For å installere pakkene, må du åpne en terminal (Command Prompt, PowerShell, eller Windows Terminal). Du kan gjøre dette ved å søke etter "cmd" eller "PowerShell" i startmenyen og åpne det.

## Trinn 3: Installere pakkene
Når terminalen er åpen, skriver du følgende kommandoer for å installere websockets og pygame:
```
pip install websockets pygame
```
Dette vil installere de nødvendige bibliotekene globalt i ditt Python-miljø.