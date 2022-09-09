# Fury EKS Installer Example

This folder contains working examples of the terraform modules provided by this Fury Installer.

In order to test them, you follow the instructions below.
Note all comments starting with `TASK: ` require you to run some manual action on your computer
that cannot be automated with the following script.

```bash
# First of all, export the needed env vars for the aws provider to work
export AWS_ACCESS_KEY_ID=<YOUR_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<SECRET_ACCESS_KEY>
export AWS_REGION=eu-<YOUR_REGION>

# Bring up the vpc and vpn
cd example/vpc-and-vpn
cp main.auto.tfvars.dist main.auto.tfvars
# TASK: fill in main.auto.tfvars with your data
terraform init
terraform apply

# Create a OpenVPN client certificate using furyagent
furyagent configure openvpn-client --config=./secrets/furyagent.yml --client-name test > /tmp/fury-example-test.ovpn
# TASK: import the generated /tmp/fury-example-test.ovpn in the openvpn client of your choice and turn it on.

cd ../eks
cp main.auto.tfvars.dist main.auto.tfvars
# TASK: fill in main.auto.tfvars with your data
terraform init
terraform apply
```
