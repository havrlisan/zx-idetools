unit Zx.IT.Reg;

interface

procedure Register;

implementation

uses
  Zx.IT.DbgVisualizer.GUID,
  Zx.IT.KeyBinding.DisableCtrlEnter,
  Zx.IT.KeyBinding.ReloadLSPServer;

procedure Register;
begin
  TZxDebuggerVisualizerGUID.Register;
  TZxDisableCtrlEnterKeyBindingNotifier.Create;
  TZxReloadLSPServerNotifier.Create;
end;

end.