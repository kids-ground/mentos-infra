project_name = "mentos"

vpc_cidr = "10.60.0.0/16"

az_names = [
  "ap-northeast-2a",
  "ap-northeast-2c",
]

public_subnets = {
  a = {
    zone = "ap-northeast-2a"
    cidr = "10.60.0.0/24"
  },
  c = {
    zone = "ap-northeast-2c"
    cidr = "10.60.1.0/24"
  },
}

private_subnets = {
  a = {
    zone = "ap-northeast-2a"
    cidr = "10.60.2.0/24"
  },
  c = {
    zone = "ap-northeast-2c"
    cidr = "10.60.3.0/24"
  },
}