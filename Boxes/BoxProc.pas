unit BoxProc;

interface
uses WinTypes;

function GetYValue(y: Byte): Word;
function GetXValue(x: Byte): Word;
procedure Paint3DRect(PaintDC: hDC; Rect: TRect);
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
	Old := SelectObject(PaintDC,  GPen);
	with Rect do begin
		MoveTo(PaintDC, Left, Bottom-1);
		LineTo(PaintDC, Left, Top);
		LineTo(PaintDC, Right-1, Top);
		GPen := SelectObject(PaintDC, WPen);
		LineTo(PaintDC, Right-1, Bottom-1);
		LineTo(PaintDC, Left, Bottom-1);
	end;
	WPen := SelectObject(PaintDC, Old);
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