param (
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [Parameter(Mandatory = $true)]
    [string]$Major,
    [Parameter(Mandatory = $true)]
    [string]$Minor
)

$ErrorActionPreference = 'Stop'

# Prerelease suffix (e.g. beta) is optional; msbuild returns an empty string when it is absent.
$suffix = (dotnet msbuild $Project -getProperty:VersionSuffix).Trim()

# Patch = commits since the version LINE last changed. -G'<Version' matches only commits whose diff
# touched a <VersionPrefix>/<VersionSuffix> line, so other edits to the props file are ignored.
$set = (git log -1 --format=%H '-G<Version' -- $Project).Trim()
if ($set) {
    $count = (git rev-list --count "$set..HEAD").Trim()
}
else {
    $count = (git rev-list --count HEAD).Trim()
}

if ($suffix) {
    $version = "$Major.$Minor.0-$suffix.$count"
}
else {
    $version = "$Major.$Minor.$count"
}
$assemblyVersion = "$Major.0.0.0"
$fileVersion = "$Major.$Minor.$count.0"

$isPrerelease = if ($suffix) { 'true' } else { 'false' }

Write-Output "Version is $version (assembly $assemblyVersion, file $fileVersion)"

"version=$version" >> $Env:GITHUB_OUTPUT
"assembly-version=$assemblyVersion" >> $Env:GITHUB_OUTPUT
"file-version=$fileVersion" >> $Env:GITHUB_OUTPUT
"patch=$count" >> $Env:GITHUB_OUTPUT
"version-suffix=$suffix" >> $Env:GITHUB_OUTPUT
"is-prerelease=$isPrerelease" >> $Env:GITHUB_OUTPUT

Write-Output "::notice::Version $version (assembly $assemblyVersion)"
