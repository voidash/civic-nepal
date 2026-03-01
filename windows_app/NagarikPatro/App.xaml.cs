using System.Windows;
using NagarikPatro.Views;

namespace NagarikPatro;

public partial class App : Application
{
    private SystemTrayManager? _trayManager;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        _trayManager = new SystemTrayManager();
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _trayManager?.Dispose();
        base.OnExit(e);
    }
}
