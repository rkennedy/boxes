unit Toolbox;

interface
uses WinTypes, oWindows;

type
	PToolbox = ^TToolbox;
	TToolbox = object(TWindow)
		CaptionRect, SystemRect: TRect;
		CaptionColor, CapTextColor: TColorRef;
		constructor Init(AParent: PWindowsObject);
		procedure Paint(PaintDC: hDC; var PaintInfo: TPaintStruct); virtual;
		procedure WMCommand(var Msg: TMessage); virtual wm_First + wm_Command;
		procedure WMNCLButtonDown(var Msg: TMessage); virtual wm_First + wm_NCLButtonDown;
		procedure WMNCHitTest(var Msg: TMessage); virtual wm_First + wm_NCHitTest;
		procedure WMNCActivate(var Msg: TMessage); virtual wm_First + wm_NCActivate;
		procedure WMLButtonDown(var Msg: TMessage); virtual wm_First + wm_LButtonDown;
		function GetClassName: PChar; virtual;
		procedure GetWindowClass(var AWndClass: TWndClass); virtual;
		function CanClose: Boolean; virtual;
		destructor Done; virtual;
	end;

implementation
uses WinProcs, Win31, Win, Resource, BoxProc, Tool;

const
	RectLeft = 16 - 3;
	RectRight = 32 + 2;
	RectHeight = RectRight - RectLeft;
	RectTop = RectHeight + 8;
	TopOffset = RectLeft + 9;
	ToolRect: array[idx_BoxGoal..idx_Void] of TRect = (
		(Left: RectLeft; Top: TopOffset + RectTop *0; Right: RectRight; Bottom: TopOffset + RectTop*0+RectHeight),
		(Left: RectLeft; Top: TopOffset + RectTop *1; Right: RectRight; Bottom: TopOffset + RectTop*1+RectHeight),
		(Left: RectLeft; Top: TopOffset + RectTop *2; Right: RectRight; Bottom: TopOffset + RectTop*2+RectHeight),
		(Left: RectLeft; Top: TopOffset + RectTop *3; Right: RectRight; Bottom: TopOffset + RectTop*3+RectHeight),
		(Left: RectLeft; Top: TopOffset + RectTop *4; Right: RectRight; Bottom: TopOffset + RectTop*4+RectHeight),
		(Left: RectLeft; Top: TopOffset + RectTop *5; Right: RectRight; Bottom: TopOffset + RectTop*5+RectHeight),
		(Left: RectLeft; Top: TopOffset + RectTop *6; Right: RectRight; Bottom: TopOffset + RectTop*6+RectHeight));
	VoidRect: TRect = (Left: RectLeft + 3; Top: TopOffset+RectTop*6+3;Right:RectLeft+3+15;Bottom:TopOffset+RectTop*6+3+15);

const
	ToolStr: array[idx_BoxGoal..idx_Void] of string = ('Box & Goal'#0,
		'Box'#0, 'Clear'#0, 'Player & Goal'#0, 'Goal'#0, 'Player'#0, 'Void'#0);

var
	Selected: array[idx_BoxGoal..idx_Void] of Boolean;

constructor TToolbox.Init;
begin
	inherited Init(AParent, 'Toolbox');
	with Attr do begin
		x := 10;
		y := 10;
		w := 126;
		h := 233;
		Style := ws_Visible or ws_Border or ws_Popup;
	end;
	SetRect(SystemRect, 0, 0, 10, 8);
	SetRect(CaptionRect, SystemRect.Right, -1, Attr.w, 8);
	Selected[PMyWin(Parent)^.GetTool] := True;
end;

procedure TToolbox.Paint;
var
	Brush: hBrush;
	memDC: hDC;
	Old: THandle;
	OldBmp: THandle;
	Title: PChar;
	lTitle: Integer;
	i: Integer;
	StrRect: TRect;
begin
	Brush := CreateSolidBrush(CaptionColor);
	FillRect(PaintDC, CaptionRect, Brush);
	DeleteObject(Brush);

	memDC := CreateMemoryDC;
	Old := SelectObject(memDC, bmp_SysMenu);
	BitBlt(PaintDC, -1, -1, 12, 9, memDC, 0, 0, srcCopy);
	bmp_SysMenu := SelectObject(memDC, Old);

	MoveTo(PaintDC, -1, 7);
	LineTo(PaintDC, Attr.w, 7);

	SetTextColor(PaintDC, CapTextColor);
	SetBkMode(PaintDC, Transparent);
	lTitle := GetWindowTextLength(hWindow) + 1;
	GetMem(Title, lTitle);
	GetWindowText(hWindow, Title, lTitle);

	Old := SelectObject(PaintDC, fnt_ToolboxCaption);
	DrawText(PaintDC, Title, -1, CaptionRect, dt_SingleLine or dt_Center or dt_VCenter or dt_NoPrefix);
	fnt_ToolboxCaption := SelectObject(PaintDC, Old);

	FreeMem(Title, lTitle);

	SetTextColor(PaintDC, GetSysColor(color_BtnText));
	Old := SelectObject(PaintDC, fnt_SansSerif);
	for i := idx_BoxGoal to idx_Void do begin
		Paint3DRect(PaintDC, ToolRect[i], Selected[i]);
		if i = idx_Void then begin
			UnrealizeObject(hbr_Background);
			FillRect(PaintDC, VoidRect, hbr_Background);
		end else begin
			OldBmp := SelectObject(memDC, bmp_Bitmap[i]);
			BitBlt(PaintDC, ToolRect[i].Left+3, ToolRect[i].Top+3, 15, 15, memDC, 0, 0, srcCopy);
			bmp_Bitmap[i] := SelectObject(memDC, OldBmp);
		end;
		CopyRect(StrRect, ToolRect[i]);
		OffsetRect(StrRect, RectHeight + 3, 0);
		DrawText(PaintDC, @ToolStr[i, 1], -1, StrRect, dt_SingleLine or dt_VCenter or dt_Left or dt_NoClip or dt_NoPrefix);
	end;
	fnt_SansSerif := SelectObject(PaintDC, Old);
	DeleteDC(memDC);
end;

procedure TToolbox.WMCommand;
begin
	case Msg.wParam of
		cm_SysMove: SendMessage(hWindow, wm_SysCommand, sc_Move, 0);
		cm_SysClose: SendMessage(hWindow, wm_SysCommand, sc_Close, 0);
		else DefWndProc(Msg);
	end;
end;

procedure TToolbox.WMNCLButtonDown;
var
	PopupRect: TRect;
begin
	DefWndProc(Msg);
	with Msg do begin
		MapWindowPoints(hWnd_Desktop, hWindow, lParam, 1);
		if PtInRect(SystemRect, MakePoint(lParam)) then begin
			CopyRect(PopupRect, SystemRect);
			MapWindowPoints(hWindow, hWnd_Desktop, PopupRect, 2);
			TrackPopupMenu(mnu_ToolboxSystem, tpm_LeftAlign or tpm_LeftButton,
				PopupRect.Left, PopupRect.Bottom-1, 0, hWindow, @PopupRect);
		end;
	end;
end;

procedure TToolbox.WMNCHitTest;
var
	i: Integer;
begin
	DefWndProc(Msg);
	with Msg do begin
		MapWindowPoints(hWnd_Desktop, hWindow, lParam, 1);
		Result := htCaption;
		if PtInRect(SystemRect, MakePoint(lParam)) then Result := htSysMenu
		else for i := idx_BoxGoal to idx_Void do if PtInRect(ToolRect[i], MakePoint(lParam)) then Result := htClient;
	end;
end;

procedure TToolbox.WMNCActivate;
begin
	if Boolean(Msg.wParam) then begin
		CaptionColor := GetSysColor(color_ActiveCaption);
		CapTextColor := GetSysColor(color_CaptionText);
	end else begin
		CaptionColor := GetSysColor(color_InactiveCaption);
		CapTextColor := GetSysColor(color_InactiveCaptionText);
	end;
	InvalidateRect(hWindow, @CaptionRect, False);
	UpdateWindow(hWindow);
	Msg.Result := LongInt(True);
end;

procedure TToolbox.WMLButtonDown;
var
	i: Integer;
begin
	for i := idx_BoxGoal to idx_Void do begin
		Selected[i] := False;
		if PtInRect(ToolRect[i], TPoint(Msg.lParam)) then begin
			PMyWin(Parent)^.SetTool(i);
			Selected[i] := True;
			InvalidateRect(hWindow, nil, False);
		end;
	end;
	Msg.Result := 0;
end;

function TToolbox.GetClassName;
begin
	GetClassName := 'TurboToolboxWindow';
end;

procedure TToolbox.GetWindowClass;
begin
	inherited GetWindowClass(AWndClass);
	with AWndClass do begin
		Style := Style or cs_ByteAlignClient or cs_ByteAlignWindow;
		hbrBackground := CreateSolidBrush(GetSysColor(color_BtnFace));
	end;
end;

function TToolbox.CanClose;
begin
	Show(sw_Hide);
	CanClose := False;
end;

destructor TToolbox.Done;
begin
	inherited Done;
end;

var
	asdf: Integer;
begin
	for asdf := idx_BoxGoal to idx_Void do Selected[asdf] := False;
end.