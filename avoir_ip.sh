#!/bin/bash -xv

INTERFACE=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
VPC_ID=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${INTERFACE}/vpc-id)

aws ec2 describe-instances --filters "Name=vpc-id, Values="${VPC_ID}"" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text > /home/ec2-user/ed/hosts
sudo mv /etc/ansible/hosts{,.bak}
sudo cp /home/ec2-user/ed/hosts /etc/ansible/hosts
sudo sed -i '1i [Tout]' /etc/ansible/hosts
sudo sed -i '62i host_key_checking = False' /etc/ansible/ansible.cfg
sudo ansible-playbook /home/ec2-user/ed/yum.yaml
sudo ansible-playbook /home/ec2-user/ed/volume.yaml
