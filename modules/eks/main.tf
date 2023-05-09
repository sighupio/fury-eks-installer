terraform {
  experiments      = [module_variable_optional_attrs]
  required_version = "~> 0.15"
  required_providers {
    aws        = "~> 3.56"
    kubernetes = "~> 1.13"
  }
}
