unit Map;

interface
uses WinTypes, Objects;

type
	TFilename = array [0..127] of Char;
	TField = array[0..255] of Char;
	TDirection = (dir_Left, dir_Up, dir_Right, dir_Down);

	PMap = ^TMap;
	TMap = object(TObject)
		OrgField, Field, UndoField: TField;
		Level: Word;
		Filename: TFilename;
		constructor Init(AFilename: TFilename);
		function GetPlayerPos: LongInt;
		function AllGoalsFilled: Boolean;
		function Move(Dir: TDirection): Boolean;
		function SetLevel(ALevel: Integer): Boolean; virtual;
		function NumLevels: LongInt; virtual;
		function Undo: Boolean; virtual;
		function Undoable: Boolean; virtual;
		procedure Revert; virtual;
		procedure Paint(PaintDC: hDC; var PaintInfo: TPaintStruct; x, y: Integer); virtual;
		destructor Done; virtual;
		function PlayerIndex: Integer;
	private
		FileOpen: Boolean;
		FileHandle: THandle;
	end;

implementation

uses WinProcs, strings, Resource, BoxProc, WinDOS;

constructor TMap.Init;
begin
	inherited Init;
	FileExpand{StrCopy}(Filename, AFilename);
  FileHandle := _lopen(Filename, of_Read or of_Share_Deny_Write);
	FileOpen := FileHandle <> 0;
	SetLevel(1);
end;

function TMap.GetPlayerPos;
var
	x: Integer;
begin
	x := PlayerIndex;
	if x <> -1 then GetPlayerPos := (GetYValue(x) shl 8) or GetXValue(x) else GetPlayerPos := x;
end;

function TMap.AllGoalsFilled;
var
	i: Integer;
begin
	AllGoalsFilled := True;
	for i := 0 to 255 do if Field[i] in [chr_Goal, chr_Box] then AllGoalsFilled := False;
end;

function TMap.Move;
var
	Result: Boolean;
	a: Integer;
begin
	Result := False;
	a := PlayerIndex;
	if a = -1 then exit;
	Result := True;
	UndoField := Field;
	case Dir of
		dir_Up: begin
			if a - 16 < 0 then begin
				Result := False;
			end else if Field[a-16] = chr_Clear then begin
				Field[a-16] := chr_Player;
				if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
			end else if Field[a-16] = chr_Goal then begin
				Field[a-16] := chr_PlayerGoal;
				if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
			end else if Field[a-16] = chr_Box then begin
				if a - 32 < 0 then begin
					Result := False;
				end else if Field[a-32] = chr_Clear then begin
					Field[a-32] := chr_Box;
					Field[a-16] := chr_Player;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else if Field[a-32] = chr_Goal then begin
					Field[a-32] := chr_BoxGoal;
					Field[a-16] := chr_Player;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else Result := False;
			end else if Field[a-16] = chr_BoxGoal then begin
				if a - 32 < 0 then begin
					Result := False;
				end else if Field[a-32] = chr_Clear then begin
					Field[a-32] := chr_Box;
					Field[a-16] := chr_PlayerGoal;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else if Field[a-32] = chr_Goal then begin
					Field[a-32] := chr_BoxGoal;
					Field[a-16] := chr_PlayerGoal;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else Result := False;
			end else Result := False;
		end;
		dir_Left: begin
			if GetXValue(a - 1) < 0 then begin
				Result := False;
			end else if Field[a-1] = chr_Clear then begin
				Field[a-1] := chr_Player;
				if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
			end else if Field[a-1] = chr_Goal then begin
				Field[a-1] := chr_PlayerGoal;
				if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
			end else if Field[a-1] = chr_Box then begin
				if GetXValue(a - 2) < 0 then begin
					Result := False;
				end else if Field[a-2] = chr_Clear then begin
					Field[a-2] := chr_Box;
					Field[a-1] := chr_Player;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else if Field[a-2] = chr_Goal then begin
					Field[a-2] := chr_BoxGoal;
					Field[a-1] := chr_Player;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else Result := False;
			end else if Field[a-1] = chr_BoxGoal then begin
				if GetXValue(a - 2) < 0 then begin
					Result := False;
				end else if Field[a-2] = chr_Clear then begin
					Field[a-2] := chr_Box;
					Field[a-1] := chr_PlayerGoal;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else if Field[a-2] = chr_Goal then begin
					Field[a-2] := chr_BoxGoal;
					Field[a-1] := chr_PlayerGoal;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else Result := False;
			end else Result := False;
		end;
		dir_Right: begin
			if GetXValue(a + 1) > 31 then begin
				Result := False;
			end else if Field[a+1] = chr_Clear then begin
				Field[a+1] := chr_Player;
				if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
			end else if Field[a+1] = chr_Goal then begin
				Field[a+1] := chr_PlayerGoal;
				if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
			end else if Field[a+1] = chr_Box then begin
				if GetXValue(a + 2) > 31 then begin
					Result := False;
				end else if Field[a+2] = chr_Clear then begin
					Field[a+2] := chr_Box;
					Field[a+1] := chr_Player;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else if Field[a+2] = chr_Goal then begin
					Field[a+2] := chr_BoxGoal;
					Field[a+1] := chr_Player;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else Result := False;
			end else if Field[a+1] = chr_BoxGoal then begin
				if GetXValue(a + 2) > 31 then begin
					Result := False;
				end else if Field[a+2] = chr_Clear then begin
					Field[a+2] := chr_Box;
					Field[a+1] := chr_PlayerGoal;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else if Field[a+2] = chr_Goal then begin
					Field[a+2] := chr_BoxGoal;
					Field[a+1] := chr_PlayerGoal;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else Result := False;
			end else Result := False;
		end;
		dir_Down: begin
			if a + 16 > 255 then begin
				Result := False;
			end else if Field[a+16] = chr_Clear then begin
				Field[a+16] := chr_Player;
				if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
			end else if Field[a+16] = chr_Goal then begin
				Field[a+16] := chr_PlayerGoal;
				if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
			end else if Field[a+16] = chr_Box then begin
				if a + 32 > 255 then begin
					Result := False;
				end else if Field[a+32] = chr_Clear then begin
					Field[a+32] := chr_Box;
					Field[a+16] := chr_Player;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else if Field[a+32] = chr_Goal then begin
					Field[a+32] := chr_BoxGoal;
					Field[a+16] := chr_Player;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else Result := False;
			end else if Field[a+16] = chr_BoxGoal then begin
				if a + 32 > 255 then begin
					Result := False;
				end else if Field[a+32] = chr_Clear then begin
					Field[a+32] := chr_Box;
					Field[a+16] := chr_PlayerGoal;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else if Field[a+32] = chr_Goal then begin
					Field[a+32] := chr_BoxGoal;
					Field[a+16] := chr_PlayerGoal;
					if Field[a] = chr_Player then Field[a] := chr_Clear else Field[a] := chr_Goal;
				end else Result := False;
			end else Result := False;
		end;
		else Result := False;
	end;
	Move := Result;
end;

function TMap.SetLevel;
begin
	SetLevel := False;
	if FileOpen then begin
		_llseek(FileHandle, 256 * (ALevel-1), 0);
		if _lread(FileHandle, @OrgField, 256) = 256 then begin
			Field := OrgField;
			UndoField := OrgField;
			Level := ALevel;
			SetLevel := True;
		end;
	end;
end;

function TMap.NumLevels;
begin
	if FileOpen then NumLevels := Trunc(_llseek(FileHandle, 0, 2) / 256) else NumLevels := 0;
end;

function TMap.Undo;
begin
	if StrLComp(Field, UndoField, 256) <> 0 then begin
		Field := UndoField;
		Undo := True;
	end else Undo := False;
end;

function TMap.Undoable;
begin
	Undoable := StrLComp(Field, UndoField, 256) <> 0;
end;

procedure TMap.Revert;
begin
	Field := OrgField;
	UndoField := OrgField;
end;

procedure TMap.Paint;
var
	hBit: hBitmap;
	Old: THandle;
	i: Integer;
	memDC: hDC;
	Msg: TMsg;
begin
	if Field[0] <> '' then begin
		memDC := CreateCompatibleDC(PaintDC);
		for i := 0 to 255 do begin
			case Field[i] of
				chr_BoxGoal: hBit := bmp_BoxGoal;
				chr_Box: hBit := bmp_Box;
				chr_Clear: hBit := bmp_Clear;
				chr_PlayerGoal: hBit := bmp_PlayerGoal;
				chr_Goal: hBit := bmp_Goal;
				chr_Player: hBit := bmp_Player;
				else hBit := 0;
			end;
			if hBit <> 0 then begin
				Old := SelectObject(memDC, hBit);
{				BitBlt(PaintDC, x+GetXValue(i)*16, y+GetYValue(i)*16, 16, 16, memDC, 0, 0, srcCopy);}
				BitBlt(PaintDC, x+GetXValue(i) shl 4, y+GetYValue(i) shl 4, 16, 16, memDC, 0, 0, srcCopy);
				hBit := SelectObject(memDC, Old);
			end;

			PeekMessage(Msg, 0, wm_MouseFirst, wm_MouseLast, pm_NoRemove);
		end;
		DeleteDC(memDC);
	end;
end;

destructor TMap.Done;
begin
	if FileHandle <> 0 then _lclose(FileHandle);
	FileOpen := False;
	inherited Done;
end;

function TMap.PlayerIndex;
var
	OK: Boolean;
	i: Integer;
begin
	i := 0;
	OK := False;
	PlayerIndex := -1;
	while not OK do begin
		Inc(i);
		if (Field[i] = chr_Player) or (Field[i] = chr_PlayerGoal) then begin
			OK := True;
			PlayerIndex := i;
		end;
		if i = 255 then OK := True;
	end;
end;

end.