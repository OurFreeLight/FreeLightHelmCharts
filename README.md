# FreeLight Helm Charts
The FreeLight Helm Charts repository provides a collection of [Helm](https://helm.sh/) charts for deploying [FreeLight](https://freelight.org) applications into Kubernetes clusters.

## Prerequisites
* Kubernetes 1.20+
* Helm 3.x+
* Terraform (optional)

## Helm Deployment
This assumes you have a Kubernetes cluster setup and Helm installed.  If you do not, see the [Setting up the Cluster](#Setting-up-the-Cluster) section below.

## Setting up the Cluster
If you do not have a Kubernetes cluster setup, you can use this repo to setup a cluster using [Terraform](https://www.terraform.io/).

The FreeLight Helm Charts repo contains terraform modules that can setup a cluster in several ways. The modules are located in the [tf](tf/) directory.  The modules are:
* gcp

To get started, clone this repo:
```bash
git clone https://github.com/OurFreeLight/FreeLightHelmCharts.git
```

Then, change into the `tf` directory:
```bash
cd FreeLightHelmCharts/tf
```

Then, change into the directory of the module you want to use.  For example:
```bash
cd gcp
```

Create a new `custom.tfvars` file and add the following:
```tf
gcp_project_id        = "YOUR_GCP_PROJECT_ID"
gcp_credentials_file  = "PATH_TO_YOUR_GCP_CREDENTIALS_FILE"
deployment_type       = "vm"
k8s_type              = "microk8s"
gcp_vm_instance_type  = "e2-medium"
```

Add any other variables you may need to that file, then goto the [GCP](#GCP-Module) section below.

## GCP Module
The GCP module will create a Kubernetes cluster in GCP.  To use it, you will need to have a GCP account and a project setup.  You will also need to have the [gcloud](https://cloud.google.com/sdk/gcloud) command line tool installed.

### Compute Engine VMs
Set any other variables you may need in the `custom.tfvars` file, then run the following commands:
```bash
./setup.sh
./deploy.sh
```

This will create a e2-medium VM instance in GCP. Once the instance is created, WAIT 30 SECONDS for the startup script to finish. You can view the status of the startup script in the VM's Serial Port 1 logs. Once the startup script is finished, SSH into the instance and finish the installation by entering:
```bash
/var/run/finish-install.sh
```

This will finish installing the selected Kubernetes distribution that was set in `k8s_type` and setup the cluster. The VM will reboot when finished. Once the VM is back up, SSH back into the instance, get your kubeconfig file, and you are ready to deploy FreeLight applications using the [Helm Deployment](#Helm-Deployment) section above.