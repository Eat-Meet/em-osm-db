# -------------- AWS PROVIDER ----------------------------

provider "aws" {
  region     = "eu-west-2"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# -------------- RESOURCES ------------------------------

# -------------- VPC ------------------------------------

resource "aws_vpc" "osm_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "OSM DB VPC"
    Creator = "Terraform"
  }
}

resource "aws_subnet" "osm_subnet_a" {
  vpc_id            = aws_vpc.osm_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name    = "OSM DB Subnet A"
    Creator = "Terraform"
  }
}

resource "aws_subnet" "osm_subnet_b" {
  vpc_id            = aws_vpc.osm_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-2b"

  tags = {
    Name    = "OSM DB Subnet B"
    Creator = "Terraform"
  }
}

resource "aws_security_group" "osm_db_security_group" {
  name   = "osm_db_sg"
  vpc_id = aws_vpc.osm_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "OSM DB Security group"
    Creator = "Terraform"
  }
}

resource "aws_db_subnet_group" "osm_db_subnet_group" {
  name       = "osm_db_subnet_group"
  subnet_ids = [aws_subnet.osm_subnet_a.id, aws_subnet.osm_subnet_b.id]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "OSM DB Subnet Group"
    Creator = "Terraform"
  }
}

resource "aws_internet_gateway" "osm_igw" {
  vpc_id = aws_vpc.osm_vpc.id

  tags = {
    Name    = "OSM Internet Gateway"
    Creator = "Terraform"
  }
}

resource "aws_route_table" "osm_rt" {
  vpc_id = aws_vpc.osm_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.osm_igw.id
  }

  tags = {
    Name    = "OSM Route Table Public Access"
    Creator = "Terraform"
  }
}

resource "aws_route_table_association" "rt_association_a" {
  subnet_id      = aws_subnet.osm_subnet_a.id
  route_table_id = aws_route_table.osm_rt.id
}

resource "aws_route_table_association" "rt_association_b" {
  subnet_id      = aws_subnet.osm_subnet_b.id
  route_table_id = aws_route_table.osm_rt.id
}

# ------------------------ RDS -------------------------

resource "aws_db_instance" "osm_rds" {
  identifier = "osm-db"

  engine            = "postgres"
  engine_version    = "15.5"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "osm_db"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.osm_db_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.osm_db_subnet_group.name

  publicly_accessible = true
  skip_final_snapshot = true

  tags = {
    Name    = "OSM Postgres DB"
    Creator = "Terraform"
  }

  lifecycle {
    ignore_changes = [
      db_subnet_group_name,
      vpc_security_group_ids,
      tags
    ]
  }
}