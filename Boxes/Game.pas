unit Game;

interface

uses Map;

type
	TGame = record
		header: array[0..9] of Char;
		MapName: TFilename;
		PlayingField: TField;
		NumMoves: Word;
		TotalMoves: Word;
		Level: Word;
	end;

implementation

end.