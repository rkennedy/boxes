unit Resource;

interface
{$R BOXES.RES}
uses WinTypes;

const
	chr_BoxGoal = 'a';
	chr_Box = 'b';
	chr_Clear = 'c';
	chr_PlayerGoal = 'd';
	chr_Goal = 'e';
	chr_Player = 'f';

const
	idx_Bricks = 101;
	idx_Waves = idx_Bricks + 1;
	idx_Checks = idx_Bricks + 2;
	idx_Rivits = idx_Bricks + 3;
	idx_Squares = idx_Bricks + 4;
	idx_Icon = 101;
	idx_Menu = 101;
	idx_About = 101;
	idx_Options = idx_About + 1;
	idx_Cheer = 101;
	idx_Thp = idx_Cheer + 1;

var
	bmp_Background: array[idx_Bricks..idx_Squares] of hBitmap;

	fnt_SansSerif,
	fnt_YouWin,
	fnt_GetReady: hFont;

const
	idx_BoxGoal = 201;
	idx_Box = 202;
	idx_Clear = 203;
	idx_PlayerGoal = 204;
	idx_Goal = 205;
	idx_Player = 206;

var
	bmp_Player,
	bmp_PlayerGoal,
	bmp_Goal,
	bmp_BoxGoal,
	bmp_Box,
	bmp_Clear: hBitmap;

type
	hWaveRes = THandle;
	hWave = Pointer;

var
	hwr_Cheer,
	hwr_Thp: hWaveRes;
	wav_Cheer,
	wav_Thp: hWave;

const
	ini_Filename = 'boxes.ini';
	ini_AppName = 'Boxes';
	hlp_Filename = 'boxes.hlp';

procedure ResourceInit;
procedure ResourceDone;

implementation
uses WinProcs;

procedure ResourceInit;
var
	i: Integer;
  p: PChar;
begin
	for i := idx_Bricks to idx_Squares do bmp_Background[i] := LoadBitmap(hInstance, MakeIntResource(i));

	bmp_Player := LoadBitmap(hInstance, MakeIntResource(idx_Player));
	bmp_PlayerGoal := LoadBitmap(hInstance, MakeIntResource(idx_PlayerGoal));
	bmp_Goal := LoadBitmap(hInstance, MakeIntResource(idx_Goal));
	bmp_BoxGoal := LoadBitmap(hInstance, MakeIntResource(idx_BoxGoal));
	bmp_Box := LoadBitmap(hInstance, MakeIntResource(idx_Box));
	bmp_Clear := LoadBitmap(hInstance, MakeIntResource(idx_Clear));

  GetMem(p, 128);
	fnt_SansSerif := CreateFont(-8, 0, 0, 0, fw_Normal, 0, 0, 0, Ansi_CharSet, Out_Default_Precis, Clip_Default_Precis,
		Default_Quality, Default_Pitch or ff_Swiss, 'MS Sans Serif');
  GetPrivateProfileString(ini_AppName, 'Font.YouWin', 'Arial', p, 128, ini_Filename);
	fnt_YouWin := CreateFont(-48, 0, 0, 0, fw_Bold, 1, 0, 0, Ansi_CharSet, Out_Default_Precis, Clip_Default_Precis,
		Default_Quality, Default_Pitch or ff_DontCare, p{'Arial'});
  GetPrivateProfileString(ini_AppName, 'Font.GetReady', 'Times New Roman', p, 128, ini_Filename);
	fnt_GetReady := CreateFont(-240, 0, 0, 0, fw_Bold, 1, 0, 0, Ansi_CharSet, Out_Default_Precis, Clip_Default_Precis,
		Default_Quality, Default_Pitch or ff_DontCare, p{'Times New Roman'});
  FreeMem(p, 128);

	hwr_Cheer := LoadResource(hInstance, FindResource(hInstance, MakeIntResource(idx_Cheer), 'WAVE'));
	wav_Cheer := LockResource(hwr_Cheer);
	hwr_Thp := LoadResource(hInstance, FindResource(hInstance, MakeIntResource(idx_Thp), 'WAVE'));
	wav_Thp := LockResource(hwr_Thp);
end;

procedure ResourceDone;
var
	i: Integer;
begin
	UnLockResource(hwr_Thp);
	FreeResource(hwr_Thp);
	UnlockResource(hwr_Cheer);
	FreeResource(hwr_Cheer);

	DeleteObject(fnt_GetReady);
	DeleteObject(fnt_YouWin);
	DeleteObject(fnt_SansSerif);

	DeleteObject(bmp_Clear);
	DeleteObject(bmp_Box);
	DeleteObject(bmp_BoxGoal);
	DeleteObject(bmp_Goal);
	DeleteObject(bmp_PlayerGoal);
	DeleteObject(bmp_Player);

	for i := idx_Squares downto idx_Bricks do DeleteObject(bmp_Background[i]);
end;

end.