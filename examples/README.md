# Fury EKS Installer Example

This folder contains working examples of the terraform modules provided by this Fury Installer.

In order to test them, you follow the instructions below.
Note all comments starting with `TASK: ` require you to run some manual action on your computer
that cannot be automated with the following script.

```bash
# First of all, export the needed env vars for the aws provider to work
export AWS_ACCESS_KEY_ID=<YOUR_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<SECRET_ACCESS_KEY>
export AWS_REGION=<YOUR_REGION>

# Bring up the vpc
cd examples/vpc
terraform init
terraform apply

# Bring up the vpn, but only if you plan to spin a private cluster
cd examples/vpn
terraform init
terraform apply

# Create a OpenVPN client certificate using furyagent
furyagent configure openvpn-client --config=./secrets/furyagent.yml --client-name test > /tmp/fury-example-test.ovpn
# TASK: import the generated /tmp/fury-example-test.ovpn in the openvpn client of your choice and turn it on.

# Create a kubernetes cluster. Pick eks-private if you plan to spin a private cluster, or eks-public otherwise.
cd ../eks-private
terraform init
terraform apply

# Once all the above is done you can dump the kube config to a file of your choice
terraform output -raw kubeconfig > /var/tmp/.kubeconfig

# Last but not least, you can verify your cluster is up and running
KUBECONFIG=/var/tmp/.kubeconfig kubectl get nodes

# Destroy the cluster
terraform destroy
```
