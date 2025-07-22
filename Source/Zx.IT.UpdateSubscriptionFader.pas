unit Zx.IT.UpdateSubscriptionFader;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.Types,
  Vcl.TitleBarCtrls,
  Vcl.Graphics,
  Vcl.Controls,
  Zx.IT.DelayHooker,
  DockForm,
  IDEDockTabSet,
  ToolsAPI;

type
  TZxUpdateSubscriptionFader = class(TZxDelayHooker)
  private const
    CAppBuilder = 'TAppBuilder';

  strict private
    FStoredOnPaint: TTitleBarPaintEvent;
    FTitleBarPanel: TTitleBarPanel;
    FBackgroundColor: TRGBTriple;
    procedure OnCustomPaint(Sender: TObject; Canvas: TCanvas; var ARect: TRect);
  strict protected
    function TryLoad: Boolean; override;
  public
    destructor Destroy; override;

  strict private
    class var FInstance: IInterface;
  public
    class procedure Register; static;
  end;

implementation

uses
  System.SysUtils,
  System.Math,
  System.UITypes,
  Vcl.ActnList,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.ActnMenus,
  Zx.IT.Common;

type
  PRGBArray = ^TRGBArray;
  TRGBArray = array [0 .. 32767] of TRGBTriple;

  { TZxUpdateSubscriptionFader }

procedure TZxUpdateSubscriptionFader.OnCustomPaint(Sender: TObject; Canvas: TCanvas; var ARect: TRect);
var
  Line: PRGBArray;
begin
  if Assigned(FStoredOnPaint) then
    FStoredOnPaint(Sender, Canvas, ARect);
  var
  LBitmap := TBitmap.Create;
  try
    try
      LBitmap.PixelFormat := pf24bit;
      LBitmap.SetSize(ARect.Width, ARect.Height);
      var
      LRect := Rect(0, 0, ARect.Width, ARect.Height);
      LBitmap.Canvas.CopyRect(LRect, Canvas, ARect);
      for var Y := 0 to LBitmap.Height - 1 do
      begin
        Line := LBitmap.ScanLine[Y];
        for var X := 0 to LBitmap.Width - 1 do
          if Line[X].rgbtRed > 200 then
            if (Line[X].rgbtGreen < 150) and (Line[X].rgbtBlue < 150) then
            begin
              Line[X].rgbtBlue := FBackgroundColor.rgbtBlue;
              Line[X].rgbtGreen := FBackgroundColor.rgbtGreen;
              Line[X].rgbtRed := FBackgroundColor.rgbtRed;
            end
        { make the text white }
        // else if InRange(Line[X].rgbtGreen, 180, 250) and InRange(Line[X].rgbtBlue, 180, 250) then
        // begin
        // Line[X].rgbtBlue := 255;
        // Line[X].rgbtGreen := 255;
        // Line[X].rgbtRed := 255;
        // end
      end;
      Canvas.Draw(0, 0, LBitmap);
    except
      on E: Exception do;
    end;
  finally
    LBitmap.Free;
  end;
end;

function TZxUpdateSubscriptionFader.TryLoad: Boolean;
var
  LEditorServices: INTAEditorServices;
begin
  inherited;
  if not Supports(BorlandIDEServices, INTAEditorServices, LEditorServices) then
  begin
    // TZxIDEMessages.ShowMessage(ClassName + ': BorlandIDEServices does not support INTAEditorServices');
    Exit(False);
  end;
  if LEditorServices.TopEditWindow = nil then
  begin
    // TZxIDEMessages.ShowMessage(ClassName + ': EditorServices.TopEditWindow is not assigned');
    Exit(False);
  end;
  var
  LMainForm := LEditorServices.TopEditWindow.Form as TWinControl;
  while Assigned(LMainForm) do
    if LMainForm.ClassName = CAppBuilder then
      Break
    else
      LMainForm := LMainForm.Parent;
  if LMainForm = nil then
  begin
    // TZxIDEMessages.ShowMessage(ClassName + ': failed retrieving IDE main form: ' + CAppBuilder.QuotedString);
    Exit(False);
  end;
  var
  LMatchesNeeded := 2;
  for var LChild in LMainForm do
  begin
    if LChild is TActionMainMenuBar then
    begin
      var
      LColor := TActionMainMenuBar(LChild).Color;
      FBackgroundColor.rgbtRed := GetRValue(LColor);
      FBackgroundColor.rgbtGreen := GetGValue(LColor);
      FBackgroundColor.rgbtBlue := GetBValue(LColor);
      // TZxIDEMessages.ShowMessage(ClassName + ': BackgroundColor: R=%d G=%d B=%d',
      // [FBackgroundColor.rgbtRed, FBackgroundColor.rgbtGreen, FBackgroundColor.rgbtBlue]);
      Dec(LMatchesNeeded);
    end;
    if LChild is TTitleBarPanel then
    begin
      FTitleBarPanel := TTitleBarPanel(LChild);
      Dec(LMatchesNeeded);
    end;
    if LMatchesNeeded = 0 then
      Break;
  end;
  if LMatchesNeeded > 0 then
  begin
    // TZxIDEMessages.ShowMessage(ClassName + ': failed retrieving IDE main form''s TTitleBarPanel and/or TActionMainMenuBar');
    Exit(False);
  end;
  FStoredOnPaint := FTitleBarPanel.OnPaint;
  FTitleBarPanel.OnPaint := OnCustomPaint;
  Result := True;
end;

destructor TZxUpdateSubscriptionFader.Destroy;
begin
  if Assigned(FTitleBarPanel) then
  begin
    FTitleBarPanel.OnPaint := FStoredOnPaint;
    FTitleBarPanel.Repaint;
  end;
  inherited;
end;

class procedure TZxUpdateSubscriptionFader.Register;
begin
  FInstance := TZxUpdateSubscriptionFader.Create;
end;

end.
