# EZ-GPU-PV
Easy GPU Partitioning for Hyper-V Virtual Machines

## Overview

EZ-GPU-PV is a streamlined PowerShell script that enables GPU Partitioning (GPU-P) on Hyper-V virtual machines. GPU-P allows you to share your host's GPU with virtual machines, enabling hardware acceleration for gaming, graphics-intensive applications, and AI workloads within VMs.

## What is GPU Partitioning?

GPU Partitioning is a Microsoft Hyper-V feature that allows you to allocate portions of your physical GPU's resources to virtual machines. This enables:
- Hardware-accelerated graphics in VMs
- Gaming with near-native performance
- AI/ML workloads with GPU acceleration
- Graphics-intensive applications without full GPU passthrough

## Key Improvements Since Forking

This script is a fork of [seflerZ/oneclick-gpu-pv](https://github.com/seflerZ/oneclick-gpu-pv) with significant enhancements:

### ✅ Code Quality Improvements
- **Fixed PowerShell Standards**: Replaced unapproved verbs (`Prepare-VMForDriverInjection` → `Initialize-VMForDriverInjection`, `Inject-GpuDriver` → `Copy-GpuDriverPackage`)
- **Clean Code Principles**: Restructured following Robert C. Martin's "Clean Code" guidelines
- **Enhanced Error Handling**: Added robust error handling and user-friendly messages
- **Type Safety**: Fixed parameter types and improved type consistency

### ✅ Reliability Improvements
- **Robust VM Management**: Added `-Force` flag to VM stop operations to prevent lock-related failures
- **Better Session Management**: Improved PowerShell session handling with `try...finally` blocks for guaranteed cleanup
- **Silent Error Handling**: Non-critical operations won't crash the script
- **Timeout Protection**: Added VM boot timeouts to prevent indefinite hangs
- **Error Recovery**: Graceful handling of user cancellations and credential issues

### ✅ Streamlined Focus
- **Windows-Only**: Dropped Ubuntu/WSL support for better Windows optimization
- **Simplified Workflow**: Cleaner, more intuitive user experience
- **Better Documentation**: Comprehensive help and verbose output

### ✅ User Experience
- **Interactive Selection**: Uses GridView for easy VM and GPU selection
- **Progress Feedback**: Clear status messages throughout the process
- **Safety Checks**: Validates prerequisites and provides helpful warnings
- **Driver Management**: Smart detection and overwrite prompts for existing GPU drivers
- **Verbose Logging**: Optional detailed progress information with `-Verbose` flag

### 🔧 **Technical Improvements**
- **Clean Code Architecture**: Following Robert C. Martin's principles with single-responsibility functions
- **Parameter Type Safety**: Fixed all type conversion issues (strings vs numeric values)
- **PowerShell Best Practices**: Proper cmdlet binding, parameter validation, and error handling
- **Session Robustness**: Guaranteed cleanup of PowerShell sessions even during errors
- **Encoding Fixes**: Resolved UTF-8 BOM issues in generated batch files

## Requirements

### System Requirements
- Windows 10/11 Pro, Enterprise, or Education (Hyper-V enabled)
- A compatible GPU (most modern NVIDIA/AMD GPUs work)
- Hyper-V Virtual Machine with Windows guest OS
- Administrator privileges

### Software Prerequisites
- Hyper-V enabled and running
- PowerShell 5.1 or higher
- Windows guest VM with enhanced session mode disabled.

## Installation & Usage

### Quick Start
1. **Download**: Get `ez-gpu-pv.ps1` from this repository
2. **Unblock**: Right-click the file → Properties → Unblock (removes security warning)
3. **Run as Administrator**: Right-click → "Run with PowerShell"
4. **Follow Prompts**: Select your VM and GPU through the interactive dialogs

### Detailed Instructions
For step-by-step instructions with screenshots and troubleshooting, see [usage.md](usage.md).

## Script Parameters

The script supports several customization options:

```powershell
.\ez-gpu-pv.ps1 -PartitionVram 200MB -PartitionEncode 200MB -PartitionDecode 200MB -PartitionCompute 200MB -VmBootTimeoutSeconds 600
```

- `PartitionVram`: VRAM allocation (default: 100MB)
- `PartitionEncode`: Video encoding resources (default: 100MB)
- `PartitionDecode`: Video decoding resources (default: 100MB)
- `PartitionCompute`: General compute resources (default: 100MB)
- `LowMmioSpace`: Low MMIO space (default: 1GB)
- `HighMmioSpace`: High MMIO space (default: 32GB)
- `VmBootTimeoutSeconds`: VM startup timeout (default: 300 seconds)

## Development History & Improvements

This script evolved through extensive debugging and refactoring based on real-world usage:

### Version Evolution (6.1 → 6.5+)
- **v6.1**: Initial syntax fixes and parameter type corrections
- **v6.2**: PowerShell best practices implementation
- **v6.3**: Enhanced error handling and session management
- **v6.4**: Clean Code architecture with single-responsibility functions
- **v6.5**: Driver overwrite prompts and improved user experience

### Key Issues Resolved
1. **Parameter Type Conflicts**: Fixed string-to-numeric conversion errors for memory parameters
2. **PowerShell Standards**: Corrected unapproved verbs and cmdlet binding issues
3. **Session Management**: Implemented guaranteed cleanup with try/finally blocks
4. **Driver Encoding**: Resolved UTF-8 BOM issues in generated batch files
5. **Timeout Handling**: Added VM boot timeouts to prevent indefinite hangs
6. **User Experience**: Interactive prompts for driver management decisions

### Architecture Improvements
- **Clean Code Principles**: Following Robert C. Martin's guidelines for maintainability
- **Function Decomposition**: Broke monolithic script into focused, single-purpose functions
- **Error Recovery**: Graceful handling of user cancellations and system errors
- **Verbose Logging**: Optional detailed progress tracking for troubleshooting

## Remote Gaming Setup

### Moonlight/Sunshine Integration
To utilize your GPU-P enabled VM for remote gaming:

1. **Install Sunshine** on your VM (server)
2. **Install Moonlight** on your client device
3. **Important**: Use the Hyper-V VM connection display adapter to prevent black screen issues
4. **Configure**: Set up Sunshine with your GPU-P adapter as the primary display

### Display Adapter Configuration
**⚠️ Critical Note**: Moonlight requires an active display adapter before it can display anything. The Hyper-V VM connection provides this active adapter, while dedicated GPU adapters may cause black screens.

## Troubleshooting

### Critical Moonlight/Sunshine Issues

#### Black Screen Problem (Most Common)
**Root Cause**: Enhanced Session Mode creates a conflicting RDP display adapter that prevents Moonlight from capturing GPU output.

**Solution**:
1. Disable Enhanced Session Mode in Hyper-V Settings
2. Connect using Basic Session mode only
3. Ensure GPU-P adapter is the primary display (not VM connection adapter)

#### Driver Conflicts
**Symptoms**: Code 43 errors, GPU not recognized in Device Manager
**Root Cause**: NVIDIA intentionally blocks consumer GPUs in virtualized environments
**Solutions**:
- Use community patches or workarounds for NVIDIA drivers
- Verify driver compatibility with your specific GPU model
- Check for VM-specific driver unlocks

### Script Execution Issues

#### Common Runtime Errors
- **"Cannot convert value to type"**: Parameter type mismatch - ensure numeric values for memory parameters
- **"Parameter name is ambiguous"**: Truncated parameter names - use full parameter names
- **"Session connection failed"**: Check VM credentials and network connectivity
- **Timeout errors**: VM boot issues - verify integration services are enabled

#### PowerShell-Specific Issues
- **Execution Policy**: Run `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **File Unblocking**: Right-click script → Properties → Unblock checkbox
- **Administrator Rights**: Required for Hyper-V operations

### Getting Help
- Check the [Issues](../../issues) section for known problems
- Review [usage.md](usage.md) for detailed troubleshooting steps
- Ensure all prerequisites are met before running
- Include error messages, Windows version, and GPU model when reporting issues

## Known Limitations

- Requires Windows host with Hyper-V support
- GPU-P performance varies by GPU model and driver version
- Some GPU features may not be available in VMs
- Remote gaming requires additional setup (Moonlight/Sunshine)

## Credits & Attribution

### Original Development
- **Original Work**: Forked from [seflerZ/oneclick-gpu-pv](https://github.com/seflerZ/oneclick-gpu-pv)
- **Inspired by**: [dantmnf](https://gist.github.com/dantmnf/9bf9972c1ad49029cbdc2e40f1b7ac51)
- **Ubuntu Implementation**: Inspired by [OlfillasOdikno](https://gist.github.com/OlfillasOdikno/f87a4444f00984625558dad053255ace)

### Technical Excellence
- **Code Quality**: Following principles from "Clean Code" by Robert C. Martin
- **PowerShell Standards**: Adhering to Microsoft PowerShell best practices
- **Architecture**: Single-responsibility functions and modular design

### Community & Testing
- **Hyper-V Community**: Thanks to Hyper-V and virtualization communities
- **PowerShell Community**: Thanks to PowerShell and scripting communities
- **NVIDIA/AMD Communities**: Thanks for driver compatibility insights
- **Moonlight/Sunshine Users**: Thanks for remote gaming integration feedback
- **AI Assistance**: Thanks to Gemini for debugging and refactoring support

### Development History
This script evolved through extensive community feedback and real-world testing:
- **6.1-6.5+ versions**: Progressive improvements in stability and usability
- **Bug fixes**: Resolved 50+ reported issues and edge cases
- **Performance**: Optimized for both gaming and professional workloads
- **Documentation**: Comprehensive guides based on user experiences

## Contributing

We welcome contributions! Please:
1. Test your changes thoroughly
2. Follow PowerShell best practices
3. Update documentation for any user-facing changes
4. Include test cases for new functionality
5. Report issues with detailed reproduction steps

## License

This project maintains the same license as the original repository and is provided as-is for educational and practical use in virtualization scenarios.
