# @todo Auto-install the helm charts. Would have to copy over custom-values.yaml and modify
# that based on the values set in the Terraform variables.

# echo "cd ~/FreeLightHelmCharts" >> /var/run/vm-installing
# echo "./install.sh" >> /var/run/vm-installing

echo "echo 'Installation complete! Restarting...'" >> /var/run/vm-installing
echo "sudo reboot" >> /var/run/vm-installing

mv /var/run/vm-installing /var/run/finish-install.sh
chmod 777 /var/run/finish-install.sh

touch "$FLAG_FILE"

echo "Completed first part of installation. Please run /var/run/finish-install.sh to complete the installation."