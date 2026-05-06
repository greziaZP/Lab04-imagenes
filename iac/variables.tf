variable "vpc_cidr" {
  description = "CIDR de la VPC por entorno"
  type        = map(string)
  default = {
    dev  = "10.0.0.0/16"
    qa   = "10.0.0.0/16"
    prod = "10.0.0.0/16"
  }
}

variable "uploads_expiration_days" {
  description = "Dias que se guardan las imagenes originales en S3"
  type        = map(number)
  default = {
    dev  = 7
    qa   = 14
    prod = 30
  }
}

variable "processed_expiration_days" {
  description = "Dias que se guardan las imagenes procesadas en S3"
  type        = map(number)
  default = {
    dev  = 14
    qa   = 30
    prod = 90
  }
}

variable "upload_memory" {
  description = "Memoria de upload-lambda en MB"
  type        = map(number)
  default = {
    dev  = 256
    qa   = 256
    prod = 256
  }
}

variable "upload_timeout" {
  description = "Timeout de upload-lambda en segundos"
  type        = map(number)
  default = {
    dev  = 30
    qa   = 30
    prod = 30
  }
}

variable "crop_memory" {
  description = "Memoria de crop-lambda en MB"
  type        = map(number)
  default = {
    dev  = 512
    qa   = 512
    prod = 512
  }
}

variable "crop_timeout" {
  description = "Timeout de crop-lambda en segundos"
  type        = map(number)
  default = {
    dev  = 60
    qa   = 60
    prod = 60
  }
}

variable "log_retention_days" {
  description = "Dias de retencion de logs en CloudWatch"
  type        = map(number)
  default = {
    dev  = 7
    qa   = 14
    prod = 30
  }
}