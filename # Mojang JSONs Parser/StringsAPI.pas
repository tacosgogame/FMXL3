unit StringsAPI;

interface

const
  METHOD_SIMPLE    = 0; // ������� ������
  METHOD_SELECTIVE = 1; // ������, ���� �������� �� ���������� � ������,
                        // ���������� ���������� ������������������

function SimpleReplaceParam(var Source: string; const Param, ReplacingString: string): Boolean; inline;
function SelectiveReplaceParam(var Source: string; const Param, ReplacingString: string): Boolean; inline;
function ReplaceParam(const Source, Param, ReplacingString: string; Method: LongWord = METHOD_SIMPLE): string; overload;
function ReplaceParam(const Source, Param, ReplacingString: string; out WasReplaced: Boolean; Method: LongWord = METHOD_SIMPLE): string; overload;

{
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  * Simple - ������� �����:
  Source          = aFFabFFabc
  Param           = ab
  ReplacingString = abc

  Result = aFFabcFFabcc

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  * Selective - ������������� �����:
  Source          = aFFabFFabc
  Param           = ab
  ReplacingString = abc

  Result = aFFabcFFabc - ������� ������������������ ����� ��, ���
                         ���������� ������ (abc), ������� � �� �������

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
}

function StartsWith(const Str, Starting: string): Boolean;
function EndsWith(const Str, Ending: string): Boolean;
function GetRemainder(const Src, Starting: string; out Remainder: string): Boolean;
function GetRelativePath(const Path, Starting: string): string;

function FixSlashes(const StringToFix: string; IsURL: Boolean = False): string;
function GetXMLParameter(Data: string; Param: string): string;
function CheckSymbols(Input: string): Boolean;

implementation

uses
  SysUtils;

function SimpleReplaceParam(var Source: string; const Param, ReplacingString: string): Boolean; inline;
var
  SourceLength: Integer;
  ParamLength: Integer;
  ReplacingStrLength: Integer;

  StartPos: Integer;
  NewPos: Integer;

  TempStr: string;
begin
  SourceLength := Length(Source);
  ParamLength := Length(Param);
  ReplacingStrLength := Length(ReplacingString);
  
  NewPos := 1;

  StartPos := Pos(Param, Source);
  Result := StartPos <> 0;
  while StartPos <> 0 do
  begin
    StartPos := StartPos + NewPos - 1;
    Delete(Source, StartPos, ParamLength);
    Insert(ReplacingString, Source, StartPos);

    NewPos := StartPos + ReplacingStrLength;
    SourceLength := SourceLength + (ReplacingStrLength - ParamLength);

    TempStr := Copy(Source, NewPos, SourceLength - NewPos + 1);
    StartPos := Pos(Param, TempStr);
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function SelectiveReplaceParam(var Source: string; const Param, ReplacingString: string): Boolean; inline;
var
  SourceLength: Integer;
  ParamLength: Integer;
  ReplacingStrLength: Integer;

  StartPos: Integer;
  NewPos: Integer;

  ParamPosInReplacingString: Integer;
  LeftDelta, RightDelta: Integer;
  ParamEnvironment: string;
  TempStr: string;
begin
  SourceLength := Length(Source);
  ParamLength := Length(Param);
  ReplacingStrLength := Length(ReplacingString);

  LeftDelta := 1;
  RightDelta := ReplacingStrLength;

  ParamPosInReplacingString := Pos(Param, ReplacingString);
  if ParamPosInReplacingString <> 0 then
  begin
    LeftDelta := ParamPosInReplacingString - 1;
    RightDelta := ReplacingStrLength - ParamPosInReplacingString;
    {
      ������ ������: Pos - LeftDelta
      ����� ������: Pos + RightDelta
    }
  end;

  NewPos := 1;

  StartPos := Pos(Param, Source);
  Result := StartPos <> 0;
  while StartPos <> 0 do
  begin
    // ��������� ���������� ��������:
    StartPos := StartPos + NewPos - 1;

    // �������� ��������� ���������:
    if (StartPos - LeftDelta > 0) and (StartPos + RightDelta <= SourceLength) then
    begin
      ParamEnvironment := Copy(Source, StartPos - LeftDelta, ReplacingStrLength);
      if ParamEnvironment = ReplacingString then
      begin
        NewPos := StartPos + RightDelta + 1;

        if NewPos > SourceLength then Exit;

        TempStr := Copy(Source, NewPos, SourceLength - NewPos + 1);
        StartPos := Pos(Param, TempStr);
        Continue;
      end;
    end;

    Delete(Source, StartPos, ParamLength);
    Insert(ReplacingString, Source, StartPos);
    NewPos := StartPos + ReplacingStrLength;
    SourceLength := SourceLength + (ReplacingStrLength - ParamLength);

    TempStr := Copy(Source, NewPos, SourceLength - NewPos + 1);
    StartPos := Pos(Param, TempStr);
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function ReplaceParam(const Source, Param, ReplacingString: string; Method: LongWord = METHOD_SIMPLE): string; overload;
begin
  Result := Source;

  case Method of
    METHOD_SIMPLE:    SimpleReplaceParam(Result, Param, ReplacingString);
    METHOD_SELECTIVE: SelectiveReplaceParam(Result, Param, ReplacingString);
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function ReplaceParam(const Source, Param, ReplacingString: string; out WasReplaced: Boolean; Method: LongWord = METHOD_SIMPLE): string; overload;
begin
  Result := Source;

  case Method of
    METHOD_SIMPLE:    WasReplaced := SimpleReplaceParam(Result, Param, ReplacingString);
    METHOD_SELECTIVE: WasReplaced := SelectiveReplaceParam(Result, Param, ReplacingString);
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function StartsWith(const Str, Starting: string): Boolean;
var
  StrLength, StartingLength: Integer;
  StrStarting: string;
begin
  StrLength := Length(Str);
  StartingLength := Length(Starting);

  if StartingLength > StrLength then Exit(False);
  StrStarting := Copy(Str, 1, StartingLength);

  Result := LowerCase(StrStarting) = LowerCase(Starting);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function EndsWith(const Str, Ending: string): Boolean;
var
  StrLength, EndingLength: Integer;
  StrEnding: string;
begin
  StrLength := Length(Str);
  EndingLength := Length(Ending);

  if EndingLength > StrLength then Exit(False);
  StrEnding := Copy(Str, StrLength - EndingLength + 1, EndingLength);

  Result := LowerCase(StrEnding) = LowerCase(Ending);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function GetRemainder(const Src, Starting: string; out Remainder: string): Boolean;
var
  StartingLength, SrcLength: Integer;
  StartingPos: Integer;
begin
  Remainder := '';
  StartingLength := Length(Starting);
  SrcLength := Length(Src);

  if StartingLength >= SrcLength then Exit(False);
  //if not StartsWith(Src, Starting) then Exit(False);

  StartingPos := Pos(Starting, Src);
  if StartingPos = 0 then Exit(False);

  Remainder := Copy(Src, StartingPos + StartingLength, SrcLength - StartingLength);
  Result := True;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function GetRelativePath(const Path, Starting: string): string;
var
  FixedPath, FixedStarting: string;
begin
  Result := '';
  FixedPath := LowerCase(FixSlashes(Path));
  FixedStarting := LowerCase(FixSlashes(Starting));
  GetRemainder(FixedPath, FixedStarting, Result);
  Result := FixSlashes(Result);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function FixSlashes(const StringToFix: string; IsURL: Boolean = False): string;
var
  WasReplaced: Boolean;
begin
  if IsURL then
  begin
    Result := ReplaceParam(StringToFix, '\', '/');
    repeat
      Result := ReplaceParam(Result, '//', '/', WasReplaced);
    until not WasReplaced;
    Result := ReplaceParam(Result, ':/', '://');
  end
  else
  begin
    Result := ReplaceParam(StringToFix, '/', '\');
    repeat
      Result := ReplaceParam(Result, '\\', '\', WasReplaced);
    until not WasReplaced;
  end;
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


function GetXMLParameter(Data: string; Param: string): string;
var
  PosStart, PosEnd: Word;
  StartParam, EndParam: string;
begin
  Result := '';
  StartParam := '<'+Param+'>';
  EndParam := '</'+Param+'>';
  PosStart := Pos(StartParam, Data);
  PosEnd := Pos(EndParam, Data);

  if PosStart = 0 then Exit;
  if PosEnd <= PosStart then Exit;

  PosStart := PosStart + Length(StartParam);
  Result := Copy(Data, PosStart, PosEnd - PosStart);
end;


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

// �������� �� ����������� �������:
function CheckSymbols(Input: string): Boolean;
var
  C: Char;
begin
  Result := False;
  for C in Input do
    if CharInSet(C, ['/', '\', ':', '?', '|', '*', '"', '<', '>', ' ']) then
    begin
      Result := True;
      Exit;
    end;
end;

end.
