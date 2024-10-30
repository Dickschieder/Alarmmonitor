

#!/bin/bash -e
echo
echo *************************************************
echo
echo Willkommen zum Setup Script für den Alarmmonitor
echo
echo Das Script muss als root user ausgeführt werden
echo
echo v1                                          Rasel
echo *************************************************

# Variablen vorbelegen

ScreenVertical=0
ScreenH="#"
ScreenR="#"
ScreenL="#"
AlarmURL="https://web.alarmmonitor.de/"
#Optional
InstallVNC=1
VNCPassword=Alarmmonitor
InstallVPN=0
VPNAutostart=1

#*******************************************************************************
#Benutzer Abfragen
#*******************************************************************************
clear

echo
read -p "Bitte die Alarm URL aus dem Browser eingeben: " AlarmURL
echo

read -p "Soll der Bildschirm in vertikale Richtung gedreht werden? [N/r/l]: " Antwort
case $Antwort in 
	[nN] )   ScreenH=""	
	;;
	[Rr] )   ScreenR=""
	;;
	[Ll] )   ScreenL=""
	;;
	* )      ScreenH="" ;;
esac

echo
echo "Die folgenden Funktionen sind optional"
echo 
read -p "Soll ein VNC Server installiert werden? [J/n]: " Antwort
case $Antwort in 
	[yYjJ] ) InstallVNC=1	
	;;
	[nN] )   InstallVNC=0	
	;;
	* ) echo ;;
esac


if [ $InstallVNC == 1 ]; then
echo
read -p "VNC Benutzerpasswort festlegen: [Alarmmonitor]: " VNCPassword
fi
echo

read -p "Soll ein VPN Wireguard Client installiert werden? :
Eine Konfigurationsdatei wird unter
/etc/wireguard/wg0.conf
angelegt.
[j/N]: " Antwort
case $Antwort in 
	[yYjJ] ) InstallVPN=1	;;
	[nN] )   InstallVPN=0	;;
	* ) echo ;;
esac

if [ $InstallVPN == 1 ]; then
read -p "VPN als Dienst einrichten [J/n]: " Antwort
case $Antwort in 
	[yYjJ] ) VPNAutostart=1	;;
	[nN] )   VPNAutostart=0	;;
	* ) echo ;;
esac
fi

clear;


#*******************************************************************************
# Installation
#*******************************************************************************



apt-get update

# get software
apt-get install \
        unclutter \
    xorg \
    chromium \
    openbox \
    lightdm \
    locales \
	fonts-noto-color-emoji \
    -y

# dir
mkdir -p /home/vis/.config/openbox

# create group
groupadd vis

# create user if not exists
id -u vis &>/dev/null || useradd -m vis -g vis -s /bin/bash

# rights
chown -R vis:vis /home/vis

# remove virtual consoles
if [ -e "/etc/X11/xorg.conf" ]; then
  mv /etc/X11/xorg.conf /etc/X11/xorg.conf.backup
fi
cat > /etc/X11/xorg.conf << EOF
Section "ServerFlags"
    Option "DontVTSwitch" "true"
EndSection
EOF

# create config
if [ -e "/etc/lightdm/lightdm.conf" ]; then
  mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup
fi

cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=vis
user-session=openbox
${ScreenH}display-setup-script=xrandr
${ScreenR}display-setup-script=xrandr -o right
${ScreenL}display-setup-script=xrandr -o left
xserver-command=X -s 0 -dpms
EOF



#create touch rotation

if [ -e "/etc/X11/xorg.conf.d/40-libinput.conf" ]; then
  mv /etc/X11/xorg.conf.d/40-libinput.conf /etc/X11/xorg.conf.d/40-libinput.conf.backup
fi



cat > /etc/X11/xorg.conf.d/40-libinput.conf << EOF
Section "InputClass"
        Identifier "libinput pointer catchall"
        MatchIsPointer "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection

Section "InputClass"
        Identifier "libinput keyboard catchall"
        MatchIsKeyboard "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection

Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection

Section "InputClass"
        Identifier "libinput touchscreen catchall"
        MatchIsTouchscreen "on"
${ScreenR}          Option "TransformationMatrix" "0 1 0 -1 0 1 0 0 1"   #Rotate right
${ScreenL}          Option "TransformationMatrix" "0 -1 1 1 0 0 0 0 1"   #Rotate left
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection

Section "InputClass"
        Identifier "libinput tablet catchall"
        MatchIsTablet "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
EndSection


EOF


# create autostart
if [ -e "/home/vis/.config/openbox/autostart" ]; then
  mv /home/vis/.config/openbox/autostart /home/vis/.config/openbox/autostart.backup
fi
cat > /home/vis/.config/openbox/autostart << EOF
#!/bin/bash

unclutter --hide-on-touch -root &

while :
do
  xrandr --auto
  chromium \
    --no-first-run \
    --start-fullscreen \
    --disable \
    --disable-translate \
    --disable-infobars \
    --disable-suggestions-service \
    --disable-save-password-bubble \
    --disable-session-crashed-bubble \
	--disable-features=Translate
    --kiosk "$AlarmURL"
  sleep 5
done &
EOF


# create VNC service
if [ $InstallVNC  == 1 ]; then

apt-get install \
x11vnc \
-y

# set VNC password
x11vnc -storepasswd "$VNCPassword" /etc/x11vnc.pass

if [ -e "/etc/systemd/system/x11vnc.service" ]; then
  mv /etc/systemd/system/x11vnc.service /etc/systemd/system/x11vnc.service.backup
fi
cat > /etc/systemd/system/x11vnc.service << EOF
  [Unit]
  Description=x11vnc-Server
  
  [Service]
  ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -rfbauth /etc/x11vnc.pass -rfbport 5900 -shared
  
  [Install]
  WantedBy=multi-user.target
EOF

# activate service
systemctl daemon-reload
systemctl enable x11vnc
systemctl restart x11vnc
  
fi

#setup wireguard

if [ $InstallVPN  == 1 ]; then
  apt-get install \
  wireguard \
  resolvconf \
  -y
  
  mkdir /etc/wireguard/
  chmod 700 /etc/wireguard/
  
  
  #create config File
  cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = <private-key>
Address = 10.100.1.21/32
DNS = 10.100.1.1, 8.8.8.8

[Peer]
PublicKey = <public-key-server>
Endpoint = vpn.mynetwork.com:51820
AllowedIPs = 10.100.1.0/24
PersistentKeepalive = 25
EOF
if [ $VPNAutostart == 1 ]; then 
  systemctl enable wg-quick@wg0.service
fi
systemctl daemon-reload
systemctl start wg-quick@wg0
fi


clear
read -p "Die Installation ist vollständig. Der Rechner muss nun neu gestartet werden,
damit die Anzeige funktioniert. Soll jetzt ein Neustart durchgeführt werden? [J/n]: " Antwort
case $Antwort in 
    [nN] )   exit
	;;
	* )      reboot
	;;
esac
 

echo "Done!"


