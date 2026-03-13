#########################
# VPC
#########################

# Create a virtual private cloud
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"   # Define VPC IP range
}


#########################################################
# Availability Zones Lookup
# -------------------------------------------------------
# Queries AWS for available AZs in the configured region.
# Used to dynamically assign subnet placement.
#########################################################

data "aws_availability_zones" "available" {}

#########################
# Subnet
#########################

# Create a public subnet inside the VPC
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"   # Smaller range than VPC
  map_public_ip_on_launch = true
}

#########################
# Internet Gateway
#########################

# Allows VPC to access the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

#########################
# Route Table
#########################

# Defines routing rules for subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

#########################
# Security Group
#########################

# Firewall rules
resource "aws_security_group" "web_sg" {
  name   = "web-sg"
  vpc_id = aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Astro Calculator"
    from_port   = 54321
    to_port     = 54321
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Change Calculator"
    from_port   = 54322
    to_port     = 54322
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "San Diego Top Spots"
    from_port   = 54323
    to_port     = 54323
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#########################
# EC2 Instance
#########################
# AMI Data Source
# -------------------------------------------------------
# This block queries AWS for the most recent official
# Ubuntu 22.04 image from Canonical.
#
# Think of this as:
#   "Infrastructure lookup layer"
# The EC2 resource will reference the value below.
#-------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id   # Ubuntu AMI ID/references the filter above
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name
}

############################################################
# Generate Ansible Inventory File
#
# Terraform knows the public IP of the EC2 instance after it
# creates it. This block takes that IP and renders the
# ansible inventory template into a real inventory file.
#
# Template file:
#   ansible/inventory.tpl
#
# Generated file:
#   ansible/inventory.ini
#
# This keeps Terraform (infrastructure) and Ansible
# (configuration management) connected automatically.
############################################################

resource "local_file" "ansible_inventory" {

  ##########################################################
  # templatefile()
  #
  # Reads the template file and injects variables.
  # Here we inject the EC2 instance public IP.
  ##########################################################

  content = templatefile("${path.module}/../ansible/inventory.tpl", {
    public_ip = aws_instance.web.public_ip
  })

  ##########################################################
  # Output location for the generated inventory file
  ##########################################################

  filename = "${path.module}/../ansible/inventory.ini"
}