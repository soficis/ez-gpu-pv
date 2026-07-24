#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Configures or reverses Hyper-V Virtual Machine GPU Partitioning (GPU-P).
.DESCRIPTION
    Automates assigning host GPU partitions to Hyper-V virtual machines or undoing GPU-P.
    Includes host driver copying, VM configuration, and automated cleanup.
.PARAMETER PartitionVram
    Amount of VRAM assigned to the GPU partition (default: 1GB).
.PARAMETER PartitionEncode
    Amount of Encode resources assigned to the GPU partition (default: 500MB).
.PARAMETER PartitionDecode
    Amount of Decode resources assigned to the GPU partition (default: 500MB).
.PARAMETER PartitionCompute
    Amount of Compute resources assigned to the GPU partition (default: 500MB).
.PARAMETER LowMmioSpace
    Low Memory Mapped I/O space reserved for the VM (default: 1GB).
.PARAMETER HighMmioSpace
    High Memory Mapped I/O space reserved for the VM (default: 32GB).
.PARAMETER VmBootTimeoutSeconds
    Timeout in seconds waiting for VM heartbeat during startup (default: 300).
.PARAMETER SkipDriverCopy
    Skips checking and copying GPU drivers to the VM (useful if drivers were already copied).
.PARAMETER Reverse
    Reverses GPU Partitioning on the selected VM and restores Hyper-V defaults.
#>

[CmdletBinding()]
param(
    [long]$PartitionVram = 1GB,
    [long]$PartitionEncode = 500MB,
    [long]$PartitionDecode = 500MB,
    [long]$PartitionCompute = 500MB,
    [long]$LowMmioSpace = 1GB,
    [long]$HighMmioSpace = 32GB,
    [int]$VmBootTimeoutSeconds = 300,
    [switch]$SkipDriverCopy,
    [switch]$Reverse
)

$ErrorActionPreference = "Stop"

#region Helper Functions

function Show-Header {
    [CmdletBinding()]
    param([string]$Title)

    Clear-Host
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "                EZ-GPU-PV WIZARD                          " -ForegroundColor Cyan
    Write-Host "   $Title" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Step {
    [CmdletBinding()]
    param(
        [int]$StepNumber,
        [int]$TotalSteps,
        [string]$Message
    )
    Write-Host "`n[$StepNumber/$TotalSteps] $Message" -ForegroundColor Green
}

function Select-TargetVM {
    [CmdletBinding()]
    param([string]$Title = "Select Virtual Machine")

    Write-Verbose "Querying Hyper-V Virtual Machines..."
    $vm = Get-VM | Out-GridView -Title $Title -OutputMode Single
    if (-not $vm) {
        Write-Warning "VM selection was canceled. Exiting wizard."
        return $null
    }
    return $vm
}

function Stop-VMWithWait {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine]$VM
    )

    if ($VM.State -ne 'Off') {
        Write-Verbose "Stopping VM '$($VM.VMName)'..."
        $VM | Stop-VM -Force -ErrorAction SilentlyContinue
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        while ((Get-VM -Id $VM.VMId).State -ne 'Off') {
            if ($stopwatch.Elapsed.TotalSeconds -ge 60) {
                throw "Failed to stop VM '$($VM.VMName)' within 60 seconds."
            }
            Start-Sleep -Seconds 2
        }
        $stopwatch.Stop()
    }
}

function Wait-VMHeartbeat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Microsoft.HyperV.PowerShell.VirtualMachine]$VM,
        [int]$TimeoutSeconds
    )

    Write-Verbose "Starting VM '$($VM.VMName)'..."
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

function Get-VMAdminCredential {
    [CmdletBinding()]
    param([string]$VMName)

    Write-Host "Please enter Administrator credentials for INSIDE the VM '$VMName':" -ForegroundColor Yellow
    return Get-Credential
}

function Select-PartitionableGpu {
    [CmdletBinding()]
    param()

    $selectedGpu = Get-PnpDevice -Class Display -Status OK | Out-GridView -Title "Select Host GPU for GPU-P" -OutputMode Single
    if (-not $selectedGpu) {
        Write-Warning "GPU selection was canceled. Exiting wizard."
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
        throw "Could not find a partitionable instance path for GPU '$($selectedGpu.FriendlyName)'."
    }

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

    $pnpProperties = $GpuDevice | Get-PnpDeviceProperty
    $infPath = ($pnpProperties | Where-Object { $_.KeyName -eq "DEVPKEY_Device_DriverInfPath" }).Data
    $infSection = ($pnpProperties | Where-Object { $_.KeyName -eq "DEVPKEY_Device_DriverInfSection" }).Data
    $driverStorePath = (Get-WindowsDriver -Online | Where-Object { $_.Driver -eq $infPath }).OriginalFileName

    if (-not $driverStorePath) {
        throw "Driver package for '$($GpuDevice.FriendlyName)' could not be located."
    }

    $driverPackageDirectory = (Get-Item -LiteralPath $driverStorePath).Directory
    $remoteDriverStore = "$($env:SystemRoot)\System32\HostDriverStore\FileRepository"
    $remoteDriverPackagePath = Join-Path $remoteDriverStore $driverPackageDirectory.Name

    Write-Verbose "Clearing old HostDriverStore in VM to ensure a clean driver installation..."
    Invoke-Command -Session $Session -ScriptBlock {
        Remove-Item -Path "$($env:SystemRoot)\System32\HostDriverStore" -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Verbose "Copying GPU drivers to VM..."
    Invoke-Command -Session $Session -ScriptBlock {
        New-Item -ItemType Directory -Path $using:remoteDriverStore -Force | Out-Null
    }
    Copy-Item -LiteralPath $driverPackageDirectory.FullName -ToSession $Session -Destination $remoteDriverStore -Recurse -Force

    Write-Verbose "Writing driver setup script inside VM..."
    $remoteInfFileName = Split-Path $driverStorePath -Leaf
    $remoteInfPath = Join-Path $remoteDriverPackagePath $remoteInfFileName
    Invoke-Command -Session $Session -ScriptBlock {
        $batContent = @"
@echo off
echo Installing GPU Drivers... Please wait.
cd /d %TEMP%
set "dirname=gpup_setup_%RANDOM%"
mkdir %dirname%
cd %dirname%
pnputil /add-driver "$using:remoteInfPath" /install >nul 2>&1
start "" /wait rundll32 advpack.dll,LaunchINFSectionEx "$using:remoteInfPath,$using:infSection,,4"
cd ..
rmdir /s /q %dirname%
echo Driver setup completed.
pause
"@
        Set-Content -LiteralPath "$env:SystemDrive\GPUPAdditionalSetup.bat" -Encoding Ascii -Value $batContent
    }

    return $true
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
        [long]$LowMmio,
        [long]$HighMmio
    )

    $VM | Add-VMGpuPartitionAdapter -InstancePath $GpuInstancePath

    $gpuAdapterParams = @{
        MinPartitionVRAM        = 1
        MaxPartitionVRAM        = $Vram
        OptimalPartitionVRAM    = $Vram
        MinPartitionEncode      = 1
        MaxPartitionEncode      = $Encode
        OptimalPartitionEncode  = $Encode
        MinPartitionDecode      = 1
        MaxPartitionDecode      = $Decode
        OptimalPartitionDecode  = $Decode
        MinPartitionCompute     = 1
        MaxPartitionCompute     = $Compute
        OptimalPartitionCompute = $Compute
    }

    $VM | Set-VMGpuPartitionAdapter @gpuAdapterParams
    $VM | Set-VM -GuestControlledCacheTypes $true -LowMemoryMappedIoSpace $LowMmio -HighMemoryMappedIoSpace $HighMmio
}

#endregion

#region Workflows

function Invoke-GpuPartitionSetup {
    Show-Header -Title "Setup Mode (Enable GPU-P)"

    # Step 1: VM Selection
    Show-Step -StepNumber 1 -TotalSteps 4 -Message "Selecting target Virtual Machine..."
    $vm = Select-TargetVM -Title "Select VM to enable GPU-P"
    if (-not $vm) { return }

    # Step 2: GPU Selection
    Show-Step -StepNumber 2 -TotalSteps 4 -Message "Selecting host GPU..."
    $gpuInfo = Select-PartitionableGpu
    if (-not $gpuInfo) { return }

    # Summary & Confirmation
    Write-Host "`nSummary of configuration to apply:" -ForegroundColor Yellow
    Write-Host "  VM Name:       $($vm.VMName)"
    Write-Host "  GPU Name:      $($gpuInfo.GpuDevice.FriendlyName)"
    Write-Host "  Partition VRAM: $($PartitionVram / 1MB) MB"
    Write-Host "  Low MMIO:      $($LowMmioSpace / 1MB) MB"
    Write-Host "  High MMIO:     $($HighMmioSpace / 1GB) GB"
    
    $confirm = Read-Host "`nDo you want to proceed with GPU-P setup? (Y/N)"
    if ($confirm -notmatch '^(y|yes)$') {
        Write-Warning "Operation canceled by user."
        return
    }

    # Step 3: Driver Copy & VM Initialization
    Show-Step -StepNumber 3 -TotalSteps 4 -Message "Preparing VM and transferring GPU drivers..."
    Stop-VMWithWait -VM $vm
    $vm | Set-VM -CheckpointType Disabled
    $vm | Enable-VMIntegrationService -Name "Heartbeat"

    if ($vm | Get-VMGpuPartitionAdapter) {
        Write-Verbose "Removing existing GPU partition adapter..."
        $vm | Remove-VMGpuPartitionAdapter
    }

    $scriptWritten = $false
    if ($SkipDriverCopy) {
        Write-Host "  [*] -SkipDriverCopy specified. Skipping VM remote driver transfer." -ForegroundColor Cyan
    } else {
        $cred = Get-VMAdminCredential -VMName $vm.VMName
        Wait-VMHeartbeat -VM $vm -TimeoutSeconds $VmBootTimeoutSeconds

        $session = $null
        try {
            $session = New-PSSession -VMId $vm.VMId -Credential $cred
            $scriptWritten = Copy-GpuDriverPackage -Session $session -GpuDevice $gpuInfo.GpuDevice
        }
        finally {
            if ($session) {
                Remove-PSSession $session
            }
            Stop-VMWithWait -VM $vm
        }
    }

    # Step 4: Host GPU-P Configuration
    Show-Step -StepNumber 4 -TotalSteps 4 -Message "Applying GPU partition settings..."
    Set-VMGpuConfiguration `
        -VM $vm `
        -GpuInstancePath $gpuInfo.InstancePath `
        -Vram $PartitionVram `
        -Encode $PartitionEncode `
        -Decode $PartitionDecode `
        -Compute $PartitionCompute `
        -LowMmio $LowMmioSpace `
        -HighMmio $HighMmioSpace

    # Completion Instructions
    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "  GPU Partitioning successfully configured for '$($vm.VMName)'!" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
    if ($scriptWritten) {
        Write-Host "Next steps inside the VM:" -ForegroundColor Yellow
        Write-Host "  1. Start VM '$($vm.VMName)'."
        Write-Host "  2. Log in and right-click 'C:\GPUPAdditionalSetup.bat' -> Run as administrator."
        Write-Host "  3. Reboot the VM after driver installation finishes."
    } else {
        Write-Host "Setup complete. You can now boot your VM '$($vm.VMName)'." -ForegroundColor Yellow
    }
}

function Invoke-GpuPartitionReversal {
    Show-Header -Title "Reversal Mode (Disable GPU-P & Restore Defaults)"

    # Step 1: Select VM
    Show-Step -StepNumber 1 -TotalSteps 3 -Message "Selecting Target VM to reverse GPU-P..."
    $vm = Select-TargetVM -Title "Select VM to remove GPU-P"
    if (-not $vm) { return }

    $confirm = Read-Host "`nAre you sure you want to remove GPU-P settings from '$($vm.VMName)'? (Y/N)"
    if ($confirm -notmatch '^(y|yes)$') {
        Write-Warning "Operation canceled by user."
        return
    }

    # Step 2: Remove Partition Adapter & Restore Hyper-V Defaults
    Show-Step -StepNumber 2 -TotalSteps 3 -Message "Restoring host-side VM settings..."
    Stop-VMWithWait -VM $vm

    if ($vm | Get-VMGpuPartitionAdapter) {
        $vm | Remove-VMGpuPartitionAdapter
        Write-Host "  [+] Removed GPU Partition Adapter" -ForegroundColor Cyan
    } else {
        Write-Host "  [*] No GPU Partition Adapter found on VM" -ForegroundColor Gray
    }

    # Restore default VM settings (Standard Checkpoints, Disabled Cache Types, Standard MMIO)
    $vm | Set-VM -CheckpointType Standard -GuestControlledCacheTypes $false -LowMemoryMappedIoSpace 128MB -HighMemoryMappedIoSpace 512MB
    Write-Host "  [+] Restored Checkpoints to Standard" -ForegroundColor Cyan
    Write-Host "  [+] Restored GuestControlledCacheTypes to false" -ForegroundColor Cyan
    Write-Host "  [+] Restored MMIO spaces (Low: 128MB, High: 512MB)" -ForegroundColor Cyan

    # Step 3: Optional Driver Cleanup inside VM
    Show-Step -StepNumber 3 -TotalSteps 3 -Message "VM Driver Cleanup Option"
    $cleanVM = Read-Host "Do you want to delete host driver files inside the VM? (Y/N)"
    
    if ($cleanVM -match '^(y|yes)$') {
        try {
            $cred = Get-VMAdminCredential -VMName $vm.VMName
            Write-Host "Starting VM to perform driver cleanup..." -ForegroundColor Yellow
            Wait-VMHeartbeat -VM $vm -TimeoutSeconds $VmBootTimeoutSeconds
            
            $session = New-PSSession -VMId $vm.VMId -Credential $cred
            try {
                Invoke-Command -Session $session -ScriptBlock {
                    $storePath = "$($env:SystemRoot)\System32\HostDriverStore"
                    $batPath = "$env:SystemDrive\GPUPAdditionalSetup.bat"
                    
                    if (Test-Path $storePath) {
                        Remove-Item -Path $storePath -Recurse -Force -ErrorAction SilentlyContinue
                        Write-Host "  [+] Removed HostDriverStore inside VM"
                    }
                    if (Test-Path $batPath) {
                        Remove-Item -Path $batPath -Force -ErrorAction SilentlyContinue
                        Write-Host "  [+] Removed GPUPAdditionalSetup.bat inside VM"
                    }
                }
            }
            finally {
                Remove-PSSession $session
                Stop-VMWithWait -VM $vm
            }
        }
        catch {
            Write-Warning "Could not complete inside-VM driver cleanup: $_"
        }
    } else {
        Write-Host "Skipping inside-VM driver cleanup." -ForegroundColor Gray
    }

    Write-Host "`n==========================================================" -ForegroundColor Green
    Write-Host "  GPU Partition Reversal Complete for '$($vm.VMName)'!" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Green
}

#endregion

# --- Main Entry Point ---
if ($Reverse) {
    Invoke-GpuPartitionReversal
} else {
    Invoke-GpuPartitionSetup
}