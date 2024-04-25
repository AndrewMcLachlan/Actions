# GitHub Actions

The Set Version Number and Set Version Number NPM actions use information in code to determine a version number variable. You are responsible for supplying this version when compiling your code.

## Set Version Numer

Evaludates an MSBuild property to return the version number, with the `Build` portion set to the current workflow run number.

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
        versionPropertyName: 'Version'
    - name: Set file version number
      id: set-file-version-number
      uses: andrewmclachlan/actions/set-version-number@v2
      with:
        project: 'src/Example'
        versionPropertyName: 'FileVersion'
```

The outputs would be:

```
steps.set-version-number.outputs.version - 2.1.50
steps.set-file-version-number.outputs.version - 2024.4.50
```

## Set Version NPM

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
