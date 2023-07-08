data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["125523088429"]

  filter {
    name   = "name"
    values = ["CentOS Stream 8 x86_64 *"]
  }
}
