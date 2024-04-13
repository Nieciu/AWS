variable "region" {
  description = "The region where AWS operations will take place. Examples are us-east-1, us-west-2, etc."
  default     = "eu-west-2"
}

variable "availability_zone" {
  description = "The availability zone where the EC2 instance will be created"
  default = "eu-west-2a"
}

variable "access_key" {
  description = "The AWS access key"
}

variable "secret_key" {
  description = "The AWS secret key"
}