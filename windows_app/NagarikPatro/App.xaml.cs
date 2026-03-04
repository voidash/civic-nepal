using System.Windows;
using NagarikPatro.Core;
using NagarikPatro.Views;

namespace NagarikPatro;

public partial class App : Application
{
    private SystemTrayManager? _trayManager;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        ThemeManager.Initialize();
        _trayManager = new SystemTrayManager();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        ThemeManager.Shutdown();
        _trayManager?.Dispose();
        base.OnExit(e);
    }
}
