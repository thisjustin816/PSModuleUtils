# PSModuleUtils

A module with helper functions to build and publish PowerShell modules to the PSGallery.

## Setup

```powershell
Install-Module PSModuleUtils
```

## PowerShell Module Development

Follow [The PowerShell Best Practices and Style Guide](https://poshcode.gitbooks.io/powershell-practice-and-style/) as much as possible, with the following rules being the most important:

- Use [Approved Verbs](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-5.1) for commands so that PowerShell's built-in ability to autocomplete un-imported functions works.
- Add help comments to **all** functions because each module's wiki is auto-generated from them.

Use the following additional guidelines:

- Modules are built with [ModuleBuilder](https://github.com/PoshCode/ModuleBuilder) via `Build-PSModule`. There is no source `.psm1`: ModuleBuilder concatenates every `.ps1` under `Public`/`Private` into a single built `.psm1`, so a module's source directory holds only a manifest template (`ModuleName.psd1`) and its function folders.
- The manifest template is hand-authored and treated as a source file, not a generated one. `Build-PSModule` copies it forward and only overwrites `FunctionsToExport`, `AliasesToExport`, the version/prerelease, and git-derived fields (`Author`, `CompanyName`, `Copyright`, `ProjectUri`, `ReleaseNotes`) — everything else you author (`GUID`, `Description`, `RequiredModules`, `PrivateData.PSData.Tags`, etc.) is preserved as-is. To allow the version/prerelease/release notes to be stamped, pre-declare `PrivateData.PSData.Prerelease` and `PrivateData.PSData.ReleaseNotes` in the template (empty strings are fine). Run `New-PSModuleManifest` to scaffold or migrate a compatible template.
- Ideally, each module and each of its functions should have a set of [Pester](https://github.com/pester/Pester) unit/integration tests. At the least, any new functions or functionality should have an associated test.
- Create all functions as single `.ps1` files with the same name and without `Export-ModuleMember` statements.
  - The files should be in an appropriate nested `Public` folder that corresponds to its API category.
  - Functions that are used by other functions should be put in either `Utils` or `Private`, depending on their usage.
- **Tests must live in a top-level `tests/` folder, never inside `Public`/`Private`.** ModuleBuilder inlines every `.ps1` it finds in those folders with no exclusion, so a co-located `*.Tests.ps1` leaks `Describe`/`It` blocks into the built module and its exports.
- Keep packaged assets outside `Public` and `Private`, then pass their paths to `Build-PSModule -CopyPaths`. Use names that describe their role, such as `Assemblies`, `bin/<target-framework>`, `Settings`, `Schemas`, `Templates`, `Resources`, or culture names such as `en-US`. ModuleBuilder copies each path intact while compiling only the configured source directories into the generated `.psm1`.
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
