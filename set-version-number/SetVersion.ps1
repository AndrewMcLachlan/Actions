param (
    [Parameter(Mandatory = $true)]
    [string]$Project,
    [Parameter(Mandatory = $true)]
    [string]$VersionPropertyName,
    [Parameter(Mandatory = $true)]
    [string]$RunNumber,
    [Parameter(Mandatory = $false)]
    [string]$PatchVersionType = "run-number"
)

$res = dotnet msbuild -getProperty:Version $Project

$version = $null
$parsed = [System.Version]::TryParse($res, [ref]$version);

if (!$parsed) {
    throw "Could not parse version '$($res)' in project '$Project'"
}

if ($PatchVersionType -eq "commits-this-month") {
    $date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-01T00:00:00Z")
    $patch = git rev-list --count --after="$date" HEAD
    Write-Output "Commits this month: $patch"
} else {
    $patch = $RunNumber
}

$newVersion = [System.Version]::new($version.Major, $version.Minor, $patch)

Write-Output "Version is $($newVersion.ToString())"
Write-Output "version=$($newVersion.ToString())" >> $Env:GITHUB_OUTPUT
Write-Output "Output file is $Env:GITHUB_OUTPUT"
Get-Content $Env:GITHUB_OUTPUT | Write-Output
