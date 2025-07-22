unit Zx.IT.DelayHooker;

interface

uses
  Vcl.ExtCtrls;

type
  /// <summary>
  /// Override when implementing class that tries to wait for something to load.
  /// </summary>
  TZxDelayHooker = class abstract(TInterfacedObject)
  strict private
    FTimer: TTimer;
    FRetryCount: Cardinal;
    procedure OnTimer(Sender: TObject);
  strict protected
    function TryLoad: Boolean; virtual; abstract;
    function TryImmediately: Boolean; virtual;
    function TimerDelay: Cardinal; virtual;
    function MaxRetries: Cardinal; virtual;
  public
    procedure AfterConstruction; override;
    destructor Destroy; override;
    function IsLoaded: Boolean;
  end;

implementation

uses
  Zx.IT.Common;

{ TZxDelayHooker }

function TZxDelayHooker.MaxRetries: Cardinal;
begin
  Result := 15;
end;

function TZxDelayHooker.TimerDelay: Cardinal;
begin
  Result := 500;
end;

function TZxDelayHooker.TryImmediately: Boolean;
begin
  Result := True;
end;

procedure TZxDelayHooker.OnTimer(Sender: TObject);
begin
  if TryLoad then
    FTimer.Enabled := False
  else
  begin
    Inc(FRetryCount);
    if FRetryCount = MaxRetries then
    begin
      TZxIDEMessages.ShowMessage(ClassName + ': failed loading after %d retries (Delay=%dms)', [MaxRetries, TimerDelay]);
      FTimer.Enabled := False;
    end;
  end;
end;

procedure TZxDelayHooker.AfterConstruction;
begin
  inherited;
  if not(TryImmediately and TryLoad) then
  begin
    FTimer := TTimer.Create(nil);
    FTimer.Interval := 500;
    FTimer.OnTimer := OnTimer;
    FTimer.Enabled := True;
  end;
end;

destructor TZxDelayHooker.Destroy;
begin
  if Assigned(FTimer) then
    FTimer.Free;
  inherited;
end;

function TZxDelayHooker.IsLoaded: Boolean;
begin
  Result := (FTimer = nil) or not FTimer.Enabled;
end;

end.
