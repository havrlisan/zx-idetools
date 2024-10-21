unit Zx.IT.KeyBinding.ReopenLastClosedTab;

interface

uses
  System.Classes,
  System.SysUtils,
  ToolsAPI,
  Vcl.Menus;

type
  /// <summary>
  /// Reopens the last closed tab.
  /// </summary>
  TZxReopenLastClosedTabKeyBindingNotifier = class(TNotifierObject, IOTAKeyboardBinding)
  private const
    CFileMenuItemCaption = 'File';
    COpenRecentMenuItemCaption = 'Open Recent';

  strict private
    procedure OnKeyboardBindingExecute(const Context: IOTAKeyContext; KeyCode: TShortcut; var BindingResult: TKeyBindingResult);
    function FindOpenRecentMenuItem: TMenuItem;
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

uses
  Zx.IT.Common;

const
  CShortCut = 'Ctrl+Shift+T';

resourcestring
  SDisplayName = 'Reopen Last Closed Tab KeyBinding';
  SName = 'ZxReopenLastClosedTabKeyBinding';

  { TZxReopenLastClosedTabKeyBindingNotifier }

procedure TZxReopenLastClosedTabKeyBindingNotifier.OnKeyboardBindingExecute(const Context: IOTAKeyContext; KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
begin
  BindingResult := TKeyBindingResult.krHandled;
  var
  LOpenRecentMenuItem := FindOpenRecentMenuItem;
  if LOpenRecentMenuItem = nil then
    Exit;
  var
  LInRecentTabsSection := False;
  for var LItem in LOpenRecentMenuItem do
  begin
    if LInRecentTabsSection then
    begin
      if LItem.IsLine then
        TZxIDEMessages.ShowMessage('[INFO] ReopenLastClosedTab - no recent tabs found.')
      else
        LItem.Click; { MenuItem's OnClick is assigned, Action is nil }
      Break;
    end;
    if LItem.IsLine then
      LInRecentTabsSection := True;
  end;
end;

function TZxReopenLastClosedTabKeyBindingNotifier.FindOpenRecentMenuItem: TMenuItem;
var
  LServices: INTAServices;
begin
  Result := nil;
  if Supports(BorlandIDEServices, INTAServices, LServices) then
    for var LChild in LServices.MainMenu.Items do
      if SameCaption(LChild.Caption, CFileMenuItemCaption) then
      begin
        for var LMenuItemChild in LChild do
        begin
          if SameCaption(LMenuItemChild.Caption, COpenRecentMenuItemCaption) then
          begin
            Result := LMenuItemChild;
            Break;
          end;
        end;
        Break;
      end;
end;

function TZxReopenLastClosedTabKeyBindingNotifier.GetBindingType: TBindingType;
begin
  Result := TBindingType.btPartial;
end;

function TZxReopenLastClosedTabKeyBindingNotifier.GetDisplayName: string;
begin
  Result := SDisplayName;
end;

function TZxReopenLastClosedTabKeyBindingNotifier.GetName: string;
begin
  Result := SName;
end;

procedure TZxReopenLastClosedTabKeyBindingNotifier.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  BindingServices.AddKeyBinding([TextToShortcut(CShortCut)], OnKeyboardBindingExecute, nil, 0);
end;

class constructor TZxReopenLastClosedTabKeyBindingNotifier.ClassCreate;
begin
  FNotifierIndex := -1;
end;

class destructor TZxReopenLastClosedTabKeyBindingNotifier.ClassDestroy;
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if (FNotifierIndex > -1) and Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    LKeyboardServices.RemoveKeyboardBinding(FNotifierIndex);
end;

class procedure TZxReopenLastClosedTabKeyBindingNotifier.Register;
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if (FNotifierIndex = -1) and Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    FNotifierIndex := LKeyboardServices.AddKeyboardBinding(TZxReopenLastClosedTabKeyBindingNotifier.Create);
end;

end.
