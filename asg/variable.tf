variable "env_prefix" {}
variable "ami_image" {}
variable "security_groups" {
  type = list(string)
}
variable "instance_type" {}
variable "key_name" {}
variable "efs_dns_name" {}
variable "asg_name" {}
variable "max_size" {
  type = number
}
variable "min_size" {
  type = number
}
variable "desired_capacity" {
  type = number
}
variable "sunbets_nums" {}