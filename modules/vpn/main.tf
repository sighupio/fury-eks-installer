terraform {
  required_version = ">= 1.3"
  required_providers {
    local    = "~> 2.4"
    null     = "~> 3.2"
    aws      = "~> 3.76"
    external = "~> 2.3"
  }
}

//INSTANCE RELATED STUFF

resource "aws_security_group" "vpn" {
  vpc_id      = data.aws_vpc.this.id
  name_prefix = "${var.name}-"
  tags        = var.tags
}

resource "aws_security_group_rule" "vpn" {
  type              = "ingress"
  from_port         = var.vpn_port
  to_port           = var.vpn_port
  protocol          = "udp"
  cidr_blocks       = var.vpn_operator_cidrs
  security_group_id = aws_security_group.vpn.id
}

resource "aws_security_group_rule" "vpn_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.vpn_operator_cidrs
  security_group_id = aws_security_group.vpn.id
}

resource "aws_security_group_rule" "vpn_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vpn.id
}

resource "aws_eip" "vpn" {
  count = var.vpn_instances

  vpc  = true
  tags = var.tags
}

resource "aws_instance" "vpn" {
  count = var.vpn_instances

  ami                    = data.aws_ami.ubuntu2004.image_id
  user_data              = templatefile("${path.module}/templates/vpn.yml", local.vpntemplate_vars)
  instance_type          = var.vpn_instance_type
  subnet_id              = element(var.public_subnets, count.index % length(var.public_subnets))
  vpc_security_group_ids = [aws_security_group.vpn.id]
  source_dest_check      = false
  root_block_device {
    volume_size = var.vpn_instance_disk_size
  }
  tags = merge({ "Name" : "${var.name}-vpn-${count.index}" }, var.tags)
}

resource "aws_eip_association" "vpn" {
  count = var.vpn_instances

  instance_id   = element(aws_instance.vpn.*.id, count.index)
  allocation_id = element(aws_eip.vpn.*.id, count.index)
}


// BUCKET AND IAM
resource "aws_s3_bucket" "furyagent" {
  bucket_prefix = coalesce(var.vpn_bucket_name_prefix, "${var.name}-${var.vpc_id}-${data.aws_region.current.name}-vpn")
  acl           = "private"

  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = var.tags
}

resource "aws_iam_user" "furyagent" {
  name = "${var.name}-${var.vpc_id}-${data.aws_region.current.name}-vpn"
  path = "/"

  tags = var.tags
}

resource "aws_iam_access_key" "furyagent" {
  user = aws_iam_user.furyagent.name
}

resource "aws_iam_policy_attachment" "furyagent" {
  name       = "${var.name}-vpn"
  users      = [aws_iam_user.furyagent.name]
  policy_arn = aws_iam_policy.furyagent.arn
}

resource "aws_iam_policy" "furyagent" {
  name = "${var.name}-${var.vpc_id}-${data.aws_region.current.name}-vpn"
  path = "/"

  policy = <<EOF
{
     "Version": "2012-10-17",
     "Statement": [
         {
             "Effect": "Allow",
             "Action": [
                 "s3:*"
             ],
            "Resource": "${aws_s3_bucket.furyagent.arn}/*"
         },
         {
             "Effect": "Allow",
             "Action": [
                 "s3:ListBucket",
                 "s3:GetBucketLocation"
             ],
            "Resource": "${aws_s3_bucket.furyagent.arn}"
         }
     ]
}
EOF
}

//FURYAGENT

resource "local_file" "furyagent" {
  content  = local.furyagent
  filename = "${path.root}/secrets/furyagent.yml"
}

resource "local_file" "sshkeys" {
  content  = local.sshkeys
  filename = "${path.root}/ssh-users.yml"
}

resource "null_resource" "init" {
  triggers = {
    "init" : "just-once",
  }
  provisioner "local-exec" {
    command = "until `${local.local_furyagent} init openvpn --config ${local_file.furyagent.filename}`; do echo \"Retrying\"; sleep 30; done" # Required because of aws iam lag
  }
}

resource "null_resource" "ssh_users" {
  triggers = {
    "sync-users" : join(",", local.users),
    "sync-operator" : var.vpn_operator_name
  }
  provisioner "local-exec" {
    command = "until `${local.local_furyagent} init ssh-keys --config ${local_file.furyagent.filename}`; do echo \"Retrying\"; sleep 30; done" # Required because of aws iam lag
  }
}
