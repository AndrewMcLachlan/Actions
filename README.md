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

## Get Node Version

The Node counterpart of [Get .NET Version](#get-net-version). Derives an npm package version from
`package.json` where **the version is stated, not inferred**: `Major.Minor` (and an optional
prerelease suffix) come from the `version` field, and the patch is the number of commits **since
that version line last changed** (so unrelated edits to `package.json` don't reset it). State a
prerelease line by stating e.g. `5.0.0-beta`. `package.json`'s `version` plays the role that
`VersionPrefix`/`VersionSuffix` play in `Directory.Build.props` — only `Major.Minor` and the
optional `-suffix` are authoritative; the stated patch is ignored and recomputed. Requires a
full-history checkout (`fetch-depth: 0`).

### Example

Given `package.json`:

```json
{
  "name": "example",
  "version": "4.0.0"
}
```

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0          # required: full history for the commit count
    - uses: actions/setup-node@v4
      with:
        node-version: 22
        registry-url: "https://npm.pkg.github.com"
    - name: Get version
      id: version
      uses: andrewmclachlan/actions/get-node-version@v4
      with:
        package-file: 'package.json'   # optional, this is the default
    - run: npm ci
    - run: npm pkg set version=${{ steps.version.outputs.version }}
    - run: npm run build
    # Publish only from main (the stable trunk) or a prerelease line (a branch whose stated
    # version carries a suffix). A suffix-less non-main branch publishes nothing.
    - if: github.ref == 'refs/heads/main' || steps.version.outputs.is-prerelease == 'true'
      env:
        NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      run: npm publish
```

Outputs (17 commits since the `version` line changed):

```
steps.version.outputs.version        - 4.0.17   (5.0.0-beta.17 when version is 5.0.0-beta)
steps.version.outputs.major          - 4
steps.version.outputs.minor          - 0
steps.version.outputs.patch          - 17
steps.version.outputs.version-suffix -          (beta when version is 5.0.0-beta)
steps.version.outputs.is-prerelease  - false    (true when a suffix is present)
```

For a monorepo, apply the version to every published workspace, e.g.
`npm pkg set version=${{ steps.version.outputs.version }} --workspace=pkg-a --workspace=pkg-b`.

### Branching

Same model as .NET, with the version living in `package.json` *on the branch* — every branch is
self-describing and isolated, no shared tags:

- **`main` is the trunk** — every merge publishes `X.Y.<count>` (stable).
- **`feature/*` / PRs** build and test but never publish.
- **A preview line is a `release/**` branch whose stated version carries a suffix** — e.g. on
  `release/5.0-beta` set `"version": "5.0.0-beta"` → publishes `5.0.0-beta.N` while `main` stays on
  `4.x`. Graduate **in place**: remove the suffix (`"version": "5.0.0"`, which publishes nothing off
  `main`), merge to `main`, and `main` publishes `5.0.0`.

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
- Create a GitHub Release for the version tag with auto-generated notes, honouring the `prerelease`/`draft` inputs.
- **Tag according to what kind of release it is:**
  - **Stable** (not draft, not prerelease): create the annotated version tag at the dispatched commit, and move the major tag `v<MAJOR>` to it (force-push, so `@v4` advances). Fails if the version tag already exists (version tags are immutable).
  - **Prerelease** (published): create the version tag, but **do not move the major tag** — consumers on `@v4` won't pick up a prerelease.
  - **Draft**: create only the draft release — **no tags are created or moved**. The version tag and major-tag move happen when you publish it (below), so abandoning a draft leaves nothing behind.

### Publishing a draft

Use **Actions → Publish Release → Run workflow** to publish a draft cut above. With no input it publishes the **most recent draft**; optionally pass a specific draft `tag`. It will:

- Create the annotated version tag at the draft's target commit and push it.
- Publish the release (clears the draft flag).
- Move the major tag `v<MAJOR>` to that commit — **unless the draft is a prerelease**, in which case the major tag stays put.
