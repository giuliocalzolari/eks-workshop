variable "stage" {
  description = "enviroment name"
  type = string
}

variable "namespace" {
  description = "k8s namespace"
  type = string
}

variable "app_name" {
  description = "k8s app_name"
  type = string
  default = "guestbook"
}
