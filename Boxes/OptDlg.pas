unit OptDlg;

interface

uses WinTypes, oWindows, oDialogs;

type
	POptDlg = ^TOptDlg;
	TOptDlg = object(TDialog)
		idx_Background: Integer;
    bool_Sound: Boolean;
		constructor Init(AParent: PWindowsObject);
		procedure SetupWindow; virtual;
		procedure WMPaint(var Msg: TMessage); virtual wm_First + wm_Paint;
		procedure OK(var Msg: TMessage); virtual id_First + id_OK;
	end;

implementation
uses WinProcs, Win31, Resource;

constructor TOptDlg.Init;
begin
	inherited Init(AParent, MakeIntResource(idx_Options));
end;

procedure TOptDlg.SetupWindow;
var
	i: Integer;
	Rect: TRect;
begin
	inherited SetupWindow;
	GetWindowRect(hWindow, Rect);
	SetWindowPos(hWindow, 0, (GetSystemMetrics(sm_CXScreen) - Rect.Right + Rect.Left) shr 1,
		(GetSystemMetrics(sm_CYScreen) - Rect.Bottom + Rect.Top) shr 1, 0, 0, swp_NoSize or swp_NoZOrder);
	for i := 101 to 107 do SendDlgItemMsg(i, wm_SetFont, Word(fnt_SansSerif), LongInt(True));
	SendDlgItemMsg(idx_Background + 1, wm_SetFocus, GetFocus, 0);
	SendDlgItemMsg(idx_Background + 1, bm_SetCheck, 1, 0);
  SendDlgItemMsg(107, bm_SetCheck, Abs(Integer(bool_Sound)), 0);
end;

procedure TOptDlg.WMPaint;
var
	i: Integer;
	Rect: TRect;
	memDC: hDC;
	winDC: hDC;
	PaintInfo: TPaintStruct;
	Old: THandle;
begin
	DefWndProc(Msg);
	winDC := BeginPaint(hWindow, PaintInfo);
	memDC := CreateCompatibleDC(winDC);

	for i := idx_Bricks to idx_Squares do begin
		Old := SelectObject(memDC, bmp_Background[i]);
		GetWindowRect(GetItemHandle(i+1), Rect);
		MapWindowPoints(hWnd_Desktop, hWindow, Rect, 2);
		BitBlt(winDC, Rect.Left-12, Rect.Top+5, 8, 8, memDC, 0, 0, srcCopy);
		bmp_Background[i] := SelectObject(memDC, Old);
	end;

	DeleteDC(memDC);
	EndPaint(hWindow, PaintInfo);
end;

procedure TOptDlg.OK;
var
	i: Integer;
begin
	for i := idx_Bricks to idx_Squares do if SendDlgItemMsg(i+1, bm_GetCheck, 0, 0) = 1 then idx_Background := i;
  bool_Sound := SendDlgItemMsg(107, bm_GetCheck, 0, 0) = 1;
	inherited OK(Msg);
end;

end.