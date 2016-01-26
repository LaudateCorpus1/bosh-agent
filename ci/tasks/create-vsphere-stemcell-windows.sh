#!/bin/bash

set -e -x

apt-get update
apt-get install -y unzip

BOSH_AGENT_ZIP_URL=$(cat bosh-agent-zip/url)
BOSH_AGENT_SHA=$(unzip -p bosh-agent-zip/bosh-windows-integration-v*.zip commit | cat)
VERSION=$(cat bosh-vsphere-stemcell-version/number)
OVFTOOL_INSTALLATION_PATH=$(find ./ovftool-linux/ -name VMware-ovftool-*.bundle)
chmod +x $OVFTOOL_INSTALLATION_PATH
$OVFTOOL_INSTALLATION_PATH  --required --eulas-agreed

vagrant plugin install vagrant-vsphere

cat > ./metadata.json <<EOF
{
	"provider": "vsphere"
}
EOF

tar -czvf ./dummy.box ./metadata.json
vagrant box add ./dummy.box --name dummy
AGENT_ZIP_URL=$BOSH_AGENT_ZIP_URL vagrant up --provider=vsphere
vagrant halt

ovftool --sourceSSLThumbprint=$VCENTER_FINGERPRINT vi://$VCENTER_USERNAME:$VCENTER_PASSWORD@vcenter.pizza.cf-app.com:443/pizza-boxes-dc/vm/$VM_BASE_PATH/$VM_NAME image.ova
mv image.ova image

IMAGE_SHA=$(sha1sum image | cut -d ' ' -f 1)
cat > ./stemcell.MF <<EOF
---
name: bosh-vsphere-esxi-windows-2012R2-go_agent
version: '$VERSION'
bosh_protocol: 1
sha1: $IMAGE_SHA
operating_system: windows
cloud_properties:
  name: bosh-vsphere-esxi-ubuntu-trusty-go_agent
  version: '3181'
  infrastructure: vsphere
  hypervisor: esxi
  disk: 3072
  disk_format: ovf
  container_format: bare
  os_type: linux
  os_distro: ubuntu
  architecture: x86_64
  root_device_name: /dev/sda1
EOF

cat > ./apply_spec.yml <<EOF
{
	"agent_commit": "$BOSH_AGENT_SHA"
}
EOF

tar -czvf ./bosh-vsphere-stemcell/bosh-stemcell-$VERSION-vsphere-esxi-windows2012R2-go_agent.tgz apply_spec.yml stemcell.MF image
