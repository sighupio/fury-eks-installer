terraform {
  experiments = [module_variable_optional_attrs]
  required_version = "0.15.4"
  required_providers {
    aws        = "3.37.0"
    kubernetes = "1.13.3"
  }
}
