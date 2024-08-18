terraform {
  backend "local" {
    path = "./lambda.tfstate"
  }
}
