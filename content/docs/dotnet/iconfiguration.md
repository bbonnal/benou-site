---
title: "IConfiguration"
date: 2026-05-23
tags: ["dotnet", "configuration", "options"]
source: doc/pages/dotnet/iconfiguration.md
source_sha: 9acda269aa32
---

> How IConfiguration works, custom JSON files, IOptions patterns, deep nesting, validation.

## Default sources

`Host.CreateDefaultBuilder()` (or `CreateApplicationBuilder()`) registers, in order:

1. `appsettings.json`
2. `appsettings.{Environment}.json`
3. Environment variables
4. Command-line args
5. User secrets (Development only)

Later sources override earlier ones for the same keys.

## Add another JSON file

```csharp
var builder = Host.CreateDefaultBuilder(args)
    .ConfigureAppConfiguration((context, config) =>
    {
        config.AddJsonFile("mysettings.json", optional: true, reloadOnChange: true);
    });
```

## Inject IConfiguration

```csharp
public class MyService(IConfiguration configuration)
{
    var value = configuration["MySection:MyKey"];
}
```

## Bind to POCO (preferred)

```csharp
// Registration:
services.Configure<MyOptions>(configuration.GetSection("MySection"));

public class MyOptions
{
    public string MyKey { get; set; }
}

// Inject:
public class MyService(IOptions<MyOptions> options)
{
    var value = options.Value.MyKey;
}
```

- `IOptions<T>` — singleton, read once.
- `IOptionsSnapshot<T>` — scoped, re-reads per request (web apps).
- `IOptionsMonitor<T>` — singleton, change callback.

One `IConfiguration` instance — merged view of all sources.

## Complex appsettings.json example

```json
{
  "App": {
    "LaunchDate": "2026-03-15T09:00:00Z",
    "MaintenanceWindow": { "Start": "02:00:00", "End": "04:00:00" },
    "Tags": [ "production", "v2", "stable" ],
    "AllowedOrigins": [ "https://example.com", "https://api.example.com" ],
    "Limits": {
      "MaxRetries": 5,
      "TimeoutSeconds": 30.5,
      "EnableCircuitBreaker": true
    },
    "Database": {
      "Primary": {
        "Connection": {
          "Host": "db.example.com",
          "Port": 5432,
          "Credentials": { "Username": "admin", "UseSsl": true }
        }
      }
    },
    "FeatureFlags": {
      "DarkMode": true,
      "ExperimentalApi": false,
      "BetaUsers": [ "alice", "bob" ]
    },
    "Schedule": {
      "Jobs": [
        { "Name": "Cleanup", "CronExpression": "0 0 * * *", "Enabled": true,
          "RetryPolicy": { "MaxAttempts": 3, "DelaySeconds": 60 } },
        { "Name": "Report",  "CronExpression": "0 8 * * 1", "Enabled": false,
          "RetryPolicy": { "MaxAttempts": 1, "DelaySeconds": 120 } }
      ]
    },
    "Metadata": {
      "Version": "2.1.0",
      "BuildDate": "2026-02-19",
      "Environment": "staging"
    }
  }
}
```

## C# options classes

```csharp
public class AppOptions
{
    public const string SectionName = "App";

    public DateTime LaunchDate { get; set; }
    public TimeWindow MaintenanceWindow { get; set; } = new();
    public List<string> Tags { get; set; } = [];
    public string[] AllowedOrigins { get; set; } = [];
    public LimitOptions Limits { get; set; } = new();
    public DatabaseOptions Database { get; set; } = new();
    public FeatureFlagOptions FeatureFlags { get; set; } = new();
    public ScheduleOptions Schedule { get; set; } = new();
    public Dictionary<string, string> Metadata { get; set; } = new();
}

public class TimeWindow { public TimeSpan Start { get; set; } public TimeSpan End { get; set; } }
public class LimitOptions { public int MaxRetries { get; set; } public double TimeoutSeconds { get; set; } public bool EnableCircuitBreaker { get; set; } }

public class DatabaseOptions { public DatabaseInstanceOptions Primary { get; set; } = new(); }
public class DatabaseInstanceOptions { public ConnectionOptions Connection { get; set; } = new(); }
public class ConnectionOptions
{
    public string Host { get; set; } = "";
    public int Port { get; set; }
    public CredentialOptions Credentials { get; set; } = new();
}
public class CredentialOptions { public string Username { get; set; } = ""; public bool UseSsl { get; set; } }

public class FeatureFlagOptions { public bool DarkMode { get; set; } public bool ExperimentalApi { get; set; } public List<string> BetaUsers { get; set; } = []; }

public class ScheduleOptions { public List<JobOptions> Jobs { get; set; } = []; }
public class JobOptions { public string Name { get; set; } = ""; public string CronExpression { get; set; } = ""; public bool Enabled { get; set; } public RetryPolicyOptions RetryPolicy { get; set; } = new(); }
public class RetryPolicyOptions { public int MaxAttempts { get; set; } public int DelaySeconds { get; set; } }
```

## Registration

```csharp
var builder = Host.CreateApplicationBuilder(args);

// Whole section
builder.Services.Configure<AppOptions>(
    builder.Configuration.GetSection(AppOptions.SectionName));

// Sub-section
builder.Services.Configure<FeatureFlagOptions>(
    builder.Configuration.GetSection("App:FeatureFlags"));

// Deeply nested by path
builder.Services.Configure<ConnectionOptions>(
    builder.Configuration.GetSection("App:Database:Primary:Connection"));
```

## Consume

```csharp
public class MyService(
    IOptions<AppOptions> options,
    IOptionsSnapshot<AppOptions> snapshot,
    IOptionsMonitor<AppOptions> monitor)
{
    public void Demo()
    {
        var app = options.Value;

        Console.WriteLine(app.LaunchDate);                            // 2026-03-15T09:00:00Z
        Console.WriteLine(app.MaintenanceWindow.Start);               // 02:00:00

        foreach (var tag in app.Tags) Console.WriteLine(tag);

        Console.WriteLine(app.Limits.MaxRetries);
        Console.WriteLine(app.Limits.TimeoutSeconds);

        // 4-level nested access
        var creds = app.Database.Primary.Connection.Credentials;
        Console.WriteLine(creds.Username);

        foreach (var job in app.Schedule.Jobs)
            Console.WriteLine($"{job.Name}: {job.RetryPolicy.MaxAttempts} attempts");

        foreach (var (k, v) in app.Metadata)
            Console.WriteLine($"{k} = {v}");

        // Hot-reload callback
        monitor.OnChange(updated =>
            Console.WriteLine($"Config changed! New launch: {updated.LaunchDate}"));
    }
}
```

## Key type mappings

| JSON | C# Type | Example |
|------|---------|---------|
| `"2026-03-15T09:00:00Z"` | `DateTime` | ISO 8601 |
| `"2026-02-19"` | `DateOnly` | date-only |
| `"02:00:00"` | `TimeSpan` | hh:mm:ss |
| `"14:30:00"` | `TimeOnly` | .NET 6+ |
| `[...]` | `List<T>` / `T[]` / `IEnumerable<T>` | any collection |
| `[{...}]` | `List<ComplexType>` | object list |
| `{ "k": "v" }` | `Dictionary<string, string>` | flat map |
| `5` | `int`, `long`, `byte` | numeric |
| `30.5` | `double`, `float`, `decimal` | float |
| `true` | `bool` | boolean |
| `"Value"` | `MyEnum` | enum by name |

## Validation

```csharp
builder.Services.AddOptionsWithValidateOnStart<AppOptions>()
    .Bind(builder.Configuration.GetSection(AppOptions.SectionName))
    .Validate(o => o.LaunchDate > DateTime.UtcNow, "Launch date must be in the future")
    .Validate(o => o.Limits.MaxRetries > 0, "MaxRetries must be positive")
    .Validate(o => o.Tags.Count > 0, "At least one tag required");
```

Or with DataAnnotations:

```csharp
public class LimitOptions
{
    [Range(1, 10)] public int MaxRetries { get; set; }
    [Range(0.1, 300.0)] public double TimeoutSeconds { get; set; }
}

builder.Services.AddOptionsWithValidateOnStart<LimitOptions>()
    .Bind(builder.Configuration.GetSection("App:Limits"))
    .ValidateDataAnnotations();
```
