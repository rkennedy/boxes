program Boxes;

uses WinTypes, oWindows, Win, Ctl3D;

type
	PMyApp = ^TMyApp;
	TMyApp = object(TApplication)
		procedure InitMainWindow; virtual;
		procedure InitInstance; virtual;
	end;

procedure TMyApp.InitMainWindow;
begin
	MainWindow := new(PMyWin, Init(nil));
end;

procedure TMyApp.InitInstance;
begin
	inherited InitInstance;
	hAccTable := WinProcs.LoadAccelerators(hInstance, MakeIntResource(101));
	Ctl3DRegister(hInstance);
	Ctl3DAutoSubClass(hInstance);
end;

var
	MyApp: TMyApp;
begin
	MyApp.Init('Boxes');
	MyApp.Run;
	Ctl3DUnRegister(hInstance);
	MyApp.Done;
end.