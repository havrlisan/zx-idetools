unit Zx.IT.KeyBinding.ReloadLSPServer;

interface

uses
  System.SysUtils,
  System.Classes,
  ToolsAPI,
  Vcl.Menus;

type
  /// <summary>
  /// This is not an actual KeyBinding Notifier implementation, but a notifier for
  /// IDE file actions. Reason for this is because the 'Reload LSP Server' menu item
  /// is not added by the time this notifier would get registered if it was an actual
  /// keybinding notifier.
  /// </summary>
  TZxReloadLSPServerNotifier = class(TNotifierObject, IOTANotifier, IOTAIDENotifier)
  private const
    CToolsMenuItemCaption = 'Tools';
    CReloadLSPServerMenuItemCaption = 'Reload LSP Server';
    CDefaultShortcut = 'Alt+Shift+W';

  strict private
    FShortCut: TShortCut;
    FShortCutAdded: Boolean;
    procedure AddShortCut(const ALogFailed: Boolean);
    procedure RemoveShortCut;
    function FindReloadLSPServerMenuItem: TMenuItem;
  protected
    { IOTAIDENotifier }
    procedure AfterCompile(Succeeded: Boolean);
    procedure BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);
    procedure FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean);
  public
    constructor Create(AShortCut: String = String.Empty);
    destructor Destroy; override;

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
  CReloadLSPServerMenuItemNotFound = 'TMenuItem ''Reload LSP Server'' not found';

  { TZxReloadLSPServerNotifier }

procedure TZxReloadLSPServerNotifier.AddShortCut(const ALogFailed: Boolean);
begin
  if FShortCutAdded then
    Exit;
  var
  LMenuItem := FindReloadLSPServerMenuItem;
  if Assigned(LMenuItem) then
  begin
    FShortCutAdded := True;
    LMenuItem.ShortCut := FShortCut;
  end
  else if ALogFailed then
    TZxIDEMessages.ShowMessage(CReloadLSPServerMenuItemNotFound);
end;

procedure TZxReloadLSPServerNotifier.RemoveShortCut;
begin
  if not FShortCutAdded then
    Exit;
  var
  LMenuItem := FindReloadLSPServerMenuItem;
  if Assigned(LMenuItem) then
    LMenuItem.ShortCut := 0;
end;

function TZxReloadLSPServerNotifier.FindReloadLSPServerMenuItem: TMenuItem;
var
  LServices: INTAServices;
begin
  Result := nil;
  if Supports(BorlandIDEServices, INTAServices, LServices) then
    for var LChild in LServices.MainMenu.Items do
      if SameCaption(LChild.Caption, CToolsMenuItemCaption) then
      begin
        for var LMenuItemChild in LChild do
        begin
          if SameCaption(LMenuItemChild.Caption, CReloadLSPServerMenuItemCaption) then
          begin
            Result := LMenuItemChild;
            Break;
          end;
        end;
        Break;
      end;
end;

procedure TZxReloadLSPServerNotifier.AfterCompile(Succeeded: Boolean);
begin
  // do nothing
end;

procedure TZxReloadLSPServerNotifier.BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);
begin
  // do nothing
end;

procedure TZxReloadLSPServerNotifier.FileNotification(NotifyCode: TOTAFileNotification; const FileName: string;
  var Cancel: Boolean);
begin
  inherited;
  if NotifyCode = TOTAFileNotification.ofnEndProjectGroupOpen then
    AddShortCut(True);
end;

constructor TZxReloadLSPServerNotifier.Create(AShortCut: String);
begin
  inherited Create;
  FShortCut := TextToShortcut(AShortCut);
  if FShortCut = 0 then
    FShortCut := TextToShortcut(CDefaultShortcut);
  AddShortCut(False);
end;

destructor TZxReloadLSPServerNotifier.Destroy;
begin
  RemoveShortCut;
  inherited;
end;

class constructor TZxReloadLSPServerNotifier.ClassCreate;
begin
  FNotifierIndex := -1;
end;

class destructor TZxReloadLSPServerNotifier.ClassDestroy;
var
  LServices: IOTAServices;
begin
  if (FNotifierIndex > -1) and Supports(BorlandIDEServices, IOTAServices, LServices) then
    LServices.RemoveNotifier(FNotifierIndex);
end;

class procedure TZxReloadLSPServerNotifier.Register(const AShortCut: String = String.Empty);
var
  LServices: IOTAServices;
begin
  if Supports(BorlandIDEServices, IOTAServices, LServices) then
    FNotifierIndex := LServices.AddNotifier(TZxReloadLSPServerNotifier.Create(AShortCut));
end;

end.
