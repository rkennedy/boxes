unit LevelDlg;

interface
uses WinTypes, oWindows, oDialogs;

type
	PLevelDlg = ^TLevelDlg;
	TLevelDlg = object(TDialog)
		idx_Level: Integer;
		NumLevels: Integer;
		constructor Init(AParent: PWindowsObject; ALevel, ANumLevels: Integer);
		procedure SetupWindow; virtual;
		procedure OK(var Msg: TMessage); virtual id_First + id_OK;
	end;

implementation
uses WinProcs, Resource;

constructor TLevelDlg.Init;
begin
	inherited Init(AParent, MakeIntResource(idx_LevelDlg));
	idx_Level := ALevel;
	NumLevels := ANumLevels;
end;

procedure TLevelDlg.SetupWindow;
var
	i: Integer;
	Rect: TRect;
	s: string;
begin
	inherited SetupWindow;
	GetWindowRect(hWindow, Rect);
	SetWindowPos(hWindow, 0, (GetSystemMetrics(sm_CXScreen) - Rect.Right + Rect.Left) shr 1,
		(GetSystemMetrics(sm_CYScreen) - Rect.Bottom + Rect.Top) shr 1, 0, 0, swp_NoSize or swp_NoZOrder);
	for i := 100 to 101 do SendDlgItemMsg(i, wm_SetFont, Word(fnt_SansSerif), LongInt(True));
	for i := 1 to NumLevels do begin
		Str(i, s);
		s := Concat(s, #0);
		SendDlgItemMsg(101, cb_AddString, 0, LongInt(@s[1]));
	end;
	SendDlgItemMsg(101, cb_SetCurSel, idx_Level - 1, 0);
	SendDlgItemMsg(101, wm_SetFocus, GetFocus, 0);
end;

procedure TLevelDlg.OK;
begin
	idx_Level := SendDlgItemMsg(101, cb_GetCurSel, 0, 0) + 1;
	inherited OK(Msg);
end;

end.