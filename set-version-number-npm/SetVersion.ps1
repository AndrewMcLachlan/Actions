param (
    [Parameter(Mandatory = $true)]
    [string]$PackageFilePath,
    [Parameter(Mandatory = $true)]
    [string]$RunNumber,
    [Parameter(Mandatory = $false)]
    [string]$PatchVersionType = "run-number"
)

$file = Get-Content -Path $PackageFilePath | ConvertFrom-Json
Write-Host $file
$res = $file.version;

if ($null -eq $res) {
    throw "Could not find version in file '$PackageFilePath'"
}

Write-Output "Read version $res from package.json"

$version = $null
$split = $res.split("-")
$suffix = ($split.length -gt 1) ? "-$($split[1])" : ""

$parsed = [System.Version]::TryParse($split[0], [ref]$version);

if (!$parsed) {
    throw "Could not parse version '$res' in file '$PackageFilePath'"
}

if ($PatchVersionType -eq "commits-this-month") {
    $date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-01T00:00:00Z")
    $patch = git rev-list --count --after="$date" HEAD
    Write-Output "Commits this month: $patch"
} else {
    $patch = $RunNumber
}

$newVersion = [System.Version]::new($version.Major, $version.Minor, $patch)
$newVersionComplete = "$($newVersion.ToString())$suffix";

Write-Output "Version is $newVersionComplete"
Write-Output "version=$newVersionComplete" >> $Env:GITHUB_OUTPUT
Write-Output "Output file is $Env:GITHUB_OUTPUT"
Get-Content $Env:GITHUB_OUTPUT | Write-Output
