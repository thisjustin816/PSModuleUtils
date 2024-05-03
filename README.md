# PSModuleUtils

A module with helper functions to build and publish PowerShell modules to the PSGallery

## Setup

```powershell
Install-Module PSModuleUtils
```

## PowerShell Module Development

Follow [The PowerShell Best Practices and Style Guide](https://poshcode.gitbooks.io/powershell-practice-and-style/) as much as possible, with the following rules being the most important:

- Use [Approved Verbs](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands?view=powershell-5.1) for commands so that PowerShell's built-in ability to autocomplete un-imported functions works.
- Add help comments to **all** functions because each module's wiki is auto-generated from them.

Use the following additional guidelines:

- The module file itself (`.psm1`) should not contain any functions or logic, in most cases, other than a `foreach` loop to dot source all the `.ps1` files and `New-Alias` statements for specific functions.
- Ideally, each module and each of its functions should have a set of [Pester](https://github.com/pester/Pester) unit/integration tests. At the least, any new functions or functionality should have an associated test.
- Create all functions as single `.ps1` files with the same name and without `Export-ModuleMember` statements.
  - The files should be in an appropriate nested `Public` folder that corresponds to its API category.
  - Functions that are used by other functions should be put in either `Utils` or `Private`, depending on their usage.
- The module file (`.psm1`) and each function should have a corresponding `.Tests.ps1` file containing Pester unit/integration tests.
- Don't change any documentation or manifest files; they are automatically populated by the pipeline.

The folder structure should be maintained like the example below:

```console
\MODULEREPODIRECTORY
├───.gitignore
├───azure-pipelines.yml
│
└───ModuleName
    ├───ModuleName.Module.Tests.ps1
    ├───ModuleName.nuspec
    ├───ModuleName.psd1
    ├───ModuleName.psm1
    │
    public
    ├───functionalArea
    │   ├───Verb-Noun.ps1
    │   └───Verb-Noun.Tests.ps1
    │
    private
    ├───Verb-Noun.ps1
    └───Verb-Noun.Tests.ps1
```
