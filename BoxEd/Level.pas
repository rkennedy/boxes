unit Level;

interface

type
	TField = array[0..255] of Char;

	PLevel = ^TLevel;
	TLevel = object(TObject)
		Field: TField;
	end;

implementation

end.