#!/bin/bash
set -e
touch /etc/puppet/hiera.yaml
#https://github.com/mitchellh/vagrant/issues/1673
#https://github.com/dm-cracked-sean-knight/packer-templates/commit/bfec91c086e3dd318d4c16b3658a9db4a5c08d15
sed -i -r -e 's/^([# ]+)?(mesg n)/# \2/' /root/.profile

#https://github.com/comperiosearch/vagrant-elk-box/issues/19
sed -e '/templatedir/ s/^#*/#/' -i.back /etc/puppet/puppet.conf
