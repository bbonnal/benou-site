---
title: ".NET CLI"
date: 2026-05-23
tags: ["dotnet", "cli", "csharp"]
source: doc/pages/dotnet/cli.md
source_sha: ab923ea426d3
---

> `dotnet` CLI for solutions, projects, templates.

## Solutions

- New solution (modern format):
  `dotnet new sln -n MySolution --format slnx`

- Add single project:
  `dotnet sln MySolution.sln add ./src/MyProject/MyProject.csproj`

- Add all projects recursively:
  `dotnet sln MySolution.sln add **/*.csproj`

## Projects

- Class library:
  `dotnet new classlib -n MyLibrary -o ./src/MyLibrary`

- Console app:
  `dotnet new console -n MyApp -o ./src/MyApp`

- Web API:
  `dotnet new webapi -n MyApi -o ./src/MyApi`

- List templates:
  `dotnet new list`

## Restore / build / run

- Restore deps:
  `dotnet restore`

- Build:
  `dotnet build`

- Run:
  `dotnet run`

- Watch (auto-rebuild on change):
  `dotnet watch run`

- Publish (framework-dependent):
  `dotnet publish -c Release -o ./publish`

- Self-contained:
  `dotnet publish -c Release -r linux-x64 --self-contained true`

## Package management

- Add package:
  `dotnet add package Serilog`

- Specific version:
  `dotnet add package Serilog --version 3.1.1`

- Remove:
  `dotnet remove package Serilog`

- List installed:
  `dotnet list package`

- Outdated:
  `dotnet list package --outdated`

## Project references

- Add reference between projects:
  `dotnet add MyApi reference MyDomain`

- Remove:
  `dotnet remove MyApi reference MyDomain`

## Tests

- Run:
  `dotnet test`

- Filter:
  `dotnet test --filter "FullyQualifiedName~MyTests"`

- With coverage:
  `dotnet test --collect:"XPlat Code Coverage"`

## SDK info

- Versions:
  `dotnet --version`
  `dotnet --list-sdks`
  `dotnet --list-runtimes`
