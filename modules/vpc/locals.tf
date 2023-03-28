locals {
  aws_availability_zone_names = coalesce(
    length(data.aws_availability_zones.user.names) > 0 ? data.aws_availability_zones.user.names : null,
    data.aws_availability_zones.available.names
  )
}
