unit Zx.IT.Common;

interface

uses
  System.SysUtils,
  ToolsAPI;

type
  TZxIDEMessages = class
  private const
    CGroupName = 'Zx.IDETools';

  strict private
    class constructor ClassCreate;
    class function GroupMessage: IOTAMessageGroup;
  public
    class procedure ShowMessage(const AMessage: String); overload;
    class procedure ShowMessage(const AFormat: string; const AArgs: array of const); overload;
  end;

implementation

{ TZxIDEMessages }

class constructor TZxIDEMessages.ClassCreate;
begin
  var
  LMessageGroup := (BorlandIDEServices As IOTAMessageServices).GetGroup(CGroupName);
  if Assigned(LMessageGroup) then
    (BorlandIDEServices As IOTAMessageServices).ClearMessageGroup(LMessageGroup);
end;

class function TZxIDEMessages.GroupMessage: IOTAMessageGroup;
begin
  Result := (BorlandIDEServices As IOTAMessageServices).GetGroup(CGroupName);
  if Result = nil then
  begin
    Result := (BorlandIDEServices As IOTAMessageServices).AddMessageGroup(CGroupName);
    Result.AutoScroll := True;
  end;
end;

class procedure TZxIDEMessages.ShowMessage(const AMessage: String);
begin
  var
  LGroupMsg := GroupMessage;
  (BorlandIDEServices As IOTAMessageServices).AddTitleMessage(AMessage, LGroupMsg);
  (BorlandIDEServices As IOTAMessageServices).ShowMessageView(LGroupMsg);
end;

class procedure TZxIDEMessages.ShowMessage(const AFormat: string; const AArgs: array of const);
begin
  ShowMessage(Format(AFormat, AArgs));
end;

end.
