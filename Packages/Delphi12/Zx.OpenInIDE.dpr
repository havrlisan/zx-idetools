program Zx.OpenInIDE;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.ShellAPI,
  System.SysUtils,
  // System.IOUtils,
  System.Win.Registry;

const
  CRADStudioMainForm = 'TAppBuilder';
  CRegistryKeyPath = '\Software\Embarcadero\BDS\23.0';
  CRegistryKey = 'App'; // Contains full path to bds.exe
  WM_BPL_READY = WM_USER + 200;

type
  TCopyDataPayload = record
    FileName: array [0 .. MAX_PATH - 1] of Char;
    Line: Integer;
    Col: Integer;
  end;

procedure Log(const AMsg: String);
begin
  // TFile.AppendAllText('Z:\tmp_sender.log', Format('[%s] %s' + sLineBreak, [DateTimeToStr(Now), AMsg]));
end;

procedure SendFileAndLine(const AWnd: HWND; const AFile: string; ALine, ACol: Integer);
var
  LCDS: TCopyDataStruct;
  LPayload: TCopyDataPayload;
begin
  // Log('Sending open request: ' + AFile + ':' + ALine.ToString + ':' + ACol.ToString);
  FillChar(LPayload, SizeOf(LPayload), 0);
  StrPLCopy(LPayload.FileName, AFile, MAX_PATH - 1);
  LPayload.Line := ALine;
  LPayload.Col := ACol;

  LCDS.dwData := 0;
  LCDS.cbData := SizeOf(LPayload);
  LCDS.lpData := @LPayload;

  SendMessage(AWnd, WM_COPYDATA, 0, LPARAM(@LCDS));
end;

function GetRADStudioPath: string;
var
  Reg: TRegistry;
begin
  Result := ParamStr(4);
  if not Result.IsEmpty then
    Exit;
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(CRegistryKeyPath) then
      Result := Reg.ReadString(CRegistryKey);
  finally
    Reg.Free;
  end;
end;

function WaitUntilIDEReady: HWND;
begin
  // loop runs ~30s
  for var I := 0 to 60 do
  begin
    var
    LIDEWnd := FindWindow(CRADStudioMainForm, nil);
    if LIDEWnd <> 0 then
      if SendMessage(LIDEWnd, WM_BPL_READY, 0, 0) = 1 then
        Exit(LIDEWnd);
    Sleep(500);
    // Log('WaitUntilReady ' + I.ToString);
  end;
  raise Exception.Create('RAD Studio loaded but BPL did not respond in time');
end;

procedure WaitForRADStudioAndSend(const AFile: string; ALine, ACol: Integer);
var
  LIDEWnd: HWND;
begin
  // loop runs ~30s
  for var I := 0 to 60 do
  begin
    LIDEWnd := FindWindow(CRADStudioMainForm, nil);
    if LIDEWnd <> 0 then
      Break;
    Sleep(500);
    // Log('WaitForRADStudioAndSend ' + I.ToString);
  end;
  if LIDEWnd = 0 then
    raise Exception.Create('RAD Studio did not start in time');
  { WaitUntilIDEReady returns new HWND because it changes after RAD Studio startup }
  LIDEWnd := WaitUntilIDEReady;
  SendFileAndLine(LIDEWnd, AFile, ALine, ACol)
end;

begin
  try
    if ParamCount < 2 then
      raise Exception.Create('Usage: Zx.OpenInIDE.exe <File> [Line] [Column] [RAD Studio Path]');
    var
    LIDEWnd := FindWindow(CRADStudioMainForm, nil);
    if LIDEWnd <> 0 then
      SendFileAndLine(LIDEWnd, ParamStr(1), StrToIntDef(ParamStr(2), 0), StrToIntDef(ParamStr(3), 0))
    else
    begin
      // Log('RAD Studio not found, launching...');
      var
      LIDEPath := GetRADStudioPath;
      if LIDEPath = '' then
        raise Exception.Create('Cannot locate bds.exe path from registry');

      // Log('Opening ' + LIDEPath.QuotedString);
      ShellExecute(0, 'open', PChar(LIDEPath), nil, nil, SW_SHOWNORMAL);
      WaitForRADStudioAndSend(ParamStr(1), StrToIntDef(ParamStr(2), 0), StrToIntDef(ParamStr(3), 0));
    end;
  except
    on E: Exception do
      Log(E.ClassName + ': ' + E.Message);
  end;

end.
