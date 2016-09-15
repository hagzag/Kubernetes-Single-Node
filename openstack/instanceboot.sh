#!/bin/bash
# 
# Copyright 2016 
# nissim bitan 
# niv azriel

LOG_FILE=/var/log/k8s-singlenode-install.log
ANSIBLE_PKG=/ansible_2.1.1.0-1ppa~trusty_all.deb
#ANSIBLE_PKG=/opt/ansible_1.9.6-1ppa~trusty_all.deb
#ANSIBLE_URL=https://launchpad.net/~ansible/+archive/ubuntu/ansible-1.9/+files/ansible_1.9.6-1ppa~trusty_all.deb
ANSIBLE_URL=https://launchpad.net/~ansible/+archive/ubuntu/ansible/+files/ansible_2.1.1.0-1ppa~trusty_all.deb

function validate_ansible_reqs() {
  for pkg in sshpass python-netaddr python-yaml python-support python-jinja2 python-paramiko python-markupsafe;
  do
    is_package_installed ${pkg} || install_package ${pkg}
    is_package_installed ${pkg} || (echo "Error installing packages '${pkg}'" && exit 2)
  done
}

function install_ansible() {
  echo "Installing Ansible" | tee -a ${LOG_FILE}
  validate_ansible_reqs
  [ ! -f $ANSIBLE_PKG ] && wget --continue $ANSIBLE_URL -O $ANSIBLE_PKG
  dpkg -i $ANSIBLE_PKG
  apt-get -f install --yes --force-yes
  [ $(ansible --version | grep 2\.1\.1\.0 | wc -l) != 1 ] && echo "*** Error while installing Ansible, aborting execution." && exit 1
  echo "Installed Ansible version: $(ansible --version)"
}


function kubernetes_single_node() {
  set -x
  install_ansible
  echo "Installing kubernetes single node from git"
  if [ ! -d "/opt/install" ]; then
    mkdir /opt/install
    apt-get update && apt-get install git -y
    cd /opt/install && git clone https://github.com/niso120b/Kubernetes-Single-Node.git .
    cd /opt/install/scripts && ./deploy-local-cluster.sh
  else
    echo "*** Error to deploy a kubernetes on single node server /etc/install exists" && exit 1
  fi
}

# Log all output to file.
kubernetes_single_node 2>&1 | tee -a ${LOG_FILE}
