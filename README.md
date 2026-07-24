# EZ-GPU-PV

> **Easy, Automated GPU Partitioning (GPU-P) & Reversal for Hyper-V Virtual Machines**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](#-license)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6.svg)]()
[![Hyper-V](https://img.shields.io/badge/Hyper--V-GPU--P-7F52FF.svg)]()

---

## 📖 Overview

**EZ-GPU-PV** is an interactive, beginner-friendly PowerShell wizard that automates **GPU Partitioning (GPU-P)** on Microsoft Hyper-V virtual machines. 

GPU Partitioning splits your physical host GPU (NVIDIA or AMD) into shared partitions, allowing your Windows Virtual Machines to access true hardware graphics acceleration for gaming, video rendering, AI workloads, and remote desktop streaming—without losing GPU access on your host PC!

It also includes a **Reversal Wizard (`-Reverse`)** to easily undo GPU partitioning, clean up driver files inside the VM, and restore default Hyper-V settings with a single command.

---

## ✨ Features

- 🎮 **Hardware GPU Acceleration:** Share your host GPU with virtual machines for high-performance gaming and compute.
- 🧙 **Interactive Wizard:** Easy GridView selection for target VMs and host GPUs—no typing complex device instance IDs.
- 🚗 **Automated Driver Injection:** Detects host GPU drivers, copies them into the VM's `HostDriverStore`, and generates a one-click setup script (`GPUPAdditionalSetup.bat`).
- 🔄 **One-Click Reversal (`-Reverse`):** Easily remove GPU partitions, re-enable VM checkpoints, restore default MMIO memory space, and option to wipe host driver stores inside the VM.
- 🛡️ **Fail-Safe & Robust:** Built-in boot timeout protection, automatic VM state handling, and proper session cleanup.
- 🕹️ **Apollo & Moonlight Integration Ready:** Tailored for remote gaming via **Apollo** with built-in SudoVDA virtual display support.

---

## 📋 System Requirements

### Host Computer
* **Operating System:** Windows 10 or Windows 11 (Pro, Enterprise, or Education editions). *Home edition does not support Hyper-V.*
* **Hardware GPU:** Dedicated NVIDIA or AMD graphics card.
* **Hyper-V:** Enabled and running.
* **Privileges:** Administrator privileges on both host and VM.

### Guest Virtual Machine
* **Guest OS:** Windows 10 or Windows 11.
* **Generation:** Generation 2 VM recommended.
* **Integration Services:** Enabled (specifically Heartbeat service).

---

## 🚀 Quick Start Guide (5 Minutes)

1. **Download:** Get `ez-gpu-pv.ps1` from this repository.
2. **Unblock the Script:**
   - Right-click `ez-gpu-pv.ps1` → select **Properties**.
   - Check the **Unblock** box at the bottom → click **OK**.
3. **Run as Administrator:**
   - Right-click `ez-gpu-pv.ps1` → select **Run with PowerShell** (or run from an elevated PowerShell prompt).
4. **Follow the Interactive Wizard:**
   - Select your target VM from the pop-up list.
   - Select your host GPU from the pop-up list.
   - Enter your VM Administrator credentials when prompted.
5. **Complete VM Setup:**
   - Boot up your VM.
   - Inside the VM, right-click `C:\GPUPAdditionalSetup.bat` and choose **Run as administrator**.
   - Reboot the VM when completed. Done! 🎉

---

## 📝 Detailed Step-by-Step Setup

### Step 1: Enable Hyper-V on Host

If Hyper-V is not already enabled:
1. Press `Win + R`, type `optionalfeatures.exe`, and press **Enter**.
2. Check the box for **Hyper-V** (ensure both Management Tools and Platform are checked).
3. Click **OK** and restart your computer when prompted.

Alternatively, via PowerShell (Administrator):
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

---

### Step 2: Create & Prepare Your Virtual Machine

1. Open **Hyper-V Manager**.
2. Click **New** → **Virtual Machine**.
3. Configure the VM:
   - **Generation:** Select **Generation 2**.
   - **RAM:** Allocate at least 4GB (8GB+ recommended for gaming).
   - **Networking:** Select **Default Switch**.
   - **Virtual Hard Disk:** Create a VHDX (64GB+ recommended).
4. Install Windows 10 or 11 on the VM and log in to set up an Administrator account.
5. Ensure Integration Services are enabled:
   - In Hyper-V Manager, right-click VM → **Settings** → **Integration Services** → Check all services (especially **Heartbeat**).

---

### Step 3: Run the EZ-GPU-PV Setup Wizard

1. Open PowerShell as **Administrator**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
2. Navigate to the folder containing `ez-gpu-pv.ps1`:
   ```powershell
   cd "C:\Path\To\Script"
   ```
3. Run the script:
   ```powershell
   .\ez-gpu-pv.ps1
   ```
4. **Interactive Prompts:**
   - **Select VM:** A graphical grid window will list all available VMs. Click your target VM and click **OK**.
   - **Select GPU:** Choose your host graphics card from the grid.
   - **Enter VM Credentials:** Input the local Administrator username and password for *inside* the guest VM.
   - **Confirm Setup:** Review the configuration summary and type `Y` to apply.

---

### Step 4: Final Driver Installation Inside the VM

1. Start your Virtual Machine in Hyper-V Manager.
2. Log in to Windows inside the VM.
3. Open File Explorer and go to the root of the **C:\** drive.
4. Locate `GPUPAdditionalSetup.bat`.
5. **Right-click `GPUPAdditionalSetup.bat` → Run as administrator.**
6. Wait for the command prompt to finish installing drivers into the VM's Driver Store.
7. Restart the VM.
8. **Verify GPU-P:** Open Task Manager inside the VM → **Performance** tab. You should now see your physical GPU listed!

---

## 🔄 Reversing GPU Partitioning (`-Reverse`)

If you want to remove GPU partitioning from a VM and restore standard Hyper-V defaults:

1. Open PowerShell as Administrator.
2. Run the script with the `-Reverse` flag:
   ```powershell
   .\ez-gpu-pv.ps1 -Reverse
   ```
3. **Reversal Wizard Steps:**
   - **Select VM:** Pick the VM you want to restore.
   - **Host Cleanup:** The script stops the VM, removes the GPU partition adapter, re-enables standard checkpoints, resets guest cache settings, and restores default MMIO memory space.
   - **VM Driver Cleanup (Optional):** The wizard will ask if you also want to remove copied driver packages inside the VM (`HostDriverStore` and setup batch file). If you select `Y`, enter your VM credentials, and the script will automatically clean up the guest files!

---

## 🎮 Remote Gaming Guide: Apollo + Moonlight

Hyper-V GPU-P VMs operate in a headless state (no physical monitor attached). Standard remote desktop tools like RDP disable GPU acceleration, while traditional streaming tools like Sunshine can encounter black screen errors due to missing display outputs.

We strongly recommend using **[Apollo](https://github.com/ClassicOldSong/Apollo)** (a modern fork of Sunshine) paired with **[Moonlight](https://moonlight-stream.org/)** on your client devices.

### Why Apollo Over Sunshine for Hyper-V GPU-P?

* **Built-in SudoVDA Virtual Display Driver:** Apollo includes SudoVDA directly inside the installer. When a streaming session begins, Apollo automatically creates a virtual display monitor for your partitioned GPU and destroys it when you disconnect—**no physical dummy plugs or extra virtual display drivers required!**
* **Automatic Resolution & Refresh Rate Matching:** Apollo dynamically matches the native resolution and framerate of your client device (e.g., Steam Deck 1280x800@60Hz, iPad 2732x2048@120Hz, or 4K TV@60Hz).
* **Zero-Configuration Headless Streaming:** Fixes the Moonlight "Black Screen" problem out-of-the-box.

---

### Step-by-Step Apollo Setup in the VM

#### Step 1: Install Apollo in the VM
1. Inside your GPU-P enabled VM, open a browser and download the latest release from the [Apollo GitHub Releases](https://github.com/ClassicOldSong/Apollo/releases).
2. Run the installer executable. Make sure the option to install **SudoVDA (Virtual Display Driver)** is checked.
3. Finish the installation.

#### Step 2: Configure Apollo Web UI
1. Open a browser inside the VM and go to `https://localhost:47990`.
2. Create your admin username and password when prompted.
3. Log in to the Apollo dashboard.
4. Navigate to **Configuration** → **Audio/Video** and verify SudoVDA is detected as an active virtual display provider.

#### Step 3: Install Moonlight on Client Device
Install the Moonlight app on your streaming client:
* **Windows / macOS / Linux:** Download from [Moonlight Site](https://moonlight-stream.org/)
* **Handhelds / Mobile:** Search for **Moonlight Game Streaming** on Google Play Store, iOS App Store, or SteamOS App Store.

#### Step 4: Pair & Stream
1. Connect your client device to the same local network as your host PC / VM.
2. Launch Moonlight on your client device. Your VM running Apollo will automatically appear in the host list.
3. Click the VM icon in Moonlight. A 4-digit PIN will display on your client screen.
4. Open the Apollo Web UI in your VM (`https://localhost:47990`), go to **Pin**, enter the 4-digit PIN, and click **Send**.
5. Click your desktop or game in Moonlight to start streaming with full hardware GPU acceleration!

---

## ⚙️ Script Parameters Reference

`ez-gpu-pv.ps1` includes high-performance gaming & graphics allocations **by default out of the box**. Advanced users can optionally customize resource allocations:

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `-PartitionVram` | `long` | `1GB` | Amount of VRAM assigned to the GPU partition. |
| `-PartitionEncode` | `long` | `500MB` | Video encoding resources allocated to partition. |
| `-PartitionDecode` | `long` | `500MB` | Video decoding resources allocated to partition. |
| `-PartitionCompute` | `long` | `500MB` | General GPU compute resources allocated. |
| `-LowMmioSpace` | `long` | `1GB` | Low Memory Mapped I/O space reserved for VM. |
| `-HighMmioSpace` | `long` | `32GB` | High Memory Mapped I/O space reserved for VM. |
| `-VmBootTimeoutSeconds` | `int` | `300` | Timeout in seconds waiting for VM startup heartbeat. |
| `-SkipDriverCopy` | `switch` | `False` | Skips checking and transferring host GPU drivers to VM. |
| `-Reverse` | `switch` | `False` | Triggers the Reversal Wizard to undo GPU-P settings. |

### Usage Examples

**Default (High-Performance Gaming / Graphics):**
```powershell
.\ez-gpu-pv.ps1
```

**Fast Re-run (Skip Driver Transfer):**
```powershell
.\ez-gpu-pv.ps1 -SkipDriverCopy
```

**Custom / Higher VRAM Allocation (e.g. 2GB VRAM):**
```powershell
.\ez-gpu-pv.ps1 -PartitionVram 2GB -PartitionEncode 1GB
```

**Reverse GPU-P and Restore Hyper-V Defaults:**
```powershell
.\ez-gpu-pv.ps1 -Reverse
```

---

## 🔧 Troubleshooting

### 1. Script Fails with "Execution of scripts is disabled on this system"
Run this command in PowerShell (Administrator) to allow local scripts to execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. "File unblocking" Warning
If Windows blocks downloaded files, right-click `ez-gpu-pv.ps1` → **Properties** → check **Unblock** → click **Apply**.

### 3. GPU Shows "Code 43" in VM Device Manager
* **Cause:** NVIDIA consumer drivers historically restricted virtualized usage.
* **Fix:** Ensure you ran `GPUPAdditionalSetup.bat` as Administrator inside the VM and restarted. Also verify that host and VM display driver versions match.

### 4. Moonlight Streaming Shows a Black Screen
* **Cause:** Headless VM has no active display output.
* **Fix:** Switch from Sunshine to **Apollo**. Apollo's integrated SudoVDA virtual display driver creates a virtual monitor on demand, eliminating black screen issues without physical dummy plugs.

### 5. Script Hangs on "Waiting for VM Heartbeat"
* **Cause:** Integration services are disabled or guest OS is failing to boot.
* **Fix:** Open Hyper-V Manager, connect to the VM manually, and ensure Windows is booting up cleanly to the desktop. Check VM Settings → Integration Services → Heartbeat.

### 6. VM Fails to Start with Error "Insufficient system resources exist" (0x800705AA)
* **Cause:** The minimum VRAM/resource reservation setting was too high for the host GPU to guarantee strictly upfront at boot time.
* **Fix:** `ez-gpu-pv.ps1` automatically sets `MinPartition` parameters to `1` so Hyper-V dynamically allocates resources up to your requested maximum without throwing reservation errors on startup. Re-run `.\ez-gpu-pv.ps1` to apply the updated configuration.

---

## 🙏 Credits & Acknowledgments

* Forked and refactored from original works by [seflerZ/oneclick-gpu-pv](https://github.com/seflerZ/oneclick-gpu-pv) and [dantmnf](https://gist.github.com/dantmnf/9bf9972c1ad49029cbdc2e40f1b7ac51).

---

## 📄 License

This project is licensed under the [GNU General Public License v3.0 (GPLv3)](https://www.gnu.org/licenses/gpl-3.0.html).
