unit TulipMethodSeparators.main;

interface

uses
  System.SysUtils, System.Classes, System.Types, Vcl.Graphics, Winapi.Windows,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Dialogs, Vcl.Menus,
  System.Generics.Collections, Vcl.GraphUtil, System.Math, System.StrUtils,
  System.Win.Registry, ToolsAPI, ToolsAPI.Editor;

type
  TTulipSettings = record
    UseCustomColor: Boolean;
    CustomColor: TColor;
    PenStyle: TPenStyle;
    SeparateInImplementationOnly: Boolean;
    class function DefaultSettings: TTulipSettings; static;
    procedure Load;
    procedure Save;
  end;

  TTulipMethodSeparators = class(TNotifierObject, INTACodeEditorEvents)
  private
    FDrawLineThisRow: Boolean;
    FImplementationLine: TDictionary<TWinControl, Integer>;
    function GetImplementationLine(AControl: TWinControl): Integer;
    function GetSeparatorColor(ABackColor: TColor): TColor;
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
procedure ShowSettingsDialog;

var
  GSettings: TTulipSettings;
  EventNotifierIndex: Integer = -1;
  SettingsMenuItem: TMenuItem = nil;

implementation

const
  cRegKey = 'Software\TulipMethodSeparators';

type
  TSettingsMenuHandler = class
  public
    procedure DoOpenSettings(Sender: TObject);
  end;

  TSettingsDialogHelper = class
  private
    FSelectedColor: TColor;
    FColorPanel: TPanel;
    FBtnChooseColor: TButton;
    FChkCustomColor: TCheckBox;
    procedure OnColorClick(Sender: TObject);
    procedure OnCustomCheckClick(Sender: TObject);
  public
    property SelectedColor: TColor read FSelectedColor write FSelectedColor;
  end;

var
  SettingsMenuHandler: TSettingsMenuHandler = nil;

procedure TSettingsMenuHandler.DoOpenSettings(Sender: TObject);
begin
  ShowSettingsDialog;
end;

procedure TSettingsDialogHelper.OnColorClick(Sender: TObject);
var
  Dlg: TColorDialog;
begin
  Dlg := TColorDialog.Create(nil);
  try
    Dlg.Color := FSelectedColor;
    if Dlg.Execute then
    begin
      FSelectedColor := Dlg.Color;
      if FColorPanel <> nil then
        FColorPanel.Color := FSelectedColor;
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TSettingsDialogHelper.OnCustomCheckClick(Sender: TObject);
begin
  if FBtnChooseColor <> nil then
    FBtnChooseColor.Enabled := (FChkCustomColor <> nil) and FChkCustomColor.Checked;
end;

{ TTulipSettings }

class function TTulipSettings.DefaultSettings: TTulipSettings;
begin
  Result.UseCustomColor := False;
  Result.CustomColor := $00E0A030; // Pleasant teal/cyan accent
  Result.PenStyle := psDot;
  Result.SeparateInImplementationOnly := True;
end;

procedure TTulipSettings.Load;
var
  Reg: TRegistry;
begin
  Self := DefaultSettings;
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(cRegKey) then
    begin
      if Reg.ValueExists('UseCustomColor') then
        UseCustomColor := Reg.ReadBool('UseCustomColor');
      if Reg.ValueExists('CustomColor') then
        CustomColor := TColor(Reg.ReadInteger('CustomColor'));
      if Reg.ValueExists('PenStyle') then
        PenStyle := TPenStyle(Reg.ReadInteger('PenStyle'));
      if Reg.ValueExists('SeparateInImplementationOnly') then
        SeparateInImplementationOnly := Reg.ReadBool('SeparateInImplementationOnly');
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TTulipSettings.Save;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey(cRegKey, True) then
    begin
      Reg.WriteBool('UseCustomColor', UseCustomColor);
      Reg.WriteInteger('CustomColor', Integer(CustomColor));
      Reg.WriteInteger('PenStyle', Ord(PenStyle));
      Reg.WriteBool('SeparateInImplementationOnly', SeparateInImplementationOnly);
      Reg.CloseKey;
    end;
  finally
    Reg.Free;
  end;
end;

{ Helper to locate the implementation keyword line directly from buffer }

function FindImplementationLineFromBuffer(const ABuffer: IOTAEditBuffer): Integer;
var
  Reader: IOTAEditReader;
  Buf: AnsiString;
  ReadBytes, PosImp, I, Lines: Integer;
begin
  Result := 0;
  if ABuffer = nil then Exit;
  Reader := ABuffer.CreateReader;
  if Reader = nil then Exit;

  SetLength(Buf, 65536);
  ReadBytes := Reader.GetText(0, PAnsiChar(Buf), Length(Buf));
  if ReadBytes <= 0 then Exit;
  SetLength(Buf, ReadBytes);

  PosImp := Pos('implementation', LowerCase(string(Buf)));
  if PosImp > 0 then
  begin
    Lines := 1;
    for I := 1 to PosImp do
    begin
      if Buf[I] = #10 then
        Inc(Lines);
    end;
    Result := Lines;
  end;
end;

{ TTulipMethodSeparators }

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
var
  EditorServices: INTACodeEditorServices;
  EditView: IOTAEditView;
  ImpLine: Integer;
begin
  if not FImplementationLine.ContainsKey(Editor) then
  begin
    if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
    begin
      EditView := EditorServices.GetViewForEditor(Editor);
      if (EditView <> nil) and (EditView.Buffer <> nil) then
      begin
        ImpLine := FindImplementationLineFromBuffer(EditView.Buffer);
        if ImpLine > 0 then
          FImplementationLine.AddOrSetValue(Editor, ImpLine);
      end;
    end;
  end;
end;

function TTulipMethodSeparators.GetSeparatorColor(ABackColor: TColor): TColor;
var
  H, S, L: Word;
  bH, bL, bS: Word;
  TargetL: Integer;
begin
  ColorRGBToHLS(ColorToRGB(ABackColor), bH, bL, bS);

  if GSettings.UseCustomColor and (GSettings.CustomColor <> clNone) then
  begin
    // Convert custom color to HLS
    ColorRGBToHLS(ColorToRGB(GSettings.CustomColor), H, L, S);

    // Guarantee clear contrast against IDE editor background
    if bL < 120 then
    begin
      // Dark Theme: ensure separator is noticeably brighter than background
      if L < bL + 35 then
        TargetL := Min(240, bL + 45)
      else
        TargetL := L;
    end
    else
    begin
      // Light Theme: ensure separator is noticeably darker than background
      if L > bL - 35 then
        TargetL := Max(0, bL - 45)
      else
        TargetL := L;
    end;

    Result := TColor(ColorHLSToRGB(H, TargetL, S));
  end
  else
  begin
    // Neutral theme-aware separator
    if bL < 120 then
      TargetL := Min(240, bL + 40) // Dark theme: subtly lighter than background
    else
      TargetL := Max(0, bL - 45);  // Light theme: subtly darker than background

    Result := TColor(ColorHLSToRGB(bH, TargetL, 0));
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

function TTulipMethodSeparators.GetImplementationLine(AControl: TWinControl): Integer;
begin
  if (AControl = nil) or (not FImplementationLine.TryGetValue(AControl, Result)) then
    Result := 0;
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
  EditorServices: INTACodeEditorServices;
begin
  if Stage = plsBeginPaint then
  begin
    FDrawLineThisRow := False;
  end
  else if (Stage = plsEndPaint) and FDrawLineThisRow then
  begin
    Canvas := Context.Canvas;
    BgColor := Canvas.Brush.Color;
    try
      if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
      begin
        LineColor := GetSeparatorColor(EditorServices.Options.BackgroundColor[atWhiteSpace]);
        Canvas.Brush.Color := EditorServices.Options.BackgroundColor[atWhiteSpace];
        Canvas.Pen.Width := 1;
        Canvas.Pen.Color := LineColor;
        Canvas.Pen.Style := GSettings.PenStyle;

        Canvas.MoveTo(Rect.Left, Rect.Top);
        Canvas.LineTo(Rect.Right, Rect.Top);
      end;
    finally
      Canvas.Brush.Color := BgColor;
      FDrawLineThisRow := False;
    end;
  end;
end;

procedure TTulipMethodSeparators.PaintText(const Rect: TRect; const ColNum: SmallInt; const Text: string;
  const SyntaxCode: TOTASyntaxCode; const Hilight, BeforeEvent: Boolean; var AllowDefaultPainting: Boolean;
  const Context: INTACodeEditorPaintContext);
var
  ImpLine: Integer;
begin
  if (SyntaxCode = atReservedWord) and SameText(Text, 'implementation') then
  begin
    FImplementationLine.AddOrSetValue(Context.EditControl, Context.LogicalLineNum);
  end;

  ImpLine := GetImplementationLine(Context.EditControl);

  if (SyntaxCode = atReservedWord) and MatchText(Text, ['class', 'record']) then
  begin
    if (not GSettings.SeparateInImplementationOnly) or (Context.EditorLineNum > ImpLine) then
      FDrawLineThisRow := True;
  end;

  if (SyntaxCode = atReservedWord) and
    MatchText(Text, ['procedure', 'function', 'initialization', 'finalization', 'constructor', 'destructor']) then
  begin
    if (ImpLine = 0) or (Context.EditorLineNum > ImpLine) then
      FDrawLineThisRow := True;
  end;
end;

function TTulipMethodSeparators.UIOptions: TCodeEditorUIOptions;
begin
  Result := [];
end;

procedure ShowSettingsDialog;
var
  Form: TForm;
  Helper: TSettingsDialogHelper;
  ChkCustomColor: TCheckBox;
  ColorPanel: TPanel;
  BtnChooseColor: TButton;
  CmbStyle: TComboBox;
  LblStyle: TLabel;
  ChkImpOnly: TCheckBox;
  BtnOk, BtnCancel: TButton;
  EditorServices: IOTAEditorServices;
begin
  Form := TForm.CreateNew(nil);
  Helper := TSettingsDialogHelper.Create;
  try
    Helper.SelectedColor := GSettings.CustomColor;

    Form.Caption := 'Tulip Method Separators Settings';
    Form.BorderStyle := bsDialog;
    Form.Position := poScreenCenter;
    Form.ClientWidth := 380;
    Form.ClientHeight := 230;
    Form.Font.Name := 'Segoe UI';
    Form.Font.Size := 9;

    ChkCustomColor := TCheckBox.Create(Form);
    ChkCustomColor.Parent := Form;
    ChkCustomColor.SetBounds(24, 18, 220, 24);
    ChkCustomColor.Caption := 'Use custom line color';
    ChkCustomColor.Checked := GSettings.UseCustomColor;
    ChkCustomColor.OnClick := Helper.OnCustomCheckClick;
    Helper.FChkCustomColor := ChkCustomColor;

    ColorPanel := TPanel.Create(Form);
    ColorPanel.Parent := Form;
    ColorPanel.SetBounds(44, 48, 60, 26);
    ColorPanel.Color := Helper.SelectedColor;
    ColorPanel.ParentBackground := False;
    ColorPanel.BevelOuter := bvLowered;
    Helper.FColorPanel := ColorPanel;

    BtnChooseColor := TButton.Create(Form);
    BtnChooseColor.Parent := Form;
    BtnChooseColor.SetBounds(115, 48, 110, 26);
    BtnChooseColor.Caption := 'Choose Color...';
    BtnChooseColor.Enabled := ChkCustomColor.Checked;
    BtnChooseColor.OnClick := Helper.OnColorClick;
    Helper.FBtnChooseColor := BtnChooseColor;

    LblStyle := TLabel.Create(Form);
    LblStyle.Parent := Form;
    LblStyle.SetBounds(24, 90, 80, 20);
    LblStyle.Caption := 'Line Style:';

    CmbStyle := TComboBox.Create(Form);
    CmbStyle.Parent := Form;
    CmbStyle.Style := csDropDownList;
    CmbStyle.SetBounds(115, 87, 130, 24);
    CmbStyle.Items.Add('Dotted');
    CmbStyle.Items.Add('Dashed');
    CmbStyle.Items.Add('Solid');
    case GSettings.PenStyle of
      psDash: CmbStyle.ItemIndex := 1;
      psSolid: CmbStyle.ItemIndex := 2;
      else CmbStyle.ItemIndex := 0;
    end;

    ChkImpOnly := TCheckBox.Create(Form);
    ChkImpOnly.Parent := Form;
    ChkImpOnly.SetBounds(24, 126, 330, 24);
    ChkImpOnly.Caption := 'Only separate types in implementation section';
    ChkImpOnly.Checked := GSettings.SeparateInImplementationOnly;

    BtnOk := TButton.Create(Form);
    BtnOk.Parent := Form;
    BtnOk.SetBounds(190, 175, 80, 28);
    BtnOk.Caption := 'OK';
    BtnOk.ModalResult := mrOk;
    BtnOk.Default := True;

    BtnCancel := TButton.Create(Form);
    BtnCancel.Parent := Form;
    BtnCancel.SetBounds(280, 175, 80, 28);
    BtnCancel.Caption := 'Cancel';
    BtnCancel.ModalResult := mrCancel;
    BtnCancel.Cancel := True;

    if Form.ShowModal = mrOk then
    begin
      GSettings.UseCustomColor := ChkCustomColor.Checked;
      GSettings.CustomColor := Helper.SelectedColor;
      case CmbStyle.ItemIndex of
        1: GSettings.PenStyle := psDash;
        2: GSettings.PenStyle := psSolid;
        else GSettings.PenStyle := psDot;
      end;
      GSettings.SeparateInImplementationOnly := ChkImpOnly.Checked;
      GSettings.Save;

      if Supports(BorlandIDEServices, IOTAEditorServices, EditorServices) then
      begin
        if EditorServices.TopView <> nil then
          EditorServices.TopView.Paint;
      end;
    end;
  finally
    Helper.Free;
    Form.Free;
  end;
end;

procedure AddToolsMenuItem;
var
  NTAServices: INTAServices;
  MainMenu: TMainMenu;
  ToolsMenu: TMenuItem;
  I: Integer;
begin
  if SettingsMenuItem <> nil then Exit;
  if Supports(BorlandIDEServices, INTAServices, NTAServices) then
  begin
    MainMenu := NTAServices.MainMenu;
    if MainMenu <> nil then
    begin
      ToolsMenu := nil;
      for I := 0 to MainMenu.Items.Count - 1 do
      begin
        if SameText(MainMenu.Items[I].Name, 'ToolsMenu') or
           ContainsText(MainMenu.Items[I].Caption, 'Tools') or
           ContainsText(MainMenu.Items[I].Caption, '&Tools') then
        begin
          ToolsMenu := MainMenu.Items[I];
          Break;
        end;
      end;

      if ToolsMenu <> nil then
      begin
        if SettingsMenuHandler = nil then
          SettingsMenuHandler := TSettingsMenuHandler.Create;
        SettingsMenuItem := TMenuItem.Create(nil);
        SettingsMenuItem.Caption := 'Tulip Method Separators Settings...';
        SettingsMenuItem.OnClick := SettingsMenuHandler.DoOpenSettings;
        ToolsMenu.Add(SettingsMenuItem);
      end;
    end;
  end;
end;

procedure RemoveToolsMenuItem;
begin
  if SettingsMenuItem <> nil then
  begin
    if SettingsMenuItem.Parent <> nil then
      SettingsMenuItem.Parent.Remove(SettingsMenuItem);
    FreeAndNil(SettingsMenuItem);
  end;
  FreeAndNil(SettingsMenuHandler);
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
  AddToolsMenuItem;
end;

procedure Unregister;
var
  EditorServices: INTACodeEditorServices;
begin
  RemoveToolsMenuItem;
  if EventNotifierIndex <> -1 then
  begin
    if Supports(BorlandIDEServices, INTACodeEditorServices, EditorServices) then
      EditorServices.RemoveEditorEventsNotifier(EventNotifierIndex);
    EventNotifierIndex := -1;
  end;
end;

initialization
  GSettings.Load;

finalization
  Unregister;

end.