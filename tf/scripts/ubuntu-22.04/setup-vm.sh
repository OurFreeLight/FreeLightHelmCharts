#!/usr/bin/env bash

exec > /var/run/vm-startup-output.log 2>&1

sudo su

FLAG_FILE="/var/run/startup-script-has-run"

# If this file does not exist, this means that the startup script has not run yet, or 
# that there is an issue with the startup script.
if [ -f "$FLAG_FILE" ]; then
    echo "Startup script has already run. Exiting."
    exit 0
fi

apt update && \
apt upgrade -y

echo "#!/usr/bin/env bash" > /var/run/vm-installing
echo "git clone https://github.com/OurFreeLight/FreeLightHelmCharts.git ~/FreeLightHelmCharts" >> /var/run/vm-installing