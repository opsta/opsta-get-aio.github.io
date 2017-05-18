#!/usr/bin/env bash

set -e -x -u

export OSA_VERSION=${1:-"15.1.3"}

# Update and install required packages
apt update
apt -y dist-upgrade
apt install -y git vim python unzip iotop htop iftop

# Clone OSA
git clone -b $OSA_VERSION https://github.com/openstack/openstack-ansible \
  /opt/openstack-ansible

# Prepare OpenStack Ansible
cd /opt/openstack-ansible/
./scripts/bootstrap-ansible.sh

# Need to source scripts-library.sh for only in cloud user-data to get all
# environment variables
source scripts/scripts-library.sh

# Prepare all-in-one machine
./scripts/bootstrap-aio.sh

# Remove OpenStack Designate since it still not working for all-in-one
rm -f /etc/openstack_deploy/conf.d/designate.yml

# Don't run Tempest since it for the tests
sed -i 's/^tempest_install: .*/tempest_install: no/g;
  s/^tempest_run: .*/tempest_run: no/g' /etc/openstack_deploy/user_variables.yml

# Tweak some configuration
cat << EOF >> /etc/openstack_deploy/user_variables.yml
# Adjust Horizon timezone and session timeout
horizon_time_zone: Asia/Bangkok
horizon_session_timeout: 28800
# To make Horizon can upload via browser
horizon_images_upload_mode: legacy
EOF

# Install OSA all-in-one
./scripts/run-playbooks.sh
