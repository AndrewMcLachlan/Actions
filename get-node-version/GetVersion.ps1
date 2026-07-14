param (
    [Parameter(Mandatory = $false)]
    [string]$PackageFile = 'package.json'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $PackageFile)) {
    throw "Package file '$PackageFile' not found."
}

# The version is *stated*, not inferred. Only Major.Minor and the optional prerelease
# suffix are authoritative; the patch is computed from the commit count below.
$stated = (Get-Content -Path $PackageFile -Raw | ConvertFrom-Json).version
if (-not $stated) {
    throw "Could not find a 'version' field in '$PackageFile'."
}

Write-Output "Read stated version '$stated' from $PackageFile"

# Split off an optional prerelease suffix (e.g. 5.0.0-beta -> core '5.0.0', suffix 'beta').
$core, $suffix = $stated -split '-', 2

$parts = $core -split '\.'
$major = $parts[0]
$minor = $parts[1]

if ($major -notmatch '^\d+$' -or $minor -notmatch '^\d+$') {
    throw "Stated version '$stated' is not a valid Major.Minor version."
}

# Patch = commits since the version LINE last changed. -G'"version":' matches only commits whose
# diff touched a line containing the "version": key, so other edits to package.json are ignored.
$set = (git log -1 --format=%H '-G"version":' -- $PackageFile 2>$null | Out-String).Trim()
if ($set) {
    $patch = (git rev-list --count "$set..HEAD" | Out-String).Trim()
}
else {
    $patch = (git rev-list --count HEAD | Out-String).Trim()
}

if ($suffix) {
    $version = "$major.$minor.0-$suffix.$patch"
    $isPrerelease = 'true'
}
else {
    $version = "$major.$minor.$patch"
    $isPrerelease = 'false'
}

Write-Output "Version is $version"

"version=$version"             >> $Env:GITHUB_OUTPUT
"major=$major"                 >> $Env:GITHUB_OUTPUT
"minor=$minor"                 >> $Env:GITHUB_OUTPUT
"patch=$patch"                 >> $Env:GITHUB_OUTPUT
"suffix=$suffix"               >> $Env:GITHUB_OUTPUT
"is-prerelease=$isPrerelease"  >> $Env:GITHUB_OUTPUT

Write-Output "::notice::Version $version"
