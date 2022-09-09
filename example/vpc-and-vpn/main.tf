module "vpc-and-vpn" {
    source = "../../modules/vpc-and-vpn"

    name = "fury-example"

    network_cidr = "10.0.0.0/16"
    public_subnetwork_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnetwork_cidrs = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

    vpn_subnetwork_cidr = "192.168.200.0/24"
    vpn_ssh_users = ["github-user"]
}
