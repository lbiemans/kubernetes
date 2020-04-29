#! /bin/bash

# Link certificates
ln -s /usr/share/ca-certificates/mozilla/Starfield_Services_Root_Certificate_Authority_-_G2.crt /usr/local/share/ca-certificates/Starfield_Services_Root_Certificate_Authority_-_G2.crt
ln -s /usr/share/ca-certificates/mozilla/Amazon_Root_CA_1.crt /usr/local/share/ca-certificates/Amazon_Root_CA_1.crt
ln -s /usr/share/ca-certificates/mozilla/GlobalSign_Root_CA_-_R2.crt /usr/local/share/ca-certificates/GlobalSign_Root_CA_-_R2.crt

# Install required packages
apt install -y curl git

# Clone the reposotory and enter it
git clone https://github.com/lbiemans/kubernetes
cd kubernetes

# Give some instructions:

echo "You can now run ./bootstrap.sh worker or master"
echo "master will turn this server into a master"
echo "worker will turn this server into a worker node. Please make sure you have a working master and a join-token before creating a worker"



