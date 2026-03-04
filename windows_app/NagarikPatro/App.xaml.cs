using NagarikPatro.Views;

namespace NagarikPatro;

// Qualify explicitly: UseWindowsForms implicit using adds System.Windows.Forms.Application
// which would otherwise be ambiguous with System.Windows.Application (WPF).
public partial class App : System.Windows.Application
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
