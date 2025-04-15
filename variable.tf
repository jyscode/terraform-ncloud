variable "access_key" {
  description = "Naver Cloud Platform API access key"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "Naver Cloud Platform API secret key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Naver Cloud Platform region"
  type        = string
  default     = "KR"
}

variable "site" {
  description = "Naver Cloud Platform site (public or gov)"
  type        = string
  default     = "public"
}

variable "support_vpc" {
  description = "Whether to use VPC"
  type        = bool
  default     = true
}