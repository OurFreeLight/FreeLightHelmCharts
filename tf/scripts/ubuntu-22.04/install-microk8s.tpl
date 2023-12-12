sudo snap install microk8s --classic --channel=${k8s_version}/stable

echo "sudo usermod -a -G microk8s \$USER" >> /var/run/vm-installing