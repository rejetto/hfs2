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
{$INCLUDE defs.inc }

unit utilLib;

interface

uses
	IOUtils, main, hslib, regexpr, types, windows, graphics, dialogs, registry, classes, dateUtils, Vcl.Imaging.GIFImg,
  shlobj, shellapi, activex, comobj, strutils, forms, stdctrls, controls, psAPI, menus, math,
  longinputDlg, OverbyteIcsWSocket, OverbyteIcshttpProt, comCtrls, iniFiles, richedit, sysutils, classesLib{, fastmm4};

const
  ILLEGAL_FILE_CHARS = [#0..#31,'/','\',':','?','*','"','<','>','|'];
  DOW2STR: array [1..7] of string=( 'Sun','Mon','Tue','Wed','Thu','Fri','Sat' );
  MONTH2STR: array [1..12] of string = ( 'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec' );
  PTR1: Tobject = ptr(1);
var
  GMToffset: integer; // in minutes
  inputQueryLongdlg: TlonginputFrm;
  winVersion: (WV_LOWER, WV_2000, WV_VISTA, WV_SEVEN, WV_HIGHER);
type
  TcharSet = set of char;
  TreCB = procedure(re:TregExpr; var res:string; data:pointer);
  PstringDynArray = ^TstringDynArray;
  TnameExistsFun = function(user:string):boolean;

procedure doNothing(); inline; // useful for readability
function accountExists(user:string; evenGroups:boolean=FALSE):boolean;
function getAccount(user:string; evenGroups:boolean=FALSE):Paccount;
function nodeToFile(n:TtreeNode):Tfile;
procedure fixFontFor(frm:Tform);
function hostFromURL(s:string):string;
function hostToIP(name: string):string;
function allocatedMemory():int64;
function stringToGif(s:ansistring; gif:TgifImage=NIL):TgifImage;
function maybeUnixTime(t:Tdatetime):Tdatetime;
function filetimeToDatetime(ft:TFileTime):Tdatetime;
function localToGMT(d:Tdatetime):Tdatetime;
function onlyExistentAccounts(a:TstringDynArray):TstringDynArray;
procedure onlyForExperts(controls:array of Tcontrol);
function createAccountOnTheFly():Paccount;
function newMenuSeparator(lbl:string=''):Tmenuitem;
function accountIcon(isEnabled, isGroup:boolean):integer; overload;
function accountIcon(a:Paccount):integer; overload;
function evalFormula(s:string):real;
function boolOnce(var b:boolean):boolean;
procedure drawCentered(cnv:Tcanvas; r:Trect; text:string);
function minmax(min, max, v:integer):integer;
function isLocalIP(ip:string):boolean;
function clearAndReturn(var v:string):string;
function swapMem(var src,dest; count:dword; cond:boolean=TRUE):boolean;
function pid2file(pid:integer):string;
function port2pid(port:string):integer;
function holdingKey(key:integer):boolean;
function blend(from,to_:Tcolor; perc:real):Tcolor;
function isNT():boolean;
function setClip(s:string):boolean;
function eos(s:Tstream):boolean;
function safeDiv(a,b:real; default:real=0):real; overload;
function safeDiv(a,b:int64; default:int64=0):int64; overload;
function safeMod(a,b:int64; default:int64=0):int64;
function smartsize(size:int64):string;
function httpGet(url:string; from:int64=0; size:int64=-1):string;
function httpGetFile(url, filename:string; tryTimes:integer=1; notify:TdocDataEvent=NIL):boolean;
function httpFileSize(url:string):int64;
function getIPs():TStringDynArray;
function getPossibleAddresses():TstringDynArray;
function whatStatusPanel(statusbar:Tstatusbar; x:integer):integer;
function getExternalAddress(var res:string; provider:Pstring=NIL):boolean;
function checkAddressSyntax(address:string; wildcards:boolean=TRUE):boolean;
function inputQueryLong(const caption, msg:string; var value:string; ofs:integer=0):boolean;
procedure purgeVFSaccounts();
function exec(cmd:string; pars:string=''; showCmd:integer=SW_SHOW):boolean;
function execNew(cmd:string):boolean;
function captureExec(DosApp : string; out output:string; out exitcode:cardinal; timeout:real=0):boolean;
function openURL(url:string):boolean;
function getRes(name:pchar; typ:string='TEXT'):string;
function bmpToHico(bitmap:Tbitmap):hicon;
function compare_(i1,i2:double):integer; overload;
function compare_(i1,i2:int64):integer; overload;
function compare_(i1,i2:integer):integer; overload;
function msgDlg(msg:string; code:integer=0; title:string=''):integer;
function if_(v:boolean; v1:string; v2:string=''):string; overload; inline;
function if_(v:boolean; v1:ansistring; v2:ansistring=''):ansistring; overload; inline;
function if_(v:boolean; v1:int64; v2:int64=0):int64; overload; inline;
function if_(v:boolean; v1:integer; v2:integer=0):integer; overload; inline;
function if_(v:boolean; v1:Tobject; v2:Tobject=NIL):Tobject; overload; inline;
function if_(v:boolean; v1:boolean; v2:boolean=FALSE):boolean; overload; inline;
// file
function getEtag(filename:string):string;
function getDrive(fn:string):string;
function diskSpaceAt(path:string):int64;
function deltree(path:string):boolean;
function newMtime(fn:string; var previous:Tdatetime):boolean;
function dirCrossing(s:string):boolean;
function forceDirectory(path:string):boolean;
function moveToBin(fn:string; force:boolean=FALSE):boolean; overload;
function moveToBin(files:TstringDynArray; force:boolean=FALSE):boolean; overload;
function uri2disk(url:string; parent:Tfile=NIL; resolveLnk:boolean=TRUE):string;
function uri2diskMaybe(path:string; parent:Tfile=NIL; resolveLnk:boolean=TRUE):string;
function freeIfTemp(var f:Tfile):boolean; inline;
function isAbsolutePath(path:string):boolean;
function getTempDir():string;
function createShellLink(linkFN:WideString; destFN:string):boolean;
function readShellLink(linkFN:WideString):string;
function getShellFolder(id:string):string;
function getTempFilename():string;
function saveTempFile(data:ansistring):string; overload;
function saveTempFile(data:string):string; overload;
function fileOrDirExists(fn:string):boolean;
function sizeOfFile(fn:string):int64; overload;
function sizeOfFile(fh:Thandle):int64; overload;
function loadFile(fn:string; from:int64=0; size:int64=-1):ansistring;
function loadTextFile(fn:string):string;
function saveTextFile(fn:string; text:string; append:boolean=FALSE):boolean;
function saveFile(fn:string; data:ansistring; append:boolean=FALSE):boolean; overload;
function saveFile(var f:file; data:ansistring):boolean; overload;
function moveFile(src, dst:string; op:UINT=FO_MOVE):boolean;
function copyFile(src, dst:string):boolean;
function resolveLnk(fn:string):string;
function validFilename(s:string):boolean;
function validFilepath(fn:string; acceptUnits:boolean=TRUE):boolean;
function match(mask, txt:pchar; fullMatch:boolean=TRUE; charsNotWildcard:Tcharset=[]):integer;
function filematch(mask, fn:string):boolean;
function appendFile(fn:string; data:ansistring):boolean;
function appendTextFile(fn:string; text:string):boolean;
function getFilename(var f:file):string;
function filenameToDriveByte(fn:string):byte;
function selectFile(var fn:string; title:string=''; filter:string=''; options:TOpenOptions=[]):boolean;
function selectFiles(caption:string; var files:TStringDynArray):boolean;
function selectFolder(caption:string; var folder:string):boolean;
function selectFileOrFolder(caption:string; var fileOrFolder:string):boolean;
function isExtension(filename, ext:string):boolean;
function getMtimeUTC(filename:string):Tdatetime;
function getMtime(filename:string):Tdatetime;
// registry
function loadregistry(key,value:string; root:HKEY=0):string;
function saveregistry(key,value,data:string; root:HKEY=0):boolean;
function deleteRegistry(key,value:string; root:HKEY=0):boolean; overload;
function deleteRegistry(key:string; root:HKEY=0):boolean; overload;
// strings array
function split(separator, s:string; nonQuoted:boolean=FALSE):TStringDynArray;
function join(separator:string; ss:TstringDynArray):string;
function addUniqueString(s:string; var ss:TStringDynArray):boolean;
function addString(s:string; var ss:TStringDynArray):integer;
function replaceString(var ss:TStringDynArray; old, new:string):integer;
function popString(var ss:TstringDynArray):string;
procedure insertString(s:string; idx:integer; var ss:TStringDynArray);
function removeString(var a:TStringDynArray; idx:integer; l:integer=1):boolean; overload;
function removeString(find:string; var a:TStringDynArray):boolean; overload;
procedure removeStrings(find:string; var a:TStringDynArray);
procedure toggleString(s:string; var ss:TStringDynArray);
function onlyString(s:string; ss:TStringDynArray):boolean;
function addArray(var dst:TstringDynArray; src:array of string; where:integer=-1; srcOfs:integer=0; srcLn:integer=-1):integer;
function removeArray(var src:TstringDynArray; toRemove:array of string):integer;
function addUniqueArray(var a:TstringDynArray; b:array of string):integer;
procedure uniqueStrings(var a:TstringDynArray);
function idxOf(s:string; a:array of string; isSorted:boolean=FALSE):integer;
function stringExists(s:string; a:array of string; isSorted:boolean=FALSE):boolean;
function listToArray(l:Tstrings):TstringDynArray;
function arrayToList(a:TStringDynArray; list:TstringList=NIL):TstringList;
function sortArray(a:TStringDynArray):TStringDynArray;
// convert
function boolToPtr(b:boolean):pointer;
function strToCharset(s:string):Tcharset;
function ipToInt(ip:string):dword;
function rectToStr(r:Trect):string;
function strToRect(s:string):Trect;
function dt_(s:ansistring):Tdatetime;
function int_(s:ansistring):integer;
function str_(i:integer):ansistring; overload;
function str_(fa:TfileAttributes):ansistring; overload;
function str_(t:Tdatetime):ansistring; overload;
function str_(b:boolean):ansistring; overload;
function strToUInt(s:string):integer;
function elapsedToStr(t:Tdatetime):string;
function dateToHTTP(gmtTime:Tdatetime):string; overload;
function dateToHTTP(filename:string):string; overload;
function toSA(a:array of string):TstringDynArray; // this is just to have a way to typecast
function stringToColorEx(s:string; default:Tcolor=clNone):Tcolor;
// misc string
procedure excludeTrailingString(var s:string; ss:string);
function findEOL(s:string; ofs:integer=1; included:boolean=TRUE):integer;
function getUniqueName(start:string; exists:TnameExistsFun):string;
function getStr(from,to_:pchar):string;
function TLV(t:integer; s:string):ansistring; overload;
function TLV(t:integer; data:ansistring):ansistring; overload;
function TLV_NOT_EMPTY(t:integer; s:string):ansistring; overload;
function TLV_NOT_EMPTY(t:integer; data:ansistring):ansistring;overload;
function getCRC(data:ansistring):integer;
function dotted(i:int64):string;
function xtpl(src:string; table:array of string):string; overload;
function validUsername(s:string; acceptEmpty:boolean=FALSE):boolean;
function anycharIn(chars, s:string):boolean; overload;
function anycharIn(chars:Tcharset; s:string):boolean; overload;
function int0(i,digits:integer):string;
function addressmatch(mask, address:string):boolean;
function getTill(ss, s:string; included:boolean=FALSE):string; overload;
function getTill(i:integer; s:string):string; overload;
function singleLine(s:string):boolean;
function poss(chars:TcharSet; s:string; ofs:integer=1):integer;
function jsEncode(s, chars:string):string;
function nonEmptyConcat(pre,s:string; post:string=''):string;
function first(a,b:integer):integer; overload;
function first(a,b:double):double; overload;
function first(a,b:pointer):pointer; overload;
function first(a,b:string):string; overload;
function first(a,b:ansistring):ansistring; overload;
function first(a:array of string):string; overload;
function stripChars(s:string; cs:Tcharset; invert:boolean=FALSE):string;
function isOnlyDigits(s:string):boolean;
function strAt(s, ss:string; at:integer):boolean; inline;
function substr(s:string; start:integer; upTo:integer=0):string; inline; overload;
function substr(s:string; after:string):string; overload;
function reduceSpaces(s:string; replacement:string=' '; spaces:TcharSet=[]):string;
function replace(var s:string; ss:string; start,upTo:integer):integer;
function countSubstr(ss:string; s:string):integer;
function trim2(s:string; chars:Tcharset):string;
procedure urlToStrings(s:ansistring; sl:Tstrings);
function reCB(expr, subj:string; cb:TreCB; data:pointer=NIL):string;
function reMatch(s, exp:string; mods:string='m'; ofs:integer=1; subexp:PstringDynArray=NIL):integer;
function reReplace(subj, exp, repl:string; mods:string='m'):string;
function reGet(s, exp:string; subexpIdx:integer=1; mods:string='!mi'; ofs:integer=1):string;
function getSectionAt(p:pchar; out name:string):boolean;
function isSectionAt(p:pchar):boolean;
function dequote(s:string; quoteChars:TcharSet=['"']):string;
function quoteIfAnyChar(badChars, s:string; quote:string='"'; unquote:string='"'):string;
function getKeyFromString(s:string; key:string; def:string=''):string;
function setKeyInString(s:string; key:string; val:string=''):string;
function getFirstChar(s:string):char;
function escapeNL(s:string):string;
function unescapeNL(s:string):string;
function htmlEncode(s:string):string;
procedure enforceNUL(var s:string);
function strSHA256(s:string):string;
function strSHA1(s:string):string;
function strMD5(s:string):string;
function strToOem(s:string):ansistring;

implementation

uses
  clipbrd, JclNTFS, JclWin32, parserLib, newuserpassDlg, winsock, System.Hash, ansistrings;

var
  ipToInt_cache: ThashedStringList;
  onlyDotsRE: TRegExpr;

function strSHA256(s:string):string;
begin result:=THashSHA2.GetHashString(UTF8encode(s)) end;

function strSHA1(s:string):string;
begin result:=THashSHA1.GetHashString(UTF8encode(s)) end;

function strMD5(s:string):string;
begin result:=THashMD5.GetHashString(UTF8encode(s)) end;

function strToOem(s:string):ansistring;
begin
setLength(result, length(s));
CharToOemBuff(pWideChar(s), pAnsiChar(result), length(s));
end; // strToOem

// method TregExpr.ReplaceEx does the same thing, but doesn't allow the extra data field (sometimes necessary).
// Moreover, here i use the TfastStringAppend that will give us good performance with many replacements.
function reCB(expr, subj:string; cb:TreCB; data:pointer=NIL):string;
var
  r: string;
  last: integer;
  re: TRegExpr;
  s: TfastStringAppend;
begin
re:=TRegExpr.create;
s:=TfastStringAppend.create;
try
  re.modifierI:=TRUE;
  re.ModifierS:=FALSE;
  re.expression:=expr;
  re.compile();
  last:=1;
  if re.exec(subj) then
    repeat
    r:=re.match[0];
    cb(re, r, data);
    if re.MatchPos[0] > 1 then
      s.append(substr(subj, last, re.matchPos[0]-1)); // we must IF because 0 is the end of string for substr()
    s.append(r);
    last:=re.matchPos[0]+re.matchLen[0];
    until not re.execNext();
  s.append(substr(subj, last));
  result:=s.get();
finally
  re.free;
  s.free;
  end
end; // reCB

// this is meant to detect junctions, symbolic links, volume mount points
function isJunction(path:string):boolean; inline;
var
  attr: DWORD;
begin
attr:=getFileAttributes(PChar(path));
// don't you dare to convert the <>0 in a boolean typecast! my TurboDelphi (2006) generates the wrong assembly :-(
result:=(attr <> DWORD(-1)) and (attr and FILE_ATTRIBUTE_REPARSE_POINT <> 0)
end;

// the file may not be a junction itself, but we may have a junction at some point in the path
function hasJunction(fn:string):string;
var
  i: integer;
begin
i:=length(fn);
while i > 0 do
  begin
  result:=copy(fn,1,i);
  if isJunction(result) then
    exit;
  while (i > 0) and not charInSet(fn[i],['\','/']) do dec(i);
  dec(i);
  end;
result:='';
end; // hasJunction

// this is a fixed version of the one contained in JclNTFS.pas
function NtfsGetJunctionPointDestination(const Source: string; var Destination: widestring): Boolean;
var
  Handle: THandle;
  ReparseData: record
    case Boolean of
      False: (Reparse: TReparseDataBuffer;);
      True: (Buffer: array [0..MAXIMUM_REPARSE_DATA_BUFFER_SIZE] of Char;);
    end;
  BytesReturned: DWORD;
begin
Result := False;
if not NtfsFileHasReparsePoint(Source) then exit;
handle := CreateFile(PChar(Source), GENERIC_READ, 0, nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OPEN_REPARSE_POINT, 0);
if handle = INVALID_HANDLE_VALUE then exit;
try
  BytesReturned := 0;
  if not DeviceIoControl(Handle, FSCTL_GET_REPARSE_POINT, nil, 0, @ReparseData, MAXIMUM_REPARSE_DATA_BUFFER_SIZE, BytesReturned, nil) then exit;
  if BytesReturned < DWORD(ReparseData.Reparse.SubstituteNameLength + SizeOf(WideChar)) then exit;
  SetLength(Destination, (ReparseData.Reparse.SubstituteNameLength div SizeOf(WideChar)));
  Move(ReparseData.Reparse.PathBuffer[0], Destination[1], ReparseData.Reparse.SubstituteNameLength);
  Result := True;
finally CloseHandle(Handle) end
end; // NtfsGetJunctionPointDestination

function getDrive(fn:string):string;
var
  i: integer;
  ws: widestring;
begin
result:=fn;
  repeat
  fn:=hasJunction(result);
  if fn = '' then break;
  if not NtfsGetJunctionPointDestination(fn, ws) then
    break; // at worst we hope the drive is the same
  result:=WideCharToString(@ws[1]);
  // sometimes we get a unicode result
  i:=length(result);
  if (i > 3) and (result[2] = #0) then
    begin
    break;
    result:=wideCharToString(@result[1]);
    setLength(result, i-1);
    end;
  // remove some trailing null chars
  result:=trim(result);
  // we don't like this form, remove useless chars
  if reMatch(result, '^\\\?\?\\.:', '!') > 0 then
    delete(result, 1,4);
  until false;
result:=extractFileDrive(result);
end; // getDrive

function moveToBin(fn:string; force:boolean=FALSE):boolean; overload;
begin result:=moveToBin(toSA(fn), force) end;

function moveToBin(files:TstringDynArray; force:boolean=FALSE):boolean; overload;
var
  fo: TSHFileOpStruct;
  i: integer;
  fn, test, list: string;
begin
result:=FALSE;
// the list is null-separated. A double-null will mark the end of the list, but delphi adds an extra hidden null in every string.
list:='';
try
  for i:=0 to length(files)-1 do
    begin
    fn:=expandFileName(files[i]); // if we don't specify a full path, the bin won't be used, and the file will be just deleted
    test:=fn;
    if (reMatch(fn, '[*?]', '!')>0) then
      test:=ExtractFilePath(test);
    // this system call doesn't work on linked files. Moreover, it hangs the process for a while, so we try to detect them, to abort.
    if not fileOrDirExists(test) or (hasJunction(test) > '') then continue;
    
    list:=list+fn+#0;
    end;

  if list = '' then exit;

  try
    fillChar(fo, sizeOf(fo), 0);
    fo.wFunc:=FO_DELETE;
    fo.pFrom:=pchar(list);
    fo.fFlags:=FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_SILENT;
    result:=SHFileOperation(fo) = 0;
  except result:=FALSE end;
finally
  if not result and force then
    begin
    // enter the rude
    result:=TRUE;
    for i:=0 to length(files)-1 do
      result:=result and deltree(files[i]);
    end;
  end;
end; // moveToBin

function moveFile(src, dst:string; op:UINT=FO_MOVE):boolean;
var
  fo: TSHFileOpStruct;
begin
try
  fillChar(fo, sizeOf(fo), 0);
  fo.wFunc:=op;
  fo.pFrom:=pchar(src+#0);
  fo.pTo:=pchar(dst+#0);
  fo.fFlags:=FOF_ALLOWUNDO + FOF_NOCONFIRMATION + FOF_NOERRORUI + FOF_SILENT + FOF_NOCONFIRMMKDIR;
  result:=SHFileOperation(fo) = 0;
except result:=FALSE end;
end; // movefile

function copyFile(src, dst:string):boolean;
begin result:=movefile(src, dst, FO_COPY) end;

var
  reTempCache, reFixedCache: THashedStringList;

function reCache(exp:string; mods:string='m'):TregExpr;
const
  CACHE_MAX = 100;
var
  i: integer;
  cache: THashedStringList;
  temporary: boolean;
  key: string;

begin

// this is a temporary cache: older things get deleted. order: first is older, last is newer.
if reTempCache = NIL then
  reTempCache:=THashedStringList.create();
// this is a permanent cache: things are never deleted (while the process is alive)
if reFixedCache = NIL then
  reFixedCache:=THashedStringList.create();

// is it temporary or not?
i:=pos('!', mods);
temporary:= i=0;
Tobject(cache):=if_(temporary, reTempCache, reFixedCache);
delete(mods, i, 1);

// access the cache
key:=mods+#255+exp;
i:=cache.indexOf(key);
if i >= 0 then
  begin
  result:=cache.objects[i] as TregExpr;
  if temporary then
    cache.move(i, cache.count-1); // just requested, refresh position
  end
else
  begin
  // cache fault, create new object
  result:=TRegExpr.Create;
  cache.addObject(key, result);

  if temporary and (cache.count > CACHE_MAX) then
    // delete older ones
    for i:=1 to CACHE_MAX div 10 do
      try
        cache.objects[0].free;
        cache.delete(0);
      except end;

  result.modifierS:=FALSE;
  result.modifierStr:=mods;
  result.expression:=exp;
  result.compile();
  end;

end;//reCache

function reMatch(s, exp:string; mods:string='m'; ofs:integer=1; subexp:PstringDynArray=NIL):integer;
var
  i: integer;
  re: TRegExpr;
begin
result:=0;
re:=reCache(exp,mods);
if assigned(subexp) then
  subexp^:=NIL;
// do the job
try
  re.inputString:=s;
  if not re.execPos(ofs) then exit;
  result:=re.matchPos[0];
  if subexp = NIL then exit;
  i:=re.subExprMatchCount;
  setLength(subexp^, i+1); // it does include also the whole match, with index zero
  for i:=0 to i do
    subexp^[i]:=re.match[i]
except end;
end; // reMatch

function reGet(s, exp:string; subexpIdx:integer=1; mods:string='!mi'; ofs:integer=1):string;
var
  se: TstringDynArray;
begin
if reMatch(s, exp, mods, ofs, @se) > 0 then
  result:=se[subexpIdx]
else
  result:='';
end; // reGet

function reReplace(subj, exp, repl:string; mods:string='m'):string;
var
  re: TRegExpr;
begin
re:=reCache(exp,mods);
result:=re.replace(subj, repl, TRUE);
end; // reReplace

// converts from integer to string[4]
function str_(i:integer):ansistring; overload;
begin
setlength(result, 4);
move(i, result[1], 4);
end; // str_

// converts from boolean to string[1]
function str_(b:boolean):ansistring; overload;
begin result:=ansichar(b) end;

// converts from TfileAttributes to string[4]
function str_(fa:TfileAttributes):ansistring; overload;
begin result:=str_(integer(fa)) end;

// converts from Tdatetime to string[8]
function str_(t:Tdatetime):ansistring; overload;
begin
setlength(result, 8);
move(t, result[1], 8);
end; // str_

// converts from string[4] to integer
function int_(s:ansistring):integer;
begin result:=Pinteger(@s[1])^ end;

// converts from string[8] to datetime
function dt_(s:ansistring):Tdatetime;
begin result:=Pdatetime(@s[1])^ end;

function strToUInt(s:string):integer;
begin
s:=trim(s);
if s='' then result:=0
else result:=strToInt(s);
if result < 0 then
  raise Exception.Create('strToUInt: Signed value not accepted');
end; // strToUInt

function split(separator, s:string; nonQuoted:boolean=FALSE):TStringDynArray;
var
  i, j, n, l: integer;
begin
l:=length(s);
result:=NIL;
if l = 0 then exit;
i:=1;
n:=0;
  repeat
  if length(result) = n then
    setLength(result, n+50);
  if nonQuoted then
    j:=nonQuotedPos(separator, s, i)
  else
    j:=posEx(separator, s, i);
  if j = 0 then
    j:=l+1;
  if i < j then
    result[n]:=substr(s, i, j-1);
  i:=j+length(separator);
  inc(n);
  until j > l;
setLength(result, n);
end; // split

function join(separator:string; ss:TstringDynArray):string;
var
  i:integer;
begin
result:='';
if length(ss) = 0 then exit;
result:=ss[0];
for i:=1 to length(ss)-1 do
  result:=result+separator+ss[i];
end; // join

procedure toggleString(s:string; var ss:TStringDynArray);
var
  i: integer;
begin
i:=idxOf(s, ss);
if i < 0 then addString(s, ss)
else removeString(ss, i);
end; // toggleString

procedure uniqueStrings(var a:TstringDynArray);
var
  i, j: integer;
begin
for i:=length(a)-1 downto 1 do
  for j:=i-1 downto 0 do
    if ansiCompareText(a[i], a[j]) = 0 then
      begin
      removeString(a, i);
      break;
      end;
end; // uniqueStrings

// remove all instances of the specified string
procedure removeStrings(find:string; var a:TStringDynArray);
var
  i, l: integer;
begin
  repeat
  i:=idxOf(find,a);
  if i < 0 then break;
  l:=1;
  while (i+l < length(a)) and (ansiCompareText(a[i+l], find) = 0) do inc(l);
  removeString(a, i, l);
  until false;
end; // removeStrings

// remove first instance of the specified string
function removeString(find:string; var a:TStringDynArray):boolean;
begin result:=removeString(a, idxOf(find,a)) end;

function removeArray(var src:TstringDynArray; toRemove:array of string):integer;
var
  i, l, ofs: integer;
  b: boolean;
begin
l:=length(src);
i:=0;
ofs:=0;
while i+ofs < l do
  begin
  b:=stringExists(src[i+ofs], toRemove);
  if b then inc(ofs);
  if i+ofs > l then break;
  if ofs > 0 then src[i]:=src[i+ofs];
  if not b then inc(i);
  end;
setLength(src, l-ofs);
result:=ofs;
end; // removeArray

function popString(var ss:TstringDynArray):string;
begin
result:='';
if ss = NIL then exit;
result:=ss[0];
removeString(ss, 0);
end; // popString

function addString(s:string; var ss:TStringDynArray):integer;
begin
result:=length(ss);
addArray(ss, [s], result)
end; // addString

function replaceString(var ss:TStringDynArray; old, new:string):integer;
var
  i: integer;
begin
result:=0;
  repeat
  i:=idxOf(old, ss);
  if i < 0 then exit;
  inc(result);
  ss[i]:=new;
  until false;
end; // replaceString

function onlyString(s:string; ss:TStringDynArray):boolean;
// we are case insensitive, just like other functions in this set
begin result:=(length(ss) = 1) and sameText(ss[0], s) end;

function addUniqueString(s:string; var ss:TStringDynArray):boolean;
begin
result:=idxof(s, ss) < 0;
if result then addString(s, ss)
end; // addUniqueString

procedure insertstring(s:string; idx:integer; var ss:TStringDynArray);
begin addArray(ss, [s], idx) end;

function removestring(var a:TStringDynArray; idx:integer; l:integer=1):boolean;
begin
result:=FALSE;
if (idx<0) or (idx >= length(a)) then exit;
result:=TRUE;
while idx+l < length(a) do
  begin
  a[idx]:=a[idx+l];
  inc(idx);
  end;
setLength(a, idx);
end; // removestring

function dotted(i:int64):string;
begin
result:=intToStr(i);
i:=length(result)-2;
while i > 1 do
  begin
  insert(FormatSettings.ThousandSeparator, result, i);
  dec(i,3);
  end;
end; // dotted

function getRes(name:pchar; typ:string='TEXT'):string;
var
  h1, h2: Thandle;
  p: pAnsiChar;
  l: integer;
  ansi: ansiString;
begin
result:='';
h1:=FindResource(HInstance, name, pchar(typ));
h2:=LoadResource(HInstance, h1);
if h2=0 then exit;
l:=SizeOfResource(HInstance, h1);
p:=LockResource(h2);
setLength(ansi, l);
move(p^, ansi[1], l);
UnlockResource(h2);
FreeResource(h2);
result:=UTF8toString(ansi);
end; // getRes

function compare_(i1,i2:int64):integer; overload;
begin
if i1 < i2 then result:=-1 else
if i1 > i2 then result:=1 else
  result:=0
end; // compare_

function compare_(i1,i2:integer):integer; overload;
begin
if i1 < i2 then result:=-1 else
if i1 > i2 then result:=1 else
  result:=0
end; // compare_

function compare_(i1,i2:double):integer; overload;
begin
if i1 < i2 then result:=-1 else
if i1 > i2 then result:=1 else
  result:=0
end; // compare_

function rectToStr(r:Trect):string;
begin result:=format('%d,%d,%d,%d',[r.left,r.top,r.right,r.bottom]) end;

function strToRect(s:string):Trect;
begin
result.Left:=strToInt(chop(',',s));
result.Top:=strToInt(chop(',',s));
result.right:=strToInt(chop(',',s));
result.bottom:=strToInt(chop(',',s));
end; // strToRect

function TLV(t:integer; s:string):ansistring;
var
  raw: ansistring;
begin
raw:=UTF8encode(s);
if length(raw) > length(s) then
  inc(t, TLV_UTF8_FLAG);
result:=str_(t)+str_(length(raw))+raw
end;

function TLV(t:integer; data:ansistring):ansistring;
begin result:=str_(t)+str_(length(data))+data end;

function TLV_NOT_EMPTY(t:integer; data:ansistring):ansistring;
begin if data > '' then result:=TLV(t,data) else result:='' end;

function TLV_NOT_EMPTY(t:integer; s:string):ansistring;
begin if s > '' then result:=TLV(t,s) else result:='' end;

function getCRC(data:ansistring):integer;
var
  i:integer;
  p:Pinteger;
begin
result:=0;
p:=@data[1];
for i:=1 to length(data) div 4 do
  begin
  inc(result, p^);
  inc(p);
  end;
end; // crc

function bmpToHico(bitmap:Tbitmap):hicon;
var
  iconX, iconY : integer;
  IconInfo: TIconInfo;
  IconBitmap, MaskBitmap: TBitmap;
  dx,dy,x,y: Integer;
  tc: TColor;
begin
if bitmap=NIL then
  begin
  result:=0;
  exit;
  end;
iconX := GetSystemMetrics(SM_CXICON);
iconY := GetSystemMetrics(SM_CYICON);
IconBitmap:= TBitmap.Create;
IconBitmap.Width:= iconX;
IconBitmap.Height:= iconY;
IconBitmap.TransparentColor:=Bitmap.TransparentColor;
tc:=Bitmap.TransparentColor and $FFFFFF;
Bitmap.transparent:=FALSE;
dx:=bitmap.width*2;
dy:=bitmap.height*2;
if (dx < iconX) and (dy < iconY) then
  begin
  IconBitmap.Canvas.brush.color:=tc;
  with IconBitmap.Canvas do fillrect(clipRect);
  x:=(iconX-dx) div 2;
  y:=(iconY-dy) div 2;
  IconBitmap.Canvas.StretchDraw(Rect(x,y,x+dx,y+dy), Bitmap);
  end
else
  IconBitmap.Canvas.StretchDraw(Rect(0, 0, iconX, iconY), Bitmap);
MaskBitmap:= TBitmap.Create;
MaskBitmap.Assign(IconBitmap);
with MaskBitmap.canvas do fillrect(cliprect);
IconInfo.fIcon:= True;
IconInfo.hbmMask:= MaskBitmap.MaskHandle;
IconInfo.hbmColor:= IconBitmap.Handle;
Result:= CreateIconIndirect(IconInfo);
MaskBitmap.Free;
IconBitmap.Free;
end; // bmpToHico

function msgDlg(msg:string; code:integer=0; title:string=''):integer;
var
  parent: Thandle;
begin
result:=0;
if msg='' then exit;
if code = 0 then code:=MB_OK+MB_ICONINFORMATION;
if screen.ActiveCustomForm = NIL then parent:=0
else parent:=screen.ActiveCustomForm.handle;
application.restore();
application.BringToFront();
title:=application.Title+nonEmptyConcat(' -- ', title);
result:=messageBox(parent, pchar(msg), pchar(title), code)
end; // msgDlg

function idxOf(s:string; a:array of string; isSorted:boolean=FALSE):integer;
var
  r, b, e: integer;
begin
if not isSorted then
  begin
  result:=ansiIndexText(s,a);
  exit;
  end;
// a classic one... :-P
b:=0;
e:=length(a)-1;
while b <= e do
  begin
  result:=(b+e) div 2;
  r:=ansiCompareText(s, a[result]);
  if r = 0 then exit;
  if r < 0 then e:=result-1
  else b:=result+1;
  end;
result:=-1;
end;

function stringExists(s:string; a:array of string; isSorted:boolean=FALSE):boolean;
begin result:= idxOf(s,a, isSorted) >= 0 end;

function validUsername(s:string; acceptEmpty:boolean=FALSE):boolean;
begin
result:=(s = '') and acceptEmpty
  or (s > '') and not anycharIn('/\:?*"<>|;&',s) and (length(s) <= 40)
  and not anyMacroMarkerIn(s) // mod by mars
end;

function validFilename(s:string):boolean;
begin
result:=(s>'')
  and not dirCrossing(s)
  and not anycharIn(ILLEGAL_FILE_CHARS,s)
end;

function validFilepath(fn:string; acceptUnits:boolean=TRUE):boolean;
var
  withUnit: boolean;
begin
withUnit:=(length(fn) > 2) and charInSet(fn[1], ['a'..'z','A'..'Z']) and (fn[2] = ':');

result:=(fn > '')
  and (posEx(':', fn, if_(withUnit,3,1)) = 0)
  and (poss([#0..#31,'?','*','"','<','>','|'], fn) = 0)
  and (length(fn) <= 255+if_(withUnit, 2));
end;

function loadTextFile(fn:string):string;
begin result:=UTF8toString(loadfile(fn)) end;

function loadFile(fn:string; from:int64=0; size:int64=-1):ansistring;
var
  f:file;
  bak: byte;
begin
result:='';
IOresult;
if not validFilepath(fn) then exit;
if not isAbsolutePath(fn) then chDir(exePath);
assignFile(f, fn);
bak:=fileMode;
fileMode:=0;
try
  reset(f,1);
  if IOresult <> 0 then exit;
  if (size < 0) or (size > filesize(f)-from) then
    size:=filesize(f)-from;
  setLength(result, size);
  seek(f, from);
  blockRead(f, result[1], size);
finally
  closeFile(f);
  filemode:=bak;
  end;
end; // loadFile

function saveFile(var f:file; data:ansistring):boolean; overload;
begin
blockWrite(f, data[1], length(data));
result:=IOresult=0;
end;

function forceDirectory(path:string):boolean;
var
  s: string;
begin
result:=TRUE;
path:=excludeTrailingPathDelimiter(path);
if path = '' then exit;
if directoryExists(path) then exit;
s:=extractFilePath(path);
if s = path then exit; // we are at the top, going nowhere
forceDirectory(s);
result:=createDir(path);
end; // forceDirectory

function saveFile(fn:string; data:ansistring; append:boolean=FALSE):boolean;
var
  f: file;
  path, temp: string;
begin
result:=FALSE;
try
  if not validFilepath(fn) then exit;
  if not isAbsolutePath(fn) then chDir(exePath);
  path:=extractFilePath(fn);
  if (path > '') and not forceDirectory(path) then exit;
  IOresult();
  if append then
    begin
    assignFile(f, fn);
    reset(f,1);
    if IOresult() <> 0 then rewrite(f,1)
    else seek(f,fileSize(f));
    end
  else
    begin
    // in this case, we save to a temp file, and overwrite the previous one (if it exists) only after the saving is complete
    temp:=format('%s~%d.tmp', [fn, random(MAXINT)]);
    if not validFilepath(temp) then // fn may be too long to append something
      temp:=format('hfs~%d.tmp', [fn, random(999)]);
    assignFile(f, temp);
    rewrite(f,1)
    end;

  if IOresult() <> 0 then exit;
  if not saveFile(f, data) then exit;
  closeFile(f);
  if not append then
    begin
    deleteFile(fn); // this may fail if the file didn't exist already
    renameFile(temp, fn);
    end;
  result:=TRUE;
except end;
end; // saveFile

function saveTextFile(fn:string; text:string; append:boolean=FALSE):boolean;
begin result:=saveFile(fn, UTF8encode(text), append) end;

function appendFile(fn:string; data:ansistring):boolean;
begin result:=saveFile(fn, data, TRUE) end;

function appendTextFile(fn:string; text:string):boolean;
begin result:=saveTextFile(fn, text, TRUE) end;

function getTempFilename():string;
begin result:=TPath.GetRandomFileName() end;

function saveTempFile(data:string):string;
begin result:=saveTempFile(UTF8encode(data)) end;

function saveTempFile(data:ansistring):string;
begin
result:=getTempFilename();
if result > '' then saveFile(result, data);
end; // saveTempFile

function loadregistry(key,value:string; root:HKEY=0):string;
begin
result:='';
with Tregistry.create do
  try
    try
      if root > 0 then rootKey:=root;
      if openKey(key, FALSE) then
        begin
        result:=readString(value);
        closeKey();
        end;
    finally free end
  except end
  end; // loadregistry

function saveregistry(key,value,data:string; root:HKEY=0):boolean;
begin
result:=FALSE;
with Tregistry.create do
  try
    if root > 0 then rootKey:=root;
    try
      createKey(key);
      if openKey(key, FALSE) then
        begin
        WriteString(value,data);
        closeKey;
        result:=TRUE;
        end;
    finally free end
  except end;
end; // saveregistry

function deleteRegistry(key,value:string; root:HKEY=0):boolean; overload;
var
  reg:Tregistry;
begin
reg:=Tregistry.create;
if root > 0 then reg.RootKey:=root;
result:=reg.OpenKey(key,FALSE) and reg.DeleteValue(value);
reg.free
end; // deleteRegistry

function deleteRegistry(key:string; root:HKEY=0):boolean; overload;
var
  reg:Tregistry;
  ss:TstringList;
  i:integer;
  deleteIt:boolean;
begin
reg:=Tregistry.create;
if root > 0 then reg.RootKey:=root;
result:=reg.DeleteKey(key);
// delete also parent keys, if empty
ss:=Tstringlist.create;
while key>'' do
  begin
  i:=LastDelimiter('\',key);
  if i=0 then break;
  setlength(key, i-1);
  if not reg.OpenKeyReadOnly(key) then break;
  reg.GetValueNames(ss);
  deleteIt:=(ss.count=0) and not reg.HasSubKeys;
  reg.CloseKey;
  if deleteit then reg.deleteKey(key)
  else break;
  end;
ss.free;
reg.free
end; // deleteRegistry

function resolveLnk(fn:string):string;
Var
  sl: IShellLink;
  buffer: array [0..MAX_PATH] of char;
  fd: Twin32finddata;
begin
result:=fn;
  try
    olecheck(coCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IShellLink, sl));
    olecheck((sl as IPersistFile).load(pwidechar(widestring(fn)), STGM_READ));
    olecheck(sl.resolve(0, SLR_ANY_MATCH or SLR_NO_UI));
    olecheck(sl.getPath(Buffer, MAX_PATH, fd, 0));
    result:=buffer;
  except // convertion failed, but keep original filename
  end;
end; // resolveLnk

function anycharIn(chars:Tcharset; s:string):boolean;
begin result:=poss(chars, s) > 0 end;

function anycharIn(chars, s:string):boolean;
begin result:=anyCharIn(strToCharset(chars), s) end;

function exec(cmd:string; pars:string=''; showCmd:integer=SW_SHOW):boolean;
const
  MAX_PARS = 9;
var
  pars0: string;
  i, o: integer;
  poss: array [1..MAX_PARS] of TintegerDynArray; // positions where we found the Nth parameter, in the %N form, for later substitution
  a: TintegerDynArray;
  parsA: TStringDynArray; // splitted version of pars
begin
result:=FALSE;
cmd:=trim(cmd);
if (cmd = '') or (dequote(cmd) = '') then exit;

i:=nonQuotedPos(' ', cmd);
if (cmd > '') and (cmd[1] <> '"') and (extractFileExt(cmd) > '') and (extractFileExt(substr(cmd, 0, i)) = '') then
  pars0:=''
else
  begin
  // the cmd sometimes contains parameters, because loaded from registry
  pars0:=cmd;
  // split such parameters from the real cmd
  cmd:=chop(i, pars0);
  // if pars0 contains %1, it must be replaced with the first parameter contained 'pars'.
  // Sadly we can't just replace, because 'pars' may contain %DIGIT strings (that must not be replaced). So we collect positions first, then make substitutions.
  for i:=1 to MAX_PARS do
    begin
    a:=NIL;
    o:=0;
      repeat
      o:=posEx('%'+intToStr(i), pars0, o+1);
      if o = 0 then break;
      setLength(a, length(a)+1);
      a[length(a)-1]:=o;
      until false;
    poss[i]:=a;
    end;

  parsA:=split(' ', pars, TRUE);
  // now do all the collected replacements
  for i:=1 to MAX_PARS do
    begin
    for o:=0 to length(poss[i])-1 do
      replace(pars0, parsA[i-1], poss[i][o], 1+poss[i][o]);
    if length(poss[i]) > 0 then
      removeString(parsA, i-1);
    end;
  // ok, now we have the final version of parameters
  pars:=pars0+nonEmptyConcat(' ', join(' ',parsA));
  end;
// go
result:=(cmd > '') and (32 < shellexecute(0, 'open', pchar(cmd), pchar(pars), NIL, showCmd))
end;

// exec but does not wait for the process to end
function execNew(cmd:string):boolean;
var
  si: TStartupInfo;
  pi: TProcessInformation;
begin
fillchar(si, sizeOf(si), 0);
fillchar(pi, sizeOf(pi), 0);
si.cb:=sizeOf(si);
result:=createProcess(NIL,pchar(cmd),NIL,NIL,FALSE,0,NIL,NIL,si,pi)
end; // execNew

function addArray(var dst:TstringDynArray; src:array of string; where:integer=-1; srcOfs:integer=0; srcLn:integer=-1):integer;
var
  i, l:integer;
begin
l:=length(dst);
if where < 0 then // this means: at the end of it
  where:=l;
if srcLn < 0 then
  srcLn:=length(src);
setLength(dst, l+srcLn); // enlarge your array!

i:=max(l, where+srcLn);
while i > l do // we are over newly allocated memory, just copy
  begin
  dec(i);
  dst[i]:=src[i-where+srcOfs];
  end;
while i > where+srcLn do  // we're over the existing data, just shift
  begin
  dec(i);
  dst[i+srcLn]:=dst[i];
  end;
while i > where do // we'are in middle-earth, both shift and copy
  begin
  dec(i);
  dst[i+srcLn]:=dst[i];
  dst[i]:=src[i-where+srcOfs];
  end;
result:=l+srcLn;
end; // addArray

function addUniqueArray(var a:TstringDynArray; b:array of string):integer;
var
  i, l, j, n, lb:integer;
  found: boolean;
  bi: string;
begin
l:=length(a);
n:=l; // real/final length of 'a'
lb:=length(b); // cache this value
setlength(a, l+lb);
for i:=0 to lb-1 do
  begin
  bi:=b[i]; // cache this value
  found:=FALSE;
  for j:=0 to n-1 do
    if sameText(a[j], bi) then
      begin
      found:=TRUE;
      break;
      end;
  if found then continue;
  a[n]:=bi;
  inc(n);
  end;
setLength(a, n);
result:=n-l;
end; // addUniqueArray

function if_(v:boolean; v1:boolean; v2:boolean=FALSE):boolean;
begin if v then result:=v1 else result:=v2 end;

function if_(v:boolean; v1, v2:string):string;
begin if v then result:=v1 else result:=v2 end;

function if_(v:boolean; v1:ansistring; v2:ansistring=''):ansistring; overload; inline;
begin if v then result:=v1 else result:=v2 end;

function if_(v:boolean; v1,v2:int64):int64;
begin if v then result:=v1 else result:=v2 end;

function if_(v:boolean; v1, v2:integer):integer;
begin if v then result:=v1 else result:=v2 end;

function if_(v:boolean; v1, v2:Tobject):Tobject;
begin if v then result:=v1 else result:=v2 end;

function match(mask, txt:pchar; fullMatch:boolean; charsNotWildcard:Tcharset):integer;
// charsNotWildcard is for chars that are not allowed to be matched by wildcards, like CR/LF
var
  i: integer;
begin
result:=0;
// 1 to 1 match
while not charInSet(mask^, [#0,'*'])
and (txt^ <> #0)
and (
  (ansiUpperCase(mask^) = ansiUpperCase(txt^))
  or (upCase(mask^) = upCase(txt^))
  or (mask^ = '?') and not charInSet(txt^, charsNotWildcard)
) do
  begin
  inc(mask);
  inc(txt);
  inc(result);
  end;
if (mask^ = #0) and (not fullMatch or (txt^ = #0)) then
  exit;
if mask^ <> '*' then
  begin
  result:=0;
  exit;
  end;
while mask^ = '*' do inc(mask);
if mask^ = #0 then // final *, anything matches
  begin
  inc(result, strLen(txt));
  exit;
  end;

  repeat
  if charInSet(txt^, charsNotWildcard) then break;

  if fullMatch and (strpos(mask,'*') = NIL) then
    begin // we just passed last * so we are trying to match the final part of txt. This block is just an optimization. It happens often because of mime types and masks like *.css 
    i:=length(txt)-length(mask);
    if i < 0 then break; // not enough characters left
    // move forward of the minimum part that's required to be covered by the last *
    inc(txt, i);
    inc(result, i);
    i:=match(mask, txt, fullMatch);
    if i = 0 then break; // no more chances
    end
  else
    i:=match(mask, txt, fullMatch);

  if i > 0 then
    begin
    inc(result, i);
    exit;
    end;
  // we're after a *, next part may match at any point, so try it in every way
  inc(txt);
  inc(result);
  until txt^ = #0;
result:=0;
end; // match

function filematch(mask, fn:string):boolean;
var
  invert: integer;
begin
result:=TRUE;
invert:=0;
while (invert < length(mask)) and (mask[invert+1] = '\') do
  inc(invert);
delete(mask,1,invert);
while mask > '' do
  begin
  result:=match( pchar(chop(';',mask)), pchar(fn) ) > 0;
  if result then break;
  end;
result:=result xor odd(invert);
end; // filematch

function checkAddressSyntax(address:string; wildcards:boolean=TRUE):boolean;
var
  a1, a2: string;
  i, dots, lastDot: integer;
  wildcardsMet: boolean;

  function validNumber():boolean;
  begin result:=strToIntDef(substr(a1,lastDot+1,i-1), 0) <= 255 end;

begin
result:=FALSE;
if address = '' then exit;
while (address > '') and (address[1] = '\') do delete(address,1,1);
while address > '' do
  begin
  a2:=chop(';', address);
  if sameText(a2, 'lan') then continue;
  a1:=chop('-', a2);
  if a2 > '' then
    if not checkAddressSyntax(a1, FALSE)
    or not checkAddressSyntax(a2, FALSE) then
      exit;
  wildcardsMet:=FALSE;
  dots:=0;
  lastDot:=0;
  for i:=1 to length(a1) do
    case a1[i] of
      '.':
        begin
        if not validNumber() then exit;
        lastDot:=i;
        inc(dots);
        end;
      '0'..'9': ;
      '?','*' : if wildcards then wildcardsMet:=TRUE else exit;
      else exit;
      end;
  if (dots > 3) or not wildcardsMet and (dots <> 3) then exit;
  end;
result:=validNumber();
end; // checkAddressSyntax

function addressMatch(mask, address:string):boolean;
var
  invert: boolean;
  part1, part2: string;
  addrInt: dword;
  ofs, i, bits: integer;
  masks: TStringDynArray;
  mode: (SINGLE, BITMASK, RANGE);
begin
result:=FALSE;
invert:=FALSE;
while (mask > '') and (mask[1] = '\') do
  begin
  delete(mask,1,1);
  invert:=not invert;
  end;
addrInt:=ipToInt(address);
masks:=split(';',mask);
ofs:=1;
while not result and (ofs <= length(mask)) do
  begin
  mode:=SINGLE;
  part1:=trim(substr(mask, ofs, max(0,posEx(';', mask, ofs)-1) ));
  inc(ofs, length(part1)+1);

  if sameText(part1, 'lan') then
    begin
    result:=isLocalIP(address);
    continue;
    end;

  i:=lastDelimiter('-/', part1);
  if i > 0 then
    begin
    if part1[i] = '-' then mode:=RANGE
    else mode:=BITMASK;
    part2:=part1;
    part1:=chop(i, 1, part2);
    end;

  case mode of
    SINGLE: result:=match( pchar(part1), pchar(address) ) > 0;
    RANGE: result:=(addrInt >= ipToInt(part1)) and (addrInt <= ipToInt(part2));
    BITMASK:
      try
        bits:=32-strToInt(part2);
        result:=addrInt shr bits = ipToInt(part1) shr bits;
      except end;
    end;
  end;
result:=result xor invert;
end; // addressMatch

function freeIfTemp(var f:Tfile):boolean; inline;
begin
try
  result:=assigned(f) and f.isTemp();
  if result then freeAndNIL(f);
except result:=FALSE end;
end; // freeIfTemp

function uri2disk(url:string; parent:Tfile=NIL; resolveLnk:boolean=TRUE):string;
var
  fi: Tfile;
  i: integer;
  append: string;
begin
// don't consider wildcard-part when resolving
i:=reMatch(url, '[?*]', '!');
if i = 0 then
  append:=''
else
  begin
  i:=lastDelimiter('/', url);
  append:=substr(url,i);
  if i>0 then append[1]:='\';
  delete(url,i, MaxInt);
  end;
try
  fi:=mainfrm.findFilebyURL(url, parent);
  try result:=ifThen(resolveLnk or (fi.lnk=''), fi.resource, fi.lnk) +append;
  finally freeIfTemp(fi) end;
except result:='' end;
end; // uri2disk

function uri2diskMaybe(path:string; parent:Tfile=NIL; resolveLnk:boolean=TRUE):string;
begin
if ansiContainsStr(path, '/') then result:=uri2disk(path, parent, resolveLnk)
else result:=path;
end; // uri2diskmaybe

function sizeOfFile(fh:Thandle):int64; overload;
var
  h, l: dword;
begin
l:=getFileSize(fh, @h);
if (l = $FFFFFFFF) and (getLastError() <> NO_ERROR) then result:=-1
else result:=l+int64(h) shl 32;
end; // sizeOfFile

function sizeOfFile(fn:string):int64; overload;
var
  h: Thandle;
begin
if ansiStartsText('http://', fn) then
  begin
  result:=httpFilesize(fn);
  exit;
  end;
if ansiContainsStr(fn, '/') then fn:=uri2disk(fn);
h:=fileopen(fn, fmOpenRead+fmShareDenyNone);
result:=sizeOfFile(h);
fileClose(h);
end; // sizeOfFile

function isAbsolutePath(path:string):boolean;
begin result:=(path > '') and (path[1] = '\') or (length(path) > 1) and (path[2] = ':') end;

function min(a,b:integer):integer; inline;
begin if a>b then result:=b else result:=a end;

function fileOrDirExists(fn:string):boolean;
begin
result:=fileExists(fn) or directoryExists(fn);
{** first i used this way, because faster, but it proved to not always work: http://www.rejetto.com/forum/index.php/topic,10825.0.html
var
  sr:TsearchRec;
begin
result:= 0=findFirst(ExcludeTrailingPathDelimiter(fn),faAnyFile,sr);
if result then FindClose(sr);
}
end; // fileOrDirExists

function int0(i,digits:integer):string;
begin
result:=intToStr(i);
result:=stringOfChar('0',digits-length(result))+result;
end; // int0

function elapsedToStr(t:Tdatetime):string;
var
  sec: integer;
begin
sec:=trunc(t*SECONDS);
result:=format('%d:%.2d:%.2d', [sec div 3600, sec div 60 mod 60, sec mod 60] );
end; // elapsedToStr

// ensure f.accounts does not store non-existent users
function cbPurgeVFSaccounts(f:Tfile; callingAfterChildren:boolean; par, par2:integer):TfileCallbackReturn;
var
  usernames, renamings: THashedStringList;
  i: integer;
  act: TfileAction;
  u, n: string;
begin
result:=[];
usernames:=THashedStringList(par);
renamings:=THashedStringList(par2);
for act:=low(act) to high(act) do
  for i:=length(f.accounts[act])-1 downto 0 do
    begin
    u:=f.accounts[act][i];
    n:=renamings.values[u];
    if n > '' then
      begin
      f.accounts[act][i]:=n;
      VFSmodified:=TRUE;
      continue;
      end;
    if (u = '')
    or not charInSet(u[1], ['@','*']) and (usernames.indexOf(u) < 0) then
      begin
      removeString(f.accounts[act], i);
      VFSmodified:=TRUE;
      end;
    end;
end; // cbPurgeVFSaccounts

procedure purgeVFSaccounts();
var
  usernames, renamings: THashedStringList;
  i: integer;
  a: Paccount;
begin
usernames:=THashedStringList.create;
renamings:=THashedStringList.create;
try
  for i:=0 to length(accounts)-1 do
    begin
    a:=@accounts[i];
    usernames.add(a.user);
    if (a.wasUser > '') and (a.user <> a.wasUser) then
      renamings.Values[a.wasUser]:=a.user;
    end;
  rootFile.recursiveApply(cbPurgeVFSaccounts, integer(usernames), integer(renamings));
finally
  usernames.free;
  renamings.free;
  end;
end; // purgeVFSaccounts

function inputQueryLong(const caption, msg:string; var value:string; ofs:integer=0):boolean;
begin
inputQueryLongdlg.Caption:=caption;
inputQueryLongdlg.msgLbl.Caption:='  '+replaceStr(msg, #13,#13'  ');
inputQueryLongdlg.inputBox.Text:=value;
inputQueryLongdlg.inputBox.SelStart:=ofs;
// i want focus on the editor, but setFocus works only on visible windows -_-' any better idea?
inputQueryLongdlg.show();                                                   
inputQueryLongdlg.inputBox.SetFocus();
inputQueryLongdlg.hide();
result:=inputQueryLongdlg.ShowModal() = mrOk;
if result then value:=inputQueryLongdlg.inputBox.Text;
end; // inputQueryLong

function httpGet(url:string; from:int64=0; size:int64=-1):string;
var
  http: THttpCli;
  reply: Tstringstream;
begin
if size = 0 then
  begin
  result:='';
  exit;
  end;
reply:=TStringStream.Create('');
try
  http:=Thttpcli.create(NIL);
  try
    http.URL:=url;
    http.followRelocation:=TRUE;
    http.rcvdStream:=reply;
    http.agent:=HFS_HTTP_AGENT;
    if (from <> 0) or (size > 0) then
      http.contentRangeBegin:=intToStr(from);
    if size > 0 then
      http.contentRangeEnd:=intToStr(from+size-1);
    http.get();
    result:=reply.dataString;
  finally http.free end
finally reply.free end
end; // httpGet

function httpFileSize(url:string):int64;
var
  http: THttpCli;
begin
http:=Thttpcli.create(NIL);
try
  http.URL:=url;
  http.Agent:=HFS_HTTP_AGENT;
  try
    http.head();
    result:=http.contentLength
  except result:=-1 end;
finally http.free end
end; // httpFileSize

function httpGetFile(url, filename:string; tryTimes:integer=1; notify:TdocDataEvent=NIL):boolean;
var
  http: THttpCli;
  reply: Tfilestream;
  supposed: integer;
begin
reply:=TfileStream.Create(filename, fmCreate);
try
  http:=Thttpcli.create(NIL);
  try
    http.URL:=url;
    http.RcvdStream:=reply;
    http.Agent:=HFS_HTTP_AGENT;
    http.OnDocData:=notify;
    result:=TRUE;
    try http.get()
    except result:=FALSE end;
    supposed:=http.ContentLength;
  finally http.free end
finally reply.free end;
result:= result and (sizeOfFile(filename)=supposed);
if not result then deleteFile(filename);

if not result and (tryTimes > 1) then
  result:=httpGetFile(url, filename, tryTimes-1, notify);
end; // httpGetFile

function getExternalAddress(var res:string; provider:Pstring=NIL):boolean;

  procedure loadIPservices(src:string='');
  var
    l:string;
  begin
  if src = '' then
    begin
    if now()-IPservicesTime < 1 then exit; // once a day
    IPservicesTime:=now();
    try src:=trim(httpGet(IP_SERVICES_URL));
    except exit end;
    end;
  IPservices:=NIL;
  while src > '' do
    begin
    l:=chopLine(src);
    if ansiStartsText('http://', l) then addString(l, IPservices);
    end;
  end; // loadIPservices

const {$J+}
  lastProvider: string = ''; // this acts as a static variable
var
  s, mark, addr: string;
  i: integer;
begin
result:=FALSE;
if customIPservice > '' then s:=customIPservice
else
  begin
  loadIPservices();
  if IPservices = NIL then
    loadIPservices(getRes('IPservices'));
  if IPservices = NIL then
    exit;

    repeat
      s:=IPservices[random(length(IPservices))];
    until (s <> lastProvider) or (length(IPservices) < 2);
  lastProvider:=s;
  end;
addr:=chop('|',s);
if assigned(provider) then provider^:=addr;
mark:=s;
try s:=httpGet(addr);
except exit end;
if mark > '' then chop(mark, s);
s:=trim(s);
if s = '' then exit;
// try to determine length
i:=1;
while (i < length(s)) and (i < 15) and charInSet(s[i+1], ['0'..'9','.']) do inc(i);
while (i > 0) and (s[i] = '.') do dec(i);
setLength(s,i);
result:= checkAddressSyntax(s) and not HSlib.isLocalIP(s);
if not result then exit;
if (res <> s) and mainFrm.logOtherEventsChk.checked then
  mainFrm.add2log('New external address: '+s+' via '+hostFromURL(addr));
res:=s;
end; // getExternalAddress

function whatStatusPanel(statusbar:Tstatusbar; x:integer):integer;
var
  x1: integer;
begin
result:=0;
x1:=statusbar.panels[0].width;
while (x > x1) and (result < statusbar.Panels.Count-1) do
  begin
  inc(result);
  inc(x1, statusbar.panels[result].width);
  end;
end; // whatStatusPanel

function getIPs():TStringDynArray;
begin
try result:=listToArray(localIPlist) except result:=NIL end;
end;

function getPossibleAddresses():TstringDynArray;
begin // next best
result:=toSA([defaultIP, dyndns.host]);
addArray(result, customIPs);
addString(externalIP, result);
addArray(result, getIPs());
removeStrings('', result);
uniqueStrings(result);
end; // getPossibleAddresses

function getFilename(var f:file):string;
begin result:=pchar(@f)+72 end;

function filenameToDriveByte(fn:string):byte;
begin
if (length(fn) < 2) or (fn[2] <> ':') then fn:=exePath; // relative paths are actually based on the same drive of the executable
fn:=getDrive(fn);
if fn = '' then
  result:=0
else
  result:=ord(upcase(fn[1]))-ord('A')+1;
end; // filenameToDriveByte

function smartsize(size:int64):string;
begin
if size < 0 then result:='N/A'
else
  if size < 1 shl 10 then result:=intToStr(size)
  else
    if size < 1 shl 20 then result:=format('%.1f K',[size/(1 shl 10)])
    else
      if size < 1 shl 30 then result:=format('%.1f M',[size/(1 shl 20)])
      else result:=format('%.1f G',[size/(1 shl 30)])
end; // smartsize

function cbSelectFolder(wnd:HWND; uMsg:UINT; lp,lpData:LPARAM):LRESULT; stdcall;
begin
result:=0;
if (uMsg <> BFFM_INITIALIZED) or (lpdata = 0) then exit;
SendMessage(wnd, BFFM_SETSELECTION, 1, LPARAM(pchar(lpdata)));
SendMessage(wnd, BFFM_ENABLEOK, 0, 1);
end; // cbSelectFolder

function selectWrapper(caption:string; var from:string; flags:dword=0):boolean;
const
  BIF_NEWDIALOGSTYLE = $40;
  BIF_UAHINT = $100;
  BIF_SHAREABLE = $8000;
var
  bi: TBrowseInfo;
  res: PItemIDList;
  buff: array [0..MAX_PATH] of char;
  im: iMalloc;
begin
result:=FALSE;
if SHGetMalloc(im) <> 0 then exit;
bi.hwndOwner:=GetActiveWindow();
bi.pidlRoot:=NIL;
bi.pszDisplayName:=@buff;
bi.lpszTitle:=pchar(caption);
bi.ulFlags:=BIF_RETURNONLYFSDIRS+BIF_NEWDIALOGSTYLE+BIF_SHAREABLE+BIF_UAHINT+BIF_EDITBOX+flags;
bi.lpfn:=@cbSelectFolder;
bi.lParam:=integer(@from[1]);
bi.iImage:=0;
res:=SHBrowseForFolder(bi);
if res = NIL then exit;
if not SHGetPathFromIDList(res, buff) then exit;
im.Free(res);
from:=buff;
result:=TRUE;
end; // selectWrapper

function selectFolder(caption:string; var folder:string):boolean;
begin result:=selectWrapper(caption, folder) end;

// works only on XP
function selectFileOrFolder(caption:string; var fileOrFolder:string):boolean;
begin result:=selectWrapper(caption, fileOrFolder, BIF_BROWSEINCLUDEFILES) end;

function selectFile(var fn:string; title, filter:string; options:TOpenOptions):boolean;
var
  dlg: TopenDialog;
begin
result:=FALSE;
dlg:=TopenDialog.create(screen.activeForm);
if title > '' then dlg.Title:=title;
dlg.Filter:=filter;
if fn > '' then
  begin
  dlg.FileName:=fn;
  if not isAbsolutePath(fn) then dlg.InitialDir:=exePath;
  end;
try
  dlg.Options:=[ofEnableSizing]+options;
  if not dlg.Execute() then exit;
  fn:=dlg.FileName;
  result:=TRUE;
finally dlg.free end;
end; // selectFile

function safeMod(a,b:int64; default:int64=0):int64;
begin if b=0 then result:=default else result:=a mod b end;

function safeDiv(a,b:int64; default:int64=0):int64; inline;
begin if b=0 then result:=default else result:=a div b end;

function safeDiv(a,b:real; default:real=0):real; inline;
begin if b=0 then result:=default else result:=a/b end;

function isExtension(filename, ext:string):boolean;
begin result:= 0=ansiCompareText(ext, extractFileExt(filename)) end;

function getTill(ss, s:string; included:boolean=FALSE):string;
var
  i: integer;
begin
i:=pos(ss, s);
if i = 0 then result:=s
else result:=copy(s,1,i-1+if_(included,length(ss)));
end; // getTill

function getTill(i:integer; s:string):string;
begin
if i < 0 then i:=length(s)+i;
result:=copy(s, 1, i);
end; // getTill

function dateToHTTP(filename:string):string; overload;
begin result:=dateToHTTP(getMtimeUTC(filename)) end;

function dateToHTTP(gmtTime:Tdatetime):string; overload;
begin
result:=formatDateTime('"'+DOW2STR[dayOfWeek(gmtTime)]+'," dd "'+MONTH2STR[monthOf(gmtTime)]
  +'" yyyy hh":"nn":"ss "GMT"', gmtTime);
end; // dateToHTTP

function getEtag(filename:string):string;
var
  sr: TsearchRec;
  st: TSystemTime;
begin
result:='';
if findFirst(filename, faAnyFile, sr) <> 0 then exit;
FileTimeToSystemTime(sr.FindData.ftLastWriteTime, st);
result:=intToStr(sr.Size)+':'+floatToStr(SystemTimeToDateTime(st))+':'+expandFileName(filename);
findClose(sr);
result:=StrMD5(result);
end; // getEtag

function getMtimeUTC(filename:string):Tdatetime;
var
  sr: TsearchRec;
  st: TSystemTime;
begin
result:=0;
if findFirst(filename, faAnyFile, sr) <> 0 then exit;
FileTimeToSystemTime(sr.FindData.ftLastWriteTime, st);
result:=SystemTimeToDateTime(st);
findClose(sr);
end; // getMtimeUTC

function getMtime(filename:string):Tdatetime;
begin
if not fileAge(filename, result) then
  result:=0;
end; // getMtime

function ipToInt(ip:string):dword;
var
  i: integer;
begin
i:=ipToInt_cache.Add(ip);
result:=dword(ipToInt_cache.Objects[i]);
if result <> 0 then exit;
result:=WSocket_ntohl(WSocket_inet_addr(ansistring(ip)));
ipToInt_cache.Objects[i]:=Tobject(result);
end; // ipToInt

function getShellFolder(id:string):string;
begin
result:=loadregistry(
  'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', id,
  HKEY_CURRENT_USER);
end; // getShellFolder

function createShellLink(linkFN:WideString; destFN:string):boolean;
var
  ShellObject: IUnknown;
begin
shellObject:=CreateComObject(CLSID_ShellLink);
result:=((shellObject as IShellLink).setPath(PChar(destFN)) = NOERROR)
  and ((shellObject as IPersistFile).Save(PWChar(linkFN), False) = S_OK)
end; // createShellLink

function readShellLink(linkFN:WideString):string;
var
  ShellObject: IUnknown;
  pfd: _WIN32_FIND_DATA;
begin
shellObject:=CreateComObject(CLSID_ShellLink);
if (shellObject as IPersistFile).Load(PWChar(linkFN), 0) <> S_OK then
  raise Exception.create('readShellLink: cannot load');
setLength(result, MAX_PATH);
if (shellObject as IShellLink).getPath(pchar(result), length(result), pfd, 0) <> NOERROR then
  raise Exception.create('readShellLink: cannot getPath');
setLength(result, strLen(pchar(result)));
end; // readShellLink

function selectFiles(caption:string; var files:TStringDynArray):boolean;
var
  dlg: TopenDialog;
  i: integer;
begin
dlg:=TopenDialog.create(screen.activeForm);
try
  dlg.Options:=dlg.Options+[ofAllowMultiSelect, ofFileMustExist, ofPathMustExist];
  result:=dlg.Execute();
  if result then
    begin
    setLength(files, dlg.Files.count);
    for i:=0 to dlg.files.Count-1 do
      files[i]:=dlg.files[i];
    end;
finally dlg.free end;
end;

function eos(s:Tstream):boolean;
begin result:=s.position >= s.size end;

function singleLine(s:string):boolean;
var
  i, l: integer;
begin
i:=pos(#13,s);
l:=length(s);
result:=(i = 0) or (i = l) or (i = l-1) and (s[l] = #10)
end; // singleLine

function setClip(s:string):boolean;
begin
result:=TRUE;
try clipboard().AsText:=s
except result:=FALSE end;
end; // setClip

function getStr(from, to_:pchar):string;
var
  l: integer;
begin
result:='';
if (from = NIL) or assigned(to_) and (from > to_) then exit;
if to_ = NIL then
  begin
  to_:=strEnd(from);
  dec(to_);
  end;
l:=to_-from+1;
setLength(result, l);
if l > 0 then strLcopy(@result[1], from, l);
end; // getStr

function poss(chars:TcharSet; s:string; ofs:integer=1):integer;
begin
for result:=ofs to length(s) do
  if charInSet(s[result], chars) then
    exit;
result:=0;
end; // poss

function isNT():boolean;
var
  vi: TOSVERSIONINFO;
begin
result:=TRUE;
vi.dwOSVersionInfoSize:=sizeOf(vi);
if not windows.getVersionEx(vi) then exit;
result:= vi.dwPlatformId = VER_PLATFORM_WIN32_NT;
end; // isNT

function getTempDir():string;
begin
setLength(result, 1000);
setLength(result, getTempPath(length(result), @result[1]));
end; // getTempDir

function blend(from,to_:Tcolor; perc:real):Tcolor;
var
  i: integer;
begin
result:=0;
from:=ColorToRGB(from);
to_:=ColorToRGB(to_);
for i:=0 to 2 do
  inc(result, min($FF, round(((from shr (i*8)) and $FF)*(1-perc)
    +((to_ shr (i*8)) and $FF)*perc)) shl (i*8));
end; // blend

function listToArray(l:Tstrings):TstringDynArray;
var
  i: integer;
begin
try
  setLength(result, l.Count);
  for i:=0 to l.Count-1 do
    result[i]:=l[i];
except
  result:=NIL
  end
end; // listToArray

function jsEncode(s, chars:string):string;
var
  i: integer;
begin
for i:=1 to length(chars) do
  s:=ansiReplaceStr(s, chars[i], '\x'+intToHex(ord(chars[i]),2));
result:=s;
end; // jsEncode

function holdingKey(key:integer):boolean;
begin result:=getAsyncKeyState(key) and $8000 <> 0 end;

// concat pre+s+post only if s is non empty
function nonEmptyConcat(pre, s:string; post:string=''):string;
begin if s = '' then result:='' else result:=pre+s+post end;

// returns the first non empty string
function first(a:array of string):string;
var
  i: integer;
begin
result:='';
for i:=0 to length(a)-1 do
  begin
  result:=a[i];
  if result > '' then exit;
  end;
end; // first

function first(a,b:string):string;
begin if a = '' then result:=b else result:=a end;

function first(a,b:ansistring):ansistring;
begin if a = '' then result:=b else result:=a end;

function first(a,b:integer):integer;
begin if a = 0 then result:=b else result:=a end;

function first(a,b:double):double;
begin if a = 0 then result:=b else result:=a end;

function first(a,b:pointer):pointer;
begin if a = NIL then result:=b else result:=a end;

// taken from http://www.delphi3000.com/articles/article_3361.asp
function captureExec(DosApp : string; out output:string; out exitcode:cardinal; timeout:real=0):boolean;
const
  ReadBuffer = 1048576;  // 1 MB Buffer
var
  sa            : TSecurityAttributes;
  ReadPipe,WritePipe  : THandle;
  start               : TStartUpInfoA;
  ProcessInfo         : TProcessInformation;
  Buffer              : Pansichar;
  TotalBytesRead,
  BytesRead           : DWORD;
  Apprunning,
  BytesLeftThisMessage,
  TotalBytesAvail : integer;
begin
result:=FALSE;
output:='';
sa.nlength:=SizeOf(sa);
sa.binherithandle:=TRUE;
sa.lpsecuritydescriptor:=NIL;

if not createPipe(ReadPipe, WritePipe, @sa, 0) then exit;
// Redirect In- and Output through STARTUPINFO structure
Buffer:=AllocMem(ReadBuffer + 1);
FillChar(Start,Sizeof(Start),#0);
start.cb:= SizeOf(start);
start.hStdOutput:= WritePipe;
start.hStdInput:= ReadPipe;
start.dwFlags:= STARTF_USESTDHANDLES + STARTF_USESHOWWINDOW;
start.wShowWindow:= SW_HIDE;
TotalBytesRead:=0;
if timeout = 0 then
  timeout:=MaxExtended
else
  timeout:=now()+timeout/SECONDS;
// Create a Console Child Process with redirected input and output
try
  if CreateProcessA(nil, PansiChar(ansistring(DosApp)), @sa, @sa, true, CREATE_NO_WINDOW or NORMAL_PRIORITY_CLASS, nil, nil, start, ProcessInfo) then
    repeat
    result:=TRUE;
    // wait for end of child process
    Apprunning := WaitForSingleObject(ProcessInfo.hProcess,100);
    Application.ProcessMessages();
    // it is important to read from time to time the output information
    // so that the pipe is not blocked by an overflow. New information
    // can be written from the console app to the pipe only if there is
    // enough buffer space.
    if not PeekNamedPipe(ReadPipe, @Buffer[TotalBytesRead], ReadBuffer,
      @BytesRead, @TotalBytesAvail, @BytesLeftThisMessage ) then
      break
    else if BytesRead > 0 then
      ReadFile(ReadPipe, Buffer[TotalBytesRead], BytesRead, BytesRead, nil );
    inc(TotalBytesRead, BytesRead);
    until (Apprunning <> WAIT_TIMEOUT) or (now() >= timeout);
  Buffer[TotalBytesRead]:= #0;
  OemToCharA(PansiChar(Buffer),Buffer);
  output:=string(ansistrings.strPas(Buffer));
finally
  GetExitCodeProcess(ProcessInfo.hProcess, exitcode);
  TerminateProcess(ProcessInfo.hProcess, 0);
  FreeMem(Buffer);
  CloseHandle(ProcessInfo.hProcess);
  CloseHandle(ProcessInfo.hThread);
  CloseHandle(ReadPipe);
  CloseHandle(WritePipe);
  end;
end; // captureExec

function port2pid(port:string):integer;
var
  s, l, p: string;
  code: cardinal;
begin
result:=-1;
if not captureExec('netstat -naop tcp', s, code) then
  exit;
  
while s > '' do
  begin
  l:=chopline(s);
  if pos('LISTENING', l) = 0 then continue;
  chop(':', l);
  p:=chop(' ',l);
  if p <> port then continue;
  chop('LISTENING', l);
  result:=strToIntDef(trim(l), -1);
  exit;
  end;
end; // port2pid

function pid2file(pid:integer):string;
var
  h: Thandle;
begin
result:='';
// this is likely to fail on Vista if we are querying a service, because we are running with less privs
h:=openProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, FALSE, pid);
if h = 0 then exit;
try
  setLength(result, MAX_PATH);
  if getModuleFileNameEx(h, 0, pchar(Result), MAX_PATH) > 0 then
    setLength(result, strLen(pchar(result)))
  else
    result:=''
finally closeHandle(h) end;
end; // pid2file

function stripChars(s:string; cs:Tcharset; invert:boolean=FALSE):string;
var
  i, l, ofs: integer;
  b: boolean;
begin
l:=length(s);
i:=1;
ofs:=0;
while i+ofs <= l do
  begin
  b:=charInSet(s[i+ofs], cs) xor invert;
  if b then inc(ofs);
  if i+ofs > l then break;
  if ofs > 0 then s[i]:=s[i+ofs];
  if not b then inc(i);
  end;
setLength(s, l-ofs);
result:=s;
end; // stripChars

function isOnlyDigits(s:string):boolean;
var
  i: integer;
begin
result:=FALSE;
for i:=length(s) downto 1 do
  if not charInSet(s[i], ['0'..'9']) then
    exit;
result:=TRUE;
end; // isOnlyDigits

function openURL(url:string):boolean;
begin
result:=exec(url);
end; // openURL

// tells if a substring is found at specific position
function strAt(s, ss:string; at:integer):boolean; inline;
begin
if (ss = '') or (length(s) < at+length(ss)-1) then result:=FALSE
else if length(ss) = 1 then result:=s[at] = ss[1]
else if length(ss) = 2 then result:=(s[at] = ss[1]) and (s[at+1] = ss[2])
else result:=copy(s,at,length(ss)) = ss;
end; // strAt

function swapMem(var src,dest; count:dword; cond:boolean=TRUE):boolean; inline;
var
  temp:pointer;
begin
result:=cond;
if not cond then exit;
getmem(temp, count);
move(src, temp^, count);
move(dest, src, count);
move(temp^, dest, count);
freemem(temp, count);
end; // swapMem

function replace(var s:string; ss:string; start,upTo:integer):integer;
var
  common, oldL, surplus: integer;
begin
oldL:=upTo-start+1;
common:=min(length(ss), oldL);
move(ss[1], s[start], common*SizeOf(char));
surplus:=oldL-length(ss);
if surplus > 0 then delete(s, start+length(ss), surplus)
else insert(copy(ss, common+1, -surplus), s, start+common);
result:=-surplus;
end; // replace

function substr(s:string; start:integer; upTo:integer=0):string; inline;
var
  l: integer;
begin
l:=length(s);
if start = 0 then inc(start)
else if start < 0 then start:=l+start+1;
if upTo <= 0 then upTo:=l+upTo;
result:=copy(s, start, upTo-start+1)
end; // substr

function substr(s:string; after:string):string;
var
  i: integer;
begin
i:=pos(after,s);
if i = 0 then result:=''
else result:=copy(s, i+length(after), MAXINT)
end; // substr

function xtpl(src:string; table:array of string):string; overload;
var
  i:integer;
begin
i:=0;
while i < length(table) do
  begin
  src:=replaceText(src,table[i],table[i+1]);
  inc(i, 2);
  end;
result:=src;
end; // xtpl

function clearAndReturn(var v:string):string;
begin
result:=v;
v:='';
end;

procedure drawCentered(cnv:Tcanvas; r:Trect; text:string);
begin drawText(cnv.Handle, pchar(text), length(text), r, DT_CENTER+DT_NOPREFIX+DT_VCENTER+DT_END_ELLIPSIS) end;

function minmax(min, max, v:integer):integer; inline;
begin
if v < min then result:=min
else if v > max then result:=max
else result:=v
end;

function isLocalIP(ip:string):boolean;
begin result:=checkAddressSyntax(ip, FALSE) and HSlib.isLocalIP(ip) end;

function reduceSpaces(s:string; replacement:string=' '; spaces:TcharSet=[]):string;
var
  i, c, l: integer;
begin
if spaces = [] then include(spaces, ' ');
i:=0;
l:=length(s);
while i < l do
  begin
  inc(i);
  c:=i;
  while (c <= l) and charInSet(s[c], spaces) do
    inc(c);
  if c = i then continue;
  replace(s, replacement, i, c-1);
  end;
result:=s;
end; // reduceSpaces

function countSubstr(ss:string; s:string):integer;
var
  i, l: integer;
  c: char;
begin
result:=0;
l:=length(ss);
if l = 1 then
  begin
  l:=length(s);
  c:=ss[1];
  for i:=1 to l do
    if s[i] = c then
      inc(result);
  exit;
  end;
i:=1;
  repeat
  i:=posEx(ss, s, i);
  if i = 0 then exit;
  inc(result);
  inc(i, l);
  until false;
end; // countSubstr

function trim2(s:string; chars:Tcharset):string;
var
  b, e: integer;
begin
b:=1;
while (b <= length(s)) and charInSet(s[b], chars) do inc(b);
e:=length(s);
while (e > 0) and charInSet(s[e], chars) do dec(e);
result:=substr(s, b, e);
end; // trim2

function boolOnce(var b:boolean):boolean;
begin result:=b; b:=FALSE end;

procedure urlToStrings(s:ansistring; sl:Tstrings);
var
  i, l, p: integer;
  t: string;
  a: ansistring;
begin
i:=1;
l:=length(s);
while i <= l do
  begin
  p:=ansistrings.posEx('&',s,i);
  a:=copy(s,i,if_(p=0,length(s),p-i));
  a:=ansistrings.replaceStr(a, '+',' ');
  t:=decodeURL(a); // TODO should we instead try to decode utf-8? doing so may affect calls to {.force ansi.} in the template
  sl.add(t);
  if p = 0 then exit;
  i:=p+1;
  end;
end; // urlToStrings

// extract at p the section name of a text, if any
function getSectionAt(p:pchar; out name:string):boolean;
var
 eos, eol: pchar;
begin
result:=FALSE;
if (p = NIL) or (p^ <> '[') then exit;
eos:=p;
while eos^ <> ']' do
  if charInSet(eos^, [#0, #10, #13]) then exit
  else inc(eos);
// ensure the line is termineted correctly
eol:=eos;
inc(eol);
while not charInSet(eol^, [#10,#0]) do
  if not charInSet(eol^, [#9,#32,#13]) then exit
  else inc(eol);
inc(p);
dec(eos);
name:=getStr(p, eos);
result:=TRUE;
end; // getSectionAt

function isSectionAt(p:pchar):boolean;
var
  trash: string;
begin
result:=getSectionAt(p, trash);
end; // isSectionAt

procedure doNothing();
begin end;

// calculates the value of a constant formula
function evalFormula(s:string):real;
// this algo is by far not the quickest, because it manipulates the string, but it's the simpler that came to my mind
const
  PAR_VAL = 100;
var
  i, v,
  mImp, // index of the most important operator
  mImpV: integer; // importance of the most important
  ofsImp: integer; // importance offset, due to parenthesis
  ch: char;
  left, right: real;
  leftS, rightS: string;

  function getOperand(dir:integer):string;
  var
    j: integer;
  begin
  i:=mImp+dir;
    repeat
    j:=i+dir;
    if (j > 0) and (j <= length(s)) and charInSet(s[j], ['0'..'9','.']) then
      i:=j
    else
      break;
    until false;
  j:=mImp+dir;
  swapMem(i, j, sizeOf(i), dir > 0);
  j:=j-i+1;
  result:=copy(s, i, j);
  end; // getOperand

begin
  repeat
  // search the most urgent operator
  ofsImp:=0;
  mImp:=0;
  mImpV:=0;
  for i:=1 to length(s) do
    begin
    // calculate operator precedence (if any)
    ch:=s[i];
    v:=0;
    case ch of
      '*','/','%','[',']': v:=5+ofsImp;
      '+','-': v:=3+ofsImp;
      '(': inc(ofsImp, PAR_VAL);
      ')': dec(ofsImp, PAR_VAL);
      end;

    if (i = 1) // a starting operator is not an operator
    or (v <= mImpV) // left-to-right precedence
    then continue;
    // we got a better one, record it
    mImpV:=v;
    mImp:=i;
    end;//for

  // found or not?
  if mImp = 0 then
    begin
    result:=strToFloat(s);
    exit;
    end;
  // determine operates
  leftS:=getOperand(-1);
  rightS:=getOperand(+1);
  left:=StrToFloatDef(trim(leftS), 0);
  right:=strToFloat(trim(rightS));
  // calculate
  ch:=s[mImp];
  case ch of
    '+': result:=left+right;
    '-': result:=left-right;
    '*': result:=left*right;
    '/':
      if right <> 0 then result:=left/right
      else raise Exception.create('division by zero');
    '%':
      if right <> 0 then result:=trunc(left) mod trunc(right)
      else raise Exception.create('division by zero');
    '[': result:=round(left) shl round(right);
    ']': result:=round(left) shr round(right);
    else raise Exception.create('operator not supported: '+ch);
    end;
  // replace sub-expression with result
  i:=mImp-length(leftS);
  v:=mImp+length(rightS);
  if (i > 1) and (v < length(s)) and (s[i-1] = '(') and (s[v+1] = ')') then
    begin  // remove also parenthesis
    dec(i);
    inc(v);
    end;
  if v-i+1 = length(s) then exit; // we already got the result
  replace(s, floatToStr(result), i, v);
  until false;
end; // evalFormula

function getUniqueName(start:string; exists:TnameExistsFun):string;
var
  i: integer;
begin
result:=start;
if not exists(result) then exit;
i:=2;
  repeat
  result:=format('%s (%d)', [start,i]);
  inc(i);
  until not exists(result);
end; // getUniqueName

function accountIcon(isEnabled, isGroup:boolean):integer; overload;
begin result:=if_(isGroup, if_(isEnabled,29,40), if_(isEnabled,27,28)) end;

function accountIcon(a:Paccount):integer; overload;
begin result:=accountIcon(a.enabled, a.group) end;

function newMenuSeparator(lbl:string=''):Tmenuitem;
begin
result:=newItem('-',0,FALSE,TRUE,NIL,0,'');
result.hint:=lbl;
result.onDrawItem:=mainfrm.menuDraw;
result.OnMeasureItem:=mainfrm.menuMeasure;
end; // newMenuSeparator

function arrayToList(a:TStringDynArray; list:TstringList=NIL):TstringList;
var
  i: integer;
begin
if list = NIL then
  list:=ThashedStringList.create;
result:=list;
list.Clear();
for i:=0 to length(a)-1 do
  list.add(a[i]);
end; // arrayToList

function createAccountOnTheFly():Paccount;
var
  acc: Taccount;
  i: integer;
begin
result:=NIL;
fillChar(acc, sizeof(acc), 0);
acc.enabled:=TRUE;
  repeat
  if not newuserpassFrm.prompt(acc.user, acc.pwd)
  or (acc.user = '') then exit;

  if getAccount(acc.user) = NIL then break;
  msgDlg('Username already exists', MB_ICONERROR)
  until false;
i:=length(accounts);
setLength(accounts, i+1);
accounts[i]:=acc;
result:=@accounts[i];
end; // createAccountOnTheFly

function sortArray(a:TStringDynArray):TStringDynArray;
var
  i, j, l: integer;
begin
l:=length(a);
for i:=0 to l-2 do
  for j:=i+1 to l-1 do
    swapMem(a[i], a[j], sizeof(a[i]), ansiCompareText(a[i], a[j]) > 0);
result:=a;
end; // sortArray

procedure onlyForExperts(controls:array of Tcontrol);
var
  i: integer;
begin
for i:=0 to length(controls)-1 do
  controls[i].visible:=not easyMode;
end; // onlyForExperts

function onlyExistentAccounts(a:TstringDynArray):TstringDynArray;
var
  i: integer;
  s: string;
begin
for i:=0 to length(a)-1 do
  begin
  s:=trim(a[i]);
  if (s = '') or (s[1] <> '@') and (getAccount(s) = NIL) then
    removeString(a, i)
  else
    a[i]:=s;
  end;
result:=a;
end; // onlyExistentAccounts

function strToCharset(s:string):Tcharset;
var
  i: integer;
begin
result:=[];
for i:=1 to length(s) do
  include(result, ansichar(s[i]));
end; // strToCharset

function boolToPtr(b:boolean):pointer;
begin result:=if_(b, PTR1, NIL) end;

// recognize strings containing pieces (separated by backslash) made of only dots
function dirCrossing(s:string):boolean;
begin
result:=FALSE;

if onlyDotsRE = NIL then
  begin
  onlyDotsRE:=TRegExpr.Create;
  onlyDotsRE.modifierM:=TRUE;
  onlyDotsRE.expression:='(^|\\)\.\.+($|\\)';
  onlyDotsRE.compile();
  end;

with onlyDotsRE do
  try result:=exec(s);
  except end;
end; // dirCrossing

// this will tell if the file has changed
function newMtime(fn:string; var previous:Tdatetime):boolean;
var
  d: TDateTime;
begin
d:=getMtime(fn);
result:=fileExists(fn) and (d <> previous);
if result then
  previous:=d;
end; // newMtime

function dequote(s:string; quoteChars:TcharSet=['"']):string;
begin
if (s > '') and (s[1] = s[length(s)]) and charInSet(s[1], quoteChars) then
  result:=copy(s, 2, length(s)-2)
else
  result:=s;
end; // dequote

// finds the end of the line
function findEOL(s:string; ofs:integer=1; included:boolean=TRUE):integer;
begin
ofs:=max(1,ofs);
result:=posEx(#13, s, ofs);
if result > 0 then
  begin
  if not included then
    dec(result)
  else
    if (result < length(s)) and (s[result+1] = #10) then
      inc(result);
  exit;
  end;
result:=posEx(#10, s, ofs);
if result > 0 then
  begin
  if not included then
    dec(result);
  exit;
  end;
result:=length(s);
end; // findEOL

function quoteIfAnyChar(badChars, s:string; quote:string='"'; unquote:string='"'):string;
begin
if anycharIn(badChars, s) then
  s:=quote+s+unquote;
result:=s;
end; // quoteIfAnyChar

function toSA(a:array of string):TstringDynArray; // this is just to have a way to typecast
begin
result:=NIL;
addArray(result, a);
end; // toSA

// this is feasible for spot and low performance needs
function getKeyFromString(s:string; key:string; def:string=''):string;
var
  i: integer;
begin
result:=def;
includeTrailingString(key, '=');
i:=1;
  repeat
  i:=ipos(key, s, i);
  if i = 0 then exit; // not found
  until (i = 1) or charInSet(s[i-1], [#13,#10]); // ensure we are at the very beginning of the line
inc(i, length(key));
result:=substr(s,i, findEOL(s,i,FALSE));
end; // getKeyFromString

// "key=val" in second parameter (with 3rd one empty) is supported
function setKeyInString(s:string; key:string; val:string=''):string;
var
  i: integer;
begin
i:=pos('=', key);
if i = 0 then
  key:=key+'='
else if val = '' then
  begin
  val:=copy(key,i+1,MAXINT);
  setLength(key, i);
  end;
// now key has a trailing '='. Let's find where it is.
i:=0;
  repeat i:=ipos(key, s, i+1);
  until (i <= 1) or charInSet(s[i-1], [#13,#10]); // we accept cases 0,1 as they are. Other cases must comply with being at start of line.
if i = 0 then // missing, then add
  begin
  if s > '' then
    includeTrailingString(s, CRLF);
  result:=s+key+val;
  exit;
  end;
// replace
inc(i, length(key));
replace(s, val, i, findEOL(s,i, FALSE));
result:=s;
end; // setKeyInString

// useful for casing on the first char
function getFirstChar(s:string):char;
begin
if s = '' then result:=#0
else result:=s[1]
end; // getFirstChar

function localToGMT(d:Tdatetime):Tdatetime;
begin result:=d-GMToffset*60/SECONDS end;

// this is useful when we don't know if the value is expressed as a real Tdatetime or in unix time format
function maybeUnixTime(t:Tdatetime):Tdatetime;
begin
if t > 1000000 then result:=unixToDateTime(round(t))
else result:=t
end;

procedure excludeTrailingString(var s:string; ss:string);
var
  i: integer;
begin
i:=length(s)-length(ss);
if copy(s, i+1, length(ss)) = ss then
  setLength(s, i);
end;

function deltree(path:string):boolean;
var
  sr: TSearchRec;
  fn: string;
begin
result:=FALSE;
if fileExists(path) then
  begin
  result:=deleteFile(path);
  exit;
  end;
if not ansiContainsStr(path, '?') and not ansiContainsStr(path, '*') then
  path:=path+'\*';
if findfirst(path, faAnyFile, sr) <> 0 then exit;
try
  repeat
  if (sr.name = '.') or (sr.name = '..') then continue;
  fn:=path+'\'+sr.name;
  if boolean(sr.attr and faDirectory) then
    delTree(fn)
  else
    deleteFile(fn);
  until findNext(sr) <> 0;
finally
  findClose(sr);
  rmDir(path);
  end;
end; // deltree

function str2bytes(s:ansistring):Tbytes;
begin
setLength(result, length(s));
move(s[1], result[0], length(result));
end;

function stringToGif(s:ansistring; gif:TgifImage=NIL):TgifImage;
var
  ss: Tbytesstream;
begin
ss:=Tbytesstream.create(str2bytes(s));
try
  if gif = NIL then
    gif:=TGIFImage.Create();
  gif.loadFromStream(ss);
  result:=gif;
finally ss.free end;
end; // stringToGif

function allocatedMemory():int64;
var
  mms: TMemoryManagerState;
  i: integer;
begin
getMemoryManagerState(mms);
result:=0;
for i:=0 to high(mms.SmallBlockTypeStates)-1 do
  with mms.SmallBlockTypeStates[i] do
    //inc(result, ReservedAddressSpace);   i guess this is real consumption from a system PoV, but it's actually preallocated, not fully used
    inc(result, internalBlockSize*allocatedBlockCount);
inc(result, mms.TotalAllocatedLargeBlockSize+mms.TotalAllocatedMediumBlockSize);
end; // allocatedMemory

{function allocatedMemory():int64;
var
  mm: TMemoryManagerUsageSummary;
begin
getMemoryManagerUsageSummary(mm);
result:=mm.allocatedBytes;
end; // allocatedMemory
}
function removeStartingStr(ss,s:string):string;
begin
if ansiStartsStr(ss, s) then
  result:=substr(s, 1+length(ss))
else
  result:=s
end; // removeStartingStr

function stringToColorEx(s:string; default:Tcolor=clNone):Tcolor;
begin
try
  if reMatch(s, '#?[0-9a-f]{3,6}','!i') > 0 then
    begin
    s:=removeStartingStr('#', s);
    case length(s) of
      3: s:=s[3]+s[3]+s[2]+s[2]+s[1]+s[1];
      6: s:=s[5]+s[6]+s[3]+s[4]+s[1]+s[2];
      end;
    end;
  result:=stringToColor('$'+s)
except
  try result:=stringToColor('cl'+s);
  except
    if default = clNone then
      result:=stringToColor(s)
    else
      try result:=stringToColor(s)
      except result:=default end;
    end;
  end;
end; // stringToColorEx

function filetimeToDatetime(ft:TFileTime):Tdatetime;
var
  st: TsystemTime;
begin
FileTimeToLocalFileTime(ft, ft);
FileTimeToSystemTime(ft, st);
TryEncodeDateTime(st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, result);
end; // filetimeToDatetime

function diskSpaceAt(path:string):int64;
var
  tmp: int64;
  was: string;
begin
while not directoryExists(path) do
  begin
  was:=path;
  path:=extractFileDir(path);
  if path = was then break; // we're on the road to nowhere
  end;
if not getDiskFreeSpaceEx(pchar(path), result, tmp, NIL) then
  result:=-1;
end; // diskSpaceAt

// this is a blocking method for dns resolving. The Wsocket.DnsLookup() method provided by ICS is non-blocking 
function hostToIP(name: string):string;
type
  Tbytes = array [0..3] of byte;
var
  hostEnt: PHostEnt;
  addr: ^Tbytes;
begin
result:='';
hostEnt:=gethostbyname(@ansiString(name)[1]);
if (hostEnt = NIL) or (hostEnt^.h_addr_list = NIL) then exit;
addr:=pointer(hostEnt^.h_addr_list^);
if addr = NIL then exit;
result:=format('%d.%d.%d.%d', [addr[0], addr[1], addr[2], addr[3]]);
end; // hostToIP

function hostFromURL(s:string):string;
begin result:=reGet(s, '([a-z]+://)?([^/]+@)?([^/]+)', 3) end;

procedure fixFontFor(frm:Tform);
var
  nonClientMetrics: TNonClientMetrics;
begin
nonClientMetrics.cbSize:=sizeOf(nonClientMetrics);
systemParametersInfo(SPI_GETNONCLIENTMETRICS, 0, @nonClientMetrics, 0);
frm.font.handle:=createFontIndirect(nonClientMetrics.lfMessageFont);
if frm.scaled then
  frm.font.height:=nonClientMetrics.lfMessageFont.lfHeight;
end; // fixFontFor

function nodeToFile(n:TtreeNode):Tfile; inline;
begin if n = NIL then result:=NIL else result:=Tfile(n.data) end;

function getAccount(user:string; evenGroups:boolean=FALSE):Paccount;
var
  i: integer;
begin
result:=NIL;
if user = '' then
  exit;
for i:=0 to length(accounts)-1 do
  if sameText(user, accounts[i].user) then
    begin
    if evenGroups or not accounts[i].group then
      result:= @accounts[i];
    exit;
    end;
end; // getAccount

function accountExists(user:string; evenGroups:boolean=FALSE):boolean;
begin result:=getAccount(user, evenGroups) <> NIL end;

type
  Tnewline = (NL_UNK, NL_D, NL_A, NL_DA, NL_MIXED);

function newlineType(s:string):Tnewline;
var
  d, a, l: integer;
begin
d:=pos(#13,s);
a:=pos(#10,s);
if d = 0 then
  if a = 0 then
    result:=NL_UNK
  else
    result:=NL_A
else
  if a = 0 then
    result:=NL_D
  else
    if a = 1 then
      result:=NL_MIXED
    else
      begin
      result:=NL_MIXED;
      // search for an unpaired #10
      while (a > 0) and (s[a-1] = #13) do
        a:=posEx(#10, s, a+1);
      if a > 0 then exit;
      // search for an unpaired #13
      l:=length(s);
      while (d < l) and (s[d+1] = #10) do
        d:=posEx(#13, s, d+1);
      if d > 0 then exit;
      // ok, all is paired
      result:=NL_DA;
      end;
end; // newlineType

function escapeNL(s:string):string;
begin
s:=replaceStr(s, '\','\\');
case newlineType(s) of
  NL_D: s:=replaceStr(s, #13,'\n');
  NL_A: s:=replaceStr(s, #10,'\n');
  NL_DA: s:=replaceStr(s, #13#10,'\n');
  NL_MIXED: s:=replaceStr(replaceStr(replaceStr(s, #13#10,'\n'), #13,'\n'), #10,'\n'); // bad case, we do our best
  end;
result:=s;
end; // escapeNL

function unescapeNL(s:string):string;
var
  o, n: integer;
begin
o:=1;
while o <= length(s) do
  begin
  o:=posEx('\n', s, o);
  if o = 0 then break;
  n:=1;
  while (o-n > 0) and (s[o-n] = '\') do inc(n);
  if odd(n) then
    begin
    s[o]:=#13;
    s[o+1]:=#10;
    end;
  inc(o,2);
  end;
result:=replaceStr(s, '\\','\');
end; // unescapeNL

function htmlEncode(s:string):string;
var
  i: integer;
  p: string;
  fs: TfastStringAppend;
begin
fs:=TfastStringAppend.create;
try
  for i:=1 to length(s) do
    begin
    case s[i] of
      '&': p:='&amp;';
      '<': p:='&lt;';
      '>': p:='&gt;';
      '"': p:='&quot;';
      '''': p:='&#039;';
      else p:=s[i];
      end;
    fs.append(p);
    end;
  result:=fs.get();
finally fs.free end;
end; // htmlEncode

procedure enforceNUL(var s:string);
begin
if s>'' then
  setLength(s, strLen(Pwidechar(@s[1])))
end; // enforceNUL

var
  TZinfo:TTimeZoneInformation;

INITIALIZATION
FormatSettings.DecimalSeparator:='.'; // standardize

ipToInt_cache:=THashedStringList.Create;
ipToInt_cache.Sorted:=TRUE;
ipToInt_cache.Duplicates:=dupIgnore;
inputQueryLongdlg:=TlonginputFrm.create(NIL); // mainFrm is NIL at this time

// calculate GMToffset
GetTimeZoneInformation(TZinfo);
case GetTimeZoneInformation(TZInfo) of
  TIME_ZONE_ID_STANDARD: GMToffset:=TZInfo.StandardBias;
  TIME_ZONE_ID_DAYLIGHT: GMToffset:=TZInfo.DaylightBias;
  else GMToffset:=0;
  end;
GMToffset:=-(TZinfo.bias+GMToffset);

// windows version detect
case byte(getversion()) of
  1..4: winVersion:=WV_LOWER;
  5: winVersion:=WV_2000;
  6: case hibyte(getversion()) of
      0: winVersion:=WV_VISTA;
      1: winVersion:=WV_SEVEN;
      else winVersion:=WV_HIGHER;
      end;
  7..15: winVersion:=WV_HIGHER;
  end;

trayMsg:='%ip%'
  +trayNL+'Uptime: %uptime%'
  +trayNL+'Downloads: %downloads%';

//fastmm4.SuppressMessageBoxes:=TRUE;

FINALIZATION
freeAndNIL(ipToInt_cache);
freeAndNIL(inputQueryLongdlg);
freeAndNIL(onlyDotsRE);

end.
