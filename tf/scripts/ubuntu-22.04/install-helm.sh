wget -q https://baltocdn.com/helm/signing.asc -O-  | apt-key add - && \
DEBIAN_FRONTEND=noninteractive apt install -y apt-transport-https && \
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
apt-get update && \
DEBIAN_FRONTEND=noninteractive apt install -y helm