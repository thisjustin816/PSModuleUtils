# PSModuleUtils

A module with helper functions to build and publish PowerShell modules to the PSGallery.

## Setup

```powershell
Install-Module PSModuleUtils
```

## Analyzer output

`Invoke-PSModuleAnalyzer` returns diagnostic records and prints a summary by default. Pass
`-NoSummary` when a controller needs to keep stdout reserved for structured output. Diagnostics,
fix behavior and the optional exit-code gate are preserved.

```powershell
$findings = Invoke-PSModuleAnalyzer -SourceDirectory ./src -NoSummary
```

## PowerShell Module Development

Follow [The PowerShell Best Practices and Style Guide](https://poshcode.gitbooks.io/powershell-practice-and-style/) as much as possible, with the following rules being the most important:

- Use [Approved Verbs](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-5.1) for commands so that PowerShell's built-in ability to autocomplete un-imported functions works.
- Add help comments to **all** functions because each module's wiki is auto-generated from them.

Use the following additional guidelines:

- Modules are built with [ModuleBuilder](https://github.com/PoshCode/ModuleBuilder) via `Build-PSModule`. There is no source `.psm1`: ModuleBuilder concatenates every `.ps1` under the configured source directories into a single built `.psm1`.
- The manifest template is hand-authored and treated as a source file, not a generated one. By default, `Build-PSModule` derives the module name from the manifest filename and uses its `ModuleVersion` and `Prerelease` values. Use `-Version` only for an explicit build override. ModuleBuilder updates `FunctionsToExport` and `AliasesToExport`, while PSModuleUtils stamps git-derived fields (`Author`, `CompanyName`, `Copyright`, `ProjectUri`, `ReleaseNotes`). Everything else you author (`GUID`, `Description`, `RequiredModules`, `PrivateData.PSData.Tags`, etc.) is preserved as-is. Pre-declare `PrivateData.PSData.Prerelease` and `PrivateData.PSData.ReleaseNotes` in the template (empty strings are fine). Run `New-PSModuleManifest` to scaffold or migrate a compatible template.
- Ideally, each module and each of its functions should have a set of [Pester](https://github.com/pester/Pester) unit/integration tests. At the least, any new functions or functionality should have an associated test.
- Create all functions as single `.ps1` files with the same name and without `Export-ModuleMember` statements.
  - The files should be in an appropriate nested `Public` folder that corresponds to its API category.
  - Functions that are used by other functions should be put in either `Utils` or `Private`, depending on their usage.
- **Tests must live in a top-level `tests/` folder, never inside `Public`/`Private`.** ModuleBuilder inlines every `.ps1` it finds in those folders with no exclusion, so a co-located `*.Tests.ps1` leaks `Describe`/`It` blocks into the built module and its exports.
- Keep packaged assets outside the configured source directories. `Build-PSModule` copies every other source-root item automatically, preserving directories such as `Assemblies`, `bin`, `Settings`, `Schemas`, `Templates`, `Resources`, and culture names such as `en-US`. Use `-CopyPaths` only for additional files or directories outside that automatic set.
- Declare files that PowerShell loads as part of module import in the manifest. Use `RequiredAssemblies` for prerequisite DLLs, `FormatsToProcess` for formatting files, and `TypesToProcess` for type extensions. Use `FileList` only as package inventory. Other runtime assets can be resolved relative to `$PSScriptRoot`; see `Get-PSModuleAnalyzerSettingsPath` for handling source and built layouts.

The folder structure should be maintained like the example below:

```console
\MODULEREPODIRECTORY
├───.github
│   └───workflows
├───.gitignore
├───LICENSE
├───README.md
├───build.ps1
│
├───src
│   ├───ModuleName.psd1
│   │
│   ├───Public
│   │   └───functionalArea
│   │       └───Verb-Noun.ps1
│   │
│   ├───Private
│   │   └───Verb-Noun.ps1
│   │
│   ├───Assemblies
│   │   └───Dependency.dll
│   │
│   └───Resources
│       └───Template.json
│
└───tests
    ├───ModuleName.Module.Tests.ps1
    └───Verb-Noun.Tests.ps1
```

## Building and testing this repository

PSModuleUtils 5 requires PowerShell 7.4 or newer and Pester 6.2 or newer within the 6.x series.
Run `./build.ps1` in a fresh PowerShell process after installing the dependencies declared in
`src/PSModuleUtils.psd1`. The build loads those dependencies directly and compiles the current
source; it does not require an installed copy of PSModuleUtils.

Pester 5 and 6 cannot share a process because their assemblies use the same names. Start a new
process when moving between build-tool majors. Tests run sequentially. `Test-PSModule` writes
NUnit XML to `out/tests/testResults.xml` and JaCoCo coverage to `out/tests/coverage.xml`. Failed
tests throw a terminating error so local callers and CI both observe the failure. Discovered suites
with zero passing tests also fail, including fully filtered or skipped suites. A directory without
test files retains the existing warning-and-return behavior.
