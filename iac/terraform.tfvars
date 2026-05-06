vpc_cidr = {
  dev  = "10.0.0.0/16"
  qa   = "10.0.0.0/16"
  prod = "10.0.0.0/16"
}

uploads_expiration_days = {
  dev  = 7
  qa   = 14
  prod = 30
}

processed_expiration_days = {
  dev  = 14
  qa   = 30
  prod = 90
}

upload_memory = {
  dev  = 256
  qa   = 256
  prod = 256
}

upload_timeout = {
  dev  = 30
  qa   = 30
  prod = 30
}

crop_memory = {
  dev  = 512
  qa   = 512
  prod = 512
}

crop_timeout = {
  dev  = 60
  qa   = 60
  prod = 60
}

log_retention_days = {
  dev  = 7
  qa   = 14
  prod = 30
}