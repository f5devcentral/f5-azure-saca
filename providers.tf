terraform {
  required_version = "~> 0.13"
}

provider azurerm {
  version = "~> 2.30.0"
  features {}
}

provider http {}
