param(
	[Parameter(Mandatory = $true)][string]$Engine,
	[Parameter(Mandatory = $true)][string]$Out,
	[string]$Preset = "Web"
)
$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
if (Test-Path $Engine -PathType Container) {
	$exes = Get-ChildItem $Engine -Filter *.exe
	$exe = $exes | Where-Object { $_.Name -match "console" } | Select-Object -First 1
	if (-not $exe) { $exe = $exes | Where-Object { $_.Name -match "redot|godot" } | Select-Object -First 1 }
	if (-not $exe) { throw "No Redot/Godot executable found in $Engine" }
	$Engine = $exe.FullName
}
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$target = Join-Path (Resolve-Path $Out) "index.html"
& $Engine --headless --path $project --import | Out-Null
& $Engine --headless --path $project --export-release $Preset $target
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $target)) { throw "Export failed (is the $Preset preset and the engine's web export template installed?)" }
Write-Host "Exported to $Out"
Get-ChildItem $Out -Filter "index.*" | ForEach-Object { "{0,12:N0}  {1}" -f $_.Length, $_.Name }
