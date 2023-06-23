# kolla-ansible-train
Deploy a openstack demo env of train version via kolla-ansbile step-by-step.

## My Lab Environment
To deploy OpenStack using Kolla Ansible, we will be using VMs created using VMware Workstation. So, I have already installed VMware Workstation on my Windows Desktop on which I have created three VMs using the following specs:

```
Name: control01
OS: Ubuntu 18.04.6 LTS
RAM: 8GB
Disk: 40 GB
CPU: Quad Core
ens33(NAT): 10.0.0.11
ens34(Host-only): Make sure no IP Address is assigned to this interface
```
```
Name: compute01
OS: Ubuntu 18.04.6 LTS
RAM: 4GB
Disk: 40 GB
CPU: Quad Core
ens33(NAT): 10.0.0.31
ens34(Host-only): Make sure no IP Address is assigned to this interface
```
```
Name: storage01
OS: Ubuntu 18.04.6 LTS
RAM: 4GB
Disk: 40 GB
Disk2: 40 GB (Addtional disk /dev/sdb for creating cinder-volumes volume group)
CPU: Quad Core
ens33(NAT): 10.0.0.41
```

## Install and Setup Kolla Ansible
Generates a pip conf on all of the nodes, creates vloume group on storage, and then install dependency packages using virtual environment on deployment before we go ahead and install Kolla Ansible:
```
ansible-playbook -i hosts site.yml
```

## Edit multinode
```
[control]
# These hostname must be resolvable from your deployment host
control01   ansible_host=10.0.0.11  ansible_python_interpreter=/usr/bin/python3

# The above can also be specified as follows:
#control[01:03] ansible_user=kolla

# The network nodes are where your l3-agent and loadbalancers will run
# This can be the same as a host in the control group
[network]
control01

[compute]
compute01   ansible_host=10.0.0.31  ansible_python_interpreter=/usr/bin/python3

[monitoring]
control01

# When compute nodes and control nodes use different interfaces,
# you can specify "api_interface" and other interfaces like below:
#compute01 neutron_external_interface=eth0 api_interface=em1 storage_interface=em1 tunnel_interface=em1

[storage]
storage01   ansible_host=10.0.0.41  ansible_python_interpreter=/usr/bin/python3

[deployment]
localhost ansible_connection=local
```

## Configure globals.yml
```
---
kolla_base_distro: "ubuntu"
kolla_install_type: "binary"
openstack_release: "train"
kolla_internal_vip_address: "10.0.0.20"
docker_registry: "registry.cn-guangzhou.aliyuncs.com"
docker_registry_username: "aliyun3882791286"
docker_namespace: "lunwei"
network_interface: "ens33"
neutron_external_interface: "ens34"
enable_cinder: "yes"
enable_cinder_backend_lvm: "yes"
nova_compute_virt_type: "qemu"
```

## Check Inventory
```
source venv/bin/activate
ansible -i multinode all -m ping
```

## Generate Password
In the next step generate the password for the services. These generated passwords will be stored in `/etc/kolla/passwords.yml` file
```
kolla-genpwd
```

## Modify Password
For convenience, change the `keystone_admin_password` which is used to login in dashboard. By the way, adding `docker_registry_password` for docker login:
```
sed -i 's#keystone_admin_password:.*#keystone_admin_password: kolla#g' /etc/kolla/passwords.yml
sed -i 's#docker_registry_password:.*#docker_registry_password: my_password#g' /etc/kolla/passwords.yml
```

## Perform Deployment
Now in the next step we are going to install bootstrap servers.
```
kolla-ansible -i multinode bootstrap-servers
```
Always do deployment checks.
```
kolla-ansible -i multinode prechecks
```
In the last step we will perform deployment.
```
kolla-ansible -i multinode deploy
```
Now install curl and the Openstack client tools
```
sudo apt install -y curl python-openstackclient
```

## Upload images to private hub (optional)
You can pull images before depoly:
```
kolla-ansible pull
```
Add local private hub to docker config:
```
sudo tee /etc/docker/daemon.json <<-'EOF'
{
    "insecure-registries": [
        "10.0.0.10:4000"
    ],
    "log-opts": {
        "max-file": "5",
        "max-size": "50m"
    }
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```
To upload these images to local private hub:
```
for i in $(sudo docker images | grep train | awk '{print $1":"$2}')
do
  bash auto_image_push.sh $i
done
```
update `/etc/kolla/globals.yml` as below if you use a local private hub to deploy:
```
---
kolla_base_distro: "ubuntu"
kolla_install_type: "binary"
openstack_release: "train"
kolla_internal_vip_address: "10.0.0.20"
docker_registry: "10.0.0.10:4000"
docker_namespace: "kolla"
network_interface: "ens33"
neutron_external_interface: "ens34"
enable_cinder: "yes"
enable_cinder_backend_lvm: "yes"
nova_compute_virt_type: "qemu"
```

## Post Deployment
Now create `admin-openrc.sh` file that basically contains admin credentials.
```
kolla-ansible post-deploy /etc/kolla/admin-openrc.sh
```
Now in the next step we will run the deployment.
```
cp /etc/kolla/admin-openrc.sh .
source admin-openrc.sh
```
The initialization script will create virtual machine resources such as cirros image, network, subnet, routing, security group, specification, quota, etc.
```
cd venv/share/kolla-ansible
./init-runonce
```
Navigate `http://10.0.0.20` to login into the dashboard of OpenStack.
```
username: admin
password: kolla
```
