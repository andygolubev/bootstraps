#!/bin/bash
apt -y update
apt -y install ubuntu-desktop
apt -y install tightvncserver
apt -y install gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal


runuser -l ubuntu -c 'mkdir /home/ubuntu/.vnc'
runuser -l ubuntu -c 'touch /home/ubuntu/.vnc/xstartup'

myuser="ubuntu"
mypasswd="1111qqqq"

echo $mypasswd | vncpasswd -f > /home/$myuser/.vnc/passwd
chown -R $myuser:$myuser /home/$myuser/.vnc
chmod 0600 /home/$myuser/.vnc/passwd

echo "#!/bin/sh

export XKL_XMODMAP_DISABLE=1
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey

vncconfig -iconic &
gnome-panel &
gnome-settings-daemon &
metacity &
nautilus &
gnome-terminal &" >> /home/ubuntu/.vnc/xstartup

runuser -l ubuntu -c 'vncserver :1'

echo "Open port for VNC 5901 by Security group"
