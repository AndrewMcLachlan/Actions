param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [string]$VersionPropertyName,
    [Parameter(Mandatory = $true)]
    [string]$RunNumber
)

$res = Select-Xml -Path $FilePath -XPath "/Project/PropertyGroup/$VersionPropertyName"

if ($null -eq $res) {
    throw "Could not find version property '$VersionPropertyName' in file '$FilePath'"
}

$version = $null
$parsed = [System.Version]::TryParse($res.Node.'#text', [ref]$version);

if (!$parsed) {
    throw "Could not parse version '$($res.Node.'#text')' in file '$FilePath'"
}

$newVersion = [System.Version]::new($version.Major, $version.Minor, $RunNumber)

Write-Output "Version is $($newVersion.ToString())"
Write-Output "version=$($newVersion.ToString())" >> $Env:GITHUB_OUTPUT
Write-Output "Output file is $Env:GITHUB_OUTPUT"
Get-Content $Env:GITHUB_OUTPUT | Write-Output
