param (
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [Parameter(Mandatory = $true)]
    [string]$VersionPropertyName
)

$res = dotnet msbuild -getProperty:$VersionPropertyName $Project

$version = $null
$parsed = [System.Version]::TryParse($res, [ref]$version);

if (!$parsed) {
    throw "Could not parse version '$($res)' in project '$Project'"
}

Write-Output "Version is $($version.ToString())"
Write-Output "major=$($version.Major)" >> $Env:GITHUB_OUTPUT
Write-Output "minor=$($version.Minor)" >> $Env:GITHUB_OUTPUT
Write-Output "Output file is $Env:GITHUB_OUTPUT"
Get-Content $Env:GITHUB_OUTPUT | Write-Output
