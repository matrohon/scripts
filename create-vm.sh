#!/bin/bash

#VM1=$1
#VM2=$2

if [ -z "$OS_TENANT_NAME" ]; then
  echo "openstack environ variables is not set"  
  exit
fi

TENANT_ID=$(keystone --os-tenant-name admin --os-username admin --os-password password tenant-list | grep " $OS_TENANT_NAME " | awk '{print $2}')
#PRINET="${OS_TENANT_NAME}"

# create private network
#NET_ID=$(quantum net-list | awk "/ private / { print \$2 }")
#echo "NET=$NET_ID"
NET_GRE=$(neutron --os-tenant-name admin --os-username admin --os-password password net-create --tenant_id $TENANT_ID net-gre100 --provider:network_type gre --provider:segmentation_id 100 | awk '/ id /{print $4}')
neutron subnet-create --gateway 10.0.0.254 net-gre100 10.0.0.0/24
NET_VXLAN=$(neutron  --os-tenant-name admin --os-username admin --os-password password net-create --tenant_id $TENANT_ID net-vxlan100 --provider:network_type vxlan --provider:segmentation_id 100 | awk '/ id /{print $4}')
neutron subnet-create --gateway 10.0.0.254 net-vxlan100 10.0.0.0/24
#
# boot instance
#
#if [ ! -z "$VM1" ]; then
#  IMAGE_ID=$(glance add name=Ubuntu-12.04 is_public=true container_format=ovf disk_format=qcow2 < ./precise-server-cloudimg-amd64-disk1.img | awk '{print $6}')
IMAGE_ID=$(glance image-list | grep ami | head -n 1 | awk '{print $2}')
echo "IMAGE=$IMAGE_ID"
for i in 1 2 
do
  VM_VXLAN=$(nova boot --image=$IMAGE_ID --flavor=1 --nic net-id=$NET_VXLAN vm$i-vxlan | awk '/ id /{print $4}')
  nova show $VM_VXLAN
  SERVER=$(nova-manage vm list | grep vm$i-vxlan | awk '{print $2}')
  echo "host for vm$i-vxlan : $SERVER"
done
for i in 1 2 
do
  VM_GRE=$(nova boot --image=$IMAGE_ID --flavor=1 --nic net-id=$NET_GRE vm$i-gre | awk '/ id /{print $4}')
  nova show $VM_GRE
  SERVER=$(nova-manage vm list | grep vm$i-gre | awk '{print $2}')
  echo "host for vm$i-gre : $SERVER"
done
