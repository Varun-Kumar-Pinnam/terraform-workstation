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

# Add user to docker group  
sudo usermod -aG docker ec2-user

# eksctl + kubectl (system-wide; cloud-init runs as root)
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH

curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm -f eksctl_$PLATFORM.tar.gz
sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm -f /tmp/eksctl

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

# Everything below must run as ec2-user with HOME=/home/ec2-user.
# Do NOT use bare `sudo -u ec2-user bash` — it does not affect following lines, and under
# cloud-init the subshell exits immediately, so `cd ~` and git clone would still be root (/root).
sudo -u ec2-user -H bash -s <<'EOF'
set -e
export PATH=$PATH:/usr/local/bin
cd /home/ec2-user

if [ ! -d roboshop-docker ]; then
  git clone https://github.com/Varun-Kumar-Pinnam/roboshop-docker.git
fi

if [ ! -d eksctl ]; then
  git clone https://github.com/Varun-Kumar-Pinnam/eksctl.git
fi

if [ ! -d k8-resources ]; then
  git clone https://github.com/Varun-Kumar-Pinnam/k8-resources.git
fi

if [ ! -d k8-roboshop ]; then
  git clone https://github.com/Varun-Kumar-Pinnam/k8-roboshop.git
fi

cd /home/ec2-user/eksctl
/usr/local/bin/eksctl create cluster --config-file=eks.yaml

# Authenticate kubectl with the cluster
aws eks update-kubeconfig --region us-east-1 --name roboshop

EOF

# kubens / k9s (install into ec2-user home)
sudo -u ec2-user -H bash -s <<'EOF'
set -e
curl -sS https://webi.sh/kubens | sh
curl -sS https://webi.sh/k9s | sh
if [ -f /home/ec2-user/.config/envman/PATH.env ]; then
  # shellcheck source=/dev/null
  . /home/ec2-user/.config/envman/PATH.env
fi
EOF

echo "Completed"