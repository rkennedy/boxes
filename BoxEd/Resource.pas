unit Resource;
{$R BOXED.RES}
interface
uses WinTypes;

const
	idx_Bricks = 101;
	idx_Waves = idx_Bricks + 1;
	idx_Checks = idx_Bricks + 2;
	idx_Rivits = idx_Bricks + 3;
	idx_Squares = idx_Bricks + 4;
	idx_bmp_SysMenu = 301;
	idx_MainMenu = 101;
	idx_Icon = 101;
	idx_About = 101;
	idx_Options = idx_About + 1;
	idx_LevelDlg = idx_About + 2;
	idx_CheckDlg = idx_About + 3;

const
	cm_SysMove = 61456;
	cm_SysClose = 61536;

var
	bmp_SysMenu: hBitmap;
	bmp_Background: array[idx_Bricks..idx_Squares] of hBitmap;
var
	mnu_ToolboxSystem: hMenu;
	ico_Main: hIcon;
	fnt_SansSerif: hFont;
	fnt_ToolboxCaption: hFont;

const
	idx_BoxGoal = 201;
	idx_Box = 202;
	idx_Clear = 203;
	idx_PlayerGoal = 204;
	idx_Goal = 205;
	idx_Player = 206;
	idx_Void = 207;

const
	chr_BoxGoal = 'a';
	chr_Box = 'b';
	chr_Clear = 'c';
	chr_PlayerGoal = 'd';
	chr_Goal = 'e';
	chr_Player = 'f';
	chr_Void = 'v';
	chr_Chars: array[idx_BoxGoal..idx_Void] of Char = (chr_BoxGoal, chr_Box,
		chr_Clear, chr_PlayerGoal, chr_Goal, chr_Player, chr_Void);

var
	cur_Tool: array[idx_BoxGoal..idx_Void] of hCursor;
	bmp_Bitmap: array[idx_BoxGoal..idx_Player] of hBitmap;
	hbr_Background: hBrush;
	idx_Background: Integer;

procedure ResourceInit;
procedure ResourceDone;

implementation
uses WinProcs;

procedure ResourceInit;
var
	i: Integer;
begin
	for i := idx_Bricks to idx_Squares do bmp_Background[i] := LoadBitmap(hInstance, MakeIntResource(i));
	for i := idx_BoxGoal to idx_Player do begin
		bmp_Bitmap[i] := LoadBitmap(hInstance, MakeIntResource(i));
		cur_Tool[i] := LoadCursor(hInstance, MakeIntResource(i));
	end;
	cur_Tool[idx_Void] := LoadCursor(hInstance, MakeIntResource(idx_Void));

{	bmp_Player := LoadBitmap(hInstance, MakeIntResource(idx_Player));
	bmp_PlayerGoal := LoadBitmap(hInstance, MakeIntResource(idx_PlayerGoal));
	bmp_Goal := LoadBitmap(hInstance, MakeIntResource(idx_Goal));
	bmp_BoxGoal := LoadBitmap(hInstance, MakeIntResource(idx_BoxGoal));
	bmp_Box := LoadBitmap(hInstance, MakeIntResource(idx_Box));
	bmp_Clear := LoadBitmap(hInstance, MakeIntResource(idx_Clear));}

	bmp_SysMenu := LoadBitmap(hInstance, MakeIntResource(idx_bmp_SysMenu));
	mnu_ToolboxSystem := CreatePopupMenu;
	AppendMenu(mnu_ToolboxSystem, mf_String, cm_SysMove, '&Move');
	AppendMenu(mnu_ToolboxSystem, mf_String, cm_SysClose, '&Close'#9'Ctrl+F4');

	ico_Main := LoadIcon(hInstance, MakeIntResource(idx_Icon));

	fnt_SansSerif := CreateFont(-8, 0, 0, 0, fw_Normal, 0, 0, 0, Ansi_CharSet, Out_Default_Precis, Clip_Default_Precis,
		Default_Quality, Default_Pitch or ff_Swiss, 'MS Sans Serif');
	fnt_ToolboxCaption := CreateFont(-8, 0, 0, 0, fw_Normal, 0, 0, 0, Ansi_CharSet, Out_Default_Precis, Clip_Default_Precis,
		Default_Quality, Default_Pitch or ff_Swiss, 'Small Fonts');
end;

procedure ResourceDone;
var
	i: Integer;
begin
	DeleteObject(fnt_ToolboxCaption);
	DeleteObject(fnt_SansSerif);

	DeleteObject(ico_Main);
	DestroyMenu(mnu_ToolboxSystem);
	DeleteObject(bmp_SysMenu);

{	DeleteObject(bmp_Clear);
	DeleteObject(bmp_Box);
	DeleteObject(bmp_BoxGoal);
	DeleteObject(bmp_Goal);
	DeleteObject(bmp_PlayerGoal);
	DeleteObject(bmp_Player);}

	DeleteObject(cur_Tool[idx_Void]);
	for i := idx_Player downto idx_BoxGoal do begin
		DeleteObject(cur_Tool[i]);
		DeleteObject(bmp_Bitmap[i]);
	end;
	for i := idx_Squares downto idx_Bricks do DeleteObject(bmp_Background[i]);
end;

end.