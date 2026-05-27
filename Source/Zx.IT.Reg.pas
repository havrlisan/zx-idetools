unit Zx.IT.Reg;

interface

procedure Register;

implementation

uses
  Zx.IT.DbgVisualizer.GUID,
  Zx.IT.KeyBinding.DisableCtrlEnter,
  Zx.IT.KeyBinding.ReloadLSPServer,
  Zx.IT.KeyBinding.ReopenLastClosedTab,
  Zx.IT.TabMiddleMouseClickOverride,
  Zx.IT.UpdateSubscriptionFader,
  Zx.IT.FileOpener;

procedure Register;
begin
  TZxDebuggerVisualizerGUID.Register;
  TZxDisableCtrlEnterKeyBindingNotifier.Register;
  TZxReloadLSPServerNotifier.Register;
  TZxReopenLastClosedTabKeyBindingNotifier.Register;
  // TZxTabMiddleMouseClickOverride.Register;
  TZxUpdateSubscriptionFader.Register;
  TZxFileOpener.Register;
end;

end.
