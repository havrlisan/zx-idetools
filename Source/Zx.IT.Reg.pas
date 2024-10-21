unit Zx.IT.Reg;

interface

procedure Register;

implementation

uses
  Zx.IT.DbgVisualizer.GUID,
  Zx.IT.KeyBinding.DisableCtrlEnter,
  Zx.IT.KeyBinding.ReloadLSPServer,
  Zx.IT.KeyBinding.ReopenLastClosedTab;

procedure Register;
begin
  TZxDebuggerVisualizerGUID.Register;
  TZxDisableCtrlEnterKeyBindingNotifier.Register;
  TZxReloadLSPServerNotifier.Register;
  TZxReopenLastClosedTabKeyBindingNotifier.Register;
end;

end.
