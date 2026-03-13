############################################################
# Ansible Inventory Template
#
# This file is NOT used directly by Ansible.
# Terraform renders this template and generates:
#
#     ansible/inventory.ini
#
# The ${public_ip} placeholder is replaced with the EC2
# instance public IP that Terraform creates.
############################################################


############################################################
# Host Group Definition
############################################################

[web]

# Public IP of the EC2 instance created by Terraform.
# Terraform dynamically injects the value here.
${public_ip}


############################################################
# Connection Variables for the "web" Host Group
############################################################

[web:vars]

# Default SSH user for Ubuntu EC2 AMIs
ansible_user=ubuntu

# Private key used to authenticate to server
# Must match the key pair specified in Terraform
ansible_ssh_private_key_file=/Users/emmanueljohnson/Desktop/terraform-lab-key.pem

# Explicitly tell Ansible to use Python3 on the remote host.
ansible_python_interpreter=/usr/bin/python3