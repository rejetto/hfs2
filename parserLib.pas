unit parserLib;

interface

uses
  strutils, sysutils, classes, types, utilLib, windows;

type
  TmacroCB = function(fullMacro:string; pars:Tstrings; cbData:pointer):string;
  EtplError = class(Exception)
    pos, row, col: integer;
    code: string;
    constructor Create(const msg, code:string; row,col:integer);
    end;
const
  MARKER_OPEN = '{.';
  MARKER_CLOSE = '.}';
  MARKER_SEP = '|';
  MARKER_QUOTE = '{:';
  MARKER_UNQUOTE = ':}';
  MARKERS: array [0..4] of string = ( MARKER_OPEN, MARKER_CLOSE, MARKER_SEP, MARKER_QUOTE, MARKER_UNQUOTE );

function anyMacroMarkerIn(s:string):boolean;
function findMacroMarker(s:string; ofs:integer=1):integer;
procedure applyMacrosAndSymbols(var txt:string; cb:TmacroCB; cbData:pointer; removeQuotings:boolean=TRUE);

implementation

const
  MAX_RECUR_LEVEL = 50;
type
  TparserIdsStack = array [1..MAX_RECUR_LEVEL] of string;

constructor EtplError.create(const msg, code:string; row, col:integer);
begin
inherited create(msg);
self.row:=row;
self.col:=col;
self.code:=code;
end;

procedure applyMacrosAndSymbols2(var txt:string; cb:TmacroCB; cbData:pointer; var idsStack:TparserIdsStack; recurLevel:integer=0);
const
  // we don't track SEPs, they are handled just before the callback
  QUOTE_ID = 0;   // QUOTE must come before OPEN because it is a substring
  UNQUOTE_ID = 1;
  OPEN_ID = 2;
  CLOSE_ID = 3;
  MAX_MARKER_ID = 3;

  function alreadyRecurredOn(s:string):boolean;
  var
    i: integer;
  begin
  result:=TRUE;
  for i:=recurLevel downto 1 do
    if sameText(s, idsStack[i]) then exit;
  result:=FALSE;
  end; // alreadyRecurredOn

  procedure handleSymbols();
  var
    b, e, l : integer;
    s, newS: string;
  begin
  e:=0;
  l:=length(txt);
  while e < l do
    begin
    // search for next symbol
    b:=posEx('%',txt,e+1);
    if b = 0 then break;
    e:=b+1;
    if txt[e] = '%' then
      begin    // we don't accept %% as a symbol. so, restart parsing from the second %
      e:=b;
      continue;
      end;
    if not charInSet(txt[e], ['_','a'..'z','A'..'Z']) then continue; // first valid character
    while (e < l) and charInSet(txt[e], ['0'..'9','a'..'z','A'..'Z','-','_']) do
      inc(e);
    if txt[e] <> '%' then continue;
    // found!
    s:=substr(txt,b,e);
    if alreadyRecurredOn(s) then continue; // the user probably didn't meant to create an infinite loop

    newS:=cb(s, NIL, cbData);
    if s = newS then continue;

    idsStack[recurLevel]:=s; // keep track of what we recur on
    // apply translation, and eventually recur
    try applyMacrosAndSymbols2(newS, cb, cbData, idsStack, recurLevel);
    except end;
    idsStack[recurLevel]:='';
    inc(e, replace(txt, newS, b, e));
    l:=length(txt);
    end;
  end; // handleSymbols

  procedure handleMacros();
  var
    pars: Tstrings;

    function expand(from,to_:integer):integer;
    var
      s, fullMacro: string;
      i, o, q, u: integer;
    begin
    result:=0;
    fullMacro:=substr(txt, from+length(MARKER_OPEN), to_-length(MARKER_CLOSE));
    if alreadyRecurredOn(fullMacro) then exit; // the user probably didn't meant to create an infinite loop

    // let's find the SEPs to build 'pars'
    pars.clear();
    i:=1; // char pointer from where we shall copy the macro parameter
    o:=0;
    q:=posEx(MARKER_QUOTE, fullMacro); // q points to _QUOTE
      repeat
      o:=posEx(MARKER_SEP, fullmacro, o+1);
      if o = 0 then break;
      if (q > 0) and (q < o) then // this SEP is possibly quoted
        begin
        // update 'q' and 'u'
          repeat
          u:=posEx(MARKER_UNQUOTE, fullMacro, q);
          if u = 0 then exit; // macro quoting not properly closed
          q:=posEx(MARKER_QUOTE, fullMacro, q+1); // update q for next cycle
          // if we find other _QUOTEs before _UNQUOTE, then they are stacked, and we must go through the same number of both markers
          while (q > 0) and (q < u) do
            begin
            u:=posEx(MARKER_UNQUOTE, fullMacro, u+1);
            if u = 0 then exit; // macro quoting not properly closed
            q:=posEx(MARKER_QUOTE, fullMacro, q+1);
            end;
          until (q = 0) or (o < q);
        // eventually skip this chunk of string
        if o < u then
          begin // yes, this SEP is quoted
          o:=u;
          continue;
          end;
        end;
      // ok, that's a valid SEP, so we collect this as a parameter 
      pars.add(substr(fullMacro, i, o-1));
      i:=o+length(MARKER_SEP);
      until false;
    pars.add(substr(fullMacro, i, length(fullMacro))); // last piece
    // ok, 'pars' has now been built

    // do the call, recur, and replace with the result
    s:=cb(fullMacro, pars, cbData);
    idsStack[recurLevel]:=fullmacro; // keep track of what we recur on
    try
      try applyMacrosAndSymbols2(s, cb, cbData, idsStack, recurLevel) except end;
    finally idsStack[recurLevel]:='' end;
    result:=replace(txt, s, from, to_);
    end; // expand

  const
    ID2TAG: array [0..MAX_MARKER_ID] of string = (MARKER_QUOTE, MARKER_UNQUOTE, MARKER_OPEN, MARKER_CLOSE);
  type
    TstackItem = record
      pos: integer;
      row, col: word;
      quote: boolean;
      end;
  var
    i, lastNL, row, m, t: integer;
    stack: array of TstackItem;
    Nstack: integer;
  begin
  setLength(stack, length(txt) div length(MARKER_OPEN)); // it will never need more than this
  Nstack:=0;
  pars:=TstringList.create;
  try
    i:=1;
    row:=1;
    lastNL:=0;
    while i <= length(txt) do
      begin
      if txt[i] = #10 then
        begin
        inc(row);
        lastNL:=i;
        end;
      for m:=0 to MAX_MARKER_ID do
        begin
        if not strAt(txt, ID2TAG[m], i) then continue;
        case m of
          QUOTE_ID,
          OPEN_ID:
            begin
            if (m = OPEN_ID) and (Nstack > 0) and stack[Nstack-1].quote then continue; // don't consider quoted OPEN markers
            stack[Nstack].pos:=i;
            stack[Nstack].quote:= m=QUOTE_ID;
            stack[Nstack].row:=row;
            stack[Nstack].col:=i-lastNL;
            inc(Nstack);
            end;
          CLOSE_ID:
            begin
            if Nstack = 0 then
              raise EtplError.create('unmatched marker', copy(txt,i,30), row, i-lastNL);
            if (Nstack > 0) and stack[Nstack-1].quote then continue; // don't consider quoted CLOSE markers
            t:=length(MARKER_CLOSE);
            inc(i, t-1+expand(stack[Nstack-1].pos, i+t-1));
            dec(Nstack);
            end;
          UNQUOTE_ID:
            begin
            if (Nstack = 0) or not stack[Nstack-1].quote then continue;
            dec(Nstack);
            end;
          end;
        end;//for
      inc(i);
      end;
  finally pars.free end;
  if Nstack > 0 then
    with stack[Nstack-1] do
      raise EtplError.create('unmatched marker', copy(txt,pos,30), row, col)
  end; // handleMacros

begin
if recurLevel > MAX_RECUR_LEVEL then exit;
inc(recurLevel);
handleSymbols();
handleMacros();
end; //applyMacrosAndSymbols2

procedure applyMacrosAndSymbols(var txt:string; cb:TmacroCB; cbData:pointer; removeQuotings:boolean=TRUE);
var
  idsStack: TparserIdsStack;
begin
enforceNUL(txt);
applyMacrosAndSymbols2(txt,cb,cbData,idsStack);
if removeQuotings then
  txt:=xtpl(txt, [MARKER_QUOTE, '', MARKER_UNQUOTE, ''])
end;

function findMacroMarker(s:string; ofs:integer=1):integer;
begin result:=reMatch(s, '\{[.:]|[.:]\}|\|', 'm!', ofs) end;

function anyMacroMarkerIn(s:string):boolean;
begin result:=findMacroMarker(s) > 0 end;

end.
