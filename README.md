# GitHub Actions

The Set Version Number and Set Version Number NPM actions use information in code to determine a version number variable. You are responsible for supplying this version when compiling your code.

## JSON Substitution

Replace values in a JSON file using jq.

### Example

```yaml
name: Build
on:
  push:
    branches:
      - "master"
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        file: './appsettings.json'
        values: |
          [
            {"path": ".Logging.LogLevel.Default", "value": "Debug"},
            {"path": ".ConnectionStrings.DefaultConnection", "value": "Server=newhost;Database=newdb;User Id=newuser;Password=newpassword;"}
          ]
```

## Set Version Number

Evaluates an MSBuild property to return the version number, with the `Build` portion set to the current workflow run number.

### Example

Given this MSBuild file:

```xml
<PropertyGroup>
  <FileVersion>$([System.DateTime]::Now.Year).$([System.DateTime]::Now.Month).0</FileVersion>
  <Version>2.1</Version>
</PropertyGroup>
```

And this workflow, run on 2024-04-25, with a run number of 50:

```yaml
name: Build
on:
  push:
    branches:
      - "master"
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Setup .NET
      uses: actions/setup-dotnet@v4
      with:
        dotnet-version: 8.x
    - name: Set version number
      id: set-version-number
      uses: andrewmclachlan/actions/set-version-number@v2
      with:
        project: 'src/Example'
        version-property-name: 'Version'
    - name: Set file version number
      id: set-file-version-number
      uses: andrewmclachlan/actions/set-version-number@v2
      with:
        project: 'src/Example'
        version-property-name: 'FileVersion'
```

The outputs would be:

```
steps.set-version-number.outputs.version - 2.1.50
steps.set-file-version-number.outputs.version - 2024.4.50
```

## Set Version Number NPM

Returns the version number using the NPM `package.json` file, with the `Build` portion set to the current workflow run number.

### Example

Given this `package.json` snippet:

```json
{
  "name": "example",
  "version": "2.1.0",
}
```

And this workflow, with a run number of 50:

```yaml
name: Build
on:
  push:
    branches:
      - "master"
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Set version number
      id: set-version-number
      uses: andrewmclachlan/actions/set-version-number-npm@v2
      with:
        packageFilePath: 'src/Example/package.json'
```

The output would be:

```
steps.set-version-number.outputs.version - 2.1.50
```

## Get .NET Version

Derives a package version from MSBuild props where **the version is stated, not inferred**:
`Major.Minor` comes from `VersionPrefix`, and the patch is the number of commits **since that
version line last changed** (so unrelated edits to the props file don't reset it). Set
`VersionSuffix` for a prerelease line. Internally uses `get-version-number-from-project` for
Major/Minor. Requires a full-history checkout (`fetch-depth: 0`) and the .NET SDK on the runner.

### Example

Given `Directory.Build.props`:

```xml
<PropertyGroup>
  <VersionPrefix>4.0</VersionPrefix>
  <!-- optional, for a prerelease line: -->
  <!-- <VersionSuffix>beta</VersionSuffix> -->
</PropertyGroup>
```

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0          # required: full history for the commit count
    - uses: actions/setup-dotnet@v4
      with:
        dotnet-version: 10.x
    - name: Get version
      id: version
      uses: andrewmclachlan/actions/get-dotnet-version@v4
      with:
        project: 'Directory.Build.props'   # optional, this is the default
    - name: Build
      run: dotnet build --p:Version=${{ steps.version.outputs.version }} --p:AssemblyVersion=${{ steps.version.outputs.assembly-version }} --p:FileVersion=${{ steps.version.outputs.file-version }}
```

Outputs (17 commits since the `VersionPrefix` line changed):

```
steps.version.outputs.version          - 4.0.17   (5.0.0-beta.17 with VersionSuffix=beta)
steps.version.outputs.assembly-version - 4.0.0.0
steps.version.outputs.file-version     - 4.0.17.0
steps.version.outputs.major            - 4
steps.version.outputs.minor            - 0
steps.version.outputs.patch            - 17
steps.version.outputs.version-suffix   -          (e.g. "beta" for a prerelease line)
steps.version.outputs.is-prerelease    - false    (true when a VersionSuffix is set)
```

The breakdown lets a workflow branch on the parts — e.g. gate publishing to stable trunk builds and
prereleases only:

```yaml
    if: github.ref == 'refs/heads/main' || steps.version.outputs.is-prerelease == 'true'
```

## Releasing

This repo publishes reusable actions that consumers reference by tag (e.g. `andrewmclachlan/actions/set-version-number@v4`). Releases follow the **moving major tag** convention: alongside an immutable full version tag (`v4.5`, `v4.5.2`), a `v<MAJOR>` tag (`v4`) is kept pointing at the latest release in that major line. Consumers pin `@v4` and automatically pick up the newest `v4.x`.

To cut a release:

1. Go to **Actions → Release → Run workflow**.
2. Select the branch/ref you want to release from (the workflow tags whatever commit you dispatch against).
3. Enter the full version `tag`, e.g. `v4.5` or `v4.5.2` (must match `vMAJOR.MINOR` or `vMAJOR.MINOR.PATCH`).
4. Optionally tick `prerelease` and/or `draft`.
5. Run it.

The workflow will:

- Validate the tag format and derive the major tag (`v4.5` → `v4`).
- Create the annotated full version tag at the dispatched commit and push it. It **fails** if that exact version tag already exists (version tags are immutable).
- Delete and recreate the major tag `v<MAJOR>` at the same commit, force-pushing it so `@v4` moves forward.
- Create a GitHub Release for the version tag with auto-generated notes, honouring the `prerelease`/`draft` inputs.
