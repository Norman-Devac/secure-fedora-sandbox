#!/usr/bin/env bash

VM_NAME="VM-NAME-HERE"
DISK_PATH="Windows.vdi"

echo "=== INITIATING HYPERVISOR STATE AUDIT ==="

echo -e "\n[+] Network, Firmware, and I/O Execution States:"
VBoxManage showvminfo "$VM_NAME" | grep -E -i "(NIC 1|Boot Device|Nested Paging|Large Pages|Page Fusion|VPID|HPET|Number of CPUs|CPU exec cap|USB|EHCI|XHCI|Audio|UART|LPT|IOMMU|Graphics Controller|VRAM size|Acceleration|Default Frontend|Pointing Device|Clipboard Mode|Drag'n'drop Mode|Recording|Tracing|Firmware|Secure Boot|TPM|Paravirt|Teleporter|VRDE|balloon|Nested VT-x/AMD-V|Host I/O Cache|Shared folders)"

echo -e "\n[+] Microarchitectural Side-Channel Mitigations (Raw Arrays):"
VBoxManage showvminfo "$VM_NAME" --machinereadable | grep -E "(spec-ctrl|l1d-flush|mds-clear|ibpb|biossystemtimeoffset)"

echo -e "\n[+] Quality of Service and Bandwidth Topology:"
VBoxManage bandwidthctl "$VM_NAME" list

echo -e "\n[+] Temporal Epoch and Desynchronization Overrides:"
VBoxManage getextradata "$VM_NAME" enumerate | grep -E "(GetHostTimeDisabled|TSCTiedToExecution)"

echo -e "\n[+] Cryptographic Storage Medium Verification:"
VBoxManage showmediuminfo "$DISK_PATH" | grep -E -i "(Type|Auto-Reset)"