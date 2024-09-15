unit Zx.IT.KeyBinding.DisableCtrlEnter;

interface

uses
  System.Classes,
  System.SysUtils,
  ToolsAPI,
  Vcl.Menus;

type
  /// <summary>
  /// Disables the annoying Ctrl+Enter shortcut that triggers the 'Open file' dialog.
  /// </summary>
  TZxDisableCtrlEnterKeyBindingNotifier = class(TNotifierObject, IOTAKeyboardBinding)
  strict private
    procedure OnKeyboardBindingExecute(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
  strict protected
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);

  strict private
    class var FNotifierIndex: Integer;
    class constructor ClassCreate;
    class destructor ClassDestroy;
  public
    class procedure Register; static;
  end;

implementation

const
  CShortCut = 'Ctrl+Enter';

resourcestring
  SDisplayName = 'Disable Ctrl+Enter KeyBinding';
  SName = 'ZxDisableCtrlEnterKeyBinding';

  { TZxDisableCtrlEnterKeyBindingNotifier }

procedure TZxDisableCtrlEnterKeyBindingNotifier.OnKeyboardBindingExecute(const Context: IOTAKeyContext; KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
begin
  // do nothing, mark as handled
  BindingResult := TKeyBindingResult.krHandled;
end;

function TZxDisableCtrlEnterKeyBindingNotifier.GetBindingType: TBindingType;
begin
  Result := TBindingType.btPartial;
end;

function TZxDisableCtrlEnterKeyBindingNotifier.GetDisplayName: string;
begin
  Result := SDisplayName;
end;

function TZxDisableCtrlEnterKeyBindingNotifier.GetName: string;
begin
  Result := SName;
end;

procedure TZxDisableCtrlEnterKeyBindingNotifier.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  BindingServices.AddKeyBinding([TextToShortcut(CShortCut)], OnKeyboardBindingExecute, nil, 0);
end;

class constructor TZxDisableCtrlEnterKeyBindingNotifier.ClassCreate;
begin
  FNotifierIndex := -1;
end;

class destructor TZxDisableCtrlEnterKeyBindingNotifier.ClassDestroy;
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if (FNotifierIndex > -1) and Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    LKeyboardServices.RemoveKeyboardBinding(FNotifierIndex);
end;

class procedure TZxDisableCtrlEnterKeyBindingNotifier.Register;
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if (FNotifierIndex = -1) and Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    FNotifierIndex := LKeyboardServices.AddKeyboardBinding(TZxDisableCtrlEnterKeyBindingNotifier.Create);
end;

end.
