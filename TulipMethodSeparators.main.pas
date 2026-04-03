unit TulipMethodSeparators.main;

interface

uses
  System.SysUtils, System.Classes, System.Types, Vcl.Graphics, Winapi.Windows, vcl.controls,
  System.Generics.Collections, VCL.GraphUtil, System.Math,
  System.StrUtils, ToolsAPI, ToolsAPI.Editor;

type
  THarmonyType = (htComplementary, htAnalogous, htTriadic);

  TTulipMethodSeparators = class(TNotifierObject, INTACodeEditorEvents)
  private
    FDrawLineThisRow: boolean;
    FImplementationLine: TDictionary<TWinControl, Integer>;
    function GetImplementationLine(AControl: TWinControl): Integer;
    function GetSlightlyDifferentColor(AColor: TColor; Percentage: Integer = 30): TColor;
    function GetHarmoniousColor(AColor: TColor; Harmony: THarmonyType = htComplementary): TColor;
    function GetSmartAdjustedColor(AColor: TColor; LightenPercent, DarkenPercent: Byte): TColor;
  public
    function AllowedEvents: TCodeEditorEvents;
    procedure PaintText(const Rect: TRect; const ColNum: SmallInt;
      const Text: string; const SyntaxCode: TOTASyntaxCode;
      const Hilight, BeforeEvent: Boolean; var AllowDefaultPainting: Boolean;
      const Context: INTACodeEditorPaintContext);
    procedure PaintLine(const Rect: TRect; const Stage: TPaintLineStage;
      const BeforeEvent: Boolean; var AllowDefaultPainting: Boolean;
      const Context: INTACodeEditorPaintContext);
    procedure EditorScrolled(const Editor: TWinControl; const Direction: TCodeEditorScrollDirection);
    procedure EditorResized(const Editor: TWinControl);
    procedure EditorElided(const Editor: TWinControl; const LogicalLineNum: Integer);
    procedure EditorUnElided(const Editor: TWinControl; const LogicalLineNum: Integer);
    procedure EditorMouseDown(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure EditorMouseMove(const Editor: TWinControl; Shift: TShiftState; X, Y: Integer);
    procedure EditorMouseUp(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BeginPaint(const Editor: TWinControl; const ForceFullRepaint: Boolean);
    procedure EndPaint(const Editor: TWinControl);
    function AllowedGutterStages: TPaintGutterStages;
    function AllowedLineStages: TPaintLineStages;
    function UIOptions: TCodeEditorUIOptions;
    procedure PaintGutter(const Rect: TRect; const Stage: TPaintGutterStage; const BeforeEvent: Boolean;
      var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
    procedure AfterConstruction; override;
    destructor Destroy; override;
  end;

procedure Register;
procedure Unregister;

var
  EventNotifierIndex: Integer = -1;

implementation

procedure TTulipMethodSeparators.AfterConstruction;
begin
  inherited;
  FImplementationLine := TDictionary<TWinControl, Integer>.Create;
end;

function TTulipMethodSeparators.AllowedEvents: TCodeEditorEvents;
begin
  Result := [cevPaintTextEvents, cevPaintLineEvents];
end;

function TTulipMethodSeparators.AllowedGutterStages: TPaintGutterStages;
begin
  Result := [];
end;

function TTulipMethodSeparators.AllowedLineStages: TPaintLineStages;
begin
  Result := [plsBeginPaint, plsEndPaint];
end;

procedure TTulipMethodSeparators.BeginPaint(const Editor: TWinControl; const ForceFullRepaint: Boolean);
begin
  if not FImplementationLine.ContainsKey(Editor) then
  begin
    var EditorServices: INTACodeEditorServices;
    if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
    begin
      var EditBuffer := EditorServices.GetViewForEditor(Editor).Buffer;
      for var I := 1 to EditBuffer.GetLinesInBuffer do
      begin
        var LText: string := EditBuffer.GetSubViewIdentifier(I);
        if ContainsText(LText, 'implementation') then
        begin
          FImplementationLine.AddOrSetValue(Editor, I);
          Break;
        end;
      end;
    end;
  end;
end;

destructor TTulipMethodSeparators.Destroy;
begin
  FImplementationLine.Free;
  inherited;
end;

procedure TTulipMethodSeparators.EditorElided(const Editor: TWinControl; const LogicalLineNum: Integer);
begin
end;

procedure TTulipMethodSeparators.EditorMouseDown(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TTulipMethodSeparators.EditorMouseMove(const Editor: TWinControl; Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TTulipMethodSeparators.EditorMouseUp(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
end;

procedure TTulipMethodSeparators.EditorResized(const Editor: TWinControl);
begin
end;

procedure TTulipMethodSeparators.EditorScrolled(const Editor: TWinControl; const Direction: TCodeEditorScrollDirection);
begin
end;

procedure TTulipMethodSeparators.EditorUnElided(const Editor: TWinControl; const LogicalLineNum: Integer);
begin
end;

procedure TTulipMethodSeparators.EndPaint(const Editor: TWinControl);
begin
end;

function TTulipMethodSeparators.GetHarmoniousColor(AColor: TColor; Harmony: THarmonyType): TColor;
var
  RGBColor: COLORREF;
  R, G, B: Byte;
  Luminance: Double;
begin
  RGBColor := ColorToRGB(AColor);
  R := GetRValue(RGBColor);
  G := GetGValue(RGBColor);
  B := GetBValue(RGBColor);
  Luminance := (0.299 * R) + (0.587 * G) + (0.114 * B);

  if Luminance > 128 then
    Result := clBlack
  else
    Result := clWhite;
end;

function TTulipMethodSeparators.GetImplementationLine(AControl: TWinControl): Integer;
begin
  if (AControl = nil) or (not FImplementationLine.TryGetValue(AControl, Result)) then
    Result := 0;
end;

function TTulipMethodSeparators.GetSlightlyDifferentColor(AColor: TColor; Percentage: Integer): TColor;
var
  LServices: INTACodeEditorServices;
  LR, LG, LB: Byte;
begin
  Result := clGray;
  if Supports(BorlandIDEServices, INTACodeEditorServices, LServices) then
  begin
    LR := (GetRValue(AColor) + 128) div 2;
    LG := (GetGValue(AColor) + 128) div 2;
    LB := (GetBValue(AColor) + 128) div 2;
    Result := TColor(RGB(LR, LG, LB));
  end;
end;

function TTulipMethodSeparators.GetSmartAdjustedColor(AColor: TColor; LightenPercent, DarkenPercent: Byte): TColor;
var
  H, L, S: Word;
  Adjustment: Integer;
begin
  LightenPercent := Min(100, Max(0, LightenPercent));
  DarkenPercent := Min(100, Max(0, DarkenPercent));

  AColor := ColorToRGB(AColor);
  ColorRGBToHLS(AColor, H, L, S);

  if L > 120 then
  begin
    Adjustment := Round(L * (DarkenPercent / 100.0));
    L := Max(0, L - Adjustment);
  end
  else
  begin
    Adjustment := Round((240 - L) * (LightenPercent / 100.0));
    L := Min(240, L + Adjustment);
  end;

  Result := ColorHLSToRGB(H, L, S);
end;

procedure TTulipMethodSeparators.PaintGutter(const Rect: TRect; const Stage: TPaintGutterStage;
  const BeforeEvent: Boolean; var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
begin
end;

procedure TTulipMethodSeparators.PaintLine(const Rect: TRect; const Stage: TPaintLineStage; const BeforeEvent: Boolean;
  var AllowDefaultPainting: Boolean; const Context: INTACodeEditorPaintContext);
var
  Canvas: TCanvas;
  BgColor: TColor;
  LineColor: TColor;
begin
  if FDrawLineThisRow then
  begin
    if Stage = plsEndPaint then
    begin
      Canvas := Context.Canvas;
      BgColor := Canvas.Brush.Color;
      try
        var EditorServices: INTACodeEditorServices;
        if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
        begin
          LineColor := EditorServices.Options.BackgroundColor[atWhiteSpace];
          LineColor := GetSmartAdjustedColor(LineColor, 40, 30);
          Canvas.Brush.Color := EditorServices.Options.BackgroundColor[atWhiteSpace];
          Canvas.Pen.Width := 1;
          Canvas.Pen.Color := LineColor;
          Canvas.Pen.Style := TPenStyle.psDot;

          Canvas.MoveTo(Rect.Left, Rect.Top);
          Canvas.LineTo(Rect.Right, Rect.Top);
        end;
      finally
        Canvas.Brush.Color := BgColor;
        FDrawLineThisRow := False;
      end;
    end;
  end;
end;

procedure TTulipMethodSeparators.PaintText(const Rect: TRect; const ColNum: SmallInt; const Text: string;
  const SyntaxCode: TOTASyntaxCode; const Hilight, BeforeEvent: Boolean; var AllowDefaultPainting: Boolean;
  const Context: INTACodeEditorPaintContext);
var
  ImpLine: Integer;
begin
  if (SyntaxCode = atReservedWord) and MatchText(Text, ['Implementation']) then
  begin
    FImplementationLine.AddOrSetValue(Context.EditControl, Context.LogicalLineNum);
  end;

  if (SyntaxCode = atReservedWord) and MatchText(Text, ['class', 'Record']) then
  begin
    FDrawLineThisRow := True;
  end;

  if (SyntaxCode = atReservedWord) and
    MatchText(Text, ['procedure', 'function', 'initialization', 'finalization', 'constructor', 'destructor']) then
  begin
    ImpLine := GetImplementationLine(Context.EditControl);
    if (Context.EditorLineNum > ImpLine) then
    begin
      FDrawLineThisRow := True;
    end;
  end;
end;

function TTulipMethodSeparators.UIOptions: TCodeEditorUIOptions;
begin
  Result := [];
end;

procedure Register;
var
  EditorServices: INTACodeEditorServices;
begin
  if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
  begin
    if EventNotifierIndex = -1 then
      EventNotifierIndex := EditorServices.AddEditorEventsNotifier(TTulipMethodSeparators.Create);
  end;
end;

procedure Unregister;
var
  EditorServices: INTACodeEditorServices;
begin
  if EventNotifierIndex <> -1 then
  begin
    if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
      EditorServices.RemoveEditorEventsNotifier(EventNotifierIndex);
    EventNotifierIndex := -1;
  end;
end;

initialization

finalization
  Unregister;


end.