unit Win;

interface

uses WinTypes, oWindows, oDialogs, Map, Game;

const
	cm_EditClear = 201;
	cm_Options = 202;
	cm_HelpContents = 901;
	cm_HelpSearch = 902;
	cm_HelpOnHelp = 903;
	cm_HelpAbout = 904;

type
	PMyWin = ^TMyWin;
	TMyWin = object(TWindow)
		AllRect, PlayingRect, TextRect: TRect;
		Completed: Boolean;
		fGame: TGame;
		fMap: TMap;
		GameFilename: TFilename;
		hbr_Background: hBrush;
		idx_Background: Integer;
    bool_Sound: Boolean;
		LevelFile: TFilename;
		NumMoves, TotalMoves: Word;
		constructor Init(AParent: PWindowsObject);
		procedure Paint(PaintDC: hDC; var PaintInfo: TPaintStruct); virtual;
		procedure CheckForComplete; virtual;
		procedure CMFileNew(var Msg: TMessage); virtual cm_First + cm_FileNew;
		procedure CMFileOpen(var Msg: TMessage); virtual cm_First + cm_FileOpen;
		procedure CMFileSave(var Msg: TMessage); virtual cm_First + cm_FileSave;
		procedure CMFileSaveAs(var Msg: TMessage); virtual cm_First + cm_FileSaveAs;
		procedure CMEditUndo(var Msg: TMessage); virtual cm_First + cm_EditUndo;
		procedure CMEditClear(var Msg: TMessage); virtual cm_First + cm_EditClear;
		procedure CMOptions(var Msg: TMessage); virtual cm_First + cm_Options;
		procedure CMHelpContents(var Msg: TMessage); virtual cm_First + cm_HelpContents;
		procedure CMHelpSearch(var Msg: TMessage); virtual cm_First + cm_HelpSearch;
		procedure CMHelpOnHelp(var Msg: TMessage); virtual cm_First + cm_HelpOnHelp;
		procedure CMHelpAbout(var Msg: TMessage); virtual cm_First + cm_HelpAbout;
		procedure WMEraseBkgnd(var Msg: TMessage); virtual wm_First + wm_EraseBkgnd;
		procedure WMKeyDown(var Msg: TMessage); virtual wm_First + wm_KeyDown;
		function GetClassName: PChar; virtual;
		procedure GetWindowClass(var AWndClass: TWndClass); virtual;
		destructor Done; virtual;
	end;

implementation

uses WinProcs, WinDOS, Win31, CommDlg, MMSystem, strings, Resource, About, BoxProc, OptDlg;

constructor TMyWin.Init;
begin
	inherited Init(AParent, ini_AppName);
	ResourceInit;
	ProcInit;

	NumMoves := 0;
	TotalMoves := 0;
	SetRect(PlayingRect, 32, 32, 288, 288);
	SetRect(TextRect, 32, 6, 288, 26);
	UnionRect(AllRect, PlayingRect, TextRect);

	GetPrivateProfileString('General', 'Levels', 'levels.box', LevelFile, 128, ini_Filename);
	idx_Background := GetPrivateProfileInt(ini_AppName, 'Background', idx_Bricks, ini_Filename);
	hbr_Background := CreatePatternBrush(bmp_Background[idx_Background]);
  bool_Sound := Boolean(GetPrivateProfileInt(ini_AppName, 'Sound', Integer(True), ini_Filename));
	Completed := False;
	fMap.Init(LevelFile);
	with Attr do begin
		with PlayingRect do begin
			w := Left + Right + GetSystemMetrics(sm_CXBorder) shl 1;
			h := 1 + Top + Bottom + GetSystemMetrics(sm_CYBorder) + GetSystemMetrics(sm_CYMenu) + GetSystemMetrics(sm_CYCaption);
		end;
		x := (GetSystemMetrics(sm_CXScreen) - w) shr 1;
		y := (GetSystemMetrics(sm_CYScreen) - h) shr 1;
		Style := Style xor ws_MaximizeBox xor ws_SizeBox;
	end;
end;

procedure TMyWin.Paint;
var
	l, m, t: string;
	Old: THandle;
	Brush: hBrush;
begin
	if Completed then m := Concat('Congratulations', #0) else begin
		Str(NumMoves, m);
		m := Concat('Moves:  ', m, #0);
	end;
	Str(fMap.Level, l);
	Str(TotalMoves, t);
	l := Concat('  Level:  ', l, #0);
	t := Concat('Total:  ', t, '  '#0);

	Old := SelectObject(PaintDC, fnt_SansSerif);
	SetBkMode(PaintDC, Transparent);

	Paint3DRect(PaintDC, TextRect);
	Brush := CreateSolidBrush(GetSysColor(color_BtnFace));
	FillRect(PaintDC, TextRect, Brush);
	DeleteObject(Brush);

	DrawText(PaintDC, @l[1], -1, TextRect, dt_Left or dt_NoClip or dt_SingleLine or dt_VCenter);
	DrawText(PaintDC, @m[1], -1, TextRect, dt_Center or dt_NoClip or dt_SingleLine or dt_VCenter);
	DrawText(PaintDC, @t[1], -1, TextRect, dt_Right or dt_NoClip or dt_SingleLine or dt_VCenter);
	fnt_SansSerif := SelectObject(PaintDC, Old);

	if Completed then begin
		Old := SelectObject(PaintDC, fnt_YouWin);
		DrawText(PaintDC, 'You Win!', -1, PlayingRect, dt_Center or dt_VCenter or dt_SingleLine);
		fnt_YouWin := SelectObject(PaintDC, Old);
	end else begin
		fMap.Paint(PaintDC, PaintInfo, 32, 32);
	end;
end;

procedure TMyWin.CheckForComplete;
	procedure Delay(x: LongInt);
	var
		y: LongInt;
		Msg: TMsg;
	begin
		y := GetTickCount;
		repeat
			PeekMessage(Msg, hWindow, wm_MouseFirst, wm_MouseLast, pm_NoRemove);
		until GetTickCount >= x+y;
	end;
var
	DC: hDC;
	s: string;
	Old: THandle;
	Brush: hBrush;
begin
	if fMap.AllGoalsFilled then begin
		UpdateWindow(hWindow);
		DC := GetDC(hWindow);
		FillRect(DC, PlayingRect, hbr_Background);
		SetBkMode(DC, Transparent);

		Old := SelectObject(DC, fnt_YouWin);
		DrawText(DC, 'You Win!', -1, PlayingRect, dt_Center or dt_VCenter or dt_SingleLine);
		Delay(1000);
		fnt_YouWin := SelectObject(DC, Old);

		if fMap.SetLevel(fMap.Level + 1) then begin
			Str(fMap.Level, s);
			s := Concat(s, #0);
			Old := SelectObject(DC, fnt_SansSerif);
			Brush := CreateSolidBrush(GetSysColor(color_BtnFace));
			FillRect(DC, TextRect, Brush);
			DrawText(DC, 'Get ready for next level:', -1, TextRect, dt_Center or dt_VCenter or dt_SingleLine or dt_NoClip);
			fnt_SansSerif := SelectObject(DC, fnt_GetReady);
			FillRect(DC, PlayingRect, hbr_Background);
			DrawText(DC, @s[1], -1, PlayingRect, dt_Center or dt_VCenter or dt_SingleLine or dt_NoClip);
			fnt_GetReady := SelectObject(DC, Old);
			DeleteObject(Brush);
			NumMoves := 0;
			Delay(1500);
			Completed := False;
			InvalidateRect(hWindow, nil, True);
		end else begin
			Completed := True;
			InvalidateRect(hWindow, @TextRect, False);
			if bool_Sound then sndPlaySound(wav_Cheer, snd_Memory or snd_ASync or snd_NoDefault);
		end;
		ReleaseDC(hWindow, DC);
	end;
end;

procedure TMyWin.CMFileNew;
begin
	StrCopy(GameFilename, '');
	Completed := False;
	fMap.SetLevel(1);
	NumMoves := 0;
	TotalMoves := 0;
	InvalidateRect(hWindow, nil, True);
end;

procedure TMyWin.CMFileOpen;
var
	FileHandle: THandle;
	OpenFilename: TOpenFilename;
begin
	with OpenFilename do begin
		lStructSize := SizeOf(TOpenFilename);
		hWndOwner := hWindow;
		lpstrFilter := 'Boxes games (*.bgm)'#0'*.bgm'#0'Boxes maps (*.box)'#0'*.box'#0'All files (*.*)'#0'*.*'#0#0;
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
		lpstrDefExt := 'bgm';
	end;
	if GetOpenFilename(OpenFilename) then begin
		FileExpand(GameFilename, OpenFilename.lpstrFile);
		FileHandle := _lopen(GameFilename, of_Read);
		if FileHandle <> 0 then begin
			_lread(FileHandle, @fGame, SizeOf(TGame));
			_lclose(FileHandle);
		end;
		Completed := False;
		if StrComp(fGame.header, 'boxes.bgm') = 0 then begin
			fMap.Done;
			fMap.Init(fGame.MapName);
			fMap.SetLevel(fGame.Level);
			NumMoves := fGame.NumMoves;
			TotalMoves := fGame.TotalMoves;
			fMap.Field := fGame.PlayingField;
			fMap.UndoField := fGame.PlayingField;
			InvalidateRect(hWindow, nil, True);
		end else begin
			StrCopy(LevelFile, StrLower(GameFilename));
			fMap.Done;
			fMap.Init(LevelFile);
			CMFileNew(Msg);
		end;
	end;
end;

procedure TMyWin.CMFileSave;
var
	FileHandle: THandle;
begin
	if StrComp(GameFilename, '') = 0 then CMFileSaveAs(Msg) else begin
		FileHandle := _lcreat(GameFilename, 0);
		if FileHandle <> 0 then begin
			StrCopy(fGame.header, 'boxes.bgm');
			FileExpand{StrCopy}(fGame.MapName, fMap.Filename);
			fGame.NumMoves := NumMoves;
			fGame.TotalMoves := TotalMoves;
			fGame.Level := fMap.Level;
			fGame.PlayingField := fMap.Field;

			_lwrite(FileHandle, @fGame, SizeOf(TGame));
			_lclose(FileHandle);
		end;
	end;
end;

procedure TMyWin.CMFileSaveAs;
var
	FileHandle: THandle;
	SaveFilename: TOpenFilename;
begin
	with SaveFilename do begin
		lStructSize := SizeOf(TOpenFilename);
		hWndOwner := hWindow;
		lpstrFilter := 'Boxes games (*.bgm)'#0'*.bgm'#0'All files (*.*)'#0'*.*'#0#0;
		lpstrCustomFilter := '';
		nMaxCustFilter := 40;
		nFilterIndex := 1;
		lpstrFile := '';
		nMaxFile := 128;
		lpstrInitialDir := '';
		nMaxFileTitle := 128;
		lpstrTitle := nil;
		Flags := ofn_OverwritePrompt or ofn_HideReadOnly or ofn_NoReadOnlyReturn or ofn_PathMustExist or ofn_ShowHelp;
		lpstrDefExt := 'bgm';
	end;
	if GetSaveFileName(SaveFilename) then begin
		StrCopy(GameFilename, SaveFilename.lpstrFile);
		FileHandle := _lcreat(GameFilename, 0);
		if FileHandle <> 0 then begin
			StrCopy(fGame.header, 'boxes.bgm');
			FileExpand{StrCopy}(fGame.MapName, fMap.Filename);
			fGame.NumMoves := NumMoves;
			fGame.TotalMoves := TotalMoves;
			fGame.Level := fMap.Level;
			fGame.PlayingField := fMap.Field;
			_lwrite(FileHandle, @fGame, SizeOf(TGame));
			_lclose(FileHandle);
		end;
	end;
end;

procedure TMyWin.CMEditUndo;
begin
	if (not Completed) and fMap.Undo then begin
		Dec(NumMoves);
		Dec(TotalMoves);
		InvalidateRect(hWindow, @AllRect, False);
	end;
end;

procedure TMyWin.CMEditClear;
begin
	if not Completed then begin
		fMap.Revert;
		TotalMoves := TotalMoves - NumMoves;
		NumMoves := 0;
		InvalidateRect(hWindow, nil, True);
	end;
end;

procedure TMyWin.CMOptions;
var
	dlg: POptDlg;
begin
	dlg := new(POptDlg, Init(@Self));
	dlg^.idx_Background := idx_Background;
  dlg^.bool_Sound := bool_Sound;
	if Application^.ExecDialog(dlg) = idOK then begin
		idx_Background := dlg^.idx_Background;
    bool_Sound := dlg^.bool_Sound;
		DeleteObject(hbr_Background);
		hbr_Background := CreatePatternBrush(bmp_Background[idx_Background]);
		InvalidateRect(hWindow, nil, True);
	end;
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
	WinHelp(hWindow, '', Help_HelpOnHelp, 0);
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
	FillRect(hDC(Msg.wParam), Rect, hbr_Background);
end;

procedure TMyWin.WMKeyDown;
begin
	case Msg.wParam of
		vk_Left..vk_Down: if (not Completed) and fMap.Move(TDirection(Msg.wParam - vk_Left)) then begin
			Inc(NumMoves);
			Inc(TotalMoves);
			InvalidateRect(hWindow, @AllRect, False);
			if bool_Sound then sndPlaySound(wav_Thp, snd_Memory or snd_ASync or snd_NoDefault);
			CheckForComplete;
		end;
		vk_F4: CMEditClear(Msg);
		else DefWndProc(Msg);
	end;
end;

function TMyWin.GetClassName;
begin
	GetClassName := 'TurboBoxesWindow';
end;

procedure TMyWin.GetWindowClass;
begin
	inherited GetWindowClass(AWndClass);
	with AWndClass do begin
		Style := Style or cs_ByteAlignWindow;
		hbrBackground := hBrush(nil);
		hIcon := 	LoadIcon(hInstance, MakeIntResource(idx_Icon));
		lpszMenuName := MakeIntResource(idx_Menu);
	end;
end;

destructor TMyWin.Done;
var
	s: string;
begin
	WinHelp(hWindow, hlp_Filename, Help_Quit, 0);
  FileExpand(LevelFile, LevelFile);
	WritePrivateProfileString('General', 'Levels', StrLower(LevelFile), ini_Filename);
	Str(idx_Background, s);
	s := Concat(s, #0);
	WritePrivateProfileString(ini_AppName, 'Background', @s[1], ini_Filename);
	DeleteObject(hbr_Background);
  Str(Integer(bool_Sound), s);
  s := Concat(s, #0);
  WritePrivateProfileString(ini_AppName, 'Sound', @s[1], ini_Filename);
	fMap.Done;
	ProcDone;
	ResourceDone;
	inherited Done;
end;

end.