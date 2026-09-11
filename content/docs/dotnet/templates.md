---
title: ".NET templates"
date: 2026-05-23
tags: ["dotnet", "templates", "nuget"]
source: doc/pages/dotnet/templates.md
source_sha: 2717973fa013
---

> Creating and publishing `dotnet new` templates.

## Layout

```
MyTemplates/
├── templates/
│   └── my-webapi/
│       ├── .template.config/
│       │   └── template.json
│       ├── MyWebApi.csproj
│       ├── Program.cs
│       └── ...
├── MyName.Templates.csproj
└── README.md
```

## template.json

`.template.config/template.json` of the project:

```json
{
  "$schema": "http://json.schemastore.org/template",
  "author": "Your Name",
  "classifications": ["Web", "API"],
  "identity": "MyName.WebApi",
  "name": "My Custom Web API",
  "shortName": "my-webapi",
  "tags": {
    "language": "C#",
    "type": "project"
  },
  "sourceName": "MyWebApi",
  "preferNameDirectory": true,
  "symbols": {
    "useAuth": {
      "type": "parameter",
      "datatype": "bool",
      "defaultValue": "false",
      "description": "Include JWT authentication setup"
    }
  },
  "sources": [
    {
      "modifiers": [
        { "condition": "(!useAuth)", "exclude": ["Auth/**"] }
      ]
    }
  ]
}
```

- `shortName` — what users type after `dotnet new`.
- `sourceName` — token replaced with `--name` arg. `dotnet new my-webapi --name Acme.Api` swaps every `MyWebApi` → `Acme.Api` in names + contents.
- `symbols` — custom parameters (e.g. `--useAuth`).
- `sources.modifiers` — conditional include/exclude rules.

## NuGet pack project

Root `MyName.Templates.csproj`:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <PackageType>Template</PackageType>
    <PackageVersion>1.0.0</PackageVersion>
    <PackageId>MyName.Templates</PackageId>
    <Title>My Custom Templates</Title>
    <Authors>Your Name</Authors>
    <Description>Custom .NET project templates</Description>
    <PackageTags>dotnet-new;template</PackageTags>
    <TargetFramework>net8.0</TargetFramework>
    <IncludeContentInPack>true</IncludeContentInPack>
    <IncludeBuildOutput>false</IncludeBuildOutput>
    <ContentTargetFolders>content</ContentTargetFolders>
    <NoDefaultExcludes>true</NoDefaultExcludes>
    <NoWarn>$(NoWarn);NU5128</NoWarn>
  </PropertyGroup>

  <ItemGroup>
    <Content Include="templates/**/*" Exclude="templates/**/bin/**;templates/**/obj/**" />
    <Compile Remove="**/*" />
  </ItemGroup>
</Project>
```

Required bits:
- `PackageType` = `Template`
- `IncludeBuildOutput` = false (no DLL)
- `Content` pulls in everything under `templates/`

## Pack & test locally

- Pack:
  `dotnet pack -o ./nupkg`

- Install:
  `dotnet new install ./nupkg/MyName.Templates.1.0.0.nupkg`

- Try:
  `dotnet new my-webapi --name TestProject --useAuth true`

- Uninstall:
  `dotnet new uninstall MyName.Templates`

## Publish to NuGet.org

```
dotnet nuget push ./nupkg/MyName.Templates.1.0.0.nupkg \
  --api-key YOUR_API_KEY \
  --source https://api.nuget.org/v3/index.json
```

After indexing (minutes):
```
dotnet new install MyName.Templates
```

## Tips

- Conditional content inside files uses C# preprocessor: `#if (useAuth)` / `#endif`. JSON uses `//` comment-style conditions (engine strips them).
- Multiple templates in one package: add more folders under `templates/`, each with its own `.template.config/`.
- Solution-level templates: set `"tags": { "type": "solution" }` and include a `.sln`.
- Official docs: `github.com/dotnet/templating`.
