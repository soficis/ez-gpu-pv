#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures a Hyper-V Virtual Machine for GPU Partitioning (GPU-P).
.DESCRIPTION
    This script automates the process of assigning a physical GPU partition to a VM. It guides the user
    through selecting a VM and GPU, prepares the VM, injects the necessary host drivers, and configures
    the VM settings for GPU-P. It follows the principles of Clean Code for clarity and maintainability.
.NOTES
    Version: 6.5 (Approved verbs, robust VM stop)
    Inspired by the principles in "Clean Code" by Robert C. Martin.
#>

[CmdletBinding()]
param(
    # The amount of VRAM to assign to the GPU partition in bytes.
    [long]$PartitionVram = 100MB,
    # The amount of Encode resources to assign to the GPU partition in bytes.
    [long]$PartitionEncode = 100MB,
    # The amount of Decode resources to assign to the GPU partition in bytes.
    [long]$PartitionDecode = 100MB,
    # The amount of Compute resources to assign to the GPU partition in bytes.
    [long]$PartitionCompute = 100MB,
    # MODIFICATION: Changed type to [long] and value to a numeric literal.
    # The amount of Low Memory Mapped I/O space to reserve for the VM.
    [long]$LowMmioSpace = 1GB,
    # The amount of High Memory Mapped I/O space to reserve for the VM.
    [long]$HighMmioSpace = 32GB,
    # The timeout in seconds to wait for the VM to boot and respond to a heartbeat.
    [int]$VmBootTimeoutSeconds = 300
)

# Stop on any error
$ErrorActionPreference = "Stop"

#region Functions
function Get-VMSession {
    [CmdletBinding()]
    param(
        [int]$TimeoutSeconds
    )
    Write-Verbose "Selecting Virtual Machine..."
    $selectedVM = Get-VM | Out-GridView -Title "Select VM to setup GPU-P" -OutputMode Single
    if (-not $selectedVM) {
        Write-Warning "VM selection was canceled. Script will now exit."
        return $null
    }

    Write-Host "Please enter the credentials for an Administrator account INSIDE the VM '$($selectedVM.VMName)'." -ForegroundColor Yellow
    $vmAdminCredential = Get-Credential

    Initialize-VMForDriverInjection -VM $selectedVM -TimeoutSeconds $TimeoutSeconds

    Write-Verbose "Establishing PowerShell session to VM..."
    $vmSession = New-PSSession -VMId $selectedVM.VMId -Credential $vmAdminCredential
    
    return @{ VM = $selectedVM; Session = $vmSession }
}

function Initialize-VMForDriverInjection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine]$VM,
        [int]$TimeoutSeconds
    )
    Write-Verbose "Stopping VM '$($VM.VMName)'..."
    $VM | Stop-VM -Force -ErrorAction SilentlyContinue
    Write-Verbose "Disabling checkpoints..."
    $VM | Set-VM -CheckpointType Disabled
    Write-Verbose "Enabling heartbeat service..."
    $VM | Enable-VMIntegrationService -Name "Heartbeat"
    if ($VM | Get-VMGpuPartitionAdapter) {
        Write-Warning "Removing existing GPU partition adapter from VM."
        $VM | Remove-VMGpuPartitionAdapter
    }

    Write-Verbose "Starting VM to prepare for driver injection..."
    $VM | Start-VM

    Write-Verbose "Waiting for VM heartbeat (Timeout: $TimeoutSeconds seconds)..."
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    do {
        $status = ($VM | Get-VMIntegrationService -Name "Heartbeat").PrimaryStatusDescription
        if ($stopwatch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
            throw "Timeout: VM heartbeat did not return 'OK' within $TimeoutSeconds seconds."
        }
        Start-Sleep -Seconds 2
    } while ($status -ne 'OK')
    $stopwatch.Stop()
    Write-Verbose "VM heartbeat is OK."
}

function Get-PartitionableGpu {
    [CmdletBinding()]
    param()

    Write-Verbose "Selecting host GPU for partitioning..."
    $selectedGpu = Get-PnpDevice -Class Display -Status OK | Out-GridView -Title "Select Host GPU to partition" -OutputMode Single
    if (-not $selectedGpu) {
        Write-Warning "GPU selection was canceled. Script will now exit."
        return $null
    }

    $instanceIdPath = $selectedGpu.InstanceId.Replace('\', '#').ToLower()
    $partitionableGpus = Get-VMHostPartitionableGpu
    $instancePath = $null

    foreach ($gpu in $partitionableGpus) {
        if ($gpu.Name.ToLower().Contains($instanceIdPath)) {
            $instancePath = $gpu.Name
            break
        }
    }

    if (-not $instancePath) {
        throw "Could not find a partitionable instance path for the selected GPU: $($selectedGpu.FriendlyName)."
    }

    Write-Host "`n============================" -ForegroundColor Green
    Write-Host "Using GPU: $($selectedGpu.FriendlyName)"
    Write-Host "Instance Path: $instancePath"
    Write-Host "============================" -ForegroundColor Green

    return @{ GpuDevice = $selectedGpu; InstancePath = $instancePath }
}

function Copy-GpuDriverPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [Parameter(Mandatory = $true)]
        [psobject]$GpuDevice
    )
    Write-Verbose "Getting driver details for selected GPU..."
    $pnpProperties = $GpuDevice | Get-PnpDeviceProperty
    $infPath = ($pnpProperties | Where-Object { $_.KeyName -eq "DEVPKEY_Device_DriverInfPath" }).Data
    $infSection = ($pnpProperties | Where-Object { $_.KeyName -eq "DEVPKEY_Device_DriverInfSection" }).Data
    $driverStorePath = (Get-WindowsDriver -Online | Where-Object { $_.Driver -eq $infPath }).OriginalFileName

    if (-not $driverStorePath) {
        throw "Could not find the driver package for '$($GpuDevice.FriendlyName)'. This device may not be supported."
    }

    $driverPackageDirectory = (Get-Item -LiteralPath $driverStorePath).Directory
    
    $remoteDriverStore = "$($env:SystemRoot)\System32\HostDriverStore\FileRepository"
    $remoteDriverPackagePath = Join-Path $remoteDriverStore $driverPackageDirectory.Name

    if (Invoke-Command -Session $Session -ScriptBlock { Test-Path -Path $using:remoteDriverPackagePath }) {
        Write-Verbose "Driver package '$($driverPackageDirectory.Name)' already exists in the VM. Skipping copy."
        return $false # Indicates that a setup script was NOT written
    }

    Write-Verbose "Copying driver package '$($driverPackageDirectory.Name)' to VM..."
    Invoke-Command -Session $Session -ScriptBlock { New-Item -ItemType Directory -Path $using:remoteDriverStore -Force | Out-Null }
    Copy-Item -LiteralPath $driverPackageDirectory.FullName -ToSession $Session -Destination $remoteDriverStore -Recurse -Force
    
    Write-Verbose "Creating driver setup script inside the VM..."
    $remoteInfPath = Join-Path $remoteDriverPackagePath (Split-Path $infPath -Leaf)
    Invoke-Command -Session $Session -ScriptBlock {
        $batContent = @"
@echo off
echo Installing GPU Drivers... Please wait.
cd /d %TEMP%
set "dirname=gpup_setup_%RANDOM%"
mkdir %dirname%
cd %dirname%
start "" /wait rundll32 advpack.dll,LaunchINFSectionEx "$using:remoteInfPath,$using:infSection,,4"
cd ..
rmdir /s /q %dirname%
echo Done.
pause
"@
        Set-Content -LiteralPath "$env:SystemDrive\GPUPAdditionalSetup.bat" -Encoding utf8 -Value $batContent
    }

    return $true # Indicates that a setup script WAS written
}

function Set-VMGpuConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine]$VM,
        [Parameter(Mandatory = $true)]
        [string]$GpuInstancePath,
        [long]$Vram,
        [long]$Encode,
        [long]$Decode,
        [long]$Compute,
        # MODIFICATION: Changed types from [string] to [long] to match the caller.
        [long]$LowMmio,
        [long]$HighMmio
    )
    Write-Verbose "Configuring GPU-P for VM..."
    $VM | Add-VMGpuPartitionAdapter -InstancePath $GpuInstancePath

    $gpuAdapterParams = @{
        MinPartitionVRAM        = $Vram
        MaxPartitionVRAM        = $Vram
        OptimalPartitionVRAM    = $Vram
        MinPartitionEncode      = $Encode
        MaxPartitionEncode      = $Encode
        OptimalPartitionEncode  = $Encode
        MinPartitionDecode      = $Decode
        MaxPartitionDecode      = $Decode
        OptimalPartitionDecode  = $Decode
        MinPartitionCompute     = $Compute
        MaxPartitionCompute     = $Compute
        OptimalPartitionCompute = $Compute
    }
    $VM | Set-VMGpuPartitionAdapter @gpuAdapterParams
    $VM | Set-VM -GuestControlledCacheTypes $true -LowMemoryMappedIoSpace $LowMmio -HighMemoryMappedIoSpace $HighMmio
}

function Write-PostSetupInstructions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine]$VM,
        [bool]$ScriptWasWritten
    )
    Write-Host "`nDone." -ForegroundColor Green
    if ($ScriptWasWritten) {
        Write-Host "A setup file was created in the VM. You must now:"
        Write-Host "1. Start the VM '$($VM.VMName)'."
        Write-Host "2. Log in and run 'GPUPAdditionalSetup.bat' from the C: drive as an Administrator."
    } else {
        Write-Host "You can now start the VM '$($VM.VMName)'."
    }
}
#endregion

# --- Main Script Workflow ---
$vmContext = $null
try {
    # 1. Select VM and establish a remote session
    $vmContext = Get-VMSession -TimeoutSeconds $VmBootTimeoutSeconds
    if (-not $vmContext) { return } # User canceled

    # 2. Select the host GPU to partition
    $gpuInfo = Get-PartitionableGpu
    if (-not $gpuInfo) { return } # User canceled

    # 3. Copy drivers to the VM if they don't already exist
    $scriptWasWritten = Copy-GpuDriverPackage -Session $vmContext.Session -GpuDevice $gpuInfo.GpuDevice

}
finally {
    # 4. Clean up the remote session and stop the VM for final configuration
    if ($vmContext.Session) {
        Write-Verbose "Closing PSSession to the VM..."
        Remove-PSSession $vmContext.Session
    }
    if ($vmContext.VM) {
        Write-Verbose "Stopping VM for final configuration..."
        $vmContext.VM | Stop-VM -Force -ErrorAction SilentlyContinue
    }
}

# 5. Apply the GPU and memory settings to the VM
Set-VMGpuConfiguration `
    -VM $vmContext.VM `
    -GpuInstancePath $gpuInfo.InstancePath `
    -Vram $PartitionVram `
    -Encode $PartitionEncode `
    -Decode $PartitionDecode `
    -Compute $PartitionCompute `
    -LowMmio $LowMmioSpace `
    -HighMmio $HighMmioSpace

# 6. Display final instructions to the user
Write-PostSetupInstructions -VM $vmContext.VM -ScriptWasWritten $scriptWasWritten