param([string]$Godot = "")
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$qaArguments = @('tools/qa.py', '--ui', '--export')
if ($Godot) { $qaArguments += @('--godot', $Godot) }
& '.venv/Scripts/python.exe' @qaArguments
exit $LASTEXITCODE
