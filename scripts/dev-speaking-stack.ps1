[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$frontend = Join-Path $root 'Emi-Frontend'
$backend = Join-Path $root 'Emi-Backend'
$ai = Join-Path $root 'Emi-Speaking-AI'
$stateDir = Join-Path $env:TEMP 'emi-speaking'
$stateFile = Join-Path $stateDir 'processes.json'
$roles = New-Object System.Collections.ArrayList
$managedEnvNames = @('SPEAKING_AI_SERVICE_TOKEN', 'SPEAKING_AI_ENABLED', 'SPEAKING_AI_BASE_URL', 'NEXT_PUBLIC_API_BASE_URL')
$originalEnv = @{}
foreach ($name in $managedEnvNames) { $originalEnv[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }

function Resolve-CommandPath([string]$Name) {
    $command = Get-Command $Name -CommandType Application -ErrorAction Stop | Select-Object -First 1
    return [IO.Path]::GetFullPath($command.Source)
}

function Read-EnvValue([string]$Path, [string]$Name) {
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*#') { continue }
        if ($line -match ('^\s*' + [regex]::Escape($Name) + '\s*=\s*(.*)\s*$')) {
            $value = $matches[1].Trim()
            if ($value.Length -ge 2 -and (($value[0] -eq '"' -and $value[$value.Length - 1] -eq '"') -or ($value[0] -eq "'" -and $value[$value.Length - 1] -eq "'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            return $value
        }
    }
    return $null
}

function Test-PortFree([int]$Port) {
    $listener = New-Object Net.Sockets.TcpListener([Net.IPAddress]::Loopback, $Port)
    try { $listener.Start(); return $true } catch { return $false } finally { try { $listener.Stop() } catch {} }
}

function Save-State {
    $json = ConvertTo-Json -InputObject @($roles) -Depth 4
    [IO.File]::WriteAllText($stateFile, $json, (New-Object Text.UTF8Encoding($false)))
}

function Start-Role([string]$Role, [string]$Executable, [string]$Arguments, [string]$WorkingDirectory, [string]$Hint) {
    if (-not (Test-Path -LiteralPath $stateDir -PathType Container)) { throw "State directory missing: $stateDir" }
    $stdout = Join-Path $stateDir ($Role + '.out.log')
    $stderr = Join-Path $stateDir ($Role + '.err.log')
    $process = Start-Process -FilePath $Executable -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -RedirectStandardOutput $stdout -RedirectStandardError $stderr -WindowStyle Hidden -PassThru
    if ($null -eq $process) { throw "Failed to start $Role" }
    $process.Refresh()
    $actualExecutable = $process.Path
    if ([string]::IsNullOrWhiteSpace($actualExecutable)) {
        $actualExecutable = (Get-CimInstance Win32_Process -Filter ("ProcessId=" + $process.Id) -ErrorAction Stop).ExecutablePath
    }
    if ([string]::IsNullOrWhiteSpace($actualExecutable)) { throw "Cannot resolve executable for $Role" }
    [void]$roles.Add([pscustomobject]@{
        role = $Role
        pid = $process.Id
        startTimeUtc = $process.StartTime.ToUniversalTime().ToString('o')
        executable = [IO.Path]::GetFullPath($actualExecutable)
        workingDirectory = [IO.Path]::GetFullPath($WorkingDirectory)
        commandLineHint = $Hint
    })
    Save-State
}

function Wait-Ready([string]$Role, [string]$Url, [int]$Seconds) {
    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 3
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) { return }
        } catch {}
        Start-Sleep -Milliseconds 500
    }
    throw "$Role readiness timed out: $Url"
}

function Stop-StartedRoles {
    foreach ($item in @($roles | Sort-Object pid -Descending)) {
        try { & "$env:SystemRoot\System32\taskkill.exe" /PID $item.pid /T /F | Out-Null } catch {}
    }
    if (Test-Path -LiteralPath $stateFile) { Remove-Item -LiteralPath $stateFile -Force }
}

try {
    $branch = (& git -C $root branch --show-current 2>$null).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'feature/nextjs-web') { throw 'Required git branch: feature/nextjs-web' }
    foreach ($directory in @($frontend, $backend, $ai)) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) { throw "Required directory missing: $directory" }
    }
    $frontendEnv = Join-Path $frontend '.env.local'
    $backendEnv = Join-Path $backend '.env'
    foreach ($file in @($frontendEnv, $backendEnv)) {
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Required file missing: $file" }
    }
    foreach ($dependencyDirectory in @((Join-Path $frontend 'node_modules'), (Join-Path $backend 'vendor'))) {
        if (-not (Test-Path -LiteralPath $dependencyDirectory -PathType Container)) { throw "Required dependency directory missing: $dependencyDirectory" }
    }
    $venv = [IO.Path]::GetFullPath((Join-Path $ai '.venv'))
    $python = [IO.Path]::GetFullPath((Join-Path $venv 'Scripts\python.exe'))
    if (-not $python.StartsWith($ai + '\', [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $python -PathType Leaf)) { throw "AI worktree venv Python missing: $python" }
    foreach ($port in @(3000, 8000, 8001)) {
        if (-not (Test-PortFree $port)) { throw "Port $port is in use; no process was stopped" }
    }
    if (-not (Test-PortFree 3001)) { throw 'Port 3001 is in use. Stop existing EMI Next runtime using its owning launcher, then retry; no process was stopped.' }
    if (Test-Path -LiteralPath $stateFile) { throw "State file already exists; run stop-speaking-stack.ps1: $stateFile" }
    if (-not (Test-Path -LiteralPath $stateDir)) { [void](New-Item -ItemType Directory -Path $stateDir) }
    if (-not (Test-Path -LiteralPath $stateDir -PathType Container)) { throw "Cannot create state directory: $stateDir" }
    $token = [Environment]::GetEnvironmentVariable('SPEAKING_AI_SERVICE_TOKEN', 'Process')
    if ([string]::IsNullOrWhiteSpace($token)) { $token = Read-EnvValue $backendEnv 'SPEAKING_AI_SERVICE_TOKEN' }
    if ([string]::IsNullOrWhiteSpace($token)) { throw 'SPEAKING_AI_SERVICE_TOKEN must be nonblank in process environment or backend .env' }
    $env:SPEAKING_AI_SERVICE_TOKEN = $token
    $env:SPEAKING_AI_ENABLED = 'true'
    $env:SPEAKING_AI_BASE_URL = 'http://127.0.0.1:8001'
    $env:NEXT_PUBLIC_API_BASE_URL = 'http://127.0.0.1:8000/api/v1'
    $php = Resolve-CommandPath 'php.exe'
    $npm = Resolve-CommandPath 'npm.cmd'
    & $php (Join-Path $backend 'artisan') config:clear
    if ($LASTEXITCODE -ne 0) { throw 'Laravel config:clear failed' }
    & $php (Join-Path $backend 'artisan') migrate --force
    if ($LASTEXITCODE -ne 0) { throw 'Laravel migration failed' }
    Start-Role 'fastapi' $python '-m uvicorn main:app --host 127.0.0.1 --port 8001' $ai 'uvicorn main:app'
    Start-Role 'laravel' $php 'artisan serve --host=127.0.0.1 --port=8000' $backend 'artisan serve'
    Start-Role 'queue' $php 'artisan queue:work' $backend 'artisan queue:work'
    Start-Role 'next' $npm 'run dev -- --hostname 127.0.0.1 --port 3000' $frontend 'npm.cmd'
    Start-Sleep -Seconds 2
    $queueRole = @($roles | Where-Object role -eq 'queue')[-1]
    if (-not (Get-Process -Id $queueRole.pid -ErrorAction SilentlyContinue)) { throw "Queue worker exited during startup. Check: $(Join-Path $stateDir 'queue.out.log')" }
    Wait-Ready 'FastAPI' 'http://127.0.0.1:8001/health' 90
    Wait-Ready 'Laravel' 'http://127.0.0.1:8000' 90
    Wait-Ready 'Next.js' 'http://127.0.0.1:3000' 120
    Write-Output "Speaking stack ready. State: $stateFile"
} catch {
    Stop-StartedRoles
    throw
} finally {
    Remove-Variable token -ErrorAction SilentlyContinue
    foreach ($name in $managedEnvNames) { [Environment]::SetEnvironmentVariable($name, $originalEnv[$name], 'Process') }
}
