resource "aws_vpc" "tower" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true

  tags = { Name = "TowerAssignment" }
}

resource "aws_subnet" "tower_public_subnet" {
  vpc_id                  = aws_vpc.tower.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1a"

  tags = { Name = "Tower-public" }
}

resource "aws_internet_gateway" "tower_internet_gateway" {
  vpc_id = aws_vpc.tower.id

  tags = { Name = "Tower-IG" }
}

resource "aws_route_table" "tower_public_route" {
  vpc_id = aws_vpc.tower.id

  tags = { Name = "Tower-Public-Route" }
}

resource "aws_route" "tower_default_route" {
  route_table_id         = aws_route_table.tower_public_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.tower_internet_gateway.id

}


resource "aws_route_table_association" "tower_public_association" {
  subnet_id      = aws_subnet.tower_public_subnet.id
  route_table_id = aws_route_table.tower_public_route.id

}

resource "aws_security_group" "Tower-Mysql-SG" {
  name        = "Mysql-SG"
  description = "Mysql Backend"
  vpc_id      = aws_vpc.tower.id

  tags = {
    Name = "MySql Security Group"
  }

  ingress {
    description = "MYSQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MYFASTAPI"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outside"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "tower_auth" {
  key_name   = "towerkey"
  public_key = file("/Users/monu/.ssh/towerkeypair.pub")
}

resource "aws_instance" "tower_instance" {
  instance_type               = "t2.micro"
  ami                         = data.aws_ami.server_ami.id
  key_name                    = aws_key_pair.tower_auth.id
  vpc_security_group_ids      = [aws_security_group.Tower-Mysql-SG.id]
  subnet_id                   = aws_subnet.tower_public_subnet.id
  user_data                   = file("setup.tpl")
  associate_public_ip_address = true

  provisioner "file" {
    source      = "scripts"
    destination = "/home/centos/"
  }
  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "centos"
    private_key = file("/Users/monu/.ssh/towerkeypair")
    agent       = false
    timeout     = "300s"
  }
  tags = { Name = "Tower-Server-Mysql" }
}

