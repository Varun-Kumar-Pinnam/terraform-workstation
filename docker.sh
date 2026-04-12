#!/bin/bash

# We are creating 50GB root disk, but only 20GB is partitioned
# Remaining 30GB we need to extend using below commands
set -e

# Disk extension
sudo growpart /dev/nvme0n1 4
sudo lvextend -L +30G /dev/RootVG/varVol
sudo xfs_growfs /var

# Install Docker
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker
sudo systemctl enable --now docker

#Add user to docker group
sudo usermod -aG docker ec2-user

# Switch to ec2-user properly
sudo -u ec2-user bash 

# Move to home directory
cd ~

# Clone repo
git clone https://github.com/Varun-Kumar-Pinnam/roboshop-docker.git


# eksctl setup
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl

### kubectl setup
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH

#run eksctl
cd ~
git clone https://github.com/Varun-Kumar-Pinnam/eksctl.git
cd /home/ec2-user/eksctl
sudo -u ec2-user eksctl create cluster --config-file=eks.yaml

#kubens installation
curl -sS https://webi.sh/kubens | sh; \
source ~/.config/envman/PATH.env

#k9s installation
curl -sS https://webi.sh/k9s | sh; \
source ~/.config/envman/PATH.env

echo "Completed"