[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$stateDir = Join-Path $env:TEMP 'emi-speaking'
$stateFile = Join-Path $stateDir 'processes.json'

function Test-UnderRoot([string]$Path) {
    try {
        $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
        return $full.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)
    } catch { return $false }
}

if (-not (Test-Path -LiteralPath $stateFile -PathType Leaf)) {
    Write-Output 'Speaking stack is already stopped.'
    exit 0
}

try { $items = @(ConvertFrom-Json ([IO.File]::ReadAllText($stateFile))) } catch { throw "Invalid state file: $stateFile" }
$failures = New-Object System.Collections.ArrayList
foreach ($item in $items) {
    try {
        if ($null -eq $item.pid -or $null -eq $item.startTimeUtc -or $null -eq $item.executable -or $null -eq $item.role -or $null -eq $item.workingDirectory -or $null -eq $item.commandLineHint) { throw 'Incomplete state entry' }
        if (-not (Test-UnderRoot ([string]$item.workingDirectory))) { throw 'Working-directory hint is outside root' }
        $process = Get-Process -Id ([int]$item.pid) -ErrorAction SilentlyContinue
        if ($null -eq $process) { continue }
        $expectedStart = [DateTime]::Parse([string]$item.startTimeUtc).ToUniversalTime()
        if ([Math]::Abs(($process.StartTime.ToUniversalTime() - $expectedStart).TotalSeconds) -gt 1) { throw 'Process start time mismatch' }
        $cim = Get-CimInstance Win32_Process -Filter ("ProcessId=" + [int]$item.pid) -ErrorAction Stop
        if ($null -eq $cim) { continue }
        if (-not [string]::Equals([IO.Path]::GetFullPath([string]$cim.ExecutablePath), [IO.Path]::GetFullPath([string]$item.executable), [StringComparison]::OrdinalIgnoreCase)) { throw 'Executable mismatch' }
        $commandLine = [string]$cim.CommandLine
        if ([string]::IsNullOrWhiteSpace($commandLine) -or $commandLine.IndexOf([string]$item.commandLineHint, [StringComparison]::OrdinalIgnoreCase) -lt 0) { throw 'Command line mismatch' }
        & "$env:SystemRoot\System32\taskkill.exe" /PID ([int]$item.pid) /T /F | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'taskkill failed' }
    } catch {
        [void]$failures.Add(('{0} PID {1}: {2}' -f $item.role, $item.pid, $_.Exception.Message))
    }
}

if ($failures.Count -gt 0) { throw ($failures -join [Environment]::NewLine) }
Remove-Item -LiteralPath $stateFile -Force
Write-Output 'Speaking stack stopped.'
