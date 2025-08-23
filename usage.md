# EZ-GPU-PV Usage Guide
Complete Step-by-Step Instructions for Beginners

## 📋 Table of Contents
- [Quick Start](#-quick-start)
- [Detailed Setup](#-detailed-setup)
- [Remote Gaming with Moonlight](#-remote-gaming-with-moonlight)
- [Troubleshooting](#-troubleshooting)
- [Advanced Configuration](#-advanced-configuration)

---

## 🚀 Quick Start

### If You're in a Hurry:
1. **Download** `ez-gpu-pv.ps1` from this repository
2. **Right-click** the file → **Properties** → **Unblock** checkbox → **OK**
3. **Right-click** again → **"Run with PowerShell"** (as Administrator)
4. **Follow the on-screen prompts** to select your VM and GPU
5. **Done!** Your VM now has GPU acceleration

**⚠️ Important**: Make sure Hyper-V is enabled and you have a Windows VM ready!

---

## 📝 Detailed Setup

### Step 1: Prerequisites Check

Before running the script, ensure you have:

#### ✅ Required Components
- **Windows 10/11 Pro, Enterprise, or Education**
- **Hyper-V enabled** (see [How to Enable Hyper-V](#how-to-enable-hyper-v))
- **A Windows virtual machine** 
- **Administrator access** to both host and VM
- **Compatible GPU** (most modern NVIDIA/AMD GPUs work)

#### ✅ Optional but Recommended
- **Latest GPU drivers** installed on host
- **VM snapshots** for easy rollback
- **Basic PowerShell knowledge** (don't worry, we'll guide you!)

### Step 2: Download and Prepare

#### Download Options
- **GitHub**: Download `ez-gpu-pv.ps1` from the [releases](../../releases) page
- **Clone Repository**: `git clone https://github.com/yourusername/ez-gpu-pv.git`
- **Direct Download**: Click the file in GitHub and use "Download" button

#### Security Setup (Important!)
1. Right-click the downloaded `ez-gpu-pv.ps1` file
2. Select **"Properties"**
3. Check the **"Unblock"** checkbox at the bottom
4. Click **"OK"**
5. If prompted, click **"Apply"**

![Unblock File](https://via.placeholder.com/400x200/4CAF50/FFFFFF?text=Unblock+File+Screenshot)

**Why?** PowerShell blocks downloaded scripts for security. Unblocking allows execution.

### Step 3: Enable Hyper-V (if not already enabled)

#### Method 1: Control Panel (Easiest)
1. Open **Control Panel** → **Programs** → **Turn Windows features on or off**
2. Check **"Hyper-V"** box
3. Click **"OK"** and restart when prompted

#### Method 2: PowerShell (For Advanced Users)
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

#### Method 3: DISM Command
```cmd
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V
```

### Step 4: Prepare Your Virtual Machine

#### Create a New VM (Recommended for Beginners)
1. Open **Hyper-V Manager**
2. Click **"New"** → **"Virtual Machine"**
3. Follow the wizard:
   - **Name**: Choose a friendly name
   - **Generation**: 2 (for modern features)
   - **Memory**: 4GB minimum, 8GB+ recommended
   - **Network**: Default switch
   - **VHD**: 64GB+ for Windows
   - **Installation**: Mount Windows ISO

#### Use Existing VM
1. Ensure it's **Windows-based** (Windows 10/11 recommended)
2. **Enable Integration Services**:
   - VM Settings → Integration Services → Check all boxes
3. **Create a snapshot** before running the script

### Step 5: Run EZ-GPU-PV

#### Method 1: Right-Click Method (Easiest)
1. Right-click `ez-gpu-pv.ps1`
2. Select **"Run with PowerShell"**
3. If prompted, click **"Yes"** for Administrator privileges

#### Method 2: PowerShell Terminal
1. Open PowerShell as Administrator
2. Navigate to script location:
   ```powershell
   cd "C:\Path\To\Your\Download"
   ```
3. Run the script:
   ```powershell
   .\ez-gpu-pv.ps1
   ```

### Step 6: Follow the Interactive Prompts

The script will guide you through:

1. **VM Selection**: Choose from list of available VMs
2. **Credential Entry**: Enter VM administrator username/password
3. **GPU Selection**: Pick your host GPU from available options
4. **Automatic Setup**: Script handles the rest!

**Expected Runtime**: 5-15 minutes depending on VM size and network speed.

### Step 7: Complete Post-Setup Tasks

After the script finishes:

1. **Start your VM** if it's not running
2. **Run the GPU driver setup script**:
   - Look for `GPUPAdditionalSetup.bat` on the **C:\ drive root** (not desktop)
   - **Right-click** the file and select **"Run as administrator"**
   - This script installs the GPU drivers inside the VM
   - Wait for it to complete (it may take a few minutes)
3. **Test GPU acceleration**:
   - Open Task Manager → Performance → GPU
   - You should see GPU activity when running graphics apps

---

## 🎮 Remote Gaming with Moonlight

### Why Moonlight/Sunshine?

GPU-P alone gives you hardware acceleration in the VM, but to **stream games** to another device, you need remote desktop software. Moonlight and Sunshine work perfectly with GPU-P!

### Moonlight/Sunshine Setup

#### Step 1: Install Sunshine on VM (Server)
1. Download Sunshine from [GitHub](https://github.com/LizardByte/Sunshine/releases)
2. Install on your GPU-P enabled VM
3. Configure display settings:
   - **Primary Display**: Use Hyper-V VM connection adapter
   - **Resolution**: Match your client device
   - **Frame Rate**: 60+ FPS for gaming

#### Step 2: Install Moonlight on Client Device
Moonlight is available for:
- **Windows**: Microsoft Store or GitHub
- **Android**: Google Play Store
- **iOS**: App Store
- **macOS**: Homebrew or direct download
- **Linux**: Package managers

#### Step 3: Critical Display Configuration

**⚠️ MOONLIGHT BLACK SCREEN FIX**

Moonlight **requires an active display adapter** to function. Here's the secret:

1. **DO NOT** use dedicated GPU adapters for primary display
2. **ONLY USE** Hyper-V VM connection display adapter
3. **Why?** Moonlight needs an active video signal to capture

**Correct Setup:**
- ✅ Hyper-V VM connection = Primary display adapter
- ✅ GPU-P adapter = Secondary (for acceleration only)
- ❌ GPU-P adapter as primary = Black screen in Moonlight

#### Step 4: Configure Sunshine
1. Open Sunshine on your VM
2. Go to **Settings** → **Video**
3. Set **Display**: Choose the Hyper-V VM connection
4. Configure **Resolution** and **FPS**
5. Set up **Encoder** (Hardware preferred for GPU-P)

#### Step 5: Connect with Moonlight
1. Open Moonlight on your client device
2. **Add PC** using VM's IP address
3. **Pair** with the PIN shown in Sunshine
4. **Start streaming** your games!

### Performance Tips
- **Network**: Use 5GHz WiFi or Ethernet for best performance
- **Resolution**: Start with 1080p, increase if stable
- **Frame Rate**: 60 FPS is optimal for most games
- **Bitrate**: Let Moonlight auto-adjust, or set 50-80 Mbps for 4K

---

## 🔧 Troubleshooting

### Script Won't Start
**Problem**: Security warning or execution policy error

**Solutions**:
1. **Unblock the file** (see Step 2 above)
2. **Check execution policy**:
   ```powershell
   Get-ExecutionPolicy
   ```
   If "Restricted", run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### VM Selection Issues
**Problem**: No VMs appear in selection dialog

**Solutions**:
1. **Check Hyper-V Manager** - ensure VMs exist
2. **Verify VM state** - VMs must be in "Off" state initially
3. **Check permissions** - run PowerShell as Administrator

### GPU Not Detected
**Problem**: "Could not find partitionable GPU"

**Solutions**:
1. **Update GPU drivers** to latest version
2. **Check GPU compatibility** - some integrated GPUs don't support GPU-P
3. **Ensure GPU not in use** by host applications
4. **Disable GPU scheduling** in Windows Settings

### VM Won't Stop
**Problem**: Script hangs on "Stopping VM"

**Solutions**:
- **Wait** - sometimes VMs take time to shut down
- **Manual intervention** - use Hyper-V Manager to force stop
- **Check for running processes** in VM that prevent shutdown

### Driver Installation Fails
**Problem**: "Could not find the driver package"

**Solutions**:
1. **Check VM connectivity** - ensure network is working
2. **Verify credentials** - administrator access required
3. **Update host drivers** - ensure latest GPU drivers installed
4. **Check disk space** - VM needs space for driver installation

### Moonlight Black Screen
**Problem**: Streaming shows black screen

**Solutions**:
1. **Check display adapter order** (see Moonlight section above)
2. **Verify Sunshine configuration** - ensure correct display selected
3. **Check VM resolution** - must be set to a supported resolution
4. **Update graphics drivers** in VM

### Enhanced Session Mode Issues
**Problem**: Black screen or poor performance with Moonlight

**Root Cause**: Enhanced Session Mode uses RDP protocol which creates conflicting display adapters

**Solutions**:
1. **Disable Enhanced Session Mode**:
   - Open Hyper-V Manager → Hyper-V Settings
   - Under "Server" section: Uncheck "Allow enhanced session mode"
   - Under "User" section: Uncheck "Use enhanced session mode"
   - Restart VM and connect in Basic Session mode
2. **Verify Display Adapter Priority**:
   - In VM's Device Manager, ensure GPU-P adapter is primary
   - No "Microsoft Basic Display Adapter" or "Remote Display Adapter" should be present

### Driver Compatibility Issues
**Problem**: GPU shows Code 43 error or isn't recognized

**Root Cause**: NVIDIA blocks consumer GPUs in virtualized environments

**Solutions**:
1. **Check for VM-compatible drivers** for your specific GPU model
2. **Use community patches** or workarounds for NVIDIA drivers
3. **Verify driver version compatibility** with Windows version in VM
4. **Consider Tesla/Quadro cards** which have better VM support

### Batch File Execution Issues
**Problem**: GPUPAdditionalSetup.bat fails to run or shows encoding errors

**Root Cause**: File encoding issues (UTF-8 BOM vs ANSI)

**Solutions**:
1. **Check file encoding**: The script now uses ASCII encoding to prevent issues
2. **Run as Administrator**: Right-click → "Run as administrator" in VM
3. **Check file location**: Must be in C:\ drive root, not desktop
4. **Verify antivirus**: Some security software may block batch execution

### Poor Performance
**Problem**: Games run slowly or lag

**Solutions**:
1. **Increase GPU allocation** in script parameters:
   ```powershell
   .\ez-gpu-pv.ps1 -PartitionVram 500MB -PartitionEncode 300MB
   ```
2. **Check VM resources** - ensure sufficient RAM/CPU
3. **Update drivers** on both host and VM
4. **Optimize network** for Moonlight streaming

### Script Errors
**Problem**: Red error messages during execution

**Solutions**:
1. **Check prerequisites** - ensure all requirements met
2. **Run as Administrator** - required for Hyper-V operations
3. **Check PowerShell version** - 5.1 minimum required
4. **Update Windows** - ensure latest Windows updates installed

---

## ⚙️ Advanced Configuration

### Script Parameters

Customize the script behavior with parameters:

```powershell
.\ez-gpu-pv.ps1 -PartitionVram 500MB -PartitionEncode 300MB -PartitionDecode 200MB -PartitionCompute 400MB -VmBootTimeoutSeconds 600
```

**Parameter Explanations:**
- `PartitionVram`: Video memory allocation (default: 100MB)
- `PartitionEncode`: Video encoding resources (default: 100MB)
- `PartitionDecode`: Video decoding resources (default: 100MB)
- `PartitionCompute`: General GPU compute (default: 100MB)
- `LowMmioSpace`: Low memory I/O space (default: 1GB)
- `HighMmioSpace`: High memory I/O space (default: 32GB)
- `VmBootTimeoutSeconds`: VM startup wait time (default: 300)

### Verbose Output
For detailed progress information:
```powershell
.\ez-gpu-pv.ps1 -Verbose
```

### Custom VM Selection
If you have many VMs, you can filter:
```powershell
$vm = Get-VM -Name "MyGamingVM"
# Then use the script normally
```

### GPU Resource Tuning
**For Gaming:**
```powershell
.\ez-gpu-pv.ps1 -PartitionVram 500MB -PartitionEncode 300MB -PartitionDecode 200MB
```

**For AI/ML Workloads:**
```powershell
.\ez-gpu-pv.ps1 -PartitionVram 1GB -PartitionCompute 1GB
```

**For Video Editing:**
```powershell
.\ez-gpu-pv.ps1 -PartitionVram 2GB -PartitionEncode 1GB -PartitionDecode 1GB
```

### Multiple GPU Setup
If you have multiple GPUs, the script will show all compatible ones. Choose the one you want to partition.

---

## 📞 Getting Help

### Development History & Improvements

This script evolved through extensive debugging and community feedback:

#### Version Evolution (6.1 → 6.5+)
- **v6.1**: Fixed critical syntax errors and parameter type issues
- **v6.2**: Implemented PowerShell best practices and cmdlet standards
- **v6.3**: Enhanced error handling with try/finally blocks for session cleanup
- **v6.4**: Clean Code architecture with single-responsibility functions
- **v6.5**: Added driver overwrite prompts and improved user experience

#### Key Technical Improvements
- **Parameter Type Safety**: Resolved string-to-numeric conversion errors
- **Session Management**: Guaranteed cleanup even during script failures
- **Driver Encoding**: Fixed UTF-8 BOM issues in generated batch files
- **Timeout Protection**: Added VM boot timeouts to prevent hangs
- **Error Recovery**: Graceful handling of user cancellations

### Community Support
- **GitHub Issues**: Report bugs and request features
- **Discussions**: Ask questions and share experiences
- **Wiki**: Check for additional guides and tips

### Before Asking for Help
1. **Check this guide** for your specific issue
2. **Verify prerequisites** are met
3. **Try the troubleshooting steps**
4. **Include error messages** when reporting issues
5. **Check the development history** for similar issues that were resolved

### System Information to Provide
When asking for help, include:
- Windows version and edition
- GPU model and driver version
- VM configuration (RAM, CPU, OS)
- Exact error message and line number
- Steps you've already tried
- Script version (check the header comment)
- Whether you're using verbose logging (`-Verbose` flag)

---

## 🎯 Success Checklist

**After running EZ-GPU-PV, verify success:**

- [ ] VM starts without errors
- [ ] GPU appears in VM Device Manager (no Code 43 errors)
- [ ] Task Manager shows GPU utilization in VM Performance tab
- [ ] Graphics applications run smoothly with hardware acceleration
- [ ] Moonlight/Sunshine streaming works (if configured)
- [ ] GPUPAdditionalSetup.bat was executed successfully in VM
- [ ] Enhanced Session Mode is disabled (for Moonlight users)

**If all boxes are checked, congratulations!** 🎉

Your GPU-P setup is complete and ready to use.

---

## 🚀 Advanced Usage Tips

### Performance Optimization
- **Increase GPU allocation** for gaming: Use `-PartitionVram 500MB -PartitionEncode 300MB`
- **Monitor GPU usage** in both host and VM Task Managers
- **Use SSD storage** for VM to reduce I/O bottlenecks
- **Optimize VM resources**: 8GB+ RAM and 4+ CPU cores recommended

### Network Configuration for Streaming
- **Use 5GHz WiFi** or Ethernet for best Moonlight performance
- **Open firewall ports**: 47984, 47989, 47998-48010 for GameStream
- **Static IP**: Consider assigning static IP to VM for consistent connections

### Maintenance
- **Regular driver updates**: Keep both host and VM GPU drivers current
- **VM snapshots**: Create snapshots before major changes
- **Log review**: Use `-Verbose` flag for detailed troubleshooting
- **Community updates**: Check for script updates and community improvements

---

## 📋 Pre-Publishing Checklist

**Before publishing to GitHub, verify:**

- [ ] All script syntax errors are resolved
- [ ] Parameter types are correctly defined (numeric vs string)
- [ ] Error handling is robust with try/finally blocks
- [ ] Verbose logging works with `-Verbose` flag
- [ ] Driver overwrite prompts function correctly
- [ ] Documentation is complete and accurate
- [ ] Troubleshooting section covers common issues
- [ ] Moonlight/Sunshine integration is properly explained
- [ ] Development history reflects actual improvements made
- [ ] All file encodings are compatible (ASCII for batch files)
- [ ] Test scenarios work: fresh install, driver updates, error conditions

