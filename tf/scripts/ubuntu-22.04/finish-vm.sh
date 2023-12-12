echo "git clone https://github.com/OurFreeLight/FreeLightHelmCharts.git ~/FreeLightHelmCharts" >> /var/run/vm-installing
echo "sudo reboot" >> /var/run/vm-installing
mv /var/run/vm-installing /var/run/finish-install.sh
chmod 777 /var/run/finish-install.sh

touch "$FLAG_FILE"