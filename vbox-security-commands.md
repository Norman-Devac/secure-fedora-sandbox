# Oracle VM VirtualBox 7.2.14 Sandbox Architecture Configuration

This document outlines the technical configuration for establishing an isolated sandbox environment using Oracle VM VirtualBox 7.2.14 for a Windows 11 guest. The configuration balances system stability and visual fluidity for recording purposes, enforces strict execution constraints, manages cryptographic states, and limits networking surfaces.

## 1. Internal Network Assignment and VirtIO Offloading
The command links the primary adapter to an isolated switch in host memory, preventing external traffic routing. Using a paravirtualized driver bypasses legacy emulation vulnerabilities, creating an efficient memory channel. Disabling secondary interfaces blocks alternative escape routes. The engine explicitly marks nullified interfaces as disabled.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --nic1=intnet --intnet1="sandbox-net" --nic-type1=virtio --nic-promisc1=deny
VBoxManage modifyvm "VM-NAME-HERE" --nic2=none --nic3=none --nic4=none --nic5=none --nic6=none --nic7=none --nic8=none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "NIC 1"
```

**Optimal Output:**
```text
NIC 1:                       MAC: 080027XXXXXX, Attachment: Internal Network 'sandbox-net', Cable connected: on, Trace: off (file: none), Type: virtio, Reported speed: 0 Mbps, Boot priority: 0, Promisc Policy: deny, Bandwidth group: LimitGroup
```

## 2. Network Bandwidth Throttling
The configuration creates a transmission limit group capped at ten megabytes per second and binds it to the primary network adapter. The token-bucket system silently drops outbound packets that exceed this threshold. The limit remains transparent to the guest, preventing the execution of lateral network floods without alerting the payload.

**Implementation Command:**
```bash
VBoxManage bandwidthctl "VM-NAME-HERE" add "LimitGroup" --type network --limit 10M 2>/dev/null || true
VBoxManage modifyvm "VM-NAME-HERE" --nic-bandwidth-group1="LimitGroup"
```

**Diagnostic Command:**
```bash
VBoxManage bandwidthctl "VM-NAME-HERE" list
```

**Optimal Output:**
```text
Name: 'LimitGroup', Type: network, Limit: 10 MBytes/sec
```

## 3. Network Boot Deactivation
The configuration restricts the boot sequence strictly to the attached local disk. Setting remaining devices to a null state removes network boot protocols from the initialization phase. The diagnostic output specifically identifies these disconnected slots as not assigned. This prevents firmware from parsing malicious network configuration packets.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --boot1=disk --boot2=none --boot3=none --boot4=none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Boot Device"
```

**Optimal Output:**
```text
Boot Device 1:               HardDisk
Boot Device 2:               Not Assigned
Boot Device 3:               Not Assigned
Boot Device 4:               Not Assigned
```

## 4. Hardware-Assisted Paging and TLB Optimization
Activating nested paging allows the physical processor to manage memory translation directly, while large pages reduce translation overhead. The architecture-specific parameter enables virtual processor identifiers to tag cache entries, preventing severe latency during context switches. Page fusion is explicitly disabled to prevent memory deduplication side-channel vulnerabilities.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --nested-paging=on --large-pages=on --page-fusion=off
VBoxManage modifyvm "VM-NAME-HERE" --x86-vtx-vpid=on
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Nested Paging|Large Pages|Page Fusion|VPID)"
```

**Optimal Output:**
```text
Nested Paging:               enabled
Large Pages:                 enabled
VT-x VPID:                   enabled
Page Fusion:                 disabled
```

## 5. Microarchitectural Buffer Optimization
The command forces the hypervisor to scrub processor caches and execute indirect branch predictor barriers during context switches. Activating these hardware defenses isolates the host processor. The mitigations prevent malicious code from exploiting speculative execution vulnerabilities to read privileged memory pages belonging to the underlying Linux host.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --spec-ctrl=on --l1d-flush-on-vm-entry=on --mds-clear-on-vm-entry=on --ibpb-on-vm-entry=on --ibpb-on-vm-exit=on
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" --machinereadable | grep -E "(spec-ctrl|l1d-flush|mds-clear|ibpb)"
```

**Optimal Output:**
```text
ibpb-on-vm-exit="on"
ibpb-on-vm-entry="on"
spec-ctrl="on"
l1d-flush-on-vm-entry="on"
mds-clear-on-vm-entry="on"
```

## 6. Time Desynchronization and Epoch Spoofing
The command ties the virtual time stamp counter directly to the physical execution pipeline, stopping the counter when the engine pauses. A negative offset rewinds the chronological epoch by thirty days. This synthetic chronometry subverts malicious payloads relying on time-bomb logic or latency measurements to detect the analysis platform.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --hpet=on
VBoxManage setextradata "VM-NAME-HERE" "VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled" 1
VBoxManage setextradata "VM-NAME-HERE" "VBoxInternal/TM/TSCTiedToExecution" 1
VBoxManage modifyvm "VM-NAME-HERE" --bios-system-time-offset=-2592000000
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "HPET"
VBoxManage getextradata "VM-NAME-HERE" enumerate | grep -E "(GetHostTimeDisabled|TSCTiedToExecution)"
```

**Optimal Output:**
```text
HPET:                        enabled
Key: VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled, Value: 1
Key: VBoxInternal/TM/TSCTiedToExecution, Value: 1
```

## 7. Execution Architecture and Core Allocation
The command assigns four virtual processing cores to the engine and permits them to utilize their full capacity. Providing sufficient processing power prevents the guest scheduler from dropping threads under heavy analysis loads. The configuration mimics standard consumer hardware to deceive sandbox-evasion routines embedded within malicious payloads.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --cpus=4 --cpu-execution-cap=100
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Number of CPUs|CPU exec cap)"
```

**Optimal Output:**
```text
Number of CPUs:              4
CPU exec cap:                100%
```

## 8. Legacy Hardware and USB Disconnection
The command utilizes updated parameters to detach physical universal serial bus protocols entirely. It also removes legacy communication ports and eliminates the emulated audio backend. Disabling these interfaces removes thousands of lines of emulation code, permanently blinding exploit vectors that target virtualized descriptor parsing and hardware translation.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --mouse=usbtablet
VBoxManage modifyvm "VM-NAME-HERE" --usb=off --usbehci=off --usbxhci=off
VBoxManage modifyvm "VM-NAME-HERE" --audio=none
VBoxManage modifyvm "VM-NAME-HERE" --uart1=off --lpt1=off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Pointing Device|USB|EHCI|XHCI|Audio|UART|LPT)"
```

**Optimal Output:**
```text
Pointing Device:             USB Tablet
USB:                         disabled
EHCI:                        disabled
XHCI:                        disabled
Audio:                       disabled (Driver: Unknown, Controller: Unknown, Codec: Unknown)
UART 1:                      disabled
LPT 1:                       disabled
```

## 9. IOMMU and Hardware Translation Lockdown
The command explicitly disables the emulated hardware translation layer. Because the architecture relies on paravirtualized network drivers instead of passing physical hardware directly into the virtual machine, this translation layer is unnecessary. Keeping it turned off removes complex software from the execution path, eliminating the risk of out-of-bounds memory vulnerabilities. The engine capitalizes the null state for hardware translation.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --iommu=none
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "IOMMU"
```

**Optimal Output:**
```text
IOMMU:                       None
```

## 10. Graphics Controller and Hardware Acceleration
The command configures a standard graphics controller but strictly disables three-dimensional hardware acceleration using the consolidated parameter. Legacy two-dimensional acceleration parameters are removed. Relying exclusively on software rendering guarantees that malformed graphical shaders cannot bypass boundaries to exploit vulnerabilities within the physical graphics drivers of the host.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --graphicscontroller=vboxsvga --accelerate3d=off --vram=128
VBoxManage modifyvm "VM-NAME-HERE" --default-frontend=gui
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Graphics Controller|VRAM size|Acceleration|Default Frontend)"
```

**Optimal Output:**
```text
Graphics Controller:         VBoxSVGA
VRAM size:                   128MB
3D Acceleration:             disabled
2D Video Acceleration:       disabled
Default Frontend:            gui
```

## 11. Interaction Processes and Telemetry Disconnection
The command terminates all communication channels by disabling the shared clipboard and file transfers. It shuts down diagnostic recording and memory tracing systems. Closing data sockets prevents malicious software from interacting with the host clipboard or exploiting memory-mapped tracing buffers. The diagnostic output relies on specific phrasing, appending the word mode to the clipboard attributes.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --clipboard-mode=disabled --clipboard-file-transfers=off --drag-and-drop=disabled
VBoxManage modifyvm "VM-NAME-HERE" --recording=off --tracing-enabled=off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Clipboard Mode|Drag'n'drop Mode|Recording|Tracing)"
```

**Optimal Output:**
```text
Clipboard Mode:              disabled
Drag'n'drop Mode:            disabled
Recording:                   disabled
Tracing Enabled:             disabled
```

## 12. Firmware Integrity and UEFI Secure Boot
The command initializes a firmware interface and dynamically injects platform keys and signature databases into the virtual motherboard. Enabling secure boot forces the firmware to cryptographically verify the digital signature of the operating system bootloader against the injected certificates, preventing low-level bootkit malware from modifying the initialization sequence.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --firmware=efi64
VBoxManage modifynvram "VM-NAME-HERE" inituefivarstore
VBoxManage modifynvram "VM-NAME-HERE" enrollorclpk
VBoxManage modifynvram "VM-NAME-HERE" enrollmssignatures
VBoxManage modifynvram "VM-NAME-HERE" secureboot --enable
VBoxManage modifyvm "VM-NAME-HERE" --bios-boot-menu=disabled --bios-logo-display-time=0
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Firmware|Secure Boot)"
```

**Optimal Output:**
```text
Firmware:                    EFI64
Secure Boot:                 enabled
```

## 13. TPM Provisioning and Paravirtualization Stabilization
The command generates a software-based trusted platform module within the memory space of the hypervisor, completely severing the guest from the physical cryptographic hardware. Setting the virtualization provider to match standards instructs the kernel on proper interrupt routing, ensuring the system remains stable and responsive without crashing during heavy loads.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --tpm-type=2.0
VBoxManage modifyvm "VM-NAME-HERE" --paravirt-provider=hyperv
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(TPM|Paravirt)"
```

**Optimal Output:**
```text
TPM Type:                    2.0
Paravirt. Provider:          Hyper-V
Effective Paravirt. Prov.:   Hyper-V
```

## 14. Teleportation, VRDE, and Memory Ballooning
The command uses proper syntax to disable remote display endpoints and lock the dynamic memory allocation engine. Disabling the remote server closes interaction vectors, while condensing the memory balloon parameter into a single string prevents syntax rejection. This ensures malicious programs cannot manipulate memory size to exhaust physical RAM.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --teleporter=off --vrde=off
VBoxManage modifyvm "VM-NAME-HERE" --guestmemoryballoon=0
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -E -i "(Teleporter|VRDE|balloon)"
```

**Optimal Output:**
```text
VRDE:                        disabled
Teleporter Enabled:          disabled
Guest memory balloon size:   0 Megabytes
```

## 15. Nested Hardware Virtualization Constraints
The command blocks the guest operating system from accessing underlying processor virtualization instructions. This restriction stops malicious software from attempting to build internal hypervisors inside the sandbox. Preventing the guest from manipulating control structures ensures the primary containment layer remains intact, so the target operating system cannot hide its internal activities.

**Implementation Command:**
```bash
VBoxManage modifyvm "VM-NAME-HERE" --nested-hw-virt=off
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Nested VT-x/AMD-V"
```

**Optimal Output:**
```text
Nested VT-x/AMD-V:           disabled
```

## 16. PCIe NVMe Storage, Host I/O Caching, and Disk Attachment
The command adds a modern storage controller and attaches the virtual disk media. Disabling the host cache forces disk reads and writes to bypass the host kernel entirely via direct memory access. This severs the link between guest disk activity and host memory, significantly reducing the impact of storage-based exploits.

**Implementation Command:**
```bash
VBoxManage storagectl "VM-NAME-HERE" --name "NVMe-Controller" --add=pcie --controller=NVMe --portcount=1 --hostiocache=off
VBoxManage storageattach "VM-NAME-HERE" --storagectl "NVMe-Controller" --port 0 --device 0 --type hdd --medium "Windows.vdi"
```

**Diagnostic Command:**
```bash
VBoxManage showvminfo "VM-NAME-HERE" | grep -i "Host I/O Cache"
```

**Optimal Output:**
```text
Host I/O Cache:              off
```

## 17. Shared Folder Removal
The command systematically attempts to delete permanent or temporary shared folders that might exist between the host and the virtual machine. It runs silently, ignoring errors if no folders are found. Removing shared directories is a mandatory security step that destroys direct file-system bridges, preventing malicious software from escaping the engine.

**Implementation Command:**
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
Shared folders:              <none>
```

## 18. Immutable Disk State with Auto-Reset
The command locks the primary virtual disk into a read-only state, generating a differencing disk overlay within a temporary file. Every registry modification or dropped executable is captured exclusively within this transient overlay. Upon shutdown, the engine destroys the overlay completely, returning the environment to a pristine baseline.

**Implementation Command:**
```bash
VBoxManage modifymedium "Windows.vdi" --type immutable --autoreset=on
```

**Diagnostic Command:**
```bash
VBoxManage showmediuminfo "Windows.vdi" | grep -E -i "(Type|Auto-Reset)"
```

**Optimal Output:**
```text
Type:                        immutable
Auto-Reset:                  on
```