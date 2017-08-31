#!/bin/bash

INTERFACE=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
VPC_ID=$(curl --silent http://169.254.169.254/latest/meta-data/network/interfaces/macs/${INTERFACE}/vpc-id)

aws ec2 describe-instances --filters "Name=vpc-id, Values="${INTERFACE}"" --query "Reservations[*].Instances[*].PrivateIpAddress" --output text
