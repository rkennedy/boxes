unit BoxProc;

interface
uses WinTypes;

function GetYValue(y: Byte): Word;
function GetXValue(x: Byte): Word;
procedure Paint3DRect(PaintDC: hDC; Rect: TRect; Sunken: Boolean);
procedure ProcInit;
procedure ProcDone;

implementation
uses WinProcs, Win31;
var
	WPen, GPen: hPen;

function GetYValue;
var
	Result: Word;
begin
	Result := 0;
	while y >= 16 do begin
		Inc(Result);
		y := y - 16;
	end;
	GetYValue := Result;
end;

function GetXValue;
begin
	GetXValue := x - GetYValue(x) shl 4;
end;

procedure Paint3DRect;
var
	Old: THandle;
begin
	InflateRect(Rect, 1, 1);
	if Sunken then Old := SelectObject(PaintDC, GPen) else Old := SelectObject(PaintDC, WPen);
	with Rect do begin
		MoveTo(PaintDC, Left, Bottom-1);
		LineTo(PaintDC, Left, Top);
		LineTo(PaintDC, Right-1, Top);
		if Sunken then GPen := SelectObject(PaintDC, WPen) else WPen := SelectObject(PaintDC, GPen);
		LineTo(PaintDC, Right-1, Bottom-1);
		LineTo(PaintDC, Left, Bottom-1);
	end;
	if Sunken then WPen := SelectObject(PaintDC, Old) else GPen := SelectObject(PaintDC, Old);
end;

procedure ProcInit;
begin
	GPen := CreatePen(ps_Solid, 1, GetSysColor(color_BtnShadow));
	WPen := CreatePen(ps_Solid, 1, GetSysColor(color_BtnHighlight));
end;

procedure ProcDone;
begin
	DeleteObject(WPen);
	DeleteObject(GPen);
end;

end.