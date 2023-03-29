locals {
  availability_zone_ids = toset([for subnet in data.aws_subnet.this : subnet.availability_zone_id])
}
