# Setting up Microk8s on a VM

## System Requirements
* Ubuntu 22.04
* 2 vCPU
* 4GB RAM
* 20GB Disk Space

## Setup the VM
Setup the VM according to the [README.md](../README.md) for your cloud provider. Once the VM is setup, SSH into the VM and edit `/var/snap/microk8s/current/certs/csr.conf.template` and add the following to the `[alt_names]` section:
```conf
DNS.6 = YOUR_DOMAIN_HERE
```
If you're using an IP to connect to the cluster use this instead:
```conf
IP.3 = YOUR_IP_HERE
```
Then, refresh the certificates:
```bash
sudo microk8s refresh-certs --cert ca.crt
sudo microk8s refresh-certs --cert server.crt
```
Now setup the kubeconfig to connect to the cluster as an admin:
```bash
microk8s status
microk8s config > ~/.kube/config
```
Now you can use `kubectl` to manage the cluster from within the VM itself. To test this, run:
```bash
kubectl get nodes
```
If you wish to remotely administer the cluster, you will need to copy the `~/.kube/config` file to your local machine and use it as your kubeconfig file. To do this enter:
```bash
cat ~/.kube/config
```
Copy the contents of this file into your local machine's `~/.kube/config` file. In the `~/.kube/config` file, replace the `server:` line with the following:
```yaml
server: https://YOUR_DOMAIN_OR_IP_HERE:16443
```
Now you can use `kubectl` to manage the cluster from your local machine. To test this, run:
```bash
kubectl get nodes
```
You're all setup! Now you can deploy FreeLight applications using the [Helm Deployment](../README.md#Helm-Deployment) section.

## Kubernetes Dashboard
You can manage the cluster using the Kubernetes Dashboard. To access the dashboard, run:
```bash
microk8s enable dashboard
```
Then to access the dashboard in a web browser, run:
```bash
kubectl port-forward -n kube-system service/kubernetes-dashboard 10443:443
```
In a web browser, navigate to `https://localhost:10443`. You will be prompted to login. To get the token to login, run:
```bash
kubectl -n kube-system get secret microk8s-dashboard-token -o jsonpath={.data.token} | base64 -d
```