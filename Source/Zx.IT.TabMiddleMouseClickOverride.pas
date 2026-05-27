unit Zx.IT.TabMiddleMouseClickOverride;

interface

uses
  System.Classes,
  DockForm,
  IDEDockTabSet,
  ToolsAPI;

type
  TZxTabMiddleMouseClickOverride = class(TInterfacedObject)
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;

  strict private
    class var FInstance: IInterface;
  public
    class procedure Register; static;
  end;

implementation

uses
  System.SysUtils,
  Zx.IT.Common,
  Vcl.ActnList;

{ TZxTabMiddleMouseClickOverride }

procedure TZxTabMiddleMouseClickOverride.AfterConstruction;
var
  LEditorServices: INTAEditorServices;
begin
  inherited;
  if not Supports(BorlandIDEServices, INTAEditorServices, LEditorServices) then
  begin
    TZxIDEMessages.ShowMessage(ClassName + ': BorlandIDEServices does not support INTAEditorServices');
    Exit;
  end;

  TZxIDEMessages.ShowMessage('EditWindowCount: %d', [LEditorServices.EditWindowCount]);
  TZxIDEMessages.ShowMessage('LEditorServices.TopEditWindow.Form.Caption: %s', [LEditorServices.TopEditWindow.Form.Caption]);
  var
  LControl := LEditorServices.TopEditWindow.Form;
  TZxIDEMessages.ShowMessage('LControl.ClassName: %s', [LControl.ClassName]);
  TZxIDEMessages.ShowMessage('LControl.DockClientCount: %d', [LControl.DockClientCount]);
  for var I := 0 to Pred(LControl.ComponentCount) do
    if LControl.Components[I] is TIDEDockTabSet then
    begin
      var LTabSet := TIDEDockTabSet(LControl.Components[I]);
      TZxIDEMessages.ShowMessage('LControl.Components[%d]: %s', [I, LControl.Components[I].ClassName]);
      TZxIDEMessages.ShowMessage('LTabSet: %d', [LTabSet.Tabs.Count]);
    end;
end;

destructor TZxTabMiddleMouseClickOverride.Destroy;
begin

  inherited;
end;

class procedure TZxTabMiddleMouseClickOverride.Register;
begin
  FInstance := TZxTabMiddleMouseClickOverride.Create;
end;

end.
