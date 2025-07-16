unit Zx.IT.FileOpener;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  Vcl.Forms,
  Vcl.ExtCtrls,
  ToolsAPI;

type
  IZxFileOpener = interface
    ['{BA6137F0-B8E1-4FBB-BC16-DF7A68DBE192}']
    function GetPrevWndProc: Pointer;
    procedure OpenFileAtLine(const AFile: string; ALine, ACol: Integer);
    property PrevWndProc: Pointer read GetPrevWndProc;
  end;

  TZxFileOpener = class(TInterfacedObject, IZxFileOpener)
  strict private
    FHookTimer: TTimer;
    FPrevWndProc: Pointer;
    procedure HookToMainForm(Sender: TObject);
  strict protected
    { IZxFileOpener }
    function GetPrevWndProc: Pointer;
    procedure OpenFileAtLine(const AFile: string; ALine, ACol: Integer);
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;

  strict private
    class var FInstance: IZxFileOpener;
  public
    class procedure Register;
    class procedure Unregister;
    class property Instance: IZxFileOpener read FInstance;
  end;

implementation

uses
  System.IOUtils,
  Zx.IT.Common;

const
  WM_BPL_READY = WM_USER + 200;

type
  TCopyDataPayload = record
    FileName: array [0 .. MAX_PATH - 1] of Char;
    Line: Integer;
    Col: Integer;
  end;

function NewWndProc(Wnd: HWND; Msg: UINT; wParam: wParam; lParam: lParam): LRESULT; stdcall;
var
  LCDS: PCopyDataStruct;
  LPayload: ^TCopyDataPayload;
begin
  if Msg = WM_BPL_READY then
    Result := 1 { Zx.OpenInIDE expects 1 if TZxFileOpener is ready }
  else if Msg = WM_COPYDATA then
  begin
    LCDS := PCopyDataStruct(lParam);
    if LCDS^.cbData = SizeOf(TCopyDataPayload) then
    begin
      LPayload := LCDS^.lpData;
      try
        TZxFileOpener.Instance.OpenFileAtLine(LPayload^.FileName, LPayload^.Line, LPayload^.Col);
      except
        on E: Exception do
          TZxIDEMessages.ShowMessage('[TZxFileOpener] NewWndProc: failed opening file: ' + E.Message);
      end;
      Result := 1; { mark as handled }
    end
    else
      Result := CallWindowProc(TZxFileOpener.Instance.PrevWndProc, Wnd, Msg, wParam, lParam);
  end
  else
    Result := CallWindowProc(TZxFileOpener.Instance.PrevWndProc, Wnd, Msg, wParam, lParam);
end;

{ TZxFileOpener }

procedure TZxFileOpener.HookToMainForm(Sender: TObject);
begin
  var
  LFormHandle := Application.MainForm.Handle;
  if LFormHandle = 0 then
    Exit;
  FHookTimer.Enabled := False;
  FPrevWndProc := Pointer(SetWindowLongPtr(LFormHandle, GWLP_WNDPROC, LONG_PTR(@NewWndProc)));
end;

function TZxFileOpener.GetPrevWndProc: Pointer;
begin
  Result := FPrevWndProc;
end;

procedure TZxFileOpener.OpenFileAtLine(const AFile: string; ALine, ACol: Integer);
var
  LPos: TOTAEditPos;
begin
  var
  LModuleServices := BorlandIDEServices as IOTAModuleServices;
  var
  LModule := LModuleServices.OpenModule(AFile);
  if Assigned(LModule) and (LModule.ModuleFileCount > 0) then
  begin
    LModule.Show;
    if LModule.ModuleFileCount = 0 then
    begin
      TZxIDEMessages.ShowMessage('[TZxFileOpener] OpenFileAtLine: ModuleFileCount is 0');
      Exit;
    end;
    var
    LEditor := LModule.ModuleFileEditors[0] as IOTASourceEditor;
    LEditor.Show;
    if LEditor.EditViewCount = 0 then
    begin
      TZxIDEMessages.ShowMessage('[TZxFileOpener] OpenFileAtLine: EditViewCount is 0');
      Exit;
    end;
    var
    LEditView := LEditor.GetEditView(0);
    if Assigned(LEditView) then
    begin
      LEditView.Center(ALine, ACol);
      LPos.Col := ACol;
      LPos.Line := ALine;
      LEditView.CursorPos := LPos;
      var
      LWnd := Application.MainForm.Handle;

      if IsIconic(LWnd) then
        ShowWindow(LWnd, SW_RESTORE);

      SetForegroundWindow(LWnd);
      SetActiveWindow(LWnd);
    end;
  end
  else
    TZxIDEMessages.ShowMessage('[TZxFileOpener] OpenFileAtLine: could not open ' + AFile.QuotedString);
end;

procedure TZxFileOpener.AfterConstruction;
begin
  inherited;
  FHookTimer := TTimer.Create(nil);
  FHookTimer.Interval := 500;
  FHookTimer.OnTimer := HookToMainForm;
  FHookTimer.Enabled := True;
end;

destructor TZxFileOpener.Destroy;
begin
  if not FHookTimer.Enabled then
    SetWindowLongPtr(Application.MainForm.Handle, GWLP_WNDPROC, LONG_PTR(FPrevWndProc));
  FHookTimer.Free;
  inherited;
end;

class procedure TZxFileOpener.Register;
begin
  if FInstance = nil then
    FInstance := TZxFileOpener.Create;
end;

class procedure TZxFileOpener.Unregister;
begin
  FInstance := nil;
end;

end.
