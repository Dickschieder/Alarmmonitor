# Alarmmonitor
Alarmmonitor setup script Debian

Die Installation erfolgt auf einem frischen Debian 12.10  mit folgendem Code:

wget https://raw.githubusercontent.com/Dickschieder/Alarmmonitor/refs/heads/main/FFWScreenSetuptScript.sh; chmod +x FFWScreenSetuptScript.sh; ./FFWScreenSetuptScript.sh


Das Kript fragt zu beginn ab was installiert werden soll und wie der Pfad zum Alarmmonitor lautet. Zusätzlich stehen noch die Funktionen:

* Screen Rotate
* VNC Server
* VPN auf Basis von Wireguard

zur Verfügung.
Der Screen kann Optional auf den Kopf gestellt, oder nach links/rechts in den Portraitmodus gedreht werden
Per VNC Viewer kann der Rechner erreicht werden. Die Adresse ist dann IP:9001
Der VPN wird installiert. Die Konfiguration muss noch eingetragen werden. Das Konfiguartionsfile wird unter "/etc/wireguard/wg0.conf" angelegt.