unit CheckDlg;

interface
uses WinTypes, oWindows, oDialogs;

type
	PCheckDlg = ^TCheckDlg;
	TCheckDlg = object(TDialog)
		Text: PChar;
		Good: Boolean;
		constructor Init(AParent: PWindowsObject; AText: PChar; AGood: Boolean);
		procedure SetupWindow; virtual;
		destructor Done; virtual;
	end;

implementation
uses WinProcs, Win31, strings, Resource;

constructor TCheckDlg.Init;
begin
	inherited Init(AParent, MakeIntResource(idx_CheckDlg));
	Text := StrNew(AText);
	Good := AGood;
end;

procedure TCheckDlg.SetupWindow;
var
	i: Byte;
begin
	inherited SetupWindow;
	for i := 101 to 102 do SendDlgItemMsg(i, wm_SetFont, Word(fnt_SansSerif), LongInt(True));
	if Good then SendDlgItemMsg(100, stm_SetIcon, LoadIcon(0, MakeIntResource(idi_Asterisk)), 0)
	else SendDlgItemMsg(100, stm_SetIcon, LoadIcon(0, MakeIntResource(idi_Exclamation)), 0);
	SendDlgItemMsg(102, wm_SetText, 0, LongInt(Text));
end;

destructor TCheckDlg.Done;
begin
	StrDispose(Text);
	inherited Done;
end;

end.