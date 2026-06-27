# ==============================================================================
# AL TAQWA ENTERPRISE TELEMETRY AUDITOR ENGINE v5.0 (STANDALONE)
# ==============================================================================

# Immediately refresh terminal screen and show activity text
Clear-Host
Write-Host "fatching system information from user-19528..." -ForegroundColor Cyan

# Determine Script Directory Execution Path Safely
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition -ErrorAction SilentlyContinue
if ([string]::IsNullOrEmpty($ScriptDir)) { 
    $ScriptDir = $PSScriptRoot 
}
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = [System.Environment]::GetFolderPath("Desktop")
}

# Target and Metric Identification
$TargetHost = [System.Environment]::MachineName
$MetricTimestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

# Compute System Uptime States
$UptimeText = "Unable to calculate"
try {
    $LastBoot = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    if ($LastBoot.LastBootUpTime) {
        $Uptime = (Get-Date) - $LastBoot.LastBootUpTime
        $UptimeText = "$($Uptime.Days) Days, $($Uptime.Hours) Hours"
    }
} catch {
    $UptimeText = "Scope access restricted"
}

# Silicon Architecture & OS Layout Discovery
$HardwareModel = "Generic System Platform"
$PlatformOS = "Microsoft Windows"
$ProcessorName = "Central Compute Silicon Controller"
$ComputeThreads = "Addressable System Thread Vectors"

try {
    $CS = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
    $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    $Proc = Get-CimInstance -ClassName Win32_Processor -ErrorAction SilentlyContinue

    if ($CS) { 
        $HardwareModel = "$($CS.Manufacturer.Trim()) $($CS.Model.Trim())" 
        $ComputeThreads = $CS.NumberOfLogicalProcessors
    }
    if ($OS) { 
        $PlatformOS = "$($OS.Caption) ($($OS.OSArchitecture))" 
    }
    if ($Proc) { 
        $ProcessorName = $Proc.Name.Trim() 
    }
} catch {
    # Defaults are maintained if block fails
}

# Static Logical Storage Volumes Mapping
$DiskRows = ""
try {
    $LogicalDisks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" -ErrorAction SilentlyContinue
    foreach ($L in $LogicalDisks) {
        $TotalGB = [Math]::Round($L.Size / 1GB, 1)
        $FreeGB = [Math]::Round($L.FreeSpace / 1GB, 1)
        $DiskRows += "<tr><td class='accent-cyan'>$($L.DeviceID)</td><td>$TotalGB GB</td><td class='accent-white'>$FreeGB GB Free</td></tr>"
    }
} catch {
    $DiskRows = "<tr><td colspan='3' class='terminal-note-err'>Partition mapping calculation blocked</td></tr>"
}

# Communications Network Interface Maps
$NetRows = ""
try {
    $NetAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" -ErrorAction SilentlyContinue
    foreach ($Net in $NetAdapters) {
        $IPv4Addresses = $Net.IPAddress | Where-Object { $_ -match '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' }
        if ($IPv4Addresses) {
            $Addresses = $IPv4Addresses -join ", "
            $NetRows += "<tr><td class='accent-white'>$($Net.Description)</td><td class='accent-cyan'>$Addresses</td></tr>"
        }
    }
} catch {
    $NetRows = "<tr><td colspan='2' class='terminal-note-err'>Topology collection timed out</td></tr>"
}

# Build File Destination Path safely
$FileName = "Tech_Dashboard_$TargetHost.html"
$OutputDestination = [System.IO.Path]::Combine($ScriptDir, $FileName)

# Safe HTML Generation Engine via Array Joining
$HtmlContent = @(
    "<!DOCTYPE html>",
    "<html>",
    "<head>",
    "    <meta charset='UTF-8'>",
    "    <title>Telemetry Report</title>",
    "    <style>",
    "        body { font-family: 'Consolas', monospace; background-color: #050507; color: #a0aab5; margin: 40px; line-height: 1.5; }",
    "        .dashboard-canvas { max-width: 900px; margin: 0 auto; border: 1px solid #1f2430; padding: 25px; background: #0a0a0c; border-radius: 4px; }",
    "        h1 { color: #00f0ff; border-bottom: 2px solid #00f0ff; padding-bottom: 10px; margin-top: 0; }",
    "        h2 { color: #00f0ff; margin-top: 30px; border-bottom: 1px solid #1f2430; padding-bottom: 5px; font-size: 1.1rem; }",
    "        table { width: 100%; border-collapse: collapse; margin-top: 10px; }",
    "        th, td { text-align: left; padding: 10px; border: 1px solid #151922; }",
    "        th { background-color: #10141d; color: #00f0ff; }",
    "        .accent-white { color: #ffffff; }",
    "        .accent-cyan { color: #00f0ff; }",
    "        .terminal-note-err { color: #ff3333; font-style: italic; }",
    "        .meta-box { background: #11141a; padding: 15px; border-left: 4px solid #00f0ff; margin-bottom: 20px; }",
    "    </style>",
    "</head>",
    "<body>",
    "    <div class='dashboard-canvas'>",
    "        <h1>AL TAQWA TELEMETRY MATRIX REPORT</h1>",
    "        <div class='meta-box'>",
    "            <strong>Target Host Node:</strong> $TargetHost<br>",
    "            <strong>Scan Clock Timestamp:</strong> $MetricTimestamp<br>",
    "            <strong>Device Uptime State:</strong> $UptimeText",
    "        </div>",
    "        <h2>Silicon Architecture & OS Layout</h2>",
    "        <p>",
    "            <strong>Platform:</strong> $PlatformOS<br>",
    "            <strong>Processor:</strong> $ProcessorName<br>",
    "            <strong>Threads:</strong> $ComputeThreads<br>",
    "            <strong>Model:</strong> $HardwareModel",
    "        </p>",
    "        <h2>Static Logical Storage Volumes</h2>",
    "        <table>",
    "            <tr><th>Drive ID</th><th>Total Size</th><th>Available Space</th></tr>",
    "            $DiskRows",
    "        </table>",
    "        <h2>Communications Network Interface Maps</h2>",
    "        <table>",
    "            <tr><th>Interface Description</th><th>Assigned IP Strings</th></tr>",
    "            $NetRows",
    "        </table>",
    "    </div>",
    "</body>",
    "</html>"
) -join "`n"

# Output Generation and Autostart Execution
[System.IO.File]::WriteAllText($OutputDestination, $HtmlContent)
Write-Host "Done! Launching dashboard..." -ForegroundColor Green
Invoke-Item $OutputDestination
