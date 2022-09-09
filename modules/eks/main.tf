terraform {
  experiments = [module_variable_optional_attrs]
  required_version = "1.2.9"
  required_providers {
    aws        = "4.30.0"
    kubernetes = "2.13.1"
  }
}
