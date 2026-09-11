---
title: "WPF with IHost"
date: 2026-09-11
tags: ["dotnet", "wpf", "hosting"]
source: doc/pages/dotnet/wpf-apphost.md
source_sha: f98179e28b86
---

> WPF with `IHost` (DI, configuration, logging, async shutdown).

## App.xaml.cs pattern

```csharp
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using NLog.Extensions.Logging;

namespace MyWpfApp;

public partial class App : Application
{
    internal static IHost? AppHost { get; private set; }

    protected override async void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        AppHost = Host.CreateDefaultBuilder(e.Args)
            .ConfigureServices((context, services) =>
            {
                services.AddLogging(builder =>
                {
                    builder.ClearProviders();
                    builder.AddNLog();
                });
                services.Configure<ApiOptions>(context.Configuration.GetSection("Api"));
                services.AddHostedServices();
                services.AddPagesAndViewModels();

                services.AddTransient<MainWindowViewModel>();
                services.AddTransient<MainWindow>();
            })
            .Build();

        await AppHost.StartAsync();

        var mainWindow = AppHost.Services.GetRequiredService<MainWindow>();
        mainWindow.DataContext = AppHost.Services.GetRequiredService<MainWindowViewModel>();
        mainWindow.Show();
    }

    protected override async void OnExit(ExitEventArgs e)
    {
        if (AppHost is not null)
        {
            SynchronizationContext.SetSynchronizationContext(null);
            await AppHost.StopAsync();
            AppHost.Dispose();
            AppHost = null;
        }

        base.OnExit(e);
    }
}
```

## Key points

- **`OnExit`, not after `Show()`** — `Show()` is non-blocking; you can't `StopAsync` immediately after it.
- **Clear `SynchronizationContext`** before `StopAsync` to avoid dispatcher deadlocks.
- **Remove `StartupUri`** from `App.xaml` — you manage the window manually.
- **`ShutdownMode="OnLastWindowClose"`** is usually correct.

## App.xaml

```xml
<Application x:Class="MyWpfApp.App"
             xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
             xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
             ShutdownMode="OnLastWindowClose">
    <!-- StartupUri removed because OnStartup creates the window -->
</Application>
```

## Programmatic shutdown

`Application.Current.Shutdown()` triggers `OnExit` — that's the intended path.

Flow:
```
Shutdown() → closes all windows → OnExit fires → StopAsync/Dispose runs
```

`OnExit` is `async void`, so callers can't await it. Fine for normal teardown.

## Dedicated shutdown method (optional)

For more control, call your own method instead of `Shutdown()` directly:

```csharp
public partial class App : Application
{
    public static async Task ShutdownAsync()
    {
        if (AppHost is not null)
        {
            SynchronizationContext.SetSynchronizationContext(null);
            await AppHost.StopAsync();
            AppHost.Dispose();
            AppHost = null;
        }

        Current.Shutdown();   // triggers OnExit; AppHost is null so it no-ops
    }

    protected override async void OnExit(ExitEventArgs e)
    {
        if (AppHost is not null)
        {
            SynchronizationContext.SetSynchronizationContext(null);
            await AppHost.StopAsync();
            AppHost.Dispose();
            AppHost = null;
        }

        base.OnExit(e);
    }
}
```

- Normal window close / OS shutdown → `OnExit` handles cleanup.
- Programmatic shutdown → call `App.ShutdownAsync()` (cleans up, then calls `Shutdown()`; `OnExit` safely no-ops).
