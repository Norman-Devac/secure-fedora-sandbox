# Fedora Sandbox Hardening Configuration

This document outlines the exhaustive technical configuration for establishing a cryptographically sealed, deeply isolated sandbox environment using Oracle VM VirtualBox 7.2.14 for a Fedora Linux 44 guest.

## 1. Network Confinement and VirtIO Offloading
Confines the guest to an internal VLAN, drops promiscuous traffic, and utilizes the paravirtualized `virtio` driver to bypass legacy hardware emulation vulnerabilities.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --nic1 intnet --intnet1 "sandbox-net" --nictype1 virtio --nic-promisc1 deny
VBoxManage modifyvm "VM-NAME-HERE" --nic2 none --nic3 none --nic4 none --nic5 none --nic6 none --nic7 none --nic8 none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "NIC 1"
```

**Optimal Output:**
```text
NIC 1: MAC: 080027XXXXXX, Attachment: Internal Network 'sandbox-net', Cable connected: on, Trace: off (file: none), Type: virtio, Reported speed: 0 Mbps, Boot priority: 0, Promisc Policy: deny, Bandwidth group: none
```

## 2. Microarchitectural CPU Isolation
Mitigates side-channel attacks (L1TF, MDS, Spectre) by disabling nested paging, forcing shadow page tables, flushing the L1 data cache and MDS buffers on VM entry, and enforcing absolute branch predictor barriers (IBPB).

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --nested-paging off --large-pages off --page-fusion off
VBoxManage modifyvm "VM-NAME-HERE" --spec-ctrl on --l1d-flush-on-vm-entry on --mds-clear-on-vm-entry on --ibpb-on-vm-entry on --ibpb-on-vm-exit on
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Nested Paging|Large Pages|Page Fusion|L1D|MDS|Speculation|IBPB)"
```

**Optimal Output:**
```text
Nested Paging:   off
Large Pages:     off
Page Fusion:     off
L1D Flush on VM entry: on
MDS Clear on VM entry: on
Speculation Control: on
IBPB on VM entry: on
IBPB on VM exit: on
```

## 3. Execution Throttling and CPU Constraints
Restricts the guest to a single core and caps execution at 50% capacity to prevent host-level resource exhaustion and scheduler-based Denial of Service (DoS) attacks.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --cpus 1 --cpu-execution-cap 50
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "CPU exec cap"
```

**Optimal Output:**
```text
CPU exec cap:    50%
```

## 4. Hardware Perimeter Deactivation (USB, Audio, UART, LPT)
Removes superfluous peripheral controllers to shrink the host-side execution attack surface. Explicitly disables modern and legacy USB emulators and audio bridging.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --usb-xhci off --usb-ehci off --usb-ohci off
VBoxManage modifyvm "VM-NAME-HERE" --audio-enabled off
VBoxManage modifyvm "VM-NAME-HERE" --uart1 off --lpt1 off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(USB|Audio|UART|LPT)"
```

**Optimal Output:**
```text
USB xHCI:        off
USB EHCI:        off
USB OHCI:        off
Audio:           disabled
UART 1:          disabled
LPT 1:           disabled
```

## 5. Interaction Protocol Severance
Disables host-to-guest data bridging, blocking the Extended Data Control Protocols leveraged by modern Wayland compositors in Fedora 44.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --clipboard-mode disabled --clipboard-file-transfers off --drag-and-drop disabled
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E "(Clipboard|Drag'n'drop)"
```

**Optimal Output:**
```text
Clipboard Mode:  disabled
Drag'n'drop Mode: disabled
```

## 6. Time Stamp Counter (TSC) Virtualization
Prevents the guest from utilizing high-resolution timers to execute cache-timing attacks by severing wall-clock synchronization and tying the TSC exclusively to virtual execution cycles.

**Implementation Command:**
```bash
VBoxManage setextradata "VM-NAME-HERE" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
VBoxManage setextradata "VM-NAME-HERE" "VBoxInternal/TM/TSCTiedToExecution" 1
```

**Diagnostic Command:**
```bash
VBoxManage getextradata "VM-NAME-HERE" enumerate | grep -E "(GetHostTimeDisabled|TSCTiedToExecution)"
```

**Optimal Output:**
```text
Key: VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled, Value: 1
Key: VBoxInternal/TM/TSCTiedToExecution, Value: 1
```

## 7. Firmware Integrity and UEFI Secure Boot
Enforces a 64-bit EFI boot structure and cryptographically locks the NVRAM. Introduces the Oracle Platform Key to enforce a strict Secure Boot chain.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --firmware efi64
VBoxManage modifynvram "VM-NAME-HERE" inituefivarstore
VBoxManage modifynvram "VM-NAME-HERE" enrollmssignatures
VBoxManage modifynvram "VM-NAME-HERE" enrollorclpk
VBoxManage modifynvram "VM-NAME-HERE" secureboot --enable
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Firmware"
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Secure Boot"
```

**Optimal Output:**
```text
Firmware:        EFI (64-bit)
Secure Boot:     enabled
```

## 8. Paravirtualization Interface Spoofing
Hides the standard KVM hypercall endpoints from the Fedora 44 kernel, forcing strict architectural emulation and blinding the guest to the hypervisor.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --paravirt-provider none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Paravirt"
```

**Optimal Output:**
```text
Paravirt. Provider: none
```

## 9. Immutable Disk State with Auto-Reset
Forces the primary storage medium into an immutable state and deterministically discards the differential Copy-on-Write layer upon every cold boot.

**Implementation Command:**
*(Note: Replace 'Fedora.vdi' with the exact UUID or absolute file path to the virtual disk image)*
```bash
VBoxManage modifymedium "Fedora.vdi" --type immutable --autoreset on
```

**Diagnostic Command:**
```bash
VBoxManage showmediuminfo "Fedora.vdi" | grep -E -i "(Type|Auto-Reset)"
```

**Optimal Output:**
```text
Type:            immutable
Auto-Reset:      on
```

## 10. Headless Execution Enforcement
Executes the engine without a graphical user interface, removing the host-side window management and display server attack surface.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --default-frontend headless
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Default Frontend"
```

**Optimal Output:**
```text
Default Frontend: headless
```

## 11. Graphics Controller and Acceleration Restrictions
Aligns with Linux kernel 7.0+ requirements by enforcing the VMSVGA controller while strictly disabling 3D hardware translation.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --graphicscontroller vmsvga --accelerate3d off --vram 16
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Graphics Controller|3D Acceleration|VRAM size)"
```

**Optimal Output:**
```text
Graphics Controller: VMSVGA
3D Acceleration: disabled
VRAM size:       16MB
```

## 12. TPM Emulation Severance
Explicitly drops the software Trusted Platform Module (SWTPM) endpoint, eliminating the cryptographic state machine from the guest's accessible ACPI tables.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --tpm-type none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "TPM Type"
```

**Optimal Output:**
```text
TPM Type:        none
```

## 13. High Precision Event Timer (HPET) Deactivation
Disables the microsecond-accurate HPET system timer, significantly degrading the guest's ability to coordinate microarchitectural cache-timing exploits.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --hpet off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "HPET"
```

**Optimal Output:**
```text
HPET:            off
```

## 14. Teleportation and Remote State Interfaces
Nullifies the live-migration Teleporter module and the Remote Desktop Protocol (VRDE) service to seal remote memory injection and network display bridging vectors.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --teleporter off --vrde off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Teleporter|VRDE)"
```

**Optimal Output:**
```text
VRDE:            disabled
Teleporter Enabled: disabled
```

## 15. Nested Hardware Virtualization Constraints
Explicitly blocks VT-x/AMD-V instruction passthrough, stopping the guest from manipulating the host's Virtual Machine Control Structures (VMCS) to orchestrate hypervisor escapes.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --nested-hw-virt off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Nested VT-x/AMD-V"
```

**Optimal Output:**
```text
Nested VT-x/AMD-V: disabled
```

## 16. Dynamic Memory Alteration (Ballooning)
Hard-caps the `virtio-balloon` driver, preventing a compromised guest kernel from inducing Out-Of-Memory (OOM) conditions or exploiting shared memory allocations on the host.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --guestmemoryballoon 0
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Guest memory balloon"
```

**Optimal Output:**
```text
Guest memory balloon: 0MB
```