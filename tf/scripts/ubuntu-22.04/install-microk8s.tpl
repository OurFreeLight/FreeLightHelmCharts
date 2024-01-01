sudo snap install microk8s --classic --channel=${k8s_version}/stable

echo "sudo usermod -a -G microk8s \$USER" >> /var/run/vm-installing

# @todo Add specific versions here.
echo "sudo microk8s enable dns ingress hostpath-storage cert-manager" >> /var/run/vm-installing