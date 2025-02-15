# Pau's KVM tools

A set of tools I use to handle my home lab KVM architecture

## Bare Metal Configuration

* __CPU:__ Intel(R) Core(TM) i9-9900K CPU @ 3.60GHz
* __MEMORY:__ 16GB Corsair + 16GB Kingston HyperX
* __GPU:__ NVIDIA GeForce RTX 2060
* __DISK:__ LVM (500GB Samsung SM981 + 250GB Samsung SM961 + 500GB Samsung evo something)
* __STORAGE:__ 2 * 4TB Raid 1 Hard Drives 
* __OS:__ Ubuntu 24.04.1 LTS

## Setup

Below are the steps to reproduce to configure the host.

### Install deps 

```
sudo apt install virtiofsd qemu-kvm virt-manager cloud-image-utils libvirt-daemon libvirt-clients
```

### Define a bridge interface for the VMs

```
cp netplan-bridge.yaml.template /etc/netplan/00-default.yml
```
Edit:
* eno1 -> must be your interface name
* 192.168.0.99/24 -> is the ip address your host must negotiate (we use static ips)
* 192.168.0.1/24 -> your gateway ip

usually ubuntu has a default netplan configuration called 50-cloud-init.yml. You must remove it.

```
sudo netplan generate
sudo netplan apply
```

verify that the configuration works by looking at

```
ip addr
ip route
```

### Define an overlay network on br0 bridge

A preconfigured network definition for the `br0` bridge can be applied using the following script

```
./create-network.sh
```

### Prepare IOMMU for GPU passthrough

GPUs must be disabled on the host machine before attaching them to a virtual machine.
To do this, we assign them a dummy driver (vfio-pci).

```
sudo modprobe vfio-pci
```

_Note:_ PCIe slots define IOMMU groups not necessarily isolated. You must disable all the devices
you find in the GPU group.

```
./show-pci-groups.sh
```

shows the IOMMU groups for your host. Mine are:

```
IOMMU Group 0:
        00:02.0 VGA compatible controller [0300]: Intel Corporation CoffeeLake-S GT2 [UHD Graphics 630] [8086:3e98] (rev 02)
IOMMU Group 1:
        00:00.0 Host bridge [0600]: Intel Corporation 8th/9th Gen Core 8-core Desktop Processor Host Bridge/DRAM Registers [Coffee Lake S] [8086:3e30] (rev 0d)
IOMMU Group 2:
        00:01.0 PCI bridge [0604]: Intel Corporation 6th-10th Gen Core Processor PCIe Controller (x16) [8086:1901] (rev 0d)
        01:00.0 VGA compatible controller [0300]: NVIDIA Corporation TU104 [GeForce RTX 2060] [10de:1e89] (rev a1)
        01:00.1 Audio device [0403]: NVIDIA Corporation TU104 HD Audio Controller [10de:10f8] (rev a1)
        01:00.2 USB controller [0c03]: NVIDIA Corporation TU104 USB 3.1 Host Controller [10de:1ad8] (rev a1)
        01:00.3 Serial bus controller [0c80]: NVIDIA Corporation TU104 USB Type-C UCSI Controller [10de:1ad9] (rev a1)
IOMMU Group 3:
        00:14.0 USB controller [0c03]: Intel Corporation Cannon Lake PCH USB 3.1 xHCI Host Controller [8086:a36d] (rev 10)
        00:14.2 RAM memory [0500]: Intel Corporation Cannon Lake PCH Shared SRAM [8086:a36f] (rev 10)
IOMMU Group 4:
        00:16.0 Communication controller [0780]: Intel Corporation Cannon Lake PCH HECI Controller [8086:a360] (rev 10)
IOMMU Group 5:
        00:17.0 RAID bus controller [0104]: Intel Corporation SATA Controller [RAID mode] [8086:2822] (rev 10)
IOMMU Group 6:
        00:1b.0 PCI bridge [0604]: Intel Corporation Cannon Lake PCH PCI Express Root Port #17 [8086:a340] (rev f0)
IOMMU Group 7:
        00:1b.4 PCI bridge [0604]: Intel Corporation Cannon Lake PCH PCI Express Root Port #21 [8086:a32c] (rev f0)
IOMMU Group 8:
        00:1c.0 PCI bridge [0604]: Intel Corporation Cannon Lake PCH PCI Express Root Port #1 [8086:a338] (rev f0)
IOMMU Group 9:
        00:1d.0 PCI bridge [0604]: Intel Corporation Cannon Lake PCH PCI Express Root Port #9 [8086:a330] (rev f0)
IOMMU Group 10:
        00:1f.0 ISA bridge [0601]: Intel Corporation Z390 Chipset LPC/eSPI Controller [8086:a305] (rev 10)
        00:1f.3 Audio device [0403]: Intel Corporation Cannon Lake PCH cAVS [8086:a348] (rev 10)
        00:1f.4 SMBus [0c05]: Intel Corporation Cannon Lake PCH SMBus Controller [8086:a323] (rev 10)
        00:1f.5 Serial bus controller [0c80]: Intel Corporation Cannon Lake PCH SPI Controller [8086:a324] (rev 10)
        00:1f.6 Ethernet controller [0200]: Intel Corporation Ethernet Connection (7) I219-V [8086:15bc] (rev 10)
IOMMU Group 11:
        03:00.0 Non-Volatile memory controller [0108]: Samsung Electronics Co Ltd NVMe SSD Controller SM981/PM981/PM983 [144d:a808]
IOMMU Group 12:
        05:00.0 Non-Volatile memory controller [0108]: Samsung Electronics Co Ltd NVMe SSD Controller SM961/PM961/SM963 [144d:a804]
```

as you can see my GPU is in IOMMU Group 2. I have to disable devices 00:01.0 -> 00:01.3. Edit `passthrough.sh` with the list of devices you need to disable, then run

```
sudo ./passthrough.sh
```

To load the driver at boot first update initramfs by adding

```
vfio_pci
vfio
vfio_iommu_type1
```

to `/etc/initramfs-tools/modules`, run

```
sudo update-initramfs -u
```

and then copy `vfio.conf` to `/etc/modprobe.d` 

### Cloud config configuration

Edit `user-data.txt` to define the initial setup for your VMs. In most cases, you only need to replace 'yourpasswordhere' with the actual password you want to set for the vm.

### Enjoy your VMs

Edit `create-instance.sh` variables with the configuration you need. For a base setup, just focus on

```
DISK_SIZE
MEMORY
CPUS
GPU_ADDRESS (if any)
```

By default, I have commented out the line that attaches the GPU to the VM. Uncomment it as you need.
