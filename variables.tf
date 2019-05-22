variable "region" {
  default = "eu-central-1"
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap."
  type        = "list"

  default = [
    "565245139611",
  ]
}

variable "map_accounts_count" {
  description = "The count of accounts in the map_accounts list."
  type        = "string"
  default     = 1
}

variable "route53_zone_id" {
  default = "ZQ99OQAVV7HL6"
}

variable "route53_zone_domain" {
  default = "gc.crlabs.cloud"
}
