data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_availability_zones" "user" {
  state = "available"
  filter {
    name   = "zone-name"
    values = var.availability_zone_names
  }
}
