groupadd docker
env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update && \
    env DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
        docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose \
        docker-scan-plugin docker-buildx-plugin

mkdir -p /etc/docker && \
    echo '{ "features": { "buildkit": true } }' > /etc/docker/daemon.json

echo "sudo usermod -aG docker \$USER" >> /var/run/vm-installing