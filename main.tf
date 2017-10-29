provider "aws" {
  access_key = "AKIAIXC5OARPIYHR4QFQ"
  secret_key = "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"
  region     = "eu-central-1"
}

variable "platform" {
        default = "hors_prod"
}


resource "aws_vpc" "hors_prod" {
        enable_dns_hostnames = true
        enable_dns_support = true
        cidr_block      = "10.0.0.0/16"
        tags{
        Name = "${var.platform}"
        }
}

resource "aws_internet_gateway" "gw" {
        vpc_id = "${aws_vpc.hors_prod.id}"
}

resource "aws_subnet" "hors_prod_dmz" {
        vpc_id          = "${aws_vpc.hors_prod.id}"
        cidr_block      = "10.0.1.0/24"
}

resource "aws_subnet" "hors_prod_interne" {
        vpc_id          = "${aws_vpc.hors_prod.id}"
        cidr_block      = "10.0.10.0/24"
}

resource "aws_eip" "eip_nat_dmz" {
        vpc = true
}


resource "aws_nat_gateway" "nat_gw_dmz" {
        allocation_id = "${aws_eip.eip_nat_dmz.id}"
        subnet_id     = "${aws_subnet.hors_prod_dmz.id}"
}

resource "aws_route_table" "subnet_to_nat" {
        vpc_id = "${aws_vpc.hors_prod.id}"

        route {
                cidr_block = "0.0.0.0/0"
                nat_gateway_id = "${aws_nat_gateway.nat_gw_dmz.id}"
                }
}

resource "aws_route_table" "dmz_to_net" {
        vpc_id = "${aws_vpc.hors_prod.id}"

        route {
                cidr_block = "0.0.0.0/0"
                gateway_id = "${aws_internet_gateway.gw.id}"
                }
}

resource "aws_route_table_association" "assoc_interne_subnet" {
        subnet_id = "${aws_subnet.hors_prod_interne.id}"
        route_table_id = "${aws_route_table.subnet_to_nat.id}"
}

resource "aws_route_table_association" "assoc_dmz_subnet" {
        subnet_id = "${aws_subnet.hors_prod_dmz.id}"
        route_table_id = "${aws_route_table.dmz_to_net.id}"
}

resource "aws_security_group" "ssh" {
        name            = "hors_prod"
        vpc_id          = "${aws_vpc.hors_prod.id}"

         ingress {
                from_port   = 22
                to_port     = 22
                protocol    = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                }

         egress {
                from_port   = 0
                to_port     = 0
                protocol    = "-1"
                cidr_blocks = ["0.0.0.0/0"]
                }
}

resource "aws_security_group" "mysql" {
        name            = "mysql"
        vpc_id          = "${aws_vpc.hors_prod.id}"

         ingress {
                from_port   = 3306
                to_port     = 3306
                protocol    = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
                }

         egress {
                from_port   = 0
                to_port     = 0
                protocol    = "-1"
                cidr_blocks = ["0.0.0.0/0"]
                }
}

resource "aws_instance" "publique1" {
  ami           = "ami-82be18ed"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.hors_prod_dmz.id}"
  associate_public_ip_address = "true"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  key_name               = "hub_iot"
}

resource "aws_instance" "publique2" {
  ami           = "ami-82be18ed"
  instance_type = "t2.micro"
  subnet_id     = "${aws_subnet.hors_prod_dmz.id}"
  associate_public_ip_address = "true"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  key_name               = "hub_iot"
}

resource "aws_eip" "publique1" {
        instance = "${aws_instance.publique1.id}"
        vpc      = true
}

resource "aws_eip" "publique2" {
        instance = "${aws_instance.publique2.id}"
        vpc      = true
}

resource "aws_instance" "cassandra" {
  ami           = "ami-82be18ed"
  instance_type = "m3.large"
  subnet_id     = "${aws_subnet.hors_prod_interne.id}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  key_name               = "hub_iot"
  private_ip    = "10.0.10.21"
}

resource "aws_ebs_volume" "cassandra" {
  availability_zone = "eu-central-1a"
  size = 40
  encrypted = true
}

resource "aws_volume_attachment" "ebs_cas" {
  device_name = "/dev/sdh"
  volume_id = "${aws_ebs_volume.cassandra.id}"
  instance_id = "${aws_instance.cassandra.id}"
}

resource "aws_instance" "mysql" {
  ami           = "ami-82be18ed"
  instance_type = "t2.medium"
  subnet_id     = "${aws_subnet.hors_prod_interne.id}"
  vpc_security_group_ids = ["${aws_security_group.ssh.id}"]
  key_name               = "hub_iot"
  private_ip    = "10.0.10.20"
}

resource "aws_ebs_volume" "mysql" {
  availability_zone = "eu-central-1a"
  size = 40
  encrypted = true
}

resource "aws_volume_attachment" "ebs_mysql" {
  device_name = "/dev/sdh"
  volume_id = "${aws_ebs_volume.mysql.id}"
  instance_id = "${aws_instance.mysql.id}"
}


output "ip_publique_1" {
value = "${aws_eip.publique1.public_ip}"
}

output "ip_publique_2" {
value = "${aws_eip.publique2.public_ip}"
}

output "ip_prive_mysql" {
value = "${aws_instance.mysql.private_ip}"
}

output "ip_prive_cassandra" {
value = "${aws_instance.cassandra.private_ip}"
}
