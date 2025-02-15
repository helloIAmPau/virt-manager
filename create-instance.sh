#!/usr/bin/env bash

NAME=$1;
SANDBOX_ROOT="$HOME/vms";
SANDBOX="$SANDBOX_ROOT/$NAME";

VARIANT="ubuntu24.04";
BASE_IMAGE_URL="https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img";
BASE_IMAGE="$(pwd)/ubuntu_24.04.img";

CLOUD_INIT_CONFIG="$(pwd)/user-data.txt";
CLOUD_INIT="$SANDBOX/user-data.img";

DISK_FILE="$SANDBOX/ubuntu-vm-disk.qcow2";
DISK_SIZE="100G";

UEFI_FOLDER="$SANDBOX/uefi";
UEFI_CODE="$UEFI_FOLDER/OVMF_CODE-pure-efi.fd";
UEFI_VARS="$UEFI_FOLDER/OVMF_VARS-pure-efi.fd";

UEFI_BASE_FOLDER="$(pwd)/uefi";
UEFI_BASE_CODE="$UEFI_BASE_FOLDER/OVMF_CODE-pure-efi.fd";
UEFI_BASE_VARS="$UEFI_BASE_FOLDER/OVMF_VARS-pure-efi.fd";

MEMORY="$((2 * 1024))";
CPUS="2";
GPU_ADDRESS="01:00.0";

if [ "$1" == "" ]; then
  echo "Provide a name for the vm";
  exit -1;
fi

mkdir -p $SANDBOX;

if [ ! -f "$BASE_IMAGE" ]; then
  echo "Downloading base ubuntu image";
  curl $BASE_IMAGE_URL > $BASE_IMAGE;
fi

if [ ! -f "$DISK_FILE" ]; then
  echo "Creating disk";
  qemu-img create -b $BASE_IMAGE -F qcow2 -f qcow2 $DISK_FILE $DISK_SIZE;
fi

if [ ! -f "$CLOUD_INIT" ]; then
  echo "Creating cloud init disk";
  cloud-localds $CLOUD_INIT $CLOUD_INIT_CONFIG
fi

if [ ! -f "$UEFI_CODE" ]; then
  echo "Adding custom UEFI";
  cp -rfv "$UEFI_BASE_CODE" "$UEFI_CODE";
fi

if [ ! -f "$UEFI_VARS" ]; then
  echo "Adding custom UEFI vars";
  cp -rfv "$UEFI_BASE_VARS" "$UEFI_VARS";
fi


sudo virt-install \
  --os-variant $VARIANT \
  --name $NAME \
  --virt-type kvm \
  --import \
  --memory $MEMORY \
  --vcpu $CPUS \
  --cpu host-passthrough \
  --disk path=$DISK_FILE,device=disk \
  --disk path=$CLOUD_INIT,format=raw \
  --boot loader=$UEFI_CODE,loader.readonly=yes,loader.secure='no',loader.type=pflash,nvram=$UEFI_VARS \
  --autostart \
  --graphics none \
  --network network=overlay \
#  --hostdev "$GPU_ADDRESS",address.type=pci,address.multifunction=on \
