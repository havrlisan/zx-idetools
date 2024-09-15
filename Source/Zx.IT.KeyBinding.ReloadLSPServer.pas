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
    CDefaultShortcut = 'Alt+Shift+R';

  strict private
    FShortCut: TShortCut;
    FShortCutAdded: Boolean;
    procedure AddShortCut;
    function FindReloadLSPServerMenuItem: TMenuItem;
  protected
    { IOTAIDENotifier }
    procedure AfterCompile(Succeeded: Boolean);
    procedure BeforeCompile(const Project: IOTAProject; var Cancel: Boolean);
    procedure FileNotification(NotifyCode: TOTAFileNotification; const FileName: string; var Cancel: Boolean);
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
  Zx.IT.Messages;

resourcestring
  CFailedToLocateReloadLSPServerMenuItem = 'Failed to locate ''Reload LSP Server'' menu item';

  { TZxReloadLSPServerNotifier }

procedure TZxReloadLSPServerNotifier.AddShortCut;
begin
  if not FShortCutAdded then
  begin
    var
    LMenuItem := FindReloadLSPServerMenuItem;
    if Assigned(LMenuItem) then
    begin
      FShortCutAdded := True;
      LMenuItem.ShortCut := FShortCut;
    end
    else
      TZxIDEMessages.ShowMessage(CFailedToLocateReloadLSPServerMenuItem);
  end;
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
        for var LToolsMenuItemChild in LChild do
        begin
          if SameCaption(LToolsMenuItemChild.Caption, CReloadLSPServerMenuItemCaption) then
          begin
            Result := LToolsMenuItemChild;
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
    AddShortCut;
end;

constructor TZxReloadLSPServerNotifier.Create(AShortCut: String);
begin
  inherited Create;
  FShortCut := TextToShortcut(AShortCut);
  if FShortCut = 0 then
    FShortCut := TextToShortcut(CDefaultShortcut);
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
