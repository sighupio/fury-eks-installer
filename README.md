<h1 align="center">
  <img src="docs/assets/fury_installer.png" width="200px"/><br/>
  Fury EKS Installer
</h1>

<p align="center">Deploy a production-grade EKS cluster on AWS ⚔️</p>

![Release](https://img.shields.io/github/v/release/sighupio/fury-eks-installer?label=Release)
[![Slack](https://img.shields.io/badge/slack-@kubernetes/fury-yellow.svg?logo=slack)](https://kubernetes.slack.com/archives/C0154HYTAQH)
![License](https://img.shields.io/github/license/sighupio/fury-eks-installer)

## Installer

The EKS installers deploys and configures a production-ready EKS cluster without having to learn all internals of the service.

The installer is composed of two different terraform modules:

|            Module             |                  Description                   |
| ----------------------------- | ---------------------------------------------- |
| [VPC and VPN][vpc-vpn-module] | Deploy the necessary networking infrastructure |
| [EKS][eks-module]             | Deploy the EKS cluster                         |

## Architecture

![Fury Cluster Architecture](docs/assets/fury_installer_architecture.png)

The [EKS module][eks-module] deploys a **private control plane** cluster, where the control plane endpoint is not publicly accessible.

The [VPC and VPN module][vpc-vpn-module] setups all the necessary networking infrastructure and a bastion host.

The bastion host includes a OpenVPN instance easily manageable by using [furyagent][furyagent].

> 🕵🏻‍♂️ [Furyagent][furyagent] is a tool developed by SIGHUP to manage OpenVPN and SSH user access to the bastion host.

To interact with the private cluster there are two options available:

- `ssh` in to the bastion host
- connect to the OpenVPN server (recommended)

### Useful links

- [Managing users or IAM roles for your cluster](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html)
- [Create a kubeconfig for Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)
- [Tagging your Amazon EKS resources](https://docs.aws.amazon.com/eks/latest/userguide/eks-using-tags.html)
- [Amazon EKS Kubernetes versions]

## License

For license details please see [LICENSE](LICENSE)

[eks installer docs]: https://docs.kubernetesfury.com/docs/installers/managed/eks/
[vpc-vpn-module]: https://github.com/sighupio/fury-eks-installer/tree/master/modules/vpc-and-vpn
[eks-module]: https://github.com/sighupio/fury-eks-installer/tree/master/modules/eks
[Amazon EKS Kubernetes versions]: https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html
[furyagent]: https://github.com/sighupio/furyagent
