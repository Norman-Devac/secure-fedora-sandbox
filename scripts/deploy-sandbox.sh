#!/usr/bin/env bash
set -e

VM_NAME="VM-NAME-HERE"
DISK_PATH="Windows.vdi"
STORAGE_CTRL="NVMe-Controller"
NETWORK_NAME="sandbox-net"

# 1. Establish baseline network bandwidth limits
VBoxManage bandwidthctl "$VM_NAME" add "LimitGroup" --type network --limit 10M 2>/dev/null || true

# 2. Apply monolithic hypervisor configuration
VBoxManage modifyvm "$VM_NAME" \
  --nic1=intnet --intnet1="$NETWORK_NAME" --nic-type1=virtio --nic-promisc1=deny \
  --nic2=none --nic3=none --nic4=none --nic5=none --nic6=none --nic7=none --nic8=none \
  --nic-bandwidth-group1="LimitGroup" \
  --boot1=disk --boot2=none --boot3=none --boot4=none \
  --nested-paging=on --large-pages=on --page-fusion=off --x86-vtx-vpid=on \
  --spec-ctrl=on --l1d-flush-on-vm-entry=on --mds-clear-on-vm-entry=on --ibpb-on-vm-entry=on --ibpb-on-vm-exit=on \
  --hpet=on \
  --cpus=4 --cpu-execution-cap=100 \
  --usb=off --usbehci=off --usbxhci=off \
  --audio=none --uart1=off --lpt1=off \
  --iommu=none \
  --graphicscontroller=vboxsvga --accelerate3d=off --vram=128 \
  --default-frontend=gui \
  --mouse=usbtablet \
  --clipboard-mode=disabled --clipboard-file-transfers=off --drag-and-drop=disabled \
  --recording=off --tracing-enabled=off \
  --firmware=efi64 \
  --bios-boot-menu=disabled --bios-logo-display-time=0 \
  --tpm-type=2.0 --paravirt-provider=hyperv \
  --teleporter=off --vrde=off --guestmemoryballoon=0 \
  --nested-hw-virt=off

# 3. Degrade Time Stamp Counter and sever host temporal synchronization
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
VBoxManage setextradata "$VM_NAME" "VBoxInternal/TM/TSCTiedToExecution" 1

# Shift the boot epoch backwards by 30 days (2,592,000,000 milliseconds)
VBoxManage modifyvm "$VM_NAME" --bios-system-time-offset=-2592000000

# 4. Enforce UEFI Secure Boot chain with Microsoft parameters
VBoxManage modifynvram "$VM_NAME" inituefivarstore
VBoxManage modifynvram "$VM_NAME" enrollorclpk
VBoxManage modifynvram "$VM_NAME" enrollmssignatures
VBoxManage modifynvram "$VM_NAME" secureboot --enable

# 5. Lock storage interactions, provision NVMe, and attach the disk medium
VBoxManage storagectl "$VM_NAME" --name "$STORAGE_CTRL" --add=pcie --controller=NVMe --portcount=1 --hostiocache=off
VBoxManage storageattach "$VM_NAME" --storagectl "$STORAGE_CTRL" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

# 6. Seal the disk state and verify shared folder isolation
if VBoxManage showvminfo "$VM_NAME" | grep -q "host_share"; then
    VBoxManage sharedfolder remove "$VM_NAME" --name "host_share" 2>/dev/null || true
    VBoxManage sharedfolder remove "$VM_NAME" --name "host_share" --transient 2>/dev/null || true
fi
VBoxManage modifymedium "$DISK_PATH" --type immutable --autoreset=on#!/usr/bin/env bash
set -e

VM_NAME="VM-NAME-HERE"
DISK_PATH="Windows.vdi"
STORAGE_CTRL="NVMe-Controller"
NETWORK_NAME="sandbox-net"

# 1. Establish baseline network bandwidth limits
VBoxManage bandwidthctl "$VM_NAME" add "LimitGroup" --type network --limit 10M 2>/dev/null || true

# 2. Apply monolithic hypervisor configuration
VBoxManage modifyvm "$VM_NAME" \
  --nic1=intnet --intnet1="$NETWORK_NAME" --nic-type1=virtio --nic-promisc1=deny \
  --nic2=none --nic3=none --nic4=none --nic5=none --nic6=none --nic7=none --nic8=none \
  --nic-bandwidth-group1="LimitGroup" \
  --boot1=disk --boot2=none --boot3=none --boot4=none \
  --nested-paging=on --large-pages=on --page-fusion=off --x86-vtx-vpid=on \
  --spec-ctrl=on --l1d-flush-on-vm-entry=on --mds-clear-on-vm-entry=on --ibpb-on-vm-entry=on --ibpb-on-vm-exit=on \
  --hpet=on \
  --cpus=4 --cpu-execution-cap=100 \
  --usb=off --usbehci=off --usbxhci=off \
  --audio=none --uart1=off --lpt1=off \
  --iommu=none \
  --graphicscontroller=vboxsvga --accelerate3d=off --vram=128 \
  --default-frontend=gui \
  --mouse=usbtablet \
  --clipboard-mode=disabled --clipboard-file-transfers=off --drag-and-drop=disabled \
  --recording=off --tracing-enabled=off \
  --firmware=efi64 \
  --bios-boot-menu=disabled --bios-logo-display-time=0 \
  --tpm-type=2.0 --paravirt-provider=hyperv \
  --teleporter=off --vrde=off --guestmemoryballoon=0 \
  --nested-hw-virt=off

# 3. Degrade Time Stamp Counter and sever host temporal synchronization
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
VBoxManage setextradata "$VM_NAME" "VBoxInternal/TM/TSCTiedToExecution" 1

# Shift the boot epoch backwards by 30 days (2,592,000,000 milliseconds)
VBoxManage modifyvm "$VM_NAME" --bios-system-time-offset=-2592000000

# 4. Enforce UEFI Secure Boot chain with Microsoft parameters
VBoxManage modifynvram "$VM_NAME" inituefivarstore
VBoxManage modifynvram "$VM_NAME" enrollorclpk
VBoxManage modifynvram "$VM_NAME" enrollmssignatures
VBoxManage modifynvram "$VM_NAME" secureboot --enable

# 5. Lock storage interactions, provision NVMe, and attach the disk medium
VBoxManage storagectl "$VM_NAME" --name "$STORAGE_CTRL" --add=pcie --controller=NVMe --portcount=1 --hostiocache=off
VBoxManage storageattach "$VM_NAME" --storagectl "$STORAGE_CTRL" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

# 6. Seal the disk state and verify shared folder isolation
if VBoxManage showvminfo "$VM_NAME" | grep -q "host_share"; then
    VBoxManage sharedfolder remove "$VM_NAME" --name "host_share" 2>/dev/null || true
    VBoxManage sharedfolder remove "$VM_NAME" --name "host_share" --transient 2>/dev/null || true
fi
VBoxManage modifymedium "$DISK_PATH" --type immutable --autoreset=on#!/usr/bin/env bash
set -e

VM_NAME="VM-NAME-HERE"
DISK_PATH="Windows.vdi"
STORAGE_CTRL="NVMe-Controller"
NETWORK_NAME="sandbox-net"

# 1. Establish baseline network bandwidth limits
VBoxManage bandwidthctl "$VM_NAME" add "LimitGroup" --type network --limit 10M 2>/dev/null || true

# 2. Apply monolithic hypervisor configuration
VBoxManage modifyvm "$VM_NAME" \
  --nic1=intnet --intnet1="$NETWORK_NAME" --nic-type1=virtio --nic-promisc1=deny \
  --nic2=none --nic3=none --nic4=none --nic5=none --nic6=none --nic7=none --nic8=none \
  --nic-bandwidth-group1="LimitGroup" \
  --boot1=disk --boot2=none --boot3=none --boot4=none \
  --nested-paging=on --large-pages=on --page-fusion=off --x86-vtx-vpid=on \
  --spec-ctrl=on --l1d-flush-on-vm-entry=on --mds-clear-on-vm-entry=on --ibpb-on-vm-entry=on --ibpb-on-vm-exit=on \
  --hpet=on \
  --cpus=4 --cpu-execution-cap=100 \
  --usb=off --usbehci=off --usbxhci=off \
  --audio=none --uart1=off --lpt1=off \
  --iommu=none \
  --graphicscontroller=vboxsvga --accelerate3d=off --vram=128 \
  --default-frontend=gui \
  --mouse=usbtablet \
  --clipboard-mode=disabled --clipboard-file-transfers=off --drag-and-drop=disabled \
  --recording=off --tracing-enabled=off \
  --firmware=efi64 \
  --bios-boot-menu=disabled --bios-logo-display-time=0 \
  --tpm-type=2.0 --paravirt-provider=hyperv \
  --teleporter=off --vrde=off --guestmemoryballoon=0 \
  --nested-hw-virt=off#!/usr/bin/env bash
set -e

VM_NAME="VM-NAME-HERE"
DISK_PATH="Windows.vdi"
STORAGE_CTRL="NVMe-Controller"
NETWORK_NAME="sandbox-net"

# 1. Establish baseline network bandwidth limits
VBoxManage bandwidthctl "$VM_NAME" add "LimitGroup" --type network --limit 10M 2>/dev/null || true

# 2. Apply monolithic hypervisor configuration
VBoxManage modifyvm "$VM_NAME" \
  --nic1=intnet --intnet1="$NETWORK_NAME" --nic-type1=virtio --nic-promisc1=deny \
  --nic2=none --nic3=none --nic4=none --nic5=none --nic6=none --nic7=none --nic8=none \
  --nic-bandwidth-group1="LimitGroup" \
  --boot1=disk --boot2=none --boot3=none --boot4=none \
  --nested-paging=on --large-pages=on --page-fusion=off --x86-vtx-vpid=on \
  --spec-ctrl=on --l1d-flush-on-vm-entry=on --mds-clear-on-vm-entry=on --ibpb-on-vm-entry=on --ibpb-on-vm-exit=on \
  --hpet=on \
  --cpus=4 --cpu-execution-cap=100 \
  --usb=off --usbehci=off --usbxhci=off \
  --audio=none --uart1=off --lpt1=off \
  --iommu=none \
  --graphicscontroller=vboxsvga --accelerate3d=off --vram=128 \
  --default-frontend=gui \
  --mouse=usbtablet \
  --clipboard-mode=disabled --clipboard-file-transfers=off --drag-and-drop=disabled \
  --recording=off --tracing-enabled=off \
  --firmware=efi64 \
  --bios-boot-menu=disabled --bios-logo-display-time=0 \
  --tpm-type=2.0 --paravirt-provider=hyperv \
  --teleporter=off --vrde=off --guestmemoryballoon=0 \
  --nested-hw-virt=off

# 3. Degrade Time Stamp Counter and sever host temporal synchronization
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
VBoxManage setextradata "$VM_NAME" "VBoxInternal/TM/TSCTiedToExecution" 1

# Shift the boot epoch backwards by 30 days (2,592,000,000 milliseconds)
VBoxManage modifyvm "$VM_NAME" --bios-system-time-offset=-2592000000

# 4. Enforce UEFI Secure Boot chain with Microsoft parameters
VBoxManage modifynvram "$VM_NAME" inituefivarstore
VBoxManage modifynvram "$VM_NAME" enrollorclpk
VBoxManage modifynvram "$VM_NAME" enrollmssignatures
VBoxManage modifynvram "$VM_NAME" secureboot --enable

# 5. Lock storage interactions, provision NVMe, and attach the disk medium
VBoxManage storagectl "$VM_NAME" --name "$STORAGE_CTRL" --add=pcie --controller=NVMe --portcount=1 --hostiocache=off
VBoxManage storageattach "$VM_NAME" --storagectl "$STORAGE_CTRL" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

# 6. Seal the disk state and verify shared folder isolation
if VBoxManage showvminfo "$VM_NAME" | grep -q "host_share"; then
    VBoxManage sharedfolder remove "$VM_NAME" --name "host_share" 2>/dev/null || true
    VBoxManage sharedfolder remove "$VM_NAME" --name "host_share" --transient 2>/dev/null || true
fi
VBoxManage modifymedium "$DISK_PATH" --type immutable --autoreset=on

# 3. Degrade Time Stamp Counter and sever host temporal synchronization
VBoxManage setextradata "$VM_NAME" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
VBoxManage setextradata "$VM_NAME" "VBoxInternal/TM/TSCTiedToExecution" 1

# Shift the boot epoch backwards by 30 days (2,592,000,000 milliseconds)
VBoxManage modifyvm "$VM_NAME" --bios-system-time-offset=-2592000000

# 4. Enforce UEFI Secure Boot chain with Microsoft parameters
VBoxManage modifynvram "$VM_NAME" inituefivarstore
VBoxManage modifynvram "$VM_NAME" enrollorclpk
VBoxManage modifynvram "$VM_NAME" enrollmssignatures
VBoxManage modifynvram "$VM_NAME" secureboot --enable

# 5. Lock storage interactions, provision NVMe, and attach the disk medium
VBoxManage storagectl "$VM_NAME" --name "$STORAGE_CTRL" --add=pcie --controller=NVMe --portcount=1 --hostiocache=off
VBoxManage storageattach "$VM_NAME" --storagectl "$STORAGE_CTRL" --port 0 --device 0 --type hdd --medium "$DISK_PATH"

# 6. Seal the disk state and verify shared folder isolation
if VBoxManage showvminfo "$VM_NAME" | grep -q "host_share"; then
    VBoxManage sharedfolder remove "$VM_NAME" --name "host_share" 2>/dev/null || true
    VBoxManage sharedfolder remove "$VM_NAME" --name "host_share" --transient 2>/dev/null || true
fi
VBoxManage modifymedium "$DISK_PATH" --type immutable --autoreset=on