unit About;

interface
uses oDialogs;

type
	PAboutDlg = ^TAboutDlg;
	TAboutDlg = object(TDialog)
		procedure SetupWindow; virtual;
	end;

implementation
uses WinTypes, WinProcs, Resource;

procedure TAboutDlg.SetupWindow;
var
	Rect: TRect;
begin
	inherited SetupWindow;
	GetWindowRect(hWindow, Rect);
	SetWindowPos(hWindow, hWindow, (GetSystemMetrics(sm_CXScreen) - (Rect.Right-Rect.Left)) shr 1,
		(GetSystemMetrics(sm_CYScreen) - (Rect.Bottom-Rect.Top)) shr 1, 0, 0, swp_NoSize or swp_NoZOrder);
	SendDlgItemMsg(101, wm_SetFont, fnt_SansSerif, LongInt(True));
end;

end.