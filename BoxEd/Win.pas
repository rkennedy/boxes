unit Win;

interface

uses WinTypes, oWindows, Toolbox, Map;

const
	cm_MakeDefault = 101;
	cm_EditClear = 201;
	cm_Options = 202;
	cm_LevelAdd = 301;
	cm_LevelDelete = 302;
	cm_LevelCheck = 303;
	cm_LevelGoto = 304;
	cm_BoxGoal = 401;
	cm_Box = 402;
	cm_Clear = 403;
	cm_PlayerGoal = 404;
	cm_Player = 405;
	cm_Goal = 406;
	cm_Void = 407;
	cm_HelpContents = 901;
	cm_HelpSearch = 902;
	cm_HelpOnHelp = 903;
	cm_HelpAbout = 904;

type
	PMyWin = ^TMyWin;
	TMyWin = object(TWindow)
		AllRect, PlayingRect, TextRect: TRect;
		fMap: TMap;
		fToolbox: PToolbox;
		LevelFile: TFilename;
		fTool: Integer;
		constructor Init(AParent: PWindowsObject);
		procedure SetupWindow; virtual;
		procedure Paint(PaintDC: hDC; var PaintInfo: TPaintStruct); virtual;
		procedure CMFileNew(var Msg: TMessage); virtual cm_First + cm_FileNew;
		procedure CMFileOpen(var Msg: TMessage); virtual cm_First + cm_FileOpen;
		procedure CMFileSave(var Msg: TMessage); virtual cm_First + cm_FileSave;
		procedure CMFileSaveAs(var Msg: TMessage); virtual cm_First + cm_FileSaveAs;
    procedure CMMakeDefault(Var Msg: TMessage); virtual cm_First + cm_MakeDefault;
		procedure CMEditUndo(var Msg: TMessage); virtual cm_First + cm_EditUndo;
		procedure CMEditClear(var Msg: TMessage); virtual cm_First + cm_EditClear;
		procedure CMOptions(var Msg: TMessage); virtual cm_First + cm_Options;
		procedure CMLevelAdd(var Msg: TMessage); virtual cm_First + cm_LevelAdd;
		procedure CMLevelDelete(var Msg: TMessage); virtual cm_First + cm_LevelDelete;
		procedure CMLevelCheck(var Msg: TMessage); virtual cm_First + cm_LevelCheck;
		procedure CMLevelGoto(var Msg: TMessage); virtual cm_First + cm_LevelGoto;
		procedure CMBoxGoal(var Msg: TMessage); virtual cm_First + cm_BoxGoal;
		procedure CMBox(var Msg: TMessage); virtual cm_First + cm_Box;
		procedure CMClear(var Msg: TMessage); virtual cm_First + cm_Clear;
		procedure CMPlayerGoal(var Msg: TMessage); virtual cm_First + cm_PlayerGoal;
		procedure CMPlayer(var Msg: TMessage); virtual cm_First + cm_Player;
		procedure CMGoal(var Msg: TMessage); virtual cm_First + cm_Goal;
		procedure CMVoid(var Msg: TMessage); virtual cm_First + cm_Void;
		procedure CMHelpContents(var Msg: TMessage); virtual cm_First + cm_HelpContents;
		procedure CMHelpSearch(var Msg: TMessage); virtual cm_First + cm_HelpSearch;
		procedure CMHelpOnHelp(var Msg: TMessage); virtual cm_First + cm_HelpOnHelp;
		procedure CMHelpAbout(var Msg: TMessage); virtual cm_First + cm_HelpAbout;
		procedure WMEraseBkgnd(var Msg: TMessage); virtual wm_First + wm_EraseBkgnd;
		procedure WMLButtonDown(var Msg: TMessage); virtual wm_First + wm_LButtonDown;
		procedure WMMouseMove(var Msg: TMessage); virtual wm_First + wm_MouseMove;
		function GetTool: Integer; virtual;
		procedure SetTool(T: Integer); virtual;
		function GetClassName: PChar; virtual;
		procedure GetWindowClass(var AWndClass: TWndClass); virtual;
		function CanClose: Boolean; virtual;
		destructor Done; virtual;
	end;

implementation
uses WinProcs, WinDOS, Win31, CommDlg, strings, Resource, About, OptDlg, BoxProc, RectUnit, LevelDlg, CheckDlg;

const
	ini_Filename = 'boxes.ini';
	ini_AppName = 'Boxed';
	hlp_Filename = 'BOXES.HLP';

constructor TMyWin.Init;
begin
	inherited Init(AParent, 'BoxEd');
	ResourceInit;
	ProcInit;

	SetRect(PlayingRect, 32, 32, 287, 287);
	SetRect(TextRect, 32, 6, 288, 26);
	UnionRect(AllRect, PlayingRect, TextRect);

	GetPrivateProfileString('General', 'Levels', 'levels.box', LevelFile, 128, ini_Filename);
	idx_Background := GetPrivateProfileInt(ini_AppName, 'Background', idx_Bricks, ini_Filename);
	hbr_Background := CreatePatternBrush(bmp_Background[idx_Background]);
	fMap.Init(LevelFile);
	fTool := GetPrivateProfileInt(ini_AppName, 'Tool', idx_BoxGoal, ini_Filename);
	with Attr do begin
		with PlayingRect do begin
			w := 1 + Left + Right + GetSystemMetrics(sm_CXBorder) shl 1;
			h := 2 + Top + Bottom + GetSystemMetrics(sm_CYBorder) + GetSystemMetrics(sm_CYMenu) + GetSystemMetrics(sm_CYCaption);
		end;
		x := (GetSystemMetrics(sm_CXScreen) - w) shr 1;
		y := (GetSystemMetrics(sm_CYScreen) - h) shr 1;
		Style := Style xor ws_MaximizeBox xor ws_SizeBox;
	end;

	fToolbox := (new(PToolbox, Init(@Self)));
end;

procedure TMyWin.SetupWindow;
var
	s: string;
begin
	inherited SetupWindow;
  s := Concat('BoxEd - [', StrPas(StrLower(fMap.Filename)), ']', #0);
  SetWindowText(hWindow, @s[1]);
end;

procedure TMyWin.Paint;
begin
	Paint3DRect(PaintDC, PlayingRect, True);
	fMap.Paint(PaintDC, PaintInfo, 32, 32);
end;

procedure TMyWin.CMFileNew;
var
	s: string;
begin
	StrCopy(fMap.Filename, '');
  s := Concat('BoxEd - [Untitled]', #0);
  SetWindowText(hWindow, @s[1]);
	FillChar(fMap.Levels, MaxFileSize, chr_Void);
	fMap.SetLevel(1);
	InvalidateRect(hWindow, nil, True);
end;

procedure TMyWin.CMFileOpen;
var
	OpenFilename: TOpenFilename;
  s: string;
begin
	with OpenFilename do begin
		lStructSize := SizeOf(TOpenFilename);
		hWndOwner := hWindow;
		lpstrFilter := 'Boxes maps (*.box)'#0'*.box'#0'All files (*.*)'#0'*.*'#0#0;
		lpstrCustomFilter := '';
		nMaxCustFilter := 40;
		nFilterIndex := 1;
		lpstrFile := '';
		nMaxFile := 128;
		lpstrInitialDir := '';
		lpstrFileTitle := '';
		nMaxFileTitle := 128;
		lpstrTitle := nil;
		Flags := ofn_FileMustExist or ofn_HideReadOnly or ofn_NoReadOnlyReturn or ofn_PathMustExist or ofn_ShowHelp;
		lpstrDefExt := 'box';
	end;
	if GetOpenFilename(OpenFilename) then begin
		FileExpand{StrCopy}(fMap.Filename, OpenFilename.lpstrFile);
		fMap.Done;
		fMap.Init(fMap.Filename);
	  s := Concat('BoxEd - [', StrPas(StrLower(fMap.Filename)), ']', #0);
	  SetWindowText(hWindow, @s[1]);
		InvalidateRect(hWindow, nil, True);
	end;
end;

procedure TMyWin.CMFileSave;
begin
	if StrComp(fMap.FileName, '') = 0 then CMFileSaveAs(Msg) else fMap.Save;
end;

procedure TMyWin.CMFileSaveAs;
var
	SaveFilename: TOpenFilename;
  s: string;
begin
	with SaveFilename do begin
		lStructSize := SizeOf(TOpenFilename);
		hWndOwner := hWindow;
		lpstrFilter := 'Boxes maps (*.box)'#0'*.box'#0'All files (*.*)'#0'*.*'#0#0;
		lpstrCustomFilter := '';
		nMaxCustFilter := 40;
		nFilterIndex := 1;
		lpstrFile := '';
		nMaxFile := 128;
		lpstrInitialDir := '';
		nMaxFileTitle := 128;
		lpstrTitle := nil;
		Flags := ofn_OverwritePrompt or ofn_HideReadOnly or ofn_NoReadOnlyReturn or ofn_PathMustExist or ofn_ShowHelp;
		lpstrDefExt := 'box';
	end;
	if GetSaveFileName(SaveFilename) then begin
		FileExpand{StrCopy}(fMap.Filename, SaveFilename.lpstrFile);
		{fMap.UpdateLevels;}
		fMap.Save;
	  s := Concat('BoxEd - [', StrPas(fMap.Filename), ']', #0);
	  SetWindowText(hWindow, @s[1]);
    if MessageBox(hWindow, 'Do you want to make this the default file?',
			'BoxEd', mb_YesNo or mb_IconQuestion) = idYes then CMMakeDefault(Msg);
	end;
end;

procedure TMyWin.CMMakeDefault;
begin
	WritePrivateProfileString('General', 'Levels', StrLower(fMap.Filename), ini_Filename);
end;

procedure TMyWin.CMEditUndo;
begin
	if fMap.Undo then InvalidateRect(hWindow, @AllRect, True);
end;

procedure TMyWin.CMEditClear;
begin
	fMap.Clear;
	InvalidateRect(hWindow, @AllRect, True);
end;

procedure TMyWin.CMOptions;
var
	dlg: POptDlg;
begin
	dlg := new(POptDlg, Init(@Self));
	dlg^.idx_Background := idx_Background;
	if Application^.ExecDialog(dlg) = idOK then begin
		idx_Background := dlg^.idx_Background;
		DeleteObject(hbr_Background);
		hbr_Background := CreatePatternBrush(bmp_Background[idx_Background]);
		InvalidateRect(hWindow, nil, True);
		InvalidateRect(fToolbox^.hWindow, nil, True);
	end;
end;

procedure TMyWin.CMLevelAdd;
begin
	fMap.AddLevel;
	fMap.SetLevel(fMap.NumLevels);
	InvalidateRect(hWindow, nil, True);
end;

procedure TMyWin.CMLevelDelete;
var
	s: string;
begin
	Str(fMap.Level, s);
	s := Concat('Delete level ', s, '?'#0);
	if MessageBox(hWindow, @s[1], 'BoxEd', mb_YesNo or mb_IconQuestion) = idYes then begin
		fMap.DeleteLevel(fMap.Level);
		InvalidateRect(hWindow, nil, True);
	end;
end;

procedure TMyWin.CMLevelCheck;
var
	s: string;
	Result: Boolean;
begin
	Result := True;
	s := '';
	with fMap do begin
		if NumChars(chr_Box) + NumChars(chr_BoxGoal) = 0 then begin
			s := Concat(s, #13#10, 'No boxes');
			Result := False;
		end;
		if NumChars(chr_Goal) + NumChars(chr_BoxGoal) + NumChars(chr_PlayerGoal) = 0 then begin
			s := Concat(s, #10#13, 'No goals');
			Result := False;
		end;
		if NumChars(chr_Box) <> NumChars(chr_Goal) + NumChars(chr_PlayerGoal) then begin
			s := Concat(s, #10#13, 'Number of boxes does not match number of goals');
			Result := False;
		end;
		if NumChars(chr_Player) + NumChars(chr_PlayerGoal) > 1 then begin
			s := Concat(s, #13#10, 'Too many players');
			Result := False;
		end;
		if NumChars(chr_Player) + NumChars(chr_PlayerGoal) = 0 then begin
			s := Concat(s, #10#13, 'No player');
			Result := False;
		end;
	end;
	if Result then s := Concat(s, #10#13, 'Everything OK');
	s := Concat(s, #0);
	Application^.ExecDialog(new(PCheckDlg, Init(@Self, @s[1], Result)));
end;

procedure TMyWin.CMLevelGoto;
var
	dlg: PLevelDlg;
begin
	dlg := new(PLevelDlg, Init(@Self, fMap.Level, fMap.NumLevels));
	if Application^.ExecDialog(dlg) = idOK then begin
		fMap.UpdateLevels;
		fMap.SetLevel(dlg^.idx_Level);
		InvalidateRect(hWindow, nil, True);
	end;
end;

procedure TMyWin.CMBoxGoal(var Msg: TMessage);
begin
	SetTool(idx_BoxGoal);
end;

procedure TMyWin.CMBox(var Msg: TMessage);
begin
	SetTool(idx_Box);
end;

procedure TMyWin.CMClear(var Msg: TMessage);
begin
	SetTool(idx_Clear);
end;

procedure TMyWin.CMPlayerGoal(var Msg: TMessage);
begin
	SetTool(idx_PlayerGoal);
end;

procedure TMyWin.CMPlayer(var Msg: TMessage);
begin
	SetTool(idx_Player);
end;

procedure TMyWin.CMGoal(var Msg: TMessage);
begin
	SetTool(idx_Goal);
end;

procedure TMyWin.CMVoid(var Msg: TMessage);
begin
	SetTool(idx_Void);
end;

procedure TMyWin.CMHelpContents;
begin
	WinHelp(hWindow, hlp_Filename, Help_Contents, 0);
end;

procedure TMyWin.CMHelpSearch;
begin
	WinHelp(hWindow, hlp_Filename, Help_PartialKey, LongInt(PChar('')));
end;

procedure TMyWin.CMHelpOnHelp;
begin
	WinHelp(hWindow, hlp_Filename, Help_HelpOnHelp, 0);
end;

procedure TMyWin.CMHelpAbout;
begin
	Application^.ExecDialog(new(PAboutDlg, Init(@Self, MakeIntResource(idx_About))));
end;

procedure TMyWin.WMEraseBkgnd;
var
	Rect: TRect;
begin
	GetClientRect(hWindow, Rect);
	UnrealizeObject(hbr_Background);
	FillRect(hDC(Msg.wParam), Rect, hbr_Background);
	Msg.Result := 1;
end;

procedure TMyWin.WMLButtonDown;
var
	i: Byte;
begin
	for i := 0 to 255 do if PtInRect(Rects[GetYValue(i), GetXValue(i)], TPoint(Msg.lParam)) then begin
		if fMap.SetChar(i, chr_Chars[fTool]) then InvalidateRect(hWindow, @Rects[GetYValue(i), GetXValue(i)], fTool = idx_Void);
		Exit;
	end;
end;

procedure TMyWin.WMMouseMove;
begin
	if PtInRect(PlayingRect, TPoint(Msg.lParam)) then begin
		SetCursor(cur_Tool[fTool]);
	end else begin
		SetCursor(LoadCursor(0, idc_Arrow));
	end;
end;

function TMyWin.GetTool;
begin
	GetTool := fTool;
end;

procedure TMyWin.SetTool;
begin
	if (idx_BoxGoal <= T) and (T <= idx_Void) then fTool := T;
end;

function TMyWin.GetClassName;
begin
	GetClassName := 'TurboBoxEdWindow';
end;

procedure TMyWin.GetWindowClass;
begin
	inherited GetWindowClass(AWndClass);
	with AWndClass do begin
		Style := Style or cs_ByteAlignClient or cs_ByteAlignWindow;
		lpszMenuName := MakeIntResource(idx_MainMenu);
		hIcon := ico_Main;
		hbrBackground := hBrush(nil);
		hCursor := 0;
	end;
end;

function TMyWin.CanClose;
begin
	CanClose := True;
end;

destructor TMyWin.Done;
var
	s: string;
begin
	WinHelp(hWindow, hlp_Filename, Help_Quit, 0);
	Str(fTool, s);
	s := Concat(s, #0);
	WritePrivateProfileString(ini_AppName, 'Tool', @s[1], ini_Filename);
	Str(idx_Background, s);
	s := Concat(s, #0);
	WritePrivateProfileString(ini_AppName, 'Background', @s[1], ini_Filename);
	DeleteObject(hbr_Background);
	fMap.Done;

	ProcDone;
	ResourceDone;
	inherited Done;
end;

end.