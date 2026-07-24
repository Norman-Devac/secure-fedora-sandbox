# Oracle VM VirtualBox 7.2.14 Secure Sandbox Environment

## Overview
This repository provides the deployment scripts and verification tools needed to build a highly secure, isolated Windows 11 sandbox for malware analysis. Designed specifically for Oracle VM VirtualBox 7.2.14 running on a Fedora 44 Linux host, this setup locks down the system, strictly limits network access, and hides the fact that it is a virtual machine. 

The primary goal is to let analysts safely execute and observe malicious software without risking the underlying host computer, ensuring the environment remains perfectly consistent for every single test.

## Architecture Highlights

### 1. Storage Containment and Auto-Cleaning
*   **Read-Only Hard Drive:** The main Windows 11 virtual disk is locked so it cannot be permanently modified. Any changes made by malware—such as new files, encrypted documents, or registry edits—are diverted to a temporary storage layer. When you shut down the machine, this temporary layer is instantly destroyed, returning the sandbox to a perfectly clean state.
*   **Direct Disk Access:** The architecture explicitly tells the hypervisor to bypass the Linux host's normal file-caching system. This ensures that malicious disk activity inside the sandbox never interacts with the host's memory buffers, severely reducing the risk of a storage-based breakout.
*   **No Shared Interfaces:** All clipboard sharing, drag-and-drop features, and shared folders between the host and the sandbox are completely disabled to destroy any direct bridges between the two systems.

### 2. Processor and Memory Security
*   **Clearing Processor Memory:** The system is forced to aggressively wipe sensitive processor caches every time it switches operations between the host computer and the sandbox. This prevents advanced malware from using timing tricks to read your main computer's private memory.
*   **Isolated Memory Processing:** We utilize hardware features to keep the virtual machine running smoothly, but explicitly disable "memory deduplication" (sharing identical memory pages). This keeps the sandbox's memory strictly walled off from the host.
*   **Blocking Virtualization Inception:** The sandbox is blocked from accessing the underlying hardware's virtualization features. This prevents clever malware from trying to build its own hidden virtual machine inside your sandbox to evade detection.

### 3. Windows 11 Requirements and Integrity
*   **Software-Based Security Chip (TPM):** Windows 11 requires a Trusted Platform Module (TPM) to run. We emulate this chip entirely in software. This satisfies the Windows 11 requirements without ever connecting the sandbox to your computer's actual, physical security hardware.
*   **Strict Secure Boot:** We set up a verified boot process injected with Microsoft's official certificates. This stops complex malware (like bootkits) from hijacking the system before the operating system even has a chance to load.

### 4. Fooling the Malware (Anti-Evasion)
*   **Time Travel and Clock Spoofing:** Malware often checks the system clock to see if it is being delayed in a sandbox, or it waits for a specific date to attack. We disconnect the sandbox clock from the real world and rewind it by exactly 30 days to break these time-based triggers.
*   **Hardware Stripping:** We completely remove unnecessary virtual hardware, like audio devices, serial ports, and USB controllers. This gives malware fewer targets to attack and removes the obvious signs that the system is a standard VirtualBox machine.

## Prerequisites
*   **Host OS:** Fedora 44 Linux.
*   **Hypervisor:** Oracle VM VirtualBox 7.2.14.
*   **Guest OS:** Windows 11 (Standard ISO).
*   **Network Drivers:** The Windows virtual disk must have Red Hat VirtIO network drivers pre-installed so it can talk to our secure, isolated network switch.

## Deployment Strategy

The deployment relies on a single script (`DEPLOY-SANDBOX.md`) that applies all security rules, networking constraints, and storage locks in one flawless run.

1.  Clone this repository to your Fedora 44 host.
2.  Ensure your target Windows 11 virtual disk file (`.vdi`) is staged in the correct directory.
3.  Open the deployment script and assign your specific target names to the variables at the top (VM Name, Disk Path, Network Name).
4.  Execute the bash script in your terminal to instantly build and lock down the sandbox.

## Verification and Diagnostics

Security is only as good as its verification. Following deployment, run the provided **Diagnostic Command** script. 

VirtualBox uses highly specific terms behind the scenes (like `Not Assigned` or `disabled`). The diagnostic tool extracts the exact state of your virtual machine so you can compare it against the **Optimal Output** list provided in this repository. If the outputs match, you can be mathematically certain that your sandbox is sealed and ready for malicious payloads.

## Disclaimer
This architecture is designed for controlled malware analysis by security professionals. Ensure your physical host operating system is adequately segregated from your production networks. **Never** enable 3D hardware acceleration or network bridging on this machine, as doing so will collapse the security perimeter and expose your host computer to attack.