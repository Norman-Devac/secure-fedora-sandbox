# Oracle VM VirtualBox 7.2.14 Sandbox Architecture Configuration

This document outlines the technical configuration for establishing a sealed, isolated sandbox environment using Oracle VM VirtualBox 7.2.14 for a Fedora Linux guest. The objective is system stability and containment, enforcing deterministic execution constraints, eliminating hardware emulation attack surfaces, and cryptographically securing the firmware boundary against hypervisor escapes.

## 1. NAT Interface Assignment and VirtIO Offloading
Binds the primary network interface strictly to the Network Address Translation (NAT) engine to abstract the internal network stack from the host physical topology. Utilizing the paravirtualized `virtio` driver minimizes hypervisor code execution by bypassing older hardware emulation routines, which are prone to buffer overflows. Actively disables all secondary network interfaces to collapse host-only bridging opportunities.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --nic1 nat --nic-type1 virtio --nic-promisc1 deny
VBoxManage modifyvm "VM-NAME-HERE" --nic2 none --nic3 none --nic4 none --nic5 none --nic6 none --nic7 none --nic8 none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "NIC 1"
```

**Optimal Output:**
```text
NIC 1: MAC: 080027XXXXXX, Attachment: NAT, Cable connected: on, Trace: off (file: none), Type: virtio, Reported speed: 0 Mbps, Boot priority: 0, Promisc Policy: deny, Bandwidth group: none
```

## 2. Host Resolver Isolation
Proxies DNS requests through the host resolver to ensure the guest environment remains completely blind to internal network search domains and corporate DNS topology, neutralizing DNS rebinding and internal reconnaissance attacks.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --natdnsproxy1 on --natdnshostresolver1 on
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" --machinereadable | grep -E -i "natdns"
```

**Optimal Output:**
```text
natdnsproxy1="on"
natdnshostresolver1="on"
```

## 3. Host Loopback Access Denial
Explicitly restricts the NAT engine from routing traffic to the host machine loopback address (127.0.0.1). This prevents a malicious payload from interacting with exposed local RPC servers or administrative interfaces running on the host OS.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --nat-localhostreachable1 off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" --machinereadable | grep -i "localhostreachable"
```

**Optimal Output:**
```text
nat-localhostreachable1="off"
```

## 4. Port Forwarding Eradication
Deletes existing port forwarding rules, ensuring the network engine operates strictly unidirectionally for outbound traffic and preventing the hypervisor from binding internal guest listeners to host ports.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --natpf1 delete "ssh" 2>/dev/null || true
VBoxManage modifyvm "VM-NAME-HERE" --natpf1 delete "http" 2>/dev/null || true
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Rule("
```

**Optimal Output:**
*(No output indicates all rules are properly deleted)*

## 5. Network Bandwidth Throttling
Enforces a strict transmission rate limit of 10 megabytes per second. This restricts the virtual machine ability to participate in distributed denial-of-service (DDoS) campaigns or aggressively scan external networks while remaining sufficient for telemetry and package updates.

**Implementation Command:**
```bash
VBoxManage bandwidthctl "VM-NAME-HERE" add "LimitGroup" --type network --limit 10M 2>/dev/null || true
VBoxManage modifyvm "VM-NAME-HERE" --nicbandwidthgroup1 "LimitGroup"
```

**Diagnostic Command:**
```bash
VBoxManage bandwidthctl "VM-NAME-HERE" list
```

**Optimal Output:**
```text
Name: 'LimitGroup', Type: network, Limit: 10 MBytes/sec
```

## 6. Network Boot Deactivation
Removes pre-boot execution environment (PXE) mechanisms to eliminate firmware-level DHCP parsing vulnerabilities, ensuring the engine boots strictly from cryptographically verified local storage.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --boot1 disk --boot2 none --boot3 none --boot4 none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Boot Device"
```

**Optimal Output:**
```text
Boot Device 1: HardDisk
Boot Device 2: Not Assigned
Boot Device 3: Not Assigned
Boot Device 4: Not Assigned
```

## 7. Shadow Paging and TLB Isolation
Disables Nested Paging (EPT/RVI) to force the hypervisor into using validated Shadow Page Tables. Simultaneously disables Virtual Processor IDs (VPIDs) to guarantee a complete Translation Lookaside Buffer (TLB) flush during every context switch, eradicating TLB-based side-channel leakage.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --nested-paging off --large-pages off --page-fusion off
VBoxManage modifyvm "VM-NAME-HERE" --vtxvpid off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Nested Paging|Large Pages|Page Fusion|VPID)"
```

**Optimal Output:**
```text
Nested Paging:   off
Large Pages:     off
VT-x VPID:       off
Page Fusion:     off
```

## 8. Speculative Execution and Cache Flushing
Mitigates Speculative Execution vulnerabilities (L1TF, MDS) by deterministically flushing the Level 1 data cache and microarchitectural buffers upon every VM entry. Indirect Branch Predictor Barriers (IBPB) are enforced on entry and exit to neutralize Spectre v2 branch target injection attacks.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --spec-ctrl on --l1d-flush-on-vm-entry on --mds-clear-on-vm-entry on --ibpb-on-vm-entry on --ibpb-on-vm-exit on
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" --machinereadable | grep -E "(spec-ctrl|l1d-flush|mds-clear|ibpb)"
```

**Optimal Output:**
```text
spec-ctrl="on"
l1d-flush-on-vm-entry="on"
mds-clear-on-vm-entry="on"
ibpb-on-vm-entry="on"
ibpb-on-vm-exit="on"
```

## 9. Time Stamp Counter (TSC) Virtualization and HPET Deactivation
Severs wall-clock synchronization and ties the TSC exclusively to virtual execution cycles to degrade the resolution of guest timers. Disabling the High Precision Event Timer (HPET) removes secondary hardware timing interfaces, rendering cache-timing attacks (e.g., PRIME+PROBE) mathematically inviable.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --hpet off
VBoxManage setextradata "VM-NAME-HERE" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
VBoxManage setextradata "VM-NAME-HERE" "VBoxInternal/TM/TSCTiedToExecution" 1
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "HPET"
VBoxManage getextradata "VM-NAME-HERE" enumerate | grep -E "(GetHostTimeDisabled|TSCTiedToExecution)"
```

**Optimal Output:**
```text
HPET:            off
Key: VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled, Value: 1
Key: VBoxInternal/TM/TSCTiedToExecution, Value: 1
```

## 10. Execution Throttling and CPU Constraints
Restricts the guest to a single virtual core and caps execution at 50% capacity. This acts as a hard boundary against host resource exhaustion or scheduler starvation attacks (e.g., fork bombs) initiated by a hostile guest kernel.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --cpus 1 --cpu-execution-cap 50
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Number of CPUs|CPU exec cap)"
```

**Optimal Output:**
```text
Number of CPUs:  1
CPU exec cap:    50%
```

## 11. Legacy Hardware and USB Disconnection
Systematically eliminates emulated legacy controllers, which represent highly vulnerable, dense codebases in the hypervisor. This completely detaches USB states, audio backends, and serial/parallel interfaces from the guest.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --usb-ohci off --usb-ehci off --usb-xhci off
VBoxManage modifyvm "VM-NAME-HERE" --audio none
VBoxManage modifyvm "VM-NAME-HERE" --uart1 off --lpt1 off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(USB|Audio|UART|LPT)"
```

**Optimal Output:**
```text
USB OHCI:        off
USB EHCI:        off
USB xHCI:        off
Audio:           disabled
UART 1:          disabled
LPT 1:           disabled
```

## 12. IOMMU and Hardware Translation Lockdown
Since the sandbox utilizes paravirtualized VirtIO networking and lacks physical PCI passthrough, the emulated IOMMU translation layer is unnecessary. Disabling it neutralizes the risk of IOMMU-based out-of-bounds writes.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --iommu none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "IOMMU"
```

**Optimal Output:**
```text
IOMMU:           none
```

## 13. Graphics Controller, 2D/3D Restrictions, and Headless Execution
Denies both 3D translation and 2D video acceleration to prevent malicious primitives from bridging directly to the host physical GPU driver. Enforces the `vmsvga` standard software buffer. Furthermore, operating in `headless` mode terminates display server (Wayland/X11) bridging exploits.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --graphicscontroller vmsvga --accelerate3d off --accelerate-2d-video off --vram 16
VBoxManage modifyvm "VM-NAME-HERE" --defaultfrontend headless
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Graphics Controller|Acceleration|Default Frontend)"
```

**Optimal Output:**
```text
Graphics Controller: VMSVGA
3D Acceleration: off
2D Video Acceleration: off
Default Frontend: headless
```

## 14. Interaction Process and Telemetry Disconnection
Disables host-to-guest data bridging processes (clipboard, drag-and-drop) to close structured data communication sockets. Explicitly deactivates unused telemetry and diagnostic recording endpoints to ensure privileged memory-mapped tracing buffers remain closed.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --clipboard-mode disabled --clipboard-file-transfers disabled --draganddrop disabled
VBoxManage modifyvm "VM-NAME-HERE" --recording off --tracing-enabled off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E "(Clipboard|Drag'n'drop|Recording|Tracing)"
```

**Optimal Output:**
```text
Clipboard Mode:  disabled
Drag'n'drop Mode: disabled
Recording:       disabled
Tracing Enabled: disabled
```

## 15. Firmware Integrity and UEFI Secure Boot NVRAM Cryptography
Forces a 64-bit EFI structure and securely initializes the NVRAM, relying on Oracle Platform Keys to enforce a mandatory Secure Boot chain. Disabling the boot menu and logo delay completely eliminates temporal windows for interactive boot sequence manipulation.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --firmware efi64
VBoxManage modifynvram "VM-NAME-HERE" inituefivarstore
VBoxManage modifynvram "VM-NAME-HERE" enrollmssignatures
VBoxManage modifynvram "VM-NAME-HERE" enrollorclpk
VBoxManage modifynvram "VM-NAME-HERE" secureboot --enable
VBoxManage modifyvm "VM-NAME-HERE" --biosbootmenu disabled --bioslogodisplaytime 0
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Firmware|Secure Boot)"
```

**Optimal Output:**
```text
Firmware:        EFI (64-bit)
Secure Boot:     enabled
```

## 16. TPM Disconnection and Paravirtualization Spoofing
Eliminates the Software Trusted Platform Module (SWTPM) from the guest accessible ACPI tables. Concurrently spoofs the paravirtualization provider (`none`) to mask hypercall endpoints, blinding the guest to hypervisor optimizations and forcing strict hardware emulation.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --tpm-type none
VBoxManage modifyvm "VM-NAME-HERE" --paravirtprovider none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(TPM|Paravirt)"
```

**Optimal Output:**
```text
TPM Type:        none
Paravirt. Provider: none
```

## 17. Teleportation, VRDE, and Memory Ballooning
Seals network-facing remote execution vectors by disabling the Remote Desktop Protocol (VRDE) and the Teleporter (live-migration) service. Hard-caps the `virtio-balloon` driver at zero to prevent guest-induced host Out-Of-Memory (OOM) conditions.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --teleporter off --vrde off
VBoxManage modifyvm "VM-NAME-HERE" --guestmemoryballoon 0
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Teleporter|VRDE|balloon)"
```

**Optimal Output:**
```text
VRDE:            disabled
Teleporter Enabled: disabled
Guest memory balloon: 0MB
```

## 18. Nested Hardware Virtualization Constraints
Explicitly blocks VT-x/AMD-V instruction passthrough. This restricts the guest kernel from establishing internal hypervisors or manipulating Virtual Machine Control Structures (VMCS) directly within a ring-0 context, drastically reducing escape probabilities.

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

## 19. Storage Controller Host I/O Caching Eradication
Disables the Host I/O cache for the storage controller handling the immutable disk. This ensures that the host Linux/Windows kernel Page Cache does not attempt to parse or buffer the virtual disk read/writes, severing host-kernel filesystem parsing exploits.

**Implementation Command:**
*(Note: Replace 'SATA' with the exact label of the storage controller)*
```bash
VBoxManage storagectl "VM-NAME-HERE" --name "SATA" --hostiocache off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Host I/O Cache"
```

**Optimal Output:**
```text
Host I/O Cache:  off
```

## 20. Shared Folder Extermination
Ensures no transient or permanent shared folders exist that could bridge the guest and host filesystems, preventing directory traversal and file-based escape pathways.

**Implementation Command:**
*(Note: Attempt to delete any known default shares; the command will safely fail if none exist)*
```bash
VBoxManage sharedfolder remove "VM-NAME-HERE" --name "host_share" 2>/dev/null || true
VBoxManage sharedfolder remove "VM-NAME-HERE" --name "host_share" --transient 2>/dev/null || true
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Shared folders" -A 2
```

**Optimal Output:**
```text
Shared folders:  <none>
```

## 21. Immutable Disk State with Auto-Reset
Transforms the primary storage medium into an immutable asset. Writes are diverted to a temporary differential Copy-on-Write (CoW) layer that is deterministically destroyed upon every cold boot. This effectively erases rootkits and nullifies all post-exploitation persistence mechanisms.

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