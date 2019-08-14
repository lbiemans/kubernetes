#! /bin/sh

# Set variables

role=$1

# Assumptions:
# For now we use IPv4
# The network range is: 10.244.0.0/16
# The POD network is Flannel
# The container runtime is Docker

# Disable swap
swapoff -a

install_docker() {
# Refresh the apt database
apt clean && apt update

# Install packages

apt-get -y install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common

# Get the docker key and VERIFY IT!!

curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

# Enable the docker repository

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

# Install docker, the currently (2019-08-14) latest working version is: 18.09, see: https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.15.md
apt clean && apt update
apt -y install docker-ce=5:18.09.8~3-0~debian-buster

# Make docker use systemd
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker
}

# Great now we have docker installed, let's install kubernetes
# To do so we need to know if this is a worker or a master node..

# Create a user (kubeusr) for use later on

adduser \
   --system \
   --shell /bin/bash \
   --gecos 'User for our kubernetes cluster' \
   --group \
   --disabled-password \
   --home /var/lib/kubeusr \
   kubeusr

# Enable the repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt clean && apt update

# Install the packages

apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

kubemaster() {
# Ask for the network range
echo "What IPv4 range would you like to use (cidr notation)? e.g. 10.244.0.0/16"
read kubenetrange
# Ask for the IPv4 address used to connect nodes
echo "To what IPv4 address should we listen for connections? This IP must be configured on this system and should be reachable."
read kubeadmaddr

# Let's initialise the cluster
kubeadm init --pod-network-cidr=$kubenetrange --apiserver-advertise-address=$kubeadmaddr

# Finish this part of the setup
mkdir -p ~kubeusr/.kube
cp -i /etc/kubernetes/admin.conf ~kubeusr/.kube/config
chown -R kubeusr:kubeusr ~kubeusr/.kube/config

# Let's set Flannel as POD network type
su - kubeusr -c "kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/62e44c867a2846fefb68bd5f178daf4da3095ccb/Documentation/kube-flannel.yml"
}

case $role in
	master) echo "This is a master"
		install_docker
                kubemaster;;
	worker) echo "This is a slave":;;
	*) echo "Please choose between a master and a worker node"
esac
