#!/usr/bin/env bash

DEVICES="0000:01:00.0 0000:01:00.1 0000:01:00.2 0000:01:00.3";

for DEVICE in $DEVICES; do
  VENDOR="$(cat /sys/bus/pci/devices/$DEVICE/vendor) $(cat /sys/bus/pci/devices/$DEVICE/device)";

  echo "$DEVICE" > "/sys/bus/pci/devices/$DEVICE/driver/unbind";
  echo "$VENDOR" > /sys/bus/pci/drivers/vfio-pci/new_id;
done
