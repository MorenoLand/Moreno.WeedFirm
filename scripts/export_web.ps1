param(
	[Parameter(Mandatory = $true)][string]$Engine,
	[Parameter(Mandatory = $true)][string]$Out,
	[string]$Preset = "Web",
	[string]$Apk = ""
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
if ($Apk -ne "") {
	$bundle = Join-Path (Resolve-Path $Out) "data.pck"
	$icon = Join-Path (Resolve-Path $Out) "index.icon.png"
	$log = & $Engine --headless --path $project --script res://scripts/extract_cli.gd -- (Resolve-Path $Apk).Path $bundle $icon
	if ($LASTEXITCODE -ne 0 -or -not (Test-Path $bundle)) { throw "Could not build the asset bundle from $Apk" }
	Copy-Item $icon (Join-Path (Resolve-Path $Out) "index.apple-touch-icon.png") -Force
	$title = ($log | Where-Object { $_ -match "^TITLE=" } | Select-Object -First 1) -replace "^TITLE=", ""
	if ($title) {
		$html = Join-Path (Resolve-Path $Out) "index.html"
		(Get-Content $html -Raw).Replace("Moreno.WeedFirm", $title) | Set-Content $html -NoNewline
	}
	Write-Host "Bundled game data into $bundle (local use only, do not publish)"
}
Write-Host "Exported to $Out"
Get-ChildItem $Out | Where-Object { $_.Name -like "index.*" -or $_.Name -eq "data.pck" } | ForEach-Object { "{0,12:N0}  {1}" -f $_.Length, $_.Name }
