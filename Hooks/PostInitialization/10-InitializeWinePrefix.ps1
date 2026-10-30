#Requires -Modules Logging
#Requires -Modules Hooks

# Create the Wine prefix as the user the server runs as. Wine refuses to use a prefix owned by
# another user, and doing this here keeps the first server start from stalling inside wineboot.
# Runs as 10- so game install hooks (20-*) can already use the prefix.

Invoke-Hook "PreInitializeWinePrefix"

$prefix = $Env:WINEPREFIX
$runAs  = "$($Env:UID):$($Env:GID)"

if (-not (Test-Path -Path (Join-Path $prefix 'system.reg'))) {
    Write-Log "Initializing Wine prefix at $prefix (first start, this can take a minute)"

    New-Item -ItemType Directory -Path $prefix -Force | Out-Null
    chown $runAs $prefix

    & gosu $runAs wineboot --init
    & gosu $runAs wineserver --wait

    Write-Log "Wine prefix initialized"
} else {
    Write-Log "Using existing Wine prefix at $prefix"
}

Invoke-Hook "PostInitializeWinePrefix"
