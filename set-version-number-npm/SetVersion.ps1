param (
    [Parameter(Mandatory = $true)]
    [string]$PackageFilePath,
    [Parameter(Mandatory = $true)]
    [string]$RunNumber
)

$file = Get-Content -Path $PackageFilePath | ConvertFrom-Json
Write-Host $file
$res = $file.version;

if ($null -eq $res) {
    throw "Could not find version in file '$PackageFilePath'"
}

$version = $null
$parsed = [System.Version]::TryParse($res, [ref]$version);

if (!$parsed) {
    throw "Could not parse version '$res' in file '$PackageFilePath'"
}

$newVersion = [System.Version]::new($version.Major, $version.Minor, $RunNumber)

Write-Output "Version is $($newVersion.ToString())"
Write-Output "version=$($newVersion.ToString())" >> $Env:GITHUB_OUTPUT
Write-Output "Output file is $Env:GITHUB_OUTPUT"
Get-Content $Env:GITHUB_OUTPUT | Write-Output
