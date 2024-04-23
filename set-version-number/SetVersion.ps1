param (
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [Parameter(Mandatory = $true)]
    [string]$VersionPropertyName,
    [Parameter(Mandatory = $true)]
    [string]$RunNumber
)

$res = dotnet msbuild -getProperty:Version $Project

$version = $null
$parsed = [System.Version]::TryParse($res, [ref]$version);

if (!$parsed) {
    throw "Could not parse version '$($res)' in project '$Project'"
}

$newVersion = [System.Version]::new($version.Major, $version.Minor, $RunNumber)

Write-Output "Version is $($newVersion.ToString())"
Write-Output "version=$($newVersion.ToString())" >> $Env:GITHUB_OUTPUT
Write-Output "Output file is $Env:GITHUB_OUTPUT"
Get-Content $Env:GITHUB_OUTPUT | Write-Output
