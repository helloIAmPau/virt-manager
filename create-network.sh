#!/usr/bin/env bash

virsh net-define ./overlay-network.xml
virsh net-list --all
virsh net-start overlay
virsh net-autostart overlay
virsh net-list --all
