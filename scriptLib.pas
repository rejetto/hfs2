{
Copyright (C) 2002-2012  Massimo Melina (www.rejetto.com)

This file is part of HFS ~ HTTP File Server.

    HFS is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    HFS is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with HFS; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}
unit scriptLib;

interface

uses main, classesLib, iniFiles, types;

type
  TmacroData = record
    cd: TconnData;
    tpl: Ttpl;
    folder, f: Tfile;
    afterTheList, archiveAvailable, hideExt, breaking: boolean;
    aliases, tempVars: THashedStringList;
    table: TStringDynArray;
    logTS: boolean;
    end;

var
  defaultAlias: THashedStringList;
  staticVars : THashedStringList; // these scripting variables are held for the whole run-time
  eventScripts: Ttpl;

function tryApplyMacrosAndSymbols(var txt:string; var md:TmacroData; removeQuotings:boolean=true):boolean;
function macroQuote(s:string):string;
function runScript(script:string; table:TstringDynArray=NIL; tpl_:Ttpl=NIL; f:Tfile=NIL; folder:Tfile=NIL; cd:TconnData=NIL):string;
function runEventScript(event:string; table:TStringDynArray=NIL; cd:TconnData=NIL):string;
procedure resetLog();

implementation

uses windows, utilLib, trayLib, parserLib, graphics, classes, sysutils, StrUtils,
  hslib, comctrls, math, controls, forms, clipbrd, MMsystem;

const
  HEADER = '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><style>'
  +#13'dt, dd { margin:0; padding:0.2em 0.5em; white-space:pre; display:block; font-family:monospace; } dt { background:#dfd; } dd { background:#fdd; }'
  +#13'</style></head><body>';

var
  stopOnMacroRename: boolean; // this ugly global var is used to avoid endless recursion on a renaming rename event. this method won't work on a multithreaded system, but i opted for it because otherwise the changes would have been big.
  cachedTpls: TcachedTpls;

function macrosLog(textIn, textOut:string; ts:boolean=FALSE):boolean;
var
  s: string;
begin
s:='';
if ts then
    s:='<hr>'+dateTimeToStr(now())+CRLF;
s:=s+#13'<dt>'+htmlEncode(textIn)+'</dt><dd>'+htmlEncode(textOut)+'</dd>';
if sizeOfFile(MACROS_LOG_FILE) = 0 then
  s:=HEADER+s;
result:=appendTextFile(MACROS_LOG_FILE, s);
end; // macrosLog

procedure resetLog();
begin saveFile(MACROS_LOG_FILE, '') end;

function expandLinkedAccounts(account:Paccount):TStringDynArray;
var
  i: integer;
begin
result:=NIL;
if account = NIL then exit;
i:=0;
result:=account.link;
while i < length(result) do
  begin
  account:=getAccount(result[i], TRUE);
  inc(i);
  if (account = NIL) or not account.enabled then continue;
  addUniqueArray(result, account.link);
  end;
end; // expandLinkedAccounts

function encodeMarkers(s:string):string;
var
  i: integer;
  t: string;
begin
for i:=0 to length(MARKERS)-1 do
  begin
  t:=MARKERS[i];
  replace(t, '&#'+intToStr(charToUnicode(t[1]))+';', 1,1);
  s:=replaceStr(s, MARKERS[i], t);
  end;
result:=s;
end; // encodeMarkers

function noMacrosAllowed(s:string):string;
// prevent hack attempts
var
  i: integer;
begin
i:=1;
enforceNUL(s);
  repeat
  i:=findMacroMarker(s, i);
  if i = 0 then break;
  replace(s, '&#'+intToStr(charToUnicode(s[i]))+';', i,i);
  until false;
s:=reReplace(s,'%([-a-z0-9]+%)','&#37;$1', 'mi');
result:=s;
end; // noMacrosAllowed

function isMacroQuoted(s:string):boolean;
begin result:=ansiStartsStr(MARKER_QUOTE, s) and ansiEndsStr(MARKER_UNQUOTE, s) end;

function macroQuote(s:string):string;
var
  t: string;
begin
enforceNUL(s);
if not anyMacroMarkerIn(s) then
  begin
  result:=s;
  exit;
  end;
// an UNQUOTE would invalidate our quoting, so let's encode any of it
t:=MARKER_UNQUOTE;
replace(t, '&#'+intToStr(charToUnicode(t[1]))+';', 1,1);
result:=MARKER_QUOTE+replaceStr(s, MARKER_UNQUOTE, t)+MARKER_UNQUOTE
end; // macroQuote

function macroDequote(s:string):string;
begin
result:=s;
s:=trim(s);
if isMacroQuoted(s) then
  result:=copy(s, length(MARKER_QUOTE)+1, length(s)-length(MARKER_QUOTE)-length(MARKER_UNQUOTE) );
end; // macroDequote

function cbMacros(fullMacro:string; pars:Tstrings; cbData:pointer):string;
var
  md: ^TmacroData;
  name, p: string;
  unnamedPars: integer; // this is a guessing of the number of unnamed parameters. just guessing because there's no true distinction between a parameter "value" named "key", and parameter "key=value"

  procedure macroError(msg:string);
  begin result:='<div class=macroerror>macro error: '+name+nonEmptyConcat('<br>',msg)+'</div>' end;

  procedure deprecatedMacro(what:string=''; instead:string='');
  begin mainfrm.add2log('WARNING, deprecated macro: '+first(what, name)+nonEmptyConcat(' - Use instead: ',instead), NIL, clRed) end;

  function satisfied(p:pointer):boolean;
  begin
  result:=assigned(p);
  if not result then
    macroError('cannot be used here');
  end;

  procedure unsatisfied(b:boolean=TRUE);
  begin if b then macroError('cannot be used here') end;

  function parEx(idx:integer; name:string=''; doTrim:boolean=TRUE):string; overload;
  var
    i: integer;
  begin
  result:='';
  if name > '' then
    begin
    i:=pars.IndexOfName(name);
    if i >= 0 then
      begin
      result:=pars.valueFromIndex[i];
      if doTrim then result:=trim(result);
      exit;
      end;
    end;
  if (idx < 0) // no numeric index accept
  or (idx >= pars.count) // invalid index
  or (name > '') and (pars.names[idx] > '') and not anycharIn(' '#13#10, pars.names[idx]) // this numerical index was already taken by a valid mnemonic name
  then
    raise Exception.create('invalid parameter index');
  result:=pars[idx];
  if doTrim then result:=trim(result);
  end; // parEx

  function parEx(name:string; doTrim:boolean=TRUE):string; overload;
  begin result:=parEx(-1, name, doTrim) end;

  function par(idx:integer; name:string=''; doTrim:boolean=TRUE):string; overload;
  begin
  try result:=parEx(idx, name, doTrim)
  except result:='' end
  end;

  function par(name:string=''; doTrim:boolean=TRUE; defval:string=''):string; overload;
  begin
  try result:=parEx(-1, name, doTrim)
  except result:=defval end
  end;

  function parI(idx:integer):int64; overload;
  begin result:=strToInt64(par(idx)) end;

  function parI(idx:integer; def:int64):int64; overload;
  begin result:=strToInt64Def(par(idx), def) end;

  function parI(name:string; def:int64):int64; overload;
  begin result:=strToInt64Def(par(name), def) end;

  function parF(idx:integer):extended; overload;
  begin result:=strToFloat(par(idx)) end;

  function parF(idx:integer; def:extended):extended; overload;
  begin result:=strToFloatDef(par(idx), def) end;

  function parF(name:string; def:extended):extended; overload;
  begin result:=strToFloatDef(par(name), def) end;

  // note this function works on N parameters
  function parExist(names: array of string):boolean;
  var
    i: integer;
  begin
  result:=FALSE;
  for i:=0 to length(names)-1 do
    if pars.indexOfName(names[i]) < 0 then
      exit;
  result:=TRUE;
  end; // parExist

  procedure trueIf(condition:boolean);
  begin if condition then result:='1' else result:='' end;

  // this is for cases where normally we want a "clean" output. User can still detect outcome by using macro "length".
  // Reason for having this instead of using in place a simple "result:=if_(cond, ' ')" is to evidence our purpose. It's not faster or cleaner, it's more semantic.
  procedure spaceIf(condition:boolean);
  begin if condition then result:=' ' else result:='' end;

  function isFalse(s:string):boolean;
  begin result:=(s='') or (strToFloatDef(s,1) = 0) end;

  function isTrue(s:string):boolean; inline;
  begin result:=not isFalse(s) end;

  function getVarSpace(var varname:string):THashedStringList;
  begin
  varname:=trim(varname);
  if ansiStartsStr(G_VAR_PREFIX, varname) then
    begin
    result:=staticVars;
    delete(varname,1,length(G_VAR_PREFIX));
    end
  else if satisfied(md.cd) then
    result:=md.cd.vars
  else if satisfied(md.tempVars) then
    result:=md.tempVars
  else
    raise Exception.create('no namespace available');
  end; // getVarSpace

  function getVar(varname:string):string; overload;
  begin result:=getVarSpace(varname).values[varname] end;

  // if par with name exists, then it's a var name, otherwise it's a constant value at specified index
  function parVar(parname:string; idx:integer):string; overload;
  begin
  if parExist([parname]) then
    result:=getVar(par(parname))
  else
    result:=pars[idx];
  end; // parVar

  function setVar(varname, value:string; space:THashedStringList=NIL):boolean;
  var
    o: Tobject;
    i: integer;
  begin
  result:=FALSE;
  if space = NIL then
    space:=getVarSpace(varname);
  if not satisfied(space) then exit;
  i:=space.indexOfName(varname);
  if i < 0 then
    if value = '' then exit // all is good the way it is
    else i:=space.add(varname+'='+value)
  else
    if value > '' then // in case of empty value, there's no need to assign, because we are going to delete it (after we cleared the bound object)
      space.valueFromIndex[i]:=value;

  assert(i >= 0, 'setVar: i<0');
  // the previous hash object linked to this data is not valid anymore, and must be freed
  o:=space.objects[i];
  freeAndNIL(o);

  if value = '' then
    space.delete(i)
  else
    space.objects[i]:=NIL;
  result:=TRUE;
  end; // setVar

  // we wrap pos() to switch between case sensitivity
  function pos_(caseSensitive:boolean; ss, s:string; ofs:integer=1):integer;
  begin
  if caseSensitive then result:=posEx(ss,s,ofs)
  else result:=ipos(ss,s,ofs)
  end; // pos_

  procedure allLogic(isAnd:boolean); // when not "isAnd", then it isOr ;-)
  var
    i: integer;
  begin
  // AND will return first FALSE value, or having none, the last TRUE value.
  // OR will return last TRUE value, or having none, last value. 
  result:='';
  for i:=0 to pars.count-1 do
    begin
    result:=par(i);
    if isAnd xor isTrue(result) then exit;
    end;
  end; // allLogic

  procedure substring();
  var
    i, j: integer;
    s: string;
    what2inc: integer;
    caseSens: boolean;
  begin
  result:='';

  // input what to be included in the result
  s:=par('include');
  try what2inc:=strToInt(s)
  except // we also support the following values
    if s = 'none' then what2inc:=0
    else if s = 'both' then what2inc:=3
    else if s = '1+2' then what2inc:=3
    else what2inc:=1; // by default we include only the first delimiter
    end;

  caseSens:=isTrue(par('case'));

  // find the delimiters
  s:=macroDequote(par(2));
  if pars[0] = '' then i:=1
  else i:=pos_(caseSens, pars[0], s); // we don' trim this, so you can use blank-space as delimiter
  if i = 0 then exit;
  j:=pos_(caseSens, pars[1], s, i+1);
  if j = 0 then j:=length(s)+1;

  // apply what2inc
  if what2inc and 1 = 0 then
    inc(i, length(pars[0]));
  if what2inc and 2 > 0 then
    inc(j, length(pars[1]));

  // end of the story
  result:=macroQuote(copy(s, i, j-i));
  end; // substring

  procedure switch();
  var
    what, sep: string;
    i, j: integer;
    a: TStringDynArray;
  begin
  what:=par(0);
  sep:=first(pars[1], ' '); // we don' trim this, so you can use blank-space as separator
  i:=2;
  while i < pars.count do
    begin
    if i = pars.count-1 then
      begin
      result:=macroDequote(par(i));
      exit;
      end;
    a:=split(sep, par(i));
    for j:=0 to length(a)-1 do
      if sameText(a[j], what) then
        begin
        result:=macroDequote(par(i+1));
        exit;
        end;
    inc(i, 2);
    end;
  result:='';
  end; // switch

  procedure cut();
  var
    from, upTo, l: integer;
    s, v: string;
  begin
  v:=par('var');
  if v = '' then
    s:=par(2,'what')
  else
    s:=getVar(v);
  l:=length(s);

  from:=strToIntDef(par(0,'from'), 1);
  if from < 0 then from:=l+from+1;

  try upTo:=strToInt(parEx('to'))
  except
    upTo:=strToIntDef(par(1,'size'), 0);
    if upTo = 0 then
      upTo:=l
    else if upTo > 0 then
      upTo:=from+upTo-1
    else
      upTo:=l+upTo;
    end;
    
  result:=substr(s, from, upTo);
  try setVar(parEx('remainder'), substr(s,1,from-1)+substr(s,upTo+1));
  except end;
  if v = '' then exit;
  setVar(v, result);
  result:='';
  end; // cut

  procedure minOrMax();
  var
    i: integer;
    r, v: real;
    min: boolean;
  begin
  min:=name='min';
  r:=parF(0);
  for i:=1 to pars.Count-1 do
    begin
    v:=parF(i);
    if (v < r) and min
    or (v > r) and not min then
      r:=v;
    end;
  result:=floatToStr(r);
  end; // minOrMax

  procedure getUri();
  var
    i, ex, eq: integer;
    vars: Tstrings;
    s: string;
  begin
  if not satisfied(md.cd) then exit;
  try
    result:=md.cd.conn.request.url;
    if pars.count < 2 then exit;
    s:=result;
    result:=chop('?', s);
    vars:=TstringList.create();
    try
      vars.delimiter:='&';
      vars.quoteChar:=#0;
      vars.delimitedText:=s;
      if pars.count > 1 then
        for i:=1 to pars.count-1 do
          begin
          s:=par(i);
          if s = '' then continue;
          eq:=pos('=', s);
          if eq = 0 then
            begin
            if vars.indexOf(s) < 0 then
              vars.add(pars[i]);
            continue;
            end;
          ex:=vars.indexOfName(chop(eq,s));
          if ex < 0 then
            if s = '' then
              continue   // the parameter didn't exist, and we are trying to empty it
            else
              vars.add(par(i))  // didn't exist, put the whole
          else
            if s = '' then
              vars.delete(ex) //  exists, but we are trying to empty it
            else
              vars.valueFromIndex[ex]:=s; // exists, change the value
          end;
      if vars.count = 0 then exit;
      for i:=vars.Count-1 downto 0 do
        if vars[i] = '' then
          vars.delete(i);
      result:=result+'?'+vars.delimitedText;
    finally vars.free end;
  finally result:=macroQuote(result) end;
  end; // getUri

  procedure section(ofs:integer);
  var
    t: Ttpl;
    s: string;
  begin
  if not satisfied(md.tpl) then exit;
  s:=par(ofs);
  if (par('file') = '') and ((s = '') or (pos('=',s) > 0)) then
    begin // current template
    result:='';
    t:=md.tpl;
    ofs:=parI('back', 0);
    while ofs > 0 do
      begin
      dec(ofs);
      t:=t.over;
      if t = NIL then exit;
      end;
    try result:=t[p] except end;
    exit;
    end;
  // template in other file

  t:=Ttpl.create;
  try
    t.fullText:=loadTextFile(par(ofs, 'file'));
    result:=t[p];
  finally t.free end;
  // templates outside hfs folder get quoted for security reasons
  if anyCharIn('\/', par(ofs)) then
    result:=macroQuote(result);
  end; // section

  function urlVar(k:string):string;
  var
    s: string;
  begin
  if not satisfied(md.cd) then exit;
  s:=md.cd.urlvars.values[k];
  if (s = '') and (md.cd.urlvars.indexOf(k) >= 0) then s:='1';
  try
    result:=noMacrosAllowed(s);
    setVar(parEx('var'), result); // if no var is specified, it will break here, and result will have the value
    result:='';
  except end;
  end; // urlVar

  function maybeUrlvar(k:string):string;
  begin
  if (k = '') or (k[1] <> '?') then result:=k
  else result:=urlvar(copy(k,2,MAXINT));
  end; // maybeUrlvar

  function compare(op,p1,p2:string):boolean;
  var
    r1,r2: double;
    c: integer;
  begin
  try
    r1:=StrToFloat(p1);
    r2:=StrToFloat(p2);
    c:=compare_(r1,r2)
  except
    c:=ansiCompareText(p1,p2);
    end;
  if op = '=' then result:= c=0
  else if op = '>' then result:= c>0
  else if op = '<' then result:= c<0
  else if op = '>=' then result:= c>=0
  else if op = '<=' then result:= c<=0
  else if (op = '<>') or (op = '!=') then result:= c<>0
  else result:=FALSE;
  end; // compare

  procedure infixOperators(ops:array of string);
  var
    i, j: integer;
    s: string;
  begin
  if pars.count > 0 then exit;
  for i:=0 to length(ops)-1 do
    begin
    j:=pos(ops[i], name);
    if j = 0 then continue;
    s:=trim(chop(j, length(ops[i]), name));
    trueIf(compare(ops[i], maybeUrlvar(s), maybeUrlvar(trim(name))));
    exit;
    end;
  end; // infixOperators

  procedure call(code:string; ofs:integer=0);
  var
    i: integer;
  begin
  result:=code;
  if pars.count=0 then
    exit;
  for i:=ofs to pars.Count-1 do
    result:=replaceStr(result, format('$%d',[i-ofs+1]), pars[i]);
  for i:=pars.count to pars.count+5 do
    result:=replaceStr(result, format('$%d',[i-ofs+1]), '');
  end; // call

  procedure breadcrumbs();
  var
    e, d: string;
    ae, ad: TstringDynArray;
    i: integer;
    fld: Tfile;
    freeIt: boolean;
  begin
  freeIt:=FALSE;
  if md.f = NIL then
    fld:=md.folder
  else
    begin
    fld:=md.f.parent;
    if md.f.isTemp() then
      begin
      e:=extractFilePath(md.f.resource);
      if length(e) > 3 then
        e:=excludeTrailingPathDelimiter(e);
      if e <> fld.resource then
        begin
        fld:=Tfile.createTemp(e);
        fld.node:=md.f.node;
        freeIt:=TRUE;
        end
      end;
    end;

  if not satisfied(fld) then exit;
  e:=htmlEncode(encodeMarkers(fld.url(TRUE)));
  d:=htmlEncode(encodeMarkers(fld.getFolder()+fld.name+'/'));
  ae:=split('/', e);
  ad:=split('/', d);
  p:=macroDequote(p);
  result:='';
  e:='';
  i:=length(ae)-1;
  if ae[i] = '' then
    dec(i);
  for i:=parI('from',0) to i do
    begin
    e:=e+ae[i]+'/';
    result:=result+xtpl(p, [
      '%bread-url%', e,
      '%bread-name%', ad[i],
      '%bread-idx%', intToStr(i)
    ]);
    end;

  if freeIt then
    freeAndNIL(fld);
  end; // breadcrumbs

  procedure inc_(v:integer=+1);
  begin
  result:='';
  try setVar(p, intToStr(strToIntDef(getVar(p),0)+v*parI(1,1))) except end;
  end; // inc_

  procedure convert();
  begin
  if sameText(p, 'ansi') and sameText(par(1), 'utf-8') then
    result:=ansiToUTF8(ansistring(par(2)))
  else if sameText(p, 'utf-8') and sameText(par(1), 'ansi') then
    result:=utf8ToAnsi(ansistring(par(2)))
  end; // convert

  procedure encodeuri();
  var
    i: integer;
    cs: Tcharset;
  begin
  result:='';
  try cs:=[#0..#255]-strToCharset(parEx('only'));
  except
    cs:=['a'..'z','A'..'Z','0'..'9',',','/','#','&','?',':','$','@','=','+']
      -strToCharset(par('add'))+strToCharset(par('not'));
    end;
  for i:=1 to length(p) do
    if charInSet(p[i], cs) then
      result:=result+p[i]
    else
      result:=result+'%'+intToHex(ord(p[i]),2)
  end; // encodeuri

  procedure addFolder();
  var
    parent: Ttreenode;
    f, old: Tfile;
    fn, name: string;

    // extract the path from "name", if any, and assign it to "parent"
    function validateAndExtractParent():boolean;
    var
      i: integer;
      parentF: Tfile;
    begin
    result:=TRUE;
    i:=lastDelimiter('/',name);
    if i = 0 then exit;
    result:=FALSE;
    parentf:=mainfrm.findFilebyURL(chop(i+1, 0, name), NIL, FALSE);
    if parentf = NIL then exit;
    parent:=parentf.node; // ok, this is where we'll add the folder
    result:=TRUE;
    end; // validateAndExtractParent

  begin
  result:='';
  if not stringExists(p, ['real','virtual']) then exit;

  parent:=NIL;
  if assigned(md.folder) then
    parent:=md.folder.node;

  if p = 'virtual' then
    begin
    name:=par(1);
    if not validateAndExtractParent() then exit;
    f:=Tfile.createVirtualFolder(name);
    end
  else
    begin
    fn:=uri2diskMaybe(par(1));
    if not isAbsolutePath(fn) and assigned(md.folder) then
      fn:=expandFileName(md.folder.resource+'\'+fn);
    if not directoryExists(fn) then exit; // the real folder must exists on disk

    // is a name specified in the third parameter, or should we deduce it from the disk path?
    name:=par(2);
    if (name = '') or containsStr(name,'=') then
      name:=extractFileName(fn);

    if not validateAndExtractParent() then exit;
    f:=Tfile.create(fn);
    f.name:=name;
    end;

  if not validFilename(f.name) then
    begin
    f.free;
    exit;
    end;

  old:=mainfrm.findFilebyURL(f.name, nodeToFile(parent), FALSE);
  if assigned(old) then
    if not old.isRoot()
    and (not parExist(['overwrite']) or isTrue(par('overwrite'))) then
      try old.node.delete() except end // delete existing one
    else
      begin
      f.free;
      exit;
      end;

  if mainfrm.addFile(f, parent, TRUE) = NIL then
    f.free
  else
    spaceIf(TRUE)
  end; // addFolder

  procedure setItem();
  var
    f: Tfile;
    act: TfileAction;

    function get(prefix:string):TStringDynArray;
    begin
    result:=onlyExistentAccounts(split(';', parEx(prefix+FILEACTION2STR[act])));
    uniqueStrings(result);
    end;

    procedure setAttr(a:TfileAttribute; parName:string);
    begin
    try
      if isTrue(parEx(parname)) then
        include(f.flags, a)
      else
        exclude(f.flags, a);
    except end;
    end; // setAttr

  begin
  result:='';
  f:=mainfrm.findFileByURL(p, md.folder);
  if f = NIL then exit; // doesn't exist

  try f.setDynamicComment(macroDequote(parEx('comment'))) except end;
  try
    f.name:=parEx('name');
    if assigned(f.node) then
      f.node.text:=f.name;
  except end;
  try f.resource:=parEx('resource') except end;
  try f.diffTpl:=parEx('diff template') except end;
  try f.filesFilter:=parEx('files filter') except end;
  try f.foldersFilter:=parEx('folders filter') except end;

  // following commands make no sense on temporary items
  if freeIfTemp(f) then exit;

  setAttr(FA_HIDDEN, 'hide');
  setAttr(FA_HIDDENTREE, 'hide tree');
  setAttr(FA_DONT_LOG, 'no log');
  setAttr(FA_ARCHIVABLE, 'archivable');
  setAttr(FA_BROWSABLE, 'browsable');
  setAttr(FA_DL_FORBIDDEN, 'download forbidden');
  if f.isFolder() then
    try f.dontCountAsDownloadMask:=parEx('not as download') except end
  else
    setAttr(FA_DONT_COUNT_AS_DL, 'not as download');

  for act:=low(act) to high(act) do
    begin
    try f.accounts[act]:=get('') except end;
    try addUniqueArray(f.accounts[act], get('add ')) except end;
    try removeArray(f.accounts[act], get('remove ')) except end;
    end;
  VFSmodified:=TRUE;
  mainfrm.filesBox.repaint();
  end; // setItem

  function getItemIcon(f:Tfile):string;
  begin
  if f = NIL then
    result:=''
  else if (f.icon >= 0) or (mainfrm.useSystemIconsChk.checked and f.isFile()) then
    result:='/~img'+intToStr(f.getSystemIcon())
  else if f.isFile() then
    result:='/~img_file'
  else if f.isFolder() then
    if FA_UNIT in f.flags then
      result:=format('/~img%d', [f.getIconForTreeview()])
    else
      result:='/~img_folder'
  else if f.isLink() then
    result:='/~img_link'
  else
    result:='';
  end; // getItemIcon

  procedure deleteItem();
  var
    f: Tfile;
  begin
  f:=mainfrm.findFileByURL(p);
  spaceIf(assigned(f)); // so you can know if something really has been deleted
  if f = NIL then exit; // doesn't exist
  mainFrm.remove(f.node);
  VFSmodified:=TRUE;
  end; // deleteItem

  procedure getItem();
  var
    f: Tfile;
    act: TfileAction;
    w: string;

    function getAttr(name:string; a:TfileAttribute):boolean;
    begin
    result:= w = name;
    if result then
      trueIf(a in f.flags);
    end; // setAttr

  begin
  result:='';
  f:=mainfrm.findFileByURL(p, md.folder);
  if f = NIL then exit; // doesn't exist

  try
    w:=par(1);
    if w = 'exists' then
      result:='1'
    else if w = 'comment' then
      result:=f.getDynamicComment()
    else if w = 'resource' then
      result:=f.resource
    else if w = 'icon' then
      result:=getItemIcon(f)
    else if getAttr('hide', FA_HIDDEN)
      or getAttr('hide tree', FA_HIDDENTREE)
      or getAttr('no log', FA_DONT_LOG) then
      exit
    else if w = 'not as download' then
      if f.isFolder() then
        result:=f.dontCountAsDownloadMask
      else
        trueIf(FA_DONT_COUNT_AS_DL in f.flags);

    for act:=low(act) to high(act) do
      if compareText(w, FILEACTION2STR[act]) = 0 then
        begin
        result:=join(';', f.accounts[act]);
        exit;
        end;
  finally freeIfTemp(f) end;
  end; // getItem

  procedure foreach();
  var
    i, e: integer;
    s, code: string;
  begin
  e:=pars.count-2; // 3 parameters minimum (the check is outside)
  code:=macroDequote(par(pars.count-1));
  with TfastStringAppend.create do
    try
      for i:=1 to e do
        begin
        setVar(p, par(i));
        s:=code;
        applyMacrosAndSymbols(s, cbMacros, cbData);
        append(s);
        end;
      result:=reset();
    finally free end;
  end; // foreach

  procedure forLine();
  var
    lines: TStringList;
    line, code, run: string;
    i: integer;
  begin
  code:=macroDequote(par(pars.count-1));
  with TfastStringAppend.create do
    try
      lines:=TStringList.create();
      lines.text:= getVar(par('var'));
      for line in lines do
        begin
        i:=pos('=',line);
        if i > 0 then
          begin
          setVar('line-key', Copy(line, 1, i-1));
          setVar('line-value', Copy(line, i+1, MAXINT));
          end;
        setVar('line', line);
        run:=code;
        applyMacrosAndSymbols(run, cbMacros, cbData);
        append(run);
        end;
      result:=reset();
    finally
      Free;
      lines.Free;
      end;
  end; //forLine

  procedure for_();
  var
    b, e, i, d: integer;
    s, code: string;
  begin
  try
    b:=strToInt(par(1));
    e:=strToInt(par(2));
    try
      d:=strToInt(par(3));
      code:=par(4);
    except
      d:=1;
      code:=par(3);
      end;
    if d = 0 then exit;
    if (e < b) and (d > 0) then d:=-d; // we care
    code:=macroDequote(code);
    with TfastStringAppend.create do
      try
        for i:=1 to (e-b) div d+1 do
          begin
          setVar(p, intToStr(b));
          s:=code;
          applyMacrosAndSymbols(s, cbMacros, cbData);
          append(s);
          inc(b, d);
          end;
        result:=reset();
      finally free end;
  except end;
  end; // for_

  procedure while_();
  var
    bTest, bDo, s: string;
    never: boolean;
    res: TfastStringAppend;
    space: THashedStringList;
    start, timeout: Tdatetime;
  begin
  result:='';
  res:=TfastStringAppend.create;
  try
    never:=TRUE;
    bDo:=macroDequote(par(1)); // do-block

    bTest:='';
    // test-block
    space:=NIL;
    if anyMacroMarkerIn(p) then
        bTest:=macroDequote(p)
    else
      try // lets see if the test-block is just the name of a variable
        space:=getVarSpace(p);
        bTest:=p;
      except end;

    if bTest = '' then exit;

    timeout:=parF('timeout', 1)/SECONDS; // stay safe: 1 second timeout by default
    start:=now();
      repeat
      if (timeout > 0) and (now()-start > timeout) then break;
      if assigned(space) then
        s:=space.values[bTest]
      else
        begin
        s:=bTest;
        applyMacrosAndSymbols(s, cbMacros, cbData);
        end;
      if isFalse(trim(s)) then break;
      s:=bDo;
      applyMacrosAndSymbols(s, cbMacros, cbData);
      res.append(s);
      never:=FALSE;
      until false;
    if never then
      res.append(macroDequote(par('else'))); // else-block
  finally
    result:=res.reset();
    try
      setVar(parEx('var'), result);
      result:='';
    except end;
    res.free();
    end;
  end; // while_

  procedure setEncodedTable(varname, txt:string);
  var
    space, h: ThashedStringList;
    i: integer;
  begin
  chopLine(txt); // first line is just a useless header
  // search the variable in the varspace
  space:=getVarSpace(varname);
  if not satisfied(space) then exit;
  i:=space.indexOfName(varname);
  // eventually destroy previous object
  if i >= 0 then
    begin
    h:=space.objects[i] as ThashedStringList;
    freeAndNIL(h);
    space.objects[i]:=NIL;
    end;
  // create the table object
  h:=ThashedStringList.create();
  while txt > '' do
    h.add(unescapeNL(chopline(txt)));
  // assign the variable value
  txt:=h.text;
  if i < 0 then
    i:=space.add(varname+'='+txt)
  else
    space.valueFromIndex[i]:=txt;
  // link the object
  space.objects[i]:=h;
  end; // setEncodedTable

  procedure load(fn:string; varname:string='');
  var
    from, size: int64;
  begin
  result:='';
  from:=parI('from', 0);
  // 'size' has priority over 'to'
  size:=parI('size', -1);
  if size = -1 then
    begin
    size:=parI('to', -1);
    if size >= 0 then
      inc(size, 1-from);
    end;
  if size = 0 then exit;
  from:=max(0,from);

  if reMatch(fn, '^https?://', 'i!') > 0 then
    try result:=httpGet(fn, from, size)
    except result:='' end
  else
    result:=loadFile(uri2diskMaybe(fn), from, size);

  if varname = '' then
    begin
    if anyCharIn('/\',fn) then result:=macroQuote(result);
    exit;
    end;
  if ansiStartsStr(ENCODED_TABLE_HEADER, result) then
    setEncodedTable(varname, result)
  else
    setVar(varname, result);
  result:='';
  end; // load

  function uri2diskMaybeFolder(s:string):string; // like uri2diskMaybe, but limited to the path, excluding the filename
  var
    path: string;
  begin
  if ansiContainsStr(s, '/') then
    begin
    path:=uri2disk(chop(lastDelimiter('/\',s)+1, 0, s), md.folder);
    if path > '' then
      s:=path+'\'+trim(s); // mod by mars
    end;
  result:=s;
  end; // uri2diskMaybeFolder

  procedure save();
  var
    space, h: THashedStringList;
    s: string;
    i: integer;
    encode: boolean;
  begin
  result:='';
  if not parExist(['var']) then // will we work with a variable?
    s:=pars[1]
  else
    begin
    s:=par('var');
    space:=getVarSpace(s);
    if not satisfied(space) then exit;

    i:=space.indexOfName(s);
    if i < 0 then exit; // this var doesn't exit. don't write.
    encode:=FALSE;
    // if this is used as table, and has newlines, we must encode it to preserve associations
    h:=space.objects[i] as THashedStringList;
    if assigned(h) then
      for i:=0 to h.count-1 do
        if anyCharIn([#13,#10], h.strings[i]) then
          begin
          encode:=TRUE;
          break;
          end;
    if not encode then
      s:=space.valueFromIndex[i]
    else
      with TfastStringAppend.create do
        try // table must be codified, or they won't work at load-time
          append(ENCODED_TABLE_HEADER);
          for i:=0 to h.count-1 do
            append(escapeNL(h.strings[i])+CRLF);
          s:=get();
        finally free end;
    end;
  // now we have in 's' the content to be saved
  spaceIf(saveTextFile(uri2diskMaybeFolder(p), s, name='append'));
  end; // save

  procedure replace();
  var
    i: integer;
    v: string;
  begin
  try
    v:=parEx('var');
    result:=getVar(v);
  except result:=pars[pars.count-1] end;

  i:=0;
  while i < pars.count-2 do
    begin
    result:=replaceText(result, pars[i], pars[i+1]);
    inc(i, 2);
    end;
  if v = '' then exit;
  setVar(v, result);
  result:='';
  end; // replace

  procedure dialog();
  const
    STR2CODE: array [1..7] of string = (
      'okcancel=1',
      'yesno=4',
      'yesnocancel=3',
      'error=16',
      'question=32',
      'warning=48',
      'information=64'
    );
  var
    i, j, code: integer;
    decode: TStringDynArray;
    s: string;
    buttons, icon: boolean;
  begin
  decode:=split(' ',par(1));
  code:=0;
  for i:=0 to length(decode)-1 do
    for j:=1 to length(STR2CODE) do
      begin
      s:=STR2CODE[j];
      if ansiStartsStr(decode[i], s) then
        inc(code, strToIntDef(substr(s, 1+pos('=',s)), 0));
      end;
  buttons:=code AND 15 > 0;
  icon:=code SHR 4 > 0;
  if not icon and buttons then
    inc(code, MB_ICONQUESTION);
  case msgDlg(p, code, par(2)) of
    MRYES, MROK: result:=if_(buttons, '1'); // if only OK button is available, then return nothing
    MRCANCEL: result:=if_(code and MB_YESNOCANCEL = MB_YESNOCANCEL, 'cancel'); // for the YESNOCANCEL, we return cancel to allow to tell NO from CANCEL
    else result:='';
    end;
  end; // dialog

  procedure setAccount();
  var
    a: Paccount;
    s: string;
  begin
  result:='';
  if p > '' then
    a:=getAccount(p, TRUE)
  else
    a:=md.cd.account;
  if a = NIL then exit;
  spaceIf(TRUE);

  try
    s:=parEx('password');
    if validUsername(s, TRUE) then
      a.pwd:=s;
  except end;

  try
    s:=parEx('newname');
    if validUsername(s) then
      a.user:=s;
  except end;

  try a.redir:=parEx('redirect') except end;
  try a.noLimits:=isTrue(parEx('no limits')) except end;
  try a.enabled:=isTrue(parEx('enabled')) except end;
  try a.group:=isTrue(parEx('is group')) except end;
  try a.link:=split(';',parEx('member of')) except end;
  try addArray(a.link, split(';',parEx('add member of'))) except end;
  try removeArray(a.link, split(';',parEx('remove member of'))) except end;
  try a.notes:=parEx('notes') except end;
  try a.notes:=setKeyInString(a.notes, parEx('notes key')) except end;
  end; // setAccount

  procedure getterAccount();
  var
    a: Paccount;
    s: string;
  begin
  result:='';
  if p > '' then
    a:=getAccount(p, TRUE)
  else
    a:=md.cd.account;
  if a = NIL then exit;
  s:=lowercase(par(1));
  if s = 'redirect' then result:=a.redir
  else if s = 'no limits' then trueIf(a.nolimits)
  else if s = 'enabled' then trueIf(a.enabled)
  else if s = 'is group' then trueIf(a.group)
  else if s = 'member of' then result:=join(';',a.link)
  else if s = 'notes' then result:=a.notes
  else if s = 'password' then result:=a.pwd
  else if s = 'password is' then trueIf((a.pwd=pars[2]) or (trim(a.pwd)=par(2)))  //add by mars
  else if s = 'exists' then result:='1';
  try result:=getKeyFromString(a.notes, parEx('notes key')) except end;
  end; // getterAccount

  procedure newAccount();
  var
    a: Taccount;
  begin
  result:='';
  if accountExists(p, TRUE) then exit; // username already in use
  if not validUsername(p) then exit;
  fillchar(a, sizeof(a), 0); // the account is disabled by default
  a.user:=p;
  setLength(accounts, length(accounts)+1);
  accounts[length(accounts)-1]:=a;
  setAccount();
  end; // newAccount

  function fromTable(tbl, k:string):string;
  var
    i: integer;
    space, h: THashedStringList;
    s: string;
  begin
  result:='';
  if tbl = 'ini' then deprecatedMacro('from table|ini','from table|#ini');
  try space:=getVarSpace(tbl);
  except exit end;
  if not satisfied(space) then exit;
  i:=space.indexOfName(tbl);
  if (i < 0) and ansiStartsStr('$', tbl) then
    begin
    s:=md.tpl[copy(tbl,2,MAXINT)];
    if s = '' then exit;
    i:=space.add(tbl+'='+s);
    end;
  if i < 0 then exit;
  // the text of the table is converted to a hashed structure, and cached through the objects[] property
  h:=space.objects[i] as THashedStringList;
  if h = NIL then
    begin
    h:=ThashedStringList.create();
    h.text:=space.valueFromIndex[i];
    space.objects[i]:=h;
    end;
  result:=h.values[k];
  // we are reading a value from the ini, so we convert the 'no' to a valid false value (the empty string)
  if stringExists(tbl, ['ini','#ini']) and (result = 'no') then result:='';
  end; // fromTable

  procedure setTable();
  var
    i: integer;
    k, v: string;
    space, h: THashedStringList;
  begin
  result:='';
  space:=getVarSpace(p);
  if not satisfied(space) then exit;
  // set the table variable as text
  v:=par(1);
  space.values[p]:=nonEmptyConcat('', space.values[p], CRLF)+v;
  // access the table object
  i:=space.indexOfName(p);
  h:=space.objects[i] as THashedStringList;
  if h = NIL then
    begin
    h:=ThashedStringList.create();
    space.objects[i]:=h;
    end;
  // fill the object
  k:=chop('=',v);
  v:=macroDequote(v);
  h.values[k]:=v;
  end; // setTable

  procedure disconnect();
  var
    i: integer;
    ipmask, portmask: string;
  begin
  if pars.count = 0 then
    begin
    if satisfied(md.cd) then
      md.cd.conn.disconnect();
    exit;
    end;
  ipmask:=par(0,'ip');
  portmask:=par(1,'port');
  if ipmask = '' then exit;
  for i:=0 to srv.conns.count-1 do
    with conn2data(i) do
      if addressmatch(ipmask, address)
      and ((portmask = '') or filematch(portmask, conn.port)) then
        conn.disconnect();
  result:='';
  end; // disconnect

  procedure vardomain();
  var
    space: ThashedStringList;
    sep: string;
    i: integer;
    fs: TfastStringAppend;
    values: boolean;
  begin
  fs:=TfastStringAppend.create;
  try
    values:=sameText(par('get'), 'values');
    sep:=par('separator', FALSE, '|');
    space:=getVarSpace(p);
    for i:=0 to space.count-1 do
      if ansiStartsText(p, space.names[i]) then
        begin
        if fs.length > 0 then
          fs.append(sep);
        if values then
          fs.append(space.valueFromIndex[i])
        else
          fs.append(space.names[i]);
        end;
    result:=fs.get();
  finally fs.free end;
  end; // vardomain

  procedure exec_();
  var
    s: string;
    code: cardinal;
  begin
  s:=macroDequote(par(1));
  if fileOrDirExists(s) then
    s:=quoteIfAnyChar(' ', s)
  else
    if unnamedPars < 2 then
      s:='';
  if parExist(['out']) or parExist(['timeout']) or parExist(['exit code']) then
    try
      spaceIf(captureExec(macroDequote(p)+nonEmptyConcat(' ', s), s, code, parF('timeout',2)));
      try setVar(parEx('exit code'), intToStr(code)) except end;
      setVar(parEx('out'), s);
    except end
  else
    spaceIf(exec(macroDequote(p), s))
  end; // exec_

  procedure memberOf();
  var
    a: Paccount;
    s: string;
  begin
  result:='';
  s:=par(1, 'user');
  if s > '' then
    a:=getAccount(s, TRUE)
  else if assigned(md.cd) then
    a:=md.cd.account
  else
    exit;
  s:=par(0,'group');
  if s = '' then // you don't tell me the group, i'll tell you the groups
    begin
    result:=join(';',expandLinkedAccounts(md.cd.account));
    exit;
    end;
  a:=findEnabledLinkedAccount(a, split(';',s));
  if assigned(a) then result:=a.user;
  end; // memberOf

  procedure canArchive(f:Tfile);
  begin trueIf(assigned(f) and f.hasRecursive(FA_ARCHIVABLE) or (f = NIL) and md.archiveAvailable) end;

  procedure actionAllowed(action:TfileAction);
  var
    f: Tfile;
    local: boolean;
  begin // note: "delete" is meant for files inside the folder bearing the permission
  local:=FALSE;
  result:='';
  try
    f:=mainfrm.findFileByURL(parEx('path'), md.folder);
    if f = NIL then exit;
    local:=TRUE;
  except
    if action = FA_ACCESS then f:=md.f
    else f:=md.folder;
    end;
  trueIf(accountAllowed(action, md.cd, f));
  if local then
    freeIfTemp(f);
  end; // actionAllowed

  procedure cookie();

    function timeForCookies(v:string):string;
    var
      t: Tdatetime;
    begin
    try
      if charInSet(getFirstChar(v), ['+','-']) then
        t:=now()+strToFloat(v)
      else
        try t:=maybeUnixTime(strToFloat(v));
        except t:=strToDateTime(v) end;
      result:=dateToHTTP(localToGMT(t));
    except result:=v end;
    end; // timeForCookies

    function getPairs():TStringDynArray;
    var
      i: integer;
      k, v: string;
    begin
    result:=NIL;
    for i:=1 to pars.count-1 do
      begin
      v:=pars[i];
      k:=trim(chop('=', v));
      v:=trim(v);
      if k = 'value' then // this is handled below
        continue
      else if k = 'expires' then
        v:=timeForCookies(v);
      addArray(result, [k, v]);
      end;
    end; // getPairs

  begin
  if not satisfied(md.cd) then exit;
  result:='';
  try md.cd.conn.setCookie(p, parEx('value'), getPairs());
  except result:=noMacrosAllowed(md.cd.conn.getCookie(p)) end; // there was no "value" to set, so just read
  end; // cookie

  procedure regexp();
  var
    subs: TStringDynArray;
    subj, s, mods: string;
    i: integer;
  begin
  // input from variable or text
  try subj:=getVar(parEx('var'));
  except subj:=par(1) end;
  // check
  mods:='m'+if_(isFalse(par('case')),'i');
  p:=macroDequote(p);
  i:=reMatch(subj, p, mods, 1, @subs);
  if i <= 0 then
    begin
    result:='';
    exit;
    end;
  // return first match, or position
  if assigned(subs) then
    result:=subs[min(length(subs)-1,1)]
  else
    result:=intToStr(i);
  // eventually communicate matched substrings
  try
    parEx('sub');
    s:='';
    for i:=0 to length(subs)-1 do
      s:=s+format('%d=%s'+CRLF, [i, subs[i]]);
    setVar(parEx('sub'), s);
  except end;

  try
    result:=reReplace(subj, p, parEx('replace'), mods);
    setVar(parEx('var'), result); // we put the output where we got the input
    result:='';
  except end;
  end; // regexp

  procedure dir();
  var
    sr: TSearchRec;
    fs: TfastStringAppend;
    sep, s: string;
  begin
  result:='';
  // user can specify a file mask, or a folder path
  s:=excludeTrailingPathDelimiter(p);
  if directoryExists(s) then
    s:=s+'\*';
  if findfirst(s, faAnyFile, sr) <> 0 then exit;

  sep:=par('separator', FALSE, '|');
  try
    fs:=TfastStringAppend.create();
      repeat
      if (sr.name = '.') or (sr.name = '..') then continue;
      if fs.length > 0 then
        fs.append(sep);
      fs.append(sr.name);
      until findNext(sr) <> 0;
    result:=fs.get();
  finally
    findClose(sr);
    freeAndNIL(fs);
    end;
  end; // dir

  procedure handleSymbol();
  var
    s, usr: string;
    i: integer;
  begin
  // search for the symbol in the translation table
  i:=length(md.table)-2;
  if odd(i) then dec(i); // ensure the table has a legal length
  while (i >= 0) and not sameText(md.table[i], name) do
    dec(i,2);
  if i >= 0 then
    begin
    result:=md.table[i+1];
    exit;
    end;

  result:=name; // by default, an unrecognized symbol remains the same (just as the song)

  // most symbols here, are here because they can be heavy to calculate, so we ensure we do
  // it only upon request. others are for centralization.

  if ansiStartsText('%sym-', name) then // legacy: surpassed by {.section.}
    result:=tpl[substr(name,2,-1)]
  else if name = '%item-icon%' then
    result:=first(getItemIcon(md.f), name)
  else if name = '%item-archive%' then
    if assigned(md.f) and assigned(md.tpl) and md.f.hasRecursive(FA_ARCHIVABLE) then result:=md.tpl['item-archive']
    else result:=''
  else if name = '%item-dl-count%' then
    if md.f = NIL then result:=''
    else result:=intToStr(md.f.DLcount)
  else if name = '%connections%' then
    result:=intToStr(srv.conns.count)
  else if name = '%style%' then
    result:=tpl['style']
  else if name = '%timestamp%' then
    result:=dateTimeToStr(now())
  else if name = '%date%' then
    result:=dateToStr(now())
  else if name = '%time%' then
    result:=timeToStr(now())
  else if name = '%now%' then
    result:=floatToStr(now())
  else if name = '%version%' then
    result:=main.VERSION
  else if name = '%build%' then
    result:=VERSION_BUILD
  else if name = '%uptime%' then
    result:=uptimestr()
  else if name = '%speed-out%' then
    result:=floatToStrF(srv.speedOut/1000, ffFixed, 7,2)
  else if name = '%speed-in%' then
    result:=floatToStrF(srv.speedIn/1000, ffFixed, 7,2)
  else if name = '%total-out%' then
    result:=smartSize(outTotalOfs+srv.bytesSent)
  else if name = '%total-in%' then
    result:=smartSize(inTotalOfs+srv.bytesReceived)
  else if name = '%total-downloads%' then
    result:=intToStr(downloadsLogged)
  else if name = '%total-hits%' then
    result:=intToStr(hitsLogged)
  else if name = '%total-uploads%' then
    result:=intToStr(uploadsLogged)
  else if name = '%number-addresses%' then
    result:=intToStr(countIPs())
  else if name = '%number-addresses-ever%' then
    result:=intToStr(ipsEverConnected.count)
  else if name = '%number-addresses-downloading%' then
    result:=intToStr(countIPs(TRUE))
  else if name = '%number-users%' then
    result:=intToStr(countIPs(FALSE, TRUE))
  else if name = '%number-users-downloading%' then
    result:=intToStr(countIPs(TRUE, TRUE))
  else if name = '%cwd%' then
    result:=getCurrentDir()
  else if name = '%port%' then
    result:=srv.port;

  if assigned(md.cd) then
    begin
    usr:=md.cd.user;
    if name = '%host%' then
      result:=getSafeHost(md.cd)
    else if name = '%ip%' then
      result:=md.cd.address
    else if name = '%ip-to-name%' then
      result:=localDNSget(md.cd.address)
    else if name = '%lang%' then
      result:=stripChars(copy(md.cd.conn.getHeader('Accept-Language'),1,2), ['a'..'z','A'..'Z'], TRUE)
    else if name = '%url%' then
      result:=macroQuote(md.cd.conn.request.url)
    else if name = '%user%' then
      result:=macroQuote(usr)
    else if name = '%password%' then
      result:=macroQuote(md.cd.conn.request.pwd)
    else if name = '%loggedin%' then
      result:=if_(usr>'', tpl['loggedin'])
    else if name = '%login-link%' then
      result:=if_(usr='', tpl['login-link'])
    else if name = '%user-notes%' then
      if md.cd.account = NIL then result:=''
      else result:=md.cd.account.notes
    else if name = '%stream-size%' then
      result:=intToStr(md.cd.conn.bytesFullBody)
    else if name = '%is-archive%' then
      trueIf(md.cd.downloadingWhat=DW_ARCHIVE)
    end;


  if assigned(md.folder) then
    if name = '%folder-item-comment%' then
      result:=md.folder.getDynamicComment()
    else if name = '%folder-comment%' then
      begin
      result:=md.folder.getDynamicComment();
      if result > '' then
        result:=replaceText(tpl['folder-comment'], '%item-comment%', result)
      end
    else if name = '%diskfree%' then
      result:=smartSize(diskSpaceAt(md.folder.resource)-minDiskSpace*MEGA)
    else if name = '%up%' then
      result:=if_(assigned(md.tpl) and not md.folder.isRoot(), md.tpl['up'])
    else if name = '%encoded-folder%' then
      result:=md.folder.url(TRUE)
    else if name = '%parent-folder%' then
      result:=md.folder.parentURL()
    else if name = '%folder-name%' then
      result:=md.folder.name
    else if name = '%folder-resource%' then
      result:=md.folder.resource
    else if name = '%folder%' then
      with md.folder do result:=if_(isRoot(), '/', getFolder()+name+'/')
  ;

  if assigned(md.f) then
    if name = '%item-name%' then
      begin
      s:=md.f.name;
      if md.hideExt and md.f.isFile() then
        setLength(s, length(s)-length(extractFileExt(s)) );
      result:=htmlEncode(macroQuote(s))
      end
    else if name = '%item-type%' then
      if md.f.isLink() then
        result:='link'
      else if md.f.isFolder() then
        result:='folder'
      else
        result:='file'
   else if name = '%item-size-b%' then
      result:=intToStr(md.f.size)
   else if name = '%item-size-kb%' then
      result:=intToStr(md.f.size div KILO)
    else if name = '%item-size%' then
      result:=smartsize(md.f.size)
    else if name = '%item-resource%' then
      result:=macroQuote(md.f.resource)
    else if name = '%item-ext%' then
      result:=macroQuote(copy(extractFileExt(md.f.name), 2, MAXINT))
    else if name = '%item-added-dt%' then
      result:=floatToStr(md.f.atime)
    else if name = '%item-modified-dt%' then
      result:=floatToStr(md.f.mtime)
    // these twos are actually redundant, {.time||when=%item-added-dt%.}
    else if name = '%item-added%' then
      result:=datetimeToStr(md.f.atime)
    else if name = '%item-modified%' then
      result:=if_(md.f.mtime=0, 'error', datetimeToStr(md.f.mtime))
    else if name = '%item-comment%' then
      result:=md.f.getDynamicComment(TRUE)
    else if name = '%item-url%' then
      result:=macroQuote(md.f.url())
  ;

  if assigned(md.f) and assigned(md.tpl) then
    if name = '%new%' then
      result:=if_(md.f.isNew(), md.tpl['newfile'])
    else if name = '%comment%' then
      result:=if_(md.f.getDynamicComment(TRUE) > '', md.tpl['comment'])
  ;

  if assigned(md.tpl) then
    if name = '%archive%' then
      result:=if_(md.archiveAvailable, md.tpl['archive']);

  if ansiContainsText(name, 'folder') and not ansiContainsText(name, 'comment') then
    result:=macroQuote(result);
  end; // handleSymbol

  function stringTotrayMessageType(s:string):TtrayMessageType;
  begin
  if compareText(s,'warning') = 0 then
    result:=TM_WARNING
  else if compareText(s,'error') = 0 then
    result:=TM_ERROR
  else if compareText(s,'info') = 0 then
    result:=TM_INFO
  else
    result:=TM_NONE
  end; // stringTotrayMessageType

  function renameIt(src,dst:string):boolean;
  var
    srcReal, dstReal: string;
  begin
  srcReal:=uri2diskMaybe(src,NIL,FALSE);
  dstReal:=uri2diskMaybeFolder(dst);
  if isExtension(srcReal, '.lnk')
  and not isExtension(src, '.lnk') then
    dstReal:=dstReal+'.lnk';
  if extractFilePath(dstReal)='' then
    dstReal:=extractFilePath(srcReal)+dstReal;
  result:=renameFile(srcReal, dstReal)
  end; // renameIt

var
  i64: int64;
  i: integer;
  r: Tdatetime;
  s: string;
begin
try
  assert(assigned(cbData), 'cbMacros: cbData=NIL');
  md:=cbData;
  if md.breaking then exit;
  try

    name:=fullmacro;
    if (name[1] = '%') and (name[length(name)] = '%') then
      begin
      handleSymbol();
      exit;
      end;

    if not mainfrm.enableMacrosChk.checked then
      exit(fullMacro);

    if pars.count = 0 then exit;
    // extract first parameter as 'name'
    name:=trim(pars[0]);
    pars.delete(0);    // this operation is done with a memory move over pointers. Having few parameters normally, it's fast. We may eventually avoid this deletion and consider parameters starting from 1.
    if name = '' then exit;
    macroError('not supported or illegal parameters');
    // eventually remove trailing
    if pars.Count > 0 then
      begin
      p:=pars[pars.count-1];
      if ansiEndsText('/'+name, p) then
        begin
        setLength(p, length(p)-length(name)-1);
        pars[pars.count-1]:=p;
        end;
      end;

    unnamedPars:=0;
    for i:=0 to pars.count-1 do
      begin
      pars[i]:=replaceStr(pars[i], '{:|:}','|');
      if (i = unnamedPars) and (pos('=',pars[i]) = 0) then
        inc(unnamedPars);
      end;

    // handle aliases
    if assigned(md.aliases) then
      begin
      s:=md.aliases.values[name];
      if s > '' then
        begin
        if not ansiStartsStr(MARKER_OPEN, s) then
          s:=MARKER_OPEN+s+MARKER_CLOSE;
        call(s);
        exit;
        end;
      end;

    // here we try to handle some shortcuts.
    // it's a special starting character that identifies the macro, and the rest of the name is a parameter.
    p:=copy(name,2,MAXINT);

    if name[1] = '$' then
      section(0);

    if name[1] = '!' then
      // we look for they key (p) in {.^special:strings.} then in [special:strings]. If no luck, we try to output an eventual parameter, or the key itself.
      try result:=first([fromTable('special:strings',p), md.tpl.getStrByID(p), par(0), p]) except end;

    if name[1] = '^' then
      try call(getVar(p), 0) except end;

    if name[1] = '?' then  // shortcut for 'urlvar'
      result:=urlvar(p);

    p:=par(0); // a handy shortcut for the first parameter

    // comment is for comments, or if you just want to trash the output of a macro.
    // Careful: the comment itself (the parameter of this command) is executed as anything else, unless it's {:quoted:}
    if name = 'comment' then
      begin
      result:='';
      exit;
      end;

    // infix operators are macros in the form PARAMETER NAME PARAMETER. it's handy for comparisons.
    infixOperators(['>=','<=','<>','!=','=','>','<']); // the order is important, because >= would be confused with =

    // ok, fom here we have macros in the straight form NAME|PARAM|PARAM
    name:=ansiLowercase(name);

    if name = 'count' then
      if satisfied(md.cd) then
        result:=intToStr(md.cd.tplCounters.incInt(p)-1); // it can work even with no parameters

    if name = 'time' then
      begin
      s:=par(0,'format');
      r:=parF('when',now())+parF('offset',0);
      if s = 'y' then result:=floatToStr(r)
      else datetimeToString(result, first(s,'c'), r );
      end;

    if name = 'disconnect' then
      disconnect();

    if name = 'stop server' then
      stopServer();
    if name = 'start server' then
      startServer();


    if name = 'focus' then
      begin
      application.restore();
      application.bringToFront();
      result:='';
      end;

    if name = 'current downloads' then
      result:=intToStr( countDownloads( par('ip'), par('user'), if_(sameText(par('file'), 'this'), md.f) as Tfile) );

    if name = 'disconnection reason' then
      begin
      try
        if isFalse(parEx('if')) then
          begin
          result:='';
          exit;
          end;
      except end;
      result:=md.cd.disconnectReason; // return the previous state
      if pars.count > 0 then md.cd.disconnectReason:=p;
      end;

    if name = 'clipboard' then
      if p = '' then
        result:=clipboard.asText
      else
        begin
        try setClip(getVar(parEx('var')))
        except setClip(p) end;
        result:='';
        end;

    if name = 'save vfs' then
      begin
      mainfrm.saveVFS(first(p,lastFileOpen));
      result:='';
      end;

    if name = 'save cfg' then
      begin
      if p = 'file' then savemode:=SM_FILE
      else if p = 'registry' then savemode:=SM_USER
      else if p = 'global registry' then savemode:=SM_SYSTEM;
      mainFrm.saveCFG();
      result:='';
      end;

    if name = 'js encode' then
      result:=jsEncode(p, first(par(1),'''"'));

    if name = 'base64' then
      result:=base64encode(UTF8encode(p));
    if name = 'base64decode' then
      result:=utf8ToString(base64decode(ansistring(p)));
    if name = 'md5' then
      result:=strMD5(p);
    if name = 'sha1' then
      result:=strSHA1(p);

    if name = 'vfs select' then
      if pars.count = 0 then
        try result:=selectedFile.url()
        except result:='' end
      else if p = 'next' then
        if selectedFile = NIL then
          spaceIf(FALSE)
        else
          begin
          with mainFrm.filesBox do selected:=selected.getNext();
          spaceIf(TRUE);
          end
      else
        try
          s:=parEx('path');
          spaceIf(FALSE);
          mainFrm.filesBox.selected:= mainFrm.findFilebyURL(s, NIL, FALSE).node;
          spaceIf(TRUE);
        except end;

    if name = 'break' then
      begin
      result:='';
      try
        if isFalse(parEx('if')) then
          exit;
      except end;
      try result:=parEx('result') except end;
      md.breaking:=TRUE;
      exit;
      end;

    if pars.Count < 1 then exit; // from here, only macros with parameters

    if name = 'var domain' then
      vardomain();

    if name = 'dir' then
      dir();

    if name = 'no pipe' then
      result:=replaceStr(substr(fullMacro, '|'), '|','{:|:}');

    if name = 'pipe' then
      result:=replaceStr(substr(fullMacro, '|'), '{:|:}','|');

    if name = 'add to log' then
      begin
      try s:=getVar(parEx('var'))
      except s:=p end;
      mainfrm.add2log(s, md.cd, stringToColorEx(par(1,'color'), clDefault));
      result:='';
      end;

    if name = 'mkdir' then
      begin
      s:=trim(uri2diskMaybeFolder(p));
      spaceIf(not directoryExists(s) and forceDirectory(s));
      end;

    if name = 'chdir' then
      begin
      IOresult;
      setCurrentDir(p);
      spaceIf(IOresult=0);
      end;

    if name = 'encodeuri' then
      encodeuri();

    if name = 'decodeuri' then
      result:=decodeURL(ansistring(p));

    if name = 'set cfg' then
      trueIf(mainfrm.setcfg(p));

    if name = 'dialog' then
      dialog();

    if name = 'any macro marker' then
      trueIf(anyMacroMarkerIn(first(loadTextfile(uri2diskMaybe(p)), p)));

    if name = 'random' then
      result:=randomFrom(listToArray(pars));

    if name = 'random number' then
      if pars.count = 1 then
        result:=intToStr(random(1+parI(0)))
      else
        result:=intToStr(parI(0)+random(1+parI(1)-parI(0)));

    if (name = 'force ansi') or (name = 'maybe utf8') then // pre-unicode legacy
      result:=p;

    if name = 'after the list' then
      if md.afterTheList then
        result:=macroDequote(p)
      else
        result:=MARKER_OPEN+fullMacro+MARKER_CLOSE;

    if name = 'breadcrumbs' then
      breadcrumbs();

    if name = 'filename' then
      result:=substr(p, lastDelimiter('\/:',p)+1);

    if name = 'filepath' then
      begin
      i:=lastDelimiter('\/:',p);
      if i = 0 then
        result:=''
      else
        result:=substr(p, 1, i);
      end;

    if name = 'not' then
      trueIf(isFalse(p));

    if name = 'length' then
      begin // don't trim
      try s:=getVar(parEx('var', FALSE))
      except s:=pars[0] end;
      result:=intToStr(length(s));
      end;

    if name = 'load' then
      load(p, par(1,'var'));

    if name = 'load tpl' then
      if satisfied(md.cd) then
        begin
        md.cd.tpl:=cachedTpls.getTplFor(p);
        result:='';
        end;

    if name = 'filesize' then
      begin
      if reMatch(p, '^https?://', 'i!') > 0 then i64:=httpFileSize(p)
      else i64:=sizeOfFile(uri2diskMaybe(p));
      result:=intToStr(max(0,i64)); // we return 0 instead of -1 for non-existent files, t
      end;

    if name = 'filetime' then
      result:=floatToStr(getMtime(p));

    if name = 'header' then
      if satisfied(md.cd) then
        try result:=noMacrosAllowed(md.cd.conn.getHeader(ansistring(p))) except end;

    if name = 'urlvar' then
      result:=urlvar(p);

    if name = 'postvar' then
      if satisfied(md.cd) then
        try
          result:=noMacrosAllowed(md.cd.postVars.values[p]);
          setVar(parEx('var'), result); // if no var is specified, it will break here, and result will have the value
          result:='';
        except end;

    if name = 'section' then
      section(1);

    if name = 'trim' then
      result:=p;

    if name = 'lower' then
      result:=ansiLowercase(p);

    if name = 'upper' then
      result:=ansiUppercase(p);

    if name = 'abs' then
      result:=floatToStr(abs(parF(0)));

    if name = 'upload failed' then
      begin
      md.cd.uploadFailed:=p;
      result:='';
      end;

    if name = 'is file protected' then
      result:=if_(filematch(PROTECTED_FILES_MASK, parVar('var',0)), '1');

    if name = 'get' then
      try
        if p = 'can recur' then trueIf(mainFrm.recursiveListingChk.Checked)
        else if p = 'can upload' then actionAllowed(FA_UPLOAD)
        else if p = 'can delete' then actionAllowed(FA_DELETE)
        else if p = 'can access' then actionAllowed(FA_ACCESS)
        else if p = 'can archive' then canArchive(md.folder)
        else if p = 'can archive item' then canArchive(md.f)
        else if p = 'url' then getUri()
        else if p = 'stop spiders' then trueIf(mainFrm.stopSpidersChk.checked)
        else if p = 'is new' then trueIf(md.f.isNew())
        else if p = 'agent' then result:=md.cd.agent
        else if p = 'tpl file' then result:=tplFilename
        else if p = 'protocolon' then result:=protoColon()
        else if p = 'speed limit' then result:=intToStr(round(speedLimit))
        else if p = 'external address' then
          begin
          if externalIP = '' then getExternalAddress(externalIP);
          result:=externalIP;
          end
        else if p = 'accounts' then
          result:=join(';', getAccountList(
            stringExists(par(1),['','users']),
            stringExists(par(1),['','groups'])
          ))
        ;
      except unsatisfied() end;

    if name = 'call' then
      try call(getVar(p), 1) except end;

    if name = 'inc' then
      inc_();
    if name = 'dec' then
      inc_(-1);

    if name = 'chr' then
      begin
      result:='';
      for i:=0 to pars.count-1 do
        try result:=result+chr(strToInt(replaceStr(pars[i],'x','$')))
        except end;
      end;

    if name = 'dequote' then
      result:=macroDequote(p);

    if name ='quote' then
      begin
      p:=macroDequote(p);
      applyMacrosAndSymbols(p, cbMacros, cbData);
      result:=macroQuote(p);
      end;

    if name = 'encode html' then
      result:=htmlEncode(p);

    if name = 'play' then
      begin
      result:='';
      playSound(Pchar(p), 0, SND_ALIAS or SND_ASYNC or SND_NOWAIT);
      end;

    if name = 'delete' then
      begin
      s:=uri2diskMaybe(p,NIL,FALSE);
      if isTrue(par('bin',TRUE,'1')) then
        spaceIf(moveToBin(s, isTrue(par('forced'))))
      else
        spaceIf(deltree(s));
      end;

    if name = 'disk free' then
      result:=intToStr(diskSpaceAt(uri2diskMaybe(p)));

    if name = 'vfs to disk' then
      if isAbsolutePath(p) then
        result:=p
      else if dirCrossing(p) and not ansiStartsStr('/', p) then
        result:=expandFileName(includeTrailingPathDelimiter(md.folder.resource)+p)
      else
        result:=uri2disk(p, md.folder);

    if name = 'exists' then
      if ansiContainsStr(p, '/') then
        trueIf(fileExistsByURL(p))
      else
        trueIf(fileOrDirExists(p));

    if name = 'is file' then
      trueIf(fileExists(p));

    if name = 'mime' then
      begin
      result:='';
      if satisfied(md.cd) then
        md.cd.conn.reply.contentType:=ansistring(p);
      end;

    if name = 'calc' then
      result:=floatToStr(evalFormula(p));

    if name = 'smart size' then
      result:=smartsize(strToInt64(p));

    if name = 'round' then
      result:=floatToStr(roundTo(parF(0), -parI(1, 0)));

    if name = 'md5 file' then
      result:=createFingerprint(p);

    if name = 'exec' then
      exec_();

    if name = 'set speed limit for address' then
      begin
      if pars.count = 1 then
        setSpeedLimitIP(parF(0))
      else
        with objByIp(p) do
          begin
          limiter.maxSpeed:=round(parF(1)*1000);
          customizedLimiter:=TRUE;
          end;
      result:='';
      end;

    if name = 'set speed limit for connection' then
      if satisfied(md.cd) then
        try
          if assigned(md.cd.limiter) then
            begin
            md.cd.limiter.maxSpeed:=round(parF(0)*1000);
            exit;
            end;
          md.cd.limiter:=TspeedLimiter.create(round(parF(0)*1000));
          md.cd.conn.limiters.add(md.cd.limiter);
          srv.limiters.add(md.cd.limiter);
          result:='';
        except
          md.cd.conn.limiters.remove(md.cd.limiter);
          srv.limiters.remove(md.cd.limiter);
          freeAndNIL(md.cd.limiter);
          result:='';
          end;

    if name = 'member of' then
      memberOf();

    if name = 'add header' then
      if satisfied(md.cd) then
        begin
        result:='';
        // macro 'mime' should be used for content-type, but this test will save precious time to those who will be fooled by the presence this macro
        if ansiStartsText('Content-Type:', p) then
          md.cd.conn.reply.contentType:=ansistring(trim(substr(p, ':')))
        else if ansiStartsText('Location:', p) then
          with md.cd.conn.reply do
            begin
            mode:=HRM_REDIRECT;
            url:=UTF8encode(trim(substr(p, ':')))
            end
        else
          md.cd.conn.addHeader(ansistring(p), isTrue(par('overwrite',true,'1')));
        end;

    if name = 'remove header' then
      if satisfied(md.cd) then
        begin
        result:='';
        md.cd.conn.removeHeader(ansistring(p));
        end;

    if name = 'get ini' then
      result:=getKeyFromString(mainFrm.getCfg(), p);

    if name = 'set ini' then
      begin
      result:='';
      mainfrm.setCfg(p);
      end;

    if name = 'set' then
      begin
      try s:=getVar(parEx('var'));
      except
        if pars.count < 2 then s:=''
        else s:=macroDequote(pars[1]);
        end;
      if par('mode') = 'append' then
        s:=getVar(p)+s
      else if par('mode') = 'prepend' then
        s:=s+getVar(p);
      spaceIf(setVar(p, s));
      end;

    if name = 'notify' then
      begin
      tray.balloon(p, parF('timeout',3), stringTotrayMessageType(par('type')), par('title'));
      result:='';
      end;

    if name = 'cookie' then
      cookie();

    if name = 'new account' then
      newAccount();

    if name = 'delete account' then
      begin
      deleteAccount(p);
      result:='';
      end;

    if name = 'delete item' then
      deleteItem();
      
    if pars.count < 2 then exit; // from here, only macros with at least 2 parameters

    if name = 'set item' then
      setItem();
    if name = 'get item' then
      getItem();

    if name = 'while' then
      while_();

    if name = 'set table' then
      setTable();

    if name = 'add folder' then
      addFolder();

    if (name = 'save') or (name = 'append') then
      save();

    if name = 'rename' then
      begin
      spaceIf( not isExtension(par(1), '.lnk') and // security matters (by mars)
        renameIt(p, par(1)) );
      if (result > '') and not stopOnMacroRename then // should we stop recursion?
        try
          // by default, we'll stop after first stacked [on macro rename], but recursive=1 will remove this limit
          stopOnMacroRename:=isFalse(par('recursive'));
          runEventScript('on macro rename', toSA(['%old-name%',p,'%new-name%',par(1)]), md.cd);
        finally
          stopOnMacroRename:=FALSE;
          end;
      end;

    if name = 'move' then
      begin
      s:=uri2diskMaybeFolder(par(1));
      spaceIf((s>'') and movefile(uri2diskMaybe(p,NIL,FALSE), s));
      end;

    if name = 'copy' then
      spaceIf(copyfile(uri2diskMaybe(p), uri2diskMaybeFolder(par(1))));

    if name = 'from table' then
      result:=fromTable(p, par(1));

    if name = 'match' then
      trueIf(filematch(p, par(1)));

    if name = 'match address' then
      trueIf(addressmatch(p, par(1)));

    if name = 'regexp' then
      regexp();

    if name = 'pos' then
      result:=intToStr(pos_(isTrue(par('case')), parVar('what', 0), parVar('var', 1), strToIntDef(par('from'), 1)));

    if name = 'repeat' then
      result:=dupeString(macroDequote(par(1)), strToIntDef(p,1));

    if name = 'count substring' then
      result:=intToStr(countSubstr(pars[0], par(1)));

    if name = 'and' then
      allLogic(TRUE);

    if name = 'or' then
      allLogic(FALSE);

    if name = 'xor' then
      trueIf(isTrue(p) xor isTrue(par(1)));

    if name = 'add' then
      result:=floatToStr(parF(0)+parF(1));
    if name = 'sub' then
      result:=floatToStr(parF(0)-parF(1));
    if name = 'mul' then
      result:=floatToStr(parF(0)*parF(1));
    if name = 'div' then
      result:=floatToStr(safeDiv(parF(0),parF(1)));
    if name = 'mod' then
      result:=intToStr(safeMod(parI(0),parI(1)));

    if stringExists(name, ['min','max']) then
      minOrMax();

    if stringExists(name, ['if','if not']) then
      begin
      try p:=getVar(parEx('var'));
      except end;
      if isTrue(p) xor (length(name) = 2) then result:=macroDequote(par(2))
      else result:=macroDequote(par(1));
      end;

    if stringExists(name, ['=','>','>=','<','<=','<>','!=']) then
      trueIf(compare(name, p, par(1)));

    if name = 'switch' then
      switch();

    if name = 'set account' then
      setAccount();
    if name = 'get account' then
      getterAccount();

    if name = 'cut' then
      cut();

    if name ='for line' then
      forLine();

    if pars.count < 3 then exit; // from here, only macros with at least 3 parameters

    if name ='for each' then
      foreach();

    if name = 'substring' then
      substring();

    if name = 'replace' then
      replace();

    if name = 'convert' then
      convert();

    if pars.count < 4 then exit;

    if name = 'for' then
      for_();
  finally
    if mainfrm.macrosLogChk.checked then
      begin
      if not fileExists(MACROS_LOG_FILE) then
        saveTextFile(MACROS_LOG_FILE, HEADER);
      macrosLog(fullMacro, result, md.logTS);
      md.logTS:=FALSE;
      end;
    end;
except
  if mainfrm.macrosLogChk.checked then
    macrosLog(fullMacro, 'Exception, please report this bug on www.rejetto.com/forum/');
  result:='';
  end;
end; // cbMacros

function tryApplyMacrosAndSymbols(var txt:string; var md:TmacroData; removeQuotings:boolean=true):boolean;
var
  s: string;
begin
result:=FALSE;

try
  md.aliases:=defaultalias; // we don't even create a new object if not necessary
  if assigned(md.tpl) then
    begin
    s:=md.tpl['special:alias'];
    if s > '' then
      begin
      md.aliases:=THashedStringList.create;
      md.aliases.text:=s;
      md.aliases.addStrings(defaultAlias);
      end;
    end;

  if md.cd = NIL then
    begin
    md.tempVars:=THashedStringList.create;
    end;

  md.logTS:=TRUE;
  md.breaking:=FALSE;

  try
    applyMacrosAndSymbols(txt, cbMacros, @md, removeQuotings);
    result:=TRUE;
  except
    on e:EtplError do mainFrm.setStatusBarText(format('Template error at %d,%d: %s: %s ...', [e.row,e.col,e.message,e.code]), 1000);
    on Exception do raise;
    end;
finally
  if md.aliases <> defaultAlias then
    freeAndNIL(md.aliases);
  freeAndNIL(md.tempVars);  
  end;
end; // tryApplyMacrosAndSymbols

function runScript(script:string; table:TstringDynArray=NIL; tpl_:Ttpl=NIL; f:Tfile=NIL; folder:Tfile=NIL; cd:TconnData=NIL):string;
var
  md: TmacroData;
begin
result:=trim(script);
if result = '' then exit;
fillchar(md, sizeOf(md), 0);
md.tpl:=first(tpl_, tpl);
md.f:=f;
md.folder:=folder;
md.cd:=cd;
md.table:=table;
tryApplyMacrosAndSymbols(result, md);
end; // runScript

function runEventScript(event:string; table:TStringDynArray=NIL; cd:TconnData=NIL):string;
begin
addArray(table, ['%event%', event]);
result:=runScript(eventScripts[event], table, eventScripts, NIL, NIL, cd);
end; // runEventScript

initialization
cachedTpls:=TcachedTpls.create();
eventScripts:=Ttpl.create();
defaultAlias:=THashedStringList.create();
defaultAlias.caseSensitive:=FALSE;
defaultAlias.text:=getRes('alias');
staticVars:=THashedStringList.create;
currentCFGhashed:=THashedStringList.create();
with staticVars do
  objects[add('ini='+currentCFG)]:=currentCFGhashed;

finalization
freeAndNIL(cachedTpls);
freeAndNIL(eventScripts);
freeAndNIL(defaultAlias);
freeAndNIL(currentCFGhashed);
staticVars.free;

end.
