unit Map;

interface
uses WinTypes, Objects;

const
	MaxFileSize = 127 shl 8;
	MaxLevels = MaxFileSize shr 8;

type
	TField = array[0..255] of Char;
	TFilename = array [0..127] of Char;
	TDirection = (dir_Left, dir_Up, dir_Right, dir_Down);
	TLevels = array[0..MaxFileSize-1] of Char;

type
	PMap = ^TMap;
	TMap = object(TObject)
		OrgField, Field, UndoField: TField;
		Level: LongInt;
		NumLevels: LongInt;
		Levels: TLevels;
		Filename: TFilename;
		constructor Init(AFilename: TFilename);
		procedure SetFilename(AFilename: TFilename); virtual;
		procedure Save; virtual;
		procedure SetLevel(ALevel: Integer); virtual;
		procedure AddLevel; virtual;
		procedure DeleteLevel(ALevel: LongInt); virtual;
		procedure UpdateLevels; virtual;
		function SetChar(Index: Byte; AChar: Char): Boolean; virtual;
		function NumChars(c: Char): Integer;
		function Undo: Boolean; virtual;
		function Undoable: Boolean; virtual;
		procedure Clear; virtual;
		procedure Revert; virtual;
		procedure Paint(PaintDC: hDC; var PaintInfo: TPaintStruct; x, y: Integer); virtual;
		destructor Done; virtual;
		function GetPlayerPos: LongInt;
		function PlayerIndex: Integer;
		function FileOpen: Boolean;
	private
		FileHandle: THandle;
	end;

implementation

uses WinProcs, Win31, strings, Resource, BoxProc, WinDOS;

constructor TMap.Init;
begin
	inherited Init;
	FileExpand{StrCopy}(Filename, StrLower(AFilename));
	FileHandle := _lopen(Filename, of_ReadWrite or of_Share_Deny_Write); {Open the file}
	if FileOpen then begin
		NumLevels := Trunc(_llseek(FileHandle, 0, 2) / 256);
		_llseek(FileHandle, 0, 0); {Return to beginning of file}
		_lread(FileHandle, @Levels, MaxFileSize); {Read file's contents into Levels}
		SetLevel(1); {Set Fields to Level One}
		_lclose(FileHandle); {Close the file}
	end;
end;

procedure TMap.SetFilename;
begin
	FileExpand(Filename, StrLower(AFilename));
	{StrCopy(Filename, AFilename);}
end;

function TMap.GetPlayerPos;
var
	x: Integer;
begin
	x := PlayerIndex;
	if x <> -1 then GetPlayerPos := (GetYValue(x) shl 16) or GetXValue(x) else GetPlayerPos := x;
end;

procedure TMap.SetLevel;
begin
	Level := ALevel;
	StrLCopy(OrgField, Levels + (Level-1) shl 8, 256);
	Field := OrgField;
	UndoField := OrgField;
end;

procedure TMap.AddLevel;
var
	TempField: TField;
begin
	if NumLevels >= MaxLevels then Exit;
	FillChar(TempField, 256, chr_Void);
	StrLCopy(Levels + (NumLevels) shl 8, TempField, 256);
	Inc(NumLevels);
end;

procedure TMap.DeleteLevel;
begin
	if NumLevels = 1 then Exit;
	if ALevel > NumLevels then Exit;

	StrLCopy(Levels, Levels, ALevel shl 8);
	StrLCat(Levels, Levels + (ALevel+1) shl 8, StrLen(Levels + (ALevel+1) shl 8));
	Dec(NumLevels);
	if Level > NumLevels then SetLevel(Level-1);
end;

procedure TMap.UpdateLevels;
begin
	hmemcpy(Pointer(Levels + (Level-1) shl 8), @Field, 256);
end;

function TMap.SetChar;
begin
	if Field[Index] = AChar then SetChar := False else begin
		UndoField := Field;
		Field[Index] := AChar;
		SetChar := True;
	end;
end;

function TMap.NumChars;
var
	i: Integer;
	Result: Integer;
begin
	Result := 0;
	for i := 0 to 255 do if Field[i] = c then Inc(Result);
	NumChars := Result;
end;

function TMap.Undo;
begin
	if Undoable then begin
		Field := UndoField;
		Undo := True;
	end else Undo := False;
end;

function TMap.Undoable;
begin
	Undoable := StrLComp(Field, UndoField, 256) <> 0;
end;

procedure TMap.Clear;
begin
	UndoField := Field;
	FillChar(Field, SizeOf(Field), chr_Void);
end;

procedure TMap.Revert;
begin
	Field := OrgField;
	UndoField := OrgField;
end;

procedure TMap.Save;
begin
	UpdateLevels;
	FileHandle := _lcreat(Filename, 0);
	if FileOpen then begin
		_llseek(FileHandle, 0, 0);
		_lwrite(FileHandle, Levels, NumLevels shl 8{StrLen(Levels)});
		_lclose(FileHandle);
	end;
end;

procedure TMap.Paint;
var
	idx_Bit: Integer;
	Old: THandle;
	i: Integer;
	memDC: hDC;
	Msg: TMsg;
begin
	if Field[0] <> '' then begin
		memDC := CreateCompatibleDC(PaintDC);
		for i := 0 to 255 do begin
			case Field[i] of
				chr_BoxGoal: idx_Bit := idx_BoxGoal;
				chr_Box: idx_Bit := idx_Box;
				chr_Clear: idx_Bit := idx_Clear;
				chr_PlayerGoal: idx_Bit := idx_PlayerGoal;
				chr_Goal: idx_Bit := idx_Goal;
				chr_Player: idx_Bit := idx_Player;
				else idx_Bit := 0;
			end;
			if idx_Bit <> 0 then begin
				Old := SelectObject(memDC, bmp_Bitmap[idx_Bit]);
				BitBlt(PaintDC, x+GetXValue(i) shl 4, y+GetYValue(i) shl 4, 16, 16, memDC, 0, 0, srcCopy);
				bmp_Bitmap[idx_Bit] := SelectObject(memDC, Old);
			end;

			PeekMessage(Msg, 0, wm_MouseFirst, wm_MouseLast, pm_NoRemove);
		end;
		DeleteDC(memDC);
	end;
end;

destructor TMap.Done;
begin
	if FileOpen then _lclose(FileHandle);
	inherited Done;
end;

function TMap.PlayerIndex;
var
	OK: Boolean;
	i: Integer;
begin
	i := -1;
	OK := False;
	PlayerIndex := -1;
	while not OK do begin
		Inc(i);
		if Field[i] in [chr_Player, chr_PlayerGoal] then begin
			OK := True;
			PlayerIndex := i;
		end;
		if i = 255 then OK := True;
	end;
end;

function TMap.FileOpen;
begin
	FileOpen := FileHandle <> 0;
end;

end.