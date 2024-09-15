unit Zx.IT.DbgVisualizer.GUID;

interface

uses
  System.SysUtils,
  System.Character,
  ToolsAPI;

type
  /// <summary>
  /// Displays GUID value in the debugger as an actual GUID representation instead of
  /// a series of integers. Cpp visualizer is not yet implemented.
  /// </summary>
  TZxDebuggerVisualizerGUID = class(TInterfacedObject, IOTADebuggerVisualizer, IOTADebuggerVisualizerValueReplacer)
  protected type
    EZxDebuggerVisualizerGUID = class(Exception);

  strict private
    /// <summary>
    /// Deserializes default record representation of GUID in the debugger.
    /// Examples of default values:
    /// (1447001764, 50768, 18962, (174, 209, 59, 176, 130, 170, 93, 180))
    /// (D1:1447001764; D2:50768; D3:18962; D4:(174, 209, 59, 176, 130, 170, 93, 180))
    /// </summary>
    function DeserializeGUID(const AGUIDStr: string; var AGUID: TGUID): Boolean;
  protected
    { IOTADebuggerVisualizer }
    function GetSupportedTypeCount: Integer;
    procedure GetSupportedType(Index: Integer; var TypeName: string; var AllDescendants: Boolean); overload;
    function GetVisualizerIdentifier: string;
    function GetVisualizerName: string;
    function GetVisualizerDescription: string;
    { IOTADebuggerVisualizerValueReplacer }
    function GetReplacementValue(const Expression, TypeName, EvalResult: string): string;

  strict private
    class var FInstance: IOTADebuggerVisualizer;
    class destructor ClassDestroy;
  public
    class procedure Register; static;
  end;

implementation

uses
  Zx.IT.Messages;

type
{$SCOPEDENUMS ON}
  TTypeLang = (Delphi, Cpp);
{$SCOPEDENUMS OFF}

  TGUIDVisualizerType = record
    TypeName: string;
    TypeLang: TTypeLang;
  end;

const
  CGUIDVisualizerTypes: array [0 .. 4] of TGUIDVisualizerType = (

    (TypeName: 'TGUID'; TypeLang: TTypeLang.Delphi),

    (TypeName: 'function: TGUID'; TypeLang: TTypeLang.Delphi),

    (TypeName: 'System::TGUID'; TypeLang: TTypeLang.Cpp),

    (TypeName: 'System::TGUID &'; TypeLang: TTypeLang.Cpp),

    (TypeName: 'TGUID &'; TypeLang: TTypeLang.Cpp)

    );

resourcestring
  SGUIDVisualizerName = 'TGUID Visualizer for Delphi (Zx.IDETools)';
  SGUIDVisualizerDesc = 'Displays GUID properly instead of its integer field values';

  { TZxDebuggerVisualizerGUID }

function TZxDebuggerVisualizerGUID.DeserializeGUID(const AGUIDStr: string; var AGUID: TGUID): Boolean;

  function GetUIntValue(const ABuffer: String; const AMaxValue: Cardinal): Cardinal;
  begin
    Result := StrToUInt(ABuffer);
    if Result > AMaxValue then
      raise EZxDebuggerVisualizerGUID.Create('Invalid GUID representation');
  end;

const
  CIgnoredChars = ['(', ',', ';', ')', ' '];
  CFieldFirstChar = 'D';
  CSkipFieldLen = 3; // eg. "D1:"
  CMaxBufferLen = 10; // Cardinal max value is 4294967295 = 10 chars
begin
  var
  I := 1;
  var
  LBuffer := String.Empty;
  var
  LCurrField := 0;
  var
  LCurrD4Pos := 0;
  try
    while I < AGUIDStr.Length do
      if CharInSet(AGUIDStr[I], CIgnoredChars) then
      begin
        if not LBuffer.IsEmpty then
        begin
          case LCurrField of
            0:
              AGUID.D1 := StrToUInt(LBuffer);
            1:
              AGUID.D2 := GetUIntValue(LBuffer, Word.MaxValue);
            2:
              AGUID.D3 := GetUIntValue(LBuffer, Word.MaxValue);
            3:
              begin
                AGUID.D4[LCurrD4Pos] := GetUIntValue(LBuffer, Byte.MaxValue);
                Inc(LCurrD4Pos);
              end;
          end;
          if LCurrField < 3 then
            Inc(LCurrField);
          LBuffer := String.Empty;
        end;
        Inc(I);
      end
      else if AGUIDStr[I] = CFieldFirstChar then
        Inc(I, CSkipFieldLen)
      else if AGUIDStr[I].IsNumber then
      begin
        LBuffer := LBuffer + AGUIDStr[I];
        Inc(I);
      end
      else
        raise EZxDebuggerVisualizerGUID.Create('Invalid GUID representation');
  except
    on E: Exception do
    begin
      TZxIDEMessages.ShowMessage('DeserializeGUID failed: %s: %s. GUID string recieved: %s', [E.ClassName, E.ToString, AGUIDStr]);
      AGUID := TGUID.Empty;
    end;
  end;
  Result := LCurrD4Pos = Length(AGUID.D4);
end;

function TZxDebuggerVisualizerGUID.GetSupportedTypeCount: Integer;
begin
  Result := Length(CGUIDVisualizerTypes);
end;

procedure TZxDebuggerVisualizerGUID.GetSupportedType(Index: Integer; var TypeName: string; var AllDescendants: Boolean);
begin
  TypeName := CGUIDVisualizerTypes[Index].TypeName;
  AllDescendants := False;
end;

function TZxDebuggerVisualizerGUID.GetVisualizerIdentifier: string;
begin
  Result := ClassName;
end;

function TZxDebuggerVisualizerGUID.GetVisualizerName: string;
begin
  Result := SGUIDVisualizerName;
end;

function TZxDebuggerVisualizerGUID.GetVisualizerDescription: string;
begin
  Result := SGUIDVisualizerDesc;
end;

function TZxDebuggerVisualizerGUID.GetReplacementValue(const Expression, TypeName, EvalResult: string): string;
var
  LGUID: TGUID;
begin
  var
  Lang := TTypeLang(-1);
  for var LVisualizerType in CGUIDVisualizerTypes do
    if TypeName = LVisualizerType.TypeName then
    begin
      Lang := LVisualizerType.TypeLang;
      Break;
    end;
  if Lang = TTypeLang.Delphi then
  begin
    if DeserializeGUID(EvalResult, LGUID) then
      Result := LGUID.ToString
    else
      Result := EvalResult;
  end
  else if Lang = TTypeLang.Cpp then
  begin
    { not implemented }
    Result := EvalResult;
  end;
end;

class destructor TZxDebuggerVisualizerGUID.ClassDestroy;
var
  LDebuggerServices: IOTADebuggerServices;
begin
  if Assigned(FInstance) and Supports(BorlandIDEServices, IOTADebuggerServices, LDebuggerServices) then
  begin
    LDebuggerServices.UnregisterDebugVisualizer(FInstance);
    FInstance := nil;
  end;
end;

class procedure TZxDebuggerVisualizerGUID.Register;
var
  LDebuggerServices: IOTADebuggerServices;
begin
  if (FInstance = nil) and Supports(BorlandIDEServices, IOTADebuggerServices, LDebuggerServices) then
  begin
    FInstance := TZxDebuggerVisualizerGUID.Create;
    (BorlandIDEServices as IOTADebuggerServices).RegisterDebugVisualizer(FInstance);
  end;
end;

end.
