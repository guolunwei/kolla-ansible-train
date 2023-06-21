#!/usr/bin/env bash

set -ex 
export LANG=en_US.UTF-8

if [[ ! -e ~/.ssh/id_rsa ]]; then \
    ssh-keygen -q -N "" -f ~/.ssh/id_rsa
fi

sudo apt install -y sshpass

PASS=ubuntu
for i in 11 31 41; do \
sshpass -p $PASS ssh-copy-id -o StrictHostKeyChecking=no ubuntu@10.0.0.$i;done

sudo apt install -y python3-dev libffi-dev gcc libssl-dev python3-selinux python3-setuptools
sudo apt install -y python3-venv

rm -rf venv/
python3 -m venv venv/
source venv/bin/activate

pip install -U pip
pip install wheel
pip install cryptography==36.0.2
pip install 'ansible<2.10'
pip install kolla-ansible==9.2.0

sudo mkdir -p /etc/kolla
sudo chown $USER:$USER /etc/kolla

cp -r venv/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
cp venv/share/kolla-ansible/ansible/inventory/* .

if [[ ! -d /etc/ansible/ ]]; then
    sudo mkdir /etc/ansible/
fi

sudo tee /etc/ansible/ansible.cfg <<EOF
[defaults]
host_key_checking=False
pipelining=True
forks=100
EOF

