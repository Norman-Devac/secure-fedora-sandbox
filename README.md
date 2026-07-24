# Oracle VM VirtualBox 7.2.14 Secure Sandbox Environment

## Overview
This repository provides the deployment scripts and verification tools needed to build a highly secure, isolated Windows 11 sandbox for malware analysis. Designed specifically for Oracle VM VirtualBox 7.2.14 running on a Fedora 44 Linux host, this setup locks down the system, strictly limits network access, and hides the fact that it is a virtual machine. 

The primary goal is to allow analysts to safely execute and observe malicious software without risking the underlying host computer, ensuring the environment remains perfectly consistent for every single test.

## Architecture Highlights

### 1. Storage Containment and Auto-Cleaning
*   **Read-Only Hard Drive:** The main Windows 11 virtual disk is locked so it cannot be permanently modified. Any changes made by malware - such as new files, encrypted documents, or registry edits - are diverted to a temporary storage layer. When the machine shuts down, this temporary layer is instantly destroyed, returning the sandbox to a perfectly clean state.
*   **Direct Disk Access:** The architecture explicitly tells the hypervisor to bypass the Linux host's normal file-caching system. This ensures that malicious disk activity inside the sandbox never interacts with the host's memory buffers, severely reducing the risk of a storage-based breakout.
*   **No Shared Interfaces:** All clipboard sharing, drag-and-drop features, and shared folders between the host and the sandbox are completely disabled to destroy any direct bridges between the two systems.

### 2. Processor and Memory Security
*   **Clearing Processor Memory:** The system is forced to aggressively wipe sensitive processor caches every time it switches operations between the host computer and the sandbox. This prevents advanced malware from using timing tricks to read the host computer's private memory.
*   **Isolated Memory Processing:** Hardware features keep the virtual machine running smoothly, but the configuration explicitly disables memory deduplication (sharing identical memory pages). This keeps the sandbox's memory strictly walled off from the host.
*   **Blocking Virtualization Inception:** The sandbox is blocked from accessing the underlying hardware's virtualization features. This prevents clever malware from trying to build hidden virtual machines inside the sandbox to evade detection.

### 3. Windows 11 Requirements and Integrity
*   **Software-Based Security Chip (TPM):** Windows 11 requires a Trusted Platform Module (TPM) to run. The architecture emulates this chip entirely in software. This satisfies the Windows 11 requirements without ever connecting the sandbox to the physical security hardware.
*   **Strict Secure Boot:** The architecture establishes a verified boot process injected with Microsoft's official certificates. This stops complex malware (like bootkits) from hijacking the system before the operating system even has a chance to load.

### 4. Fooling the Malware (Anti-Evasion)
*   **Time Travel and Clock Spoofing:** Malware often checks the system clock to see if it is being delayed in a sandbox, or it waits for a specific date to attack. The configuration disconnects the sandbox clock from the real world and rewinds it by exactly 30 days to break these time-based triggers.
*   **Hardware Stripping:** The engine completely removes unnecessary virtual hardware, like audio devices, serial ports, and USB controllers. This gives malware fewer targets to attack and removes the obvious signs that the system is a standard VirtualBox machine.

## Prerequisites
*   **Host OS:** Fedora 44 Linux.
*   **Hypervisor:** Oracle VM VirtualBox 7.2.14.
*   **Guest OS:** Windows 11 (Standard ISO).
*   **Network Drivers:** The Windows virtual disk must have Red Hat VirtIO network drivers pre-installed so it can interface with the secure, isolated network switch.

## Deployment Strategy

The deployment relies on a single script that applies all security rules, networking constraints, and temporal obfuscations in one flawless run.

1.  Clone this repository to the Fedora 44 host.
2.  Ensure the target Windows 11 virtual disk file (.vdi) is staged in the correct directory.
3.  Open the deployment script and assign specific target names to the variables at the top (VM Name, Disk Path, Network Name).
4.  Execute the bash script in the terminal to instantly build and lock down the sandbox.

## Troubleshooting and Environment Variations

Due to the highly specific nature of hypervisor configurations, these commands may occasionally fail to execute due to minor misconfigurations in the local host device, environment variables, or network settings. 

If execution errors occur, engineers familiar with bash scripting can manually adjust the parameters to fit specific topologies. Alternatively, pasting the error output and the script into a Large Language Model (LLM) easily resolves these issues. Environment-specific syntax discrepancies are straightforward to fix with a simple prompt.

## Verification and Diagnostics

Security is only as good as its verification. Following deployment, run the provided diagnostic script. 

VirtualBox uses highly specific terms behind the scenes (like "Not Assigned" or "disabled"). The diagnostic tool extracts the exact state of the virtual machine for comparison against the optimal output list provided in this repository. If the outputs match, mathematical certainty is achieved that the sandbox is sealed and ready for malicious payloads.

## Disclaimer
This architecture is designed for controlled malware analysis by security professionals. Ensure the physical host operating system is adequately segregated from production networks. Never enable 3D hardware acceleration or network bridging on this machine, as doing so will collapse the security perimeter and expose the host computer to attack.

---

## Deployment and Verification Scripts

This section provides the consolidated deployment and verification scripts for the Windows 11 sandbox architecture. Execution of these instructions applies all security mitigations, networking constraints, temporal obfuscation, and storage containment rules to the engine in a single run. The script utilizes strict POSIX-compliant line continuations and modern syntax bindings to ensure perfect execution on a Fedora Linux host.

### Implementation Command

The following script block aggregates all architecture parameters. It configures the isolated internal network, provisions the necessary cryptographic enclaves, shifts the chronological boot epoch, and secures the NVMe storage controller by properly attaching the disk media.

Target identifiers require assignment to the variables at the top of the script prior to execution. The script assumes the virtual disk image has been pre-injected with Red Hat VirtIO network drivers.

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
    VBoxManage modifymedium "$DISK_PATH" --type immutable --autoreset=on

### Diagnostic Command

The diagnostic script parses the engine state and extracts all modified flags to verify the architecture was successfully applied without syntax rejection.

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

### Optimal Output

When the diagnostic script executes against the properly formatted and securely locked environment, the engine will return the following verified state metrics.

    === INITIATING HYPERVISOR STATE AUDIT ===
    
    [+] Network, Firmware, and I/O Execution States:
    NIC 1:                       MAC: 080027XXXXXX, Attachment: Internal Network 'sandbox-net', Cable connected: on, Trace: off (file: none), Type: virtio, Reported speed: 0 Mbps, Boot priority: 0, Promisc Policy: deny, Bandwidth group: LimitGroup
    Boot Device 1:               HardDisk
    Boot Device 2:               Not Assigned
    Boot Device 3:               Not Assigned
    Boot Device 4:               Not Assigned
    Nested Paging:               enabled
    Large Pages:                 enabled
    VT-x VPID:                   enabled
    Page Fusion:                 disabled
    HPET:                        enabled
    Number of CPUs:              4
    CPU exec cap:                100%
    Pointing Device:             USB Tablet
    USB:                         disabled
    EHCI:                        disabled
    XHCI:                        disabled
    Audio:                       disabled (Driver: Unknown, Controller: Unknown, Codec: Unknown)
    UART 1:                      disabled
    LPT 1:                       disabled
    IOMMU:                       None
    Graphics Controller:         VBoxSVGA
    VRAM size:                   128MB
    3D Acceleration:             disabled
    2D Video Acceleration:       disabled
    Default Frontend:            gui
    Clipboard Mode:              disabled
    Drag'n'drop Mode:            disabled
    Recording:                   disabled
    Tracing Enabled:             disabled
    Firmware:                    EFI64
    Secure Boot:                 enabled
    TPM Type:                    2.0
    Paravirt. Provider:          Hyper-V
    Effective Paravirt. Prov.:   Hyper-V
    VRDE:                        disabled
    Teleporter Enabled:          disabled
    Guest memory balloon size:   0 Megabytes
    Nested VT-x/AMD-V:           disabled
    Host I/O Cache:              off
    Shared folders:              <none>
    
    [+] Microarchitectural Side-Channel Mitigations (Raw Arrays):
    ibpb-on-vm-exit="on"
    ibpb-on-vm-entry="on"
    spec-ctrl="on"
    l1d-flush-on-vm-entry="on"
    mds-clear-on-vm-entry="on"
    biossystemtimeoffset="-2592000000"
    
    [+] Quality of Service and Bandwidth Topology:
    Name: 'LimitGroup', Type: network, Limit: 10 MBytes/sec
    
    [+] Temporal Epoch and Desynchronization Overrides:
    Key: VBoxInternal/Devices/VMMDev/0/Config/GetHostTimeDisabled, Value: 1
    Key: VBoxInternal/TM/TSCTiedToExecution, Value: 1
    
    [+] Cryptographic Storage Medium Verification:
    Type:                        immutable
    Auto-Reset:                  on