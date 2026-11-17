param(
  [switch]$SplitPerAbi
)

$frontendPath = Join-Path $PSScriptRoot 'sicklecare_frontend'
$pubspecPath = Join-Path $frontendPath 'pubspec.yaml'
$firebaseConfigPath = Join-Path $frontendPath 'android\app\google-services.json'

if (-not (Test-Path $pubspecPath)) {
  Write-Error "Flutter project not found: $pubspecPath"
  exit 1
}

if (-not (Test-Path $firebaseConfigPath)) {
  Write-Error @"
Android Firebase config is missing:
  $firebaseConfigPath
Configure the approved Firebase Android app before building.
"@
  exit 1
}

Push-Location $frontendPath
try {
  & flutter pub get
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  $buildArgs = @('build', 'apk', '--release')
  if ($SplitPerAbi) {
    $buildArgs += '--split-per-abi'
  }

  & flutter @buildArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  $apkDirectory = Join-Path $frontendPath 'build\app\outputs\flutter-apk'
  Get-ChildItem -Path $apkDirectory -Filter '*-release.apk' |
    Select-Object FullName, Length, LastWriteTime
} finally {
  Pop-Location
}
