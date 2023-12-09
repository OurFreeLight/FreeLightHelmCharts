echo "git clone https://github.com/OurFreeLight/FreeLightHelmCharts.git ~/FreeLightHelmCharts" >> /var/run/finish-install.sh
echo "sudo reboot" >> /var/run/finish-install.sh
chmod 777 /var/run/finish-install.sh

touch "$FLAG_FILE"