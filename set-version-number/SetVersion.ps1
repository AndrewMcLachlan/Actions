param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,
    [Parameter(Mandatory = $true)]
    [string]$VersionPropertyName,
    [Parameter(Mandatory = $true)]
    [string]$RunNumber
)

$res = Select-Xml -Path $FilePath -XPath = "/Project/PropertyGroup/$VersionPropertyName"

if ($null -eq $res) {
    throw "Could not find version property '$VersionPropertyName' in file '$FilePath'"
}

$parsed = [System.Version]::TryParse($res.Node.'#text', [out]$version);

if (!$parsed) {
    throw "Could not parse version '$($res.Node.'#text')' in file '$FilePath'"
}

$version.Build = $RunNumber

Write-Host "::set-output name=version::$($version.ToString())"