unit Zx.IT.ToggleComment;

interface

uses
  System.Classes,
  Vcl.ActnList,
  ToolsAPI;

type
  TZxToggleCommentKeyBinding = class(TNotifierObject, IOTAKeyboardBinding)
  strict private
    FAllIsCommented: Boolean;
    procedure Execute;
    procedure PreProcessLine(const Str: string);
    function ProcessLine(const Str: string): string;
    function ProcessText(const Text: string): string;
    procedure GetNewPos(var ARow: Integer; var ACol: Integer);
  strict private
    function IsComment(const Str: string): Boolean;
    function Comment(const Str: string): string;
    function Uncomment(const Str: string): string;
    function OTAEditPos(Col: SmallInt; Line: Longint): TOTAEditPos;
    function OTAEditPosToLinePos(EditPos: TOTAEditPos; EditView: IOTAEditView): Integer;
    function OTAGetCurSourcePos(var Col, Row: Integer; EditBuffer: IOTAEditBuffer): Boolean;
    function OTACharPos(CharIndex: SmallInt; Line: Longint): TOTACharPos;
    procedure OTASelectBlock(const Editor: IOTASourceEditor; const Start, After: TOTACharPos);
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

uses
  System.SysUtils,
  Vcl.Menus;

const
  CShortCut = 'Alt+Shift+S';

resourcestring
  SDisplayName = 'Toggle Comment';
  SName = 'ZxToggleComment';

  { TZxToggleCommentKeyBinding }

procedure TZxToggleCommentKeyBinding.Execute;
const
  CBatchSize = $7FFF;
var
  LEditorServices: IOTAEditorServices;
  OrigText: AnsiString;
  Text: string;
  Buf: PAnsiChar;
  BlockStartLine, BlockEndLine: Integer;
  StartPos, EndPos, ReadStart: Integer;
  Reader: IOTAEditReader;
  Writer: IOTAEditWriter;
  Row, Col, Len, ASize: Integer;
  NewRow, NewCol: Integer;
begin
  FAllIsCommented := True;
  if not Supports(BorlandIDEServices, IOTAEditorServices, LEditorServices) then
    Exit;
  var
  LEditBuffer := LEditorServices.GetTopBuffer;
  if LEditBuffer = nil then
    Exit;
  var
  LTopView := LEditBuffer.TopView;
  if LTopView = nil then
    Exit;
  var
  LBlock := LTopView.Block;
  StartPos := 0;
  EndPos := 0;
  BlockStartLine := 0;
  BlockEndLine := 0;
  NewRow := 0;
  NewCol := 0;
  if (LBlock <> nil) and LBlock.IsValid then
  begin
    BlockStartLine := LBlock.StartingRow;
    StartPos := OTAEditPosToLinePos(OTAEditPos(1, BlockStartLine), LTopView);
    BlockEndLine := LBlock.EndingRow;
    if LBlock.EndingColumn > 1 then
    begin
      if BlockEndLine < LTopView.Buffer.GetLinesInBuffer then
      begin
        Inc(BlockEndLine);
        EndPos := OTAEditPosToLinePos(OTAEditPos(1, BlockEndLine), LTopView);
      end
      else
        EndPos := OTAEditPosToLinePos(OTAEditPos(255, BlockEndLine), LTopView);
    end
    else
      EndPos := OTAEditPosToLinePos(OTAEditPos(1, BlockEndLine), LTopView);
  end
  else
  begin
    if OTAGetCurSourcePos(Col, Row, LEditBuffer) then
    begin
      StartPos := OTAEditPosToLinePos(OTAEditPos(1, Row), LTopView);
      if Row < LTopView.Buffer.GetLinesInBuffer then
      begin
        EndPos := OTAEditPosToLinePos(OTAEditPos(1, Row + 1), LTopView);
        NewRow := Row;
        NewCol := Col;
        GetNewPos(NewRow, NewCol);
      end
      else
        EndPos := OTAEditPosToLinePos(OTAEditPos(255, Row), LTopView);
    end;
  end;

  Len := EndPos - StartPos;
  Assert(Len >= 0);
  SetLength(OrigText, Len);
  Buf := Pointer(OrigText);
  ReadStart := StartPos;
  Reader := LTopView.Buffer.CreateReader;
  try
    while Len > CBatchSize do
    begin
      ASize := Reader.GetText(ReadStart, Buf, CBatchSize);
      Inc(Buf, ASize);
      Inc(ReadStart, ASize);
      Dec(Len, ASize);
    end;
    if Len > 0 then
      Reader.GetText(ReadStart, Buf, Len);
  finally
    Reader := nil;
  end;

  if OrigText <> '' then
  begin
    {$IFDEF UNICODE}
    Text := ProcessText((UTF8ToUnicodeString(OrigText)));
    {$ELSE}
    Text := ProcessText(Utf8ToAnsi(OrigText));
    {$ENDIF}
    Writer := LTopView.Buffer.CreateUndoableWriter;
    try
      Writer.CopyTo(StartPos);
      {$IFDEF UNICODE}
      Writer.Insert(PAnsiChar(Utf8Encode(Text)));
      {$ELSE}
      Writer.Insert(PAnsiChar(AnsiToUtf8(Text)));
      {$ENDIF}
      Writer.DeleteTo(EndPos);
    finally
      Writer := nil;
    end;
  end;

  if (NewRow > 0) and (NewCol > 0) then
  begin
    LTopView.CursorPos := OTAEditPos(NewCol, NewRow);
  end
  else if (BlockStartLine > 0) and (BlockEndLine > 0) then
    OTASelectBlock(LTopView.Buffer, OTACharPos(0, BlockStartLine), OTACharPos(0, BlockEndLine));
  LTopView.Paint;
end;

procedure TZxToggleCommentKeyBinding.PreProcessLine(const Str: string);
begin
  if not IsComment(Str) then
    FAllIsCommented := False;
end;

function TZxToggleCommentKeyBinding.ProcessLine(const Str: string): string;
begin
  if FAllIsCommented then
    Result := Uncomment(Str)
  else
    Result := Comment(Str);
end;

function TZxToggleCommentKeyBinding.ProcessText(const Text: string): string;
begin
  var
  LLines := TStringList.Create;
  try
    LLines.Text := Text;
    for var I := 0 to LLines.Count - 1 do
      PreProcessLine(LLines[I]);
    for var I := 0 to LLines.Count - 1 do
      LLines[I] := ProcessLine(LLines[I]);
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

procedure TZxToggleCommentKeyBinding.GetNewPos(var ARow, ACol: Integer);
begin
  Inc(ARow); { move to next line }
end;

function TZxToggleCommentKeyBinding.IsComment(const Str: string): Boolean;
var
  S: string;
begin
  S := Trim(Str);
  Result := (Pos('//', S) = 1) and ((Length(S) <= 2) or (S[3] <> '/') or (Pos('////', S) = 1) or (Pos('///*', S) = 1));
end;

function TZxToggleCommentKeyBinding.Uncomment(const Str: string): string;
begin
  if IsComment(Str) then
    Result := StringReplace(Str, '//', '', [])
  else
    Result := Str;
end;

function TZxToggleCommentKeyBinding.Comment(const Str: string): string;
begin
  Result := '//' + Str;
end;

function TZxToggleCommentKeyBinding.OTAEditPos(Col: SmallInt; Line: Longint): TOTAEditPos;
begin
  Result.Col := Col;
  Result.Line := Line;
end;

function TZxToggleCommentKeyBinding.OTAEditPosToLinePos(EditPos: TOTAEditPos; EditView: IOTAEditView): Integer;
var
  CharPos: TOTACharPos;
begin
  EditView.ConvertPos(True, EditPos, CharPos);
  Result := EditView.CharPosToPos(CharPos);
end;

function TZxToggleCommentKeyBinding.OTAGetCurSourcePos(var Col, Row: Integer; EditBuffer: IOTAEditBuffer): Boolean;
begin
  Result := False;
  try
    var
    LEditPosition := EditBuffer.GetEditPosition;
    if LEditPosition = nil then
      Exit;
    Col := LEditPosition.Column;
    Row := LEditPosition.Row;
    Result := True;
  except
    ;
  end;
end;

function TZxToggleCommentKeyBinding.OTACharPos(CharIndex: SmallInt; Line: Longint): TOTACharPos;
begin
  Result.CharIndex := CharIndex;
  Result.Line := Line;
end;

procedure TZxToggleCommentKeyBinding.OTASelectBlock(const Editor: IOTASourceEditor; const Start, After: TOTACharPos);
begin
  Editor.BlockVisible := False;
  try
    Editor.BlockType := btNonInclusive;
    Editor.BlockStart := Start;
    Editor.BlockAfter := After;
  finally
    Editor.BlockVisible := True;
  end;
end;

procedure TZxToggleCommentKeyBinding.OnKeyboardBindingExecute(const Context: IOTAKeyContext; KeyCode: TShortcut;
  var BindingResult: TKeyBindingResult);
begin
  BindingResult := TKeyBindingResult.krHandled;
  Execute;
end;

function TZxToggleCommentKeyBinding.GetBindingType: TBindingType;
begin
  Result := TBindingType.btPartial;
end;

function TZxToggleCommentKeyBinding.GetDisplayName: string;
begin
  Result := SDisplayName;
end;

function TZxToggleCommentKeyBinding.GetName: string;
begin
  Result := SName;
end;

procedure TZxToggleCommentKeyBinding.BindKeyboard(const BindingServices: IOTAKeyBindingServices);
begin
  BindingServices.AddKeyBinding([TextToShortcut(CShortCut)], OnKeyboardBindingExecute, nil, 0);
end;

class constructor TZxToggleCommentKeyBinding.ClassCreate;
begin
  FNotifierIndex := -1;
end;

class destructor TZxToggleCommentKeyBinding.ClassDestroy;
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if (FNotifierIndex > -1) and Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    LKeyboardServices.RemoveKeyboardBinding(FNotifierIndex);
end;

class procedure TZxToggleCommentKeyBinding.Register;
var
  LKeyboardServices: IOTAKeyboardServices;
begin
  if (FNotifierIndex = -1) and Supports(BorlandIDEServices, IOTAKeyboardServices, LKeyboardServices) then
    FNotifierIndex := LKeyboardServices.AddKeyboardBinding(TZxToggleCommentKeyBinding.Create);
end;

end.

