#!/usr/bin/env bash

NEWUSER=$USER

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

echo "#!/usr/bin/env bash" > /var/run/finish-install.sh
