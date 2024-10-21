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
    CDefaultShortcut = 'Ctrl+Shift+T';
    CFileMenuItemCaption = 'File';
    COpenRecentMenuItemCaption = 'Open Recent';
    CRecentTabHotkey = 'A';

  strict private
    FShortCut: TShortCut;
    procedure OnKeyboardBindingExecute(const Context: IOTAKeyContext; KeyCode: TShortCut; var BindingResult: TKeyBindingResult);
    function FindOpenRecentMenuItem: TMenuItem;
  strict protected
    function GetBindingType: TBindingType;
    function GetDisplayName: string;
    function GetName: string;
    procedure BindKeyboard(const BindingServices: IOTAKeyBindingServices);
  public
    constructor Create(AShortCut: String = String.Empty);

  strict private
    class var FNotifierIndex: Integer;
    class constructor ClassCreate;
    class destructor ClassDestroy;
  public
    class procedure Register(const AShortCut: String = String.Empty); static;
  end;

implementation

uses
  Zx.IT.Common;

resourcestring
  SDisplayName = 'Reopen Last Closed Tab KeyBinding';
  SName = 'ZxReopenLastClosedTabKeyBinding';

  { TZxReopenLastClosedTabKeyBindingNotifier }

procedure TZxReopenLastClosedTabKeyBindingNotifier.OnKeyboardBindingExecute(const Context: IOTAKeyContext; KeyCode: TShortCut;
  var BindingResult: TKeyBindingResult);
begin
  BindingResult := TKeyBindingResult.krHandled;
  var
  LOpenRecentMenuItem := FindOpenRecentMenuItem;
  if Assigned(LOpenRecentMenuItem) then
    for var LItem in LOpenRecentMenuItem do
      if GetHotkey(LItem.Caption) = CRecentTabHotkey then
      begin
        LItem.Click; { OnClick is assigned, Action is nil for these items }
        Break;
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
  BindingServices.AddKeyBinding([FShortCut], OnKeyboardBindingExecute, nil, 0);
end;

constructor TZxReopenLastClosedTabKeyBindingNotifier.Create(AShortCut: String);
begin
  inherited Create;
  FShortCut := TextToShortcut(AShortCut);
  if FShortCut = 0 then
    FShortCut := TextToShortcut(CDefaultShortcut);
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

class procedure TZxReopenLastClosedTabKeyBindingNotifier.Register(const AShortCut: String = String.Empty);
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if (FNotifierIndex = -1) and Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    FNotifierIndex := LKeyboardServices.AddKeyboardBinding(TZxReopenLastClosedTabKeyBindingNotifier.Create(AShortCut));
end;

end.
