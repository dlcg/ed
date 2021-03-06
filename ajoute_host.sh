#!/bin/bash

ANSIBLE="/etc/ansible/hosts"
REP="/appli/deploiement"

cd ${REP}

IP=$(/home/eirik/terraform/terraform output ip_publique_1)
IP1=$(/home/eirik/terraform/terraform output ip_publique_2)
IP2=$(/home/eirik/terraform/terraform output ip_prive_mysql)
IP3=$(/home/eirik/terraform/terraform output ip_prive_cassandra)

cp /etc/ansible/hosts /etc/ansible/hosts.$(date +%Y%m%d)

echo "[bastion]" > ${ANSIBLE}
echo "${IP}" >> ${ANSIBLE}
echo "[front]" >> ${ANSIBLE}
echo "${IP1}" >> ${ANSIBLE}
echo "[mysql]" >> ${ANSIBLE}
echo "${IP2}" >>  ${ANSIBLE}
echo "[cassandra]" >> ${ANSIBLE}
echo "${IP3}" >> ${ANSIBLE}
echo "[locahost]" >> ${ANSIBLE}
echo "127.0.0.1" >> ${ANSIBLE}

sed -i 's/Hostname.*/Hostname '${IP}'/' ${REP}/ssh.cfg
sed -i 's/remote.*/remote '${IP}' 443/' ${REP}/client-common.txt

