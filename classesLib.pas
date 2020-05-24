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
unit classesLib;

interface

uses
  iniFiles, types, hslib, strUtils, sysUtils, classes, math, system.Generics.Collections;

type
  TfastStringAppend = class
  protected
    buff: string;
    n: integer;
  public
    function length():integer;
    function reset():string;
    function get():string;
    function append(s:string):integer;
    end;

  PcachedIcon = ^TcachedIcon;
  TcachedIcon = record
    data: string;
    idx: integer;
    time: Tdatetime;
    end;

  TiconsCache = class
    n: integer;
    icons: array of TcachedIcon;
    function get(data:string):PcachedIcon;
    procedure put(data:string; idx:integer; time:Tdatetime);
    procedure clear();
    procedure purge(olderThan:Tdatetime);
    function idxOf(data:string):integer;
    end;

  TusersInVFS = class
  protected
    users: TstringDynArray;
    pwds: array of TstringDynArray;
  public
    procedure reset();
    procedure track(usr, pwd:string); overload;
    procedure drop(usr, pwd:string); overload;
    function match(usr, pwd:string):boolean; overload;
    function empty():boolean;
    end;

  TarchiveStream = class(Tstream)
  protected
    pos, cachedTotal: int64;
    cur: integer;

    procedure invalidate();
    procedure calculate(); virtual; abstract;
    function getTotal():int64;
  public
    flist: array of record
      src,          // full path of the file on the disk
      dst: string;  // full path of the file in the archive
      firstByte,    // offset of the file inside the archive
      mtime,
      size: int64;
      data: Tobject;  // extra data
      end;
    onDestroy: TNotifyEvent;

    constructor create;
    destructor Destroy; override;
    function addFile(src:string; dst:string=''; data:Tobject=NIL):boolean; virtual;
    function count():integer;
    procedure reset(); virtual;
    property totalSize:int64 read getTotal;
    property current:integer read cur;
    end; // TarchiveStream

  TtarStreamWhere = (TW_HEADER, TW_FILE, TW_PAD);

  TtarStream = class(TarchiveStream)
  protected
    fs: TFileStream;
    block: TStringStream;
    lastSeekFake: int64;
    where: TtarStreamWhere;
    function fsInit():boolean;
    procedure headerInit(); // fill block with header
    procedure padInit(full:boolean=FALSE); // fill block with pad
    function headerLengthForFilename(ufn:string):integer;
    procedure calculate(); override;
  public
    fileNamesOEM: boolean;
    constructor create;
    destructor Destroy; override;
    function Read(var Buffer; Count: Longint): Longint; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin=soBeginning): Int64; override;

    procedure reset(); override;
    end; // TtarStream

  Thasher = class(TstringList)
    procedure loadFrom(path:string);
    function getHashFor(fn:string):string;
    end;

  Tint2int = Tdictionary<integer,integer>;
  Tstr2str = Tdictionary<string,string>;
  Tstr2pointer = Tdictionary<string,pointer>;

  TstringToIntHash = class(ThashedStringList)
    constructor create;
    function getInt(s:string):integer;
    function getIntByIdx(idx:integer):integer;
    function incInt(s:string):integer;
    procedure setInt(s:string; int:integer);
    end;

  PtplSection = ^TtplSection;
  TtplSection = record
    name, txt: string;
    nolog, nourl, cache: boolean;
    ts: Tdatetime;
    end;

  Ttpl = class
  protected
    src: string;
    lastExt,   // cache for getTxtByExt()
    last: record section:string; idx:integer; end; // cache for getIdx()
    strTable: THashedStringList;
    fOver: Ttpl;
    sections: Tstr2pointer;
    function  getTxt(section:string):string;
    function  newSection(section:string):PtplSection;
    procedure fromString(txt:string);
    procedure setOver(v:Ttpl);
  public
    onChange: TNotifyEvent;
    constructor create(txt:string=''; over:Ttpl=NIL);
    destructor Destroy; override;
    property txt[section:string]:string read getTxt; default;
    property fullText:string read src write fromString;
    property over:Ttpl read fOver write setOver;
    function sectionExist(section:string):boolean;
    function getTxtByExt(fileExt:string):string;
    function getSection(section:string; inherit:boolean=TRUE):PtplSection;
    function getSections():TStringDynArray;
    procedure appendString(txt:string);
    function getStrByID(id:string):string;
    function me():Ttpl;
    end; // Ttpl

  TcachedTplObj = class
    ts: Tdatetime;
    tpl: Ttpl;
    end;

  TcachedTpls = class(THashedStringList)
  public
    function getTplFor(fn:string):Ttpl;
    destructor Destroy; override;
    end; // TcachedTpls

  TperIp = class // for every different address, we have an object of this class. These objects are never freed until hfs is closed.
  public
    limiter: TspeedLimiter;
    customizedLimiter: boolean;
    constructor create();
    destructor Destroy; override;
    end;

  Ttlv = class
  protected
    cur, bound: integer;
    whole, lastRaw: ansistring;
    stack: array of integer;
    stackTop: integer;
  public
    procedure parse(data:ansistring);
    function pop(var value:string; var raw:ansiString):integer;
    function down():boolean;
    function up():boolean;
    function getTotal():integer;
    function getCursor():integer;
    function getPerc():real;
    function isOver():boolean;
    function getTheRest():ansistring;
    end;

const TLV_UTF8_FLAG = $1000000;

implementation

uses
  utilLib, main, windows, dateUtils, forms;

constructor TperIp.create();
begin
limiter:=TspeedLimiter.create();
srv.limiters.add(limiter);
end;

destructor TperIp.Destroy;
begin
srv.limiters.remove(limiter);
limiter.free;
end;

//////////// TcachedTpls

destructor TcachedTpls.Destroy;
var
  i: integer;
begin
for i:=0 to count-1 do
  objects[i].free;
end;

function TcachedTpls.getTplFor(fn:string):Ttpl;
var
  i: integer;
  o: TcachedTplObj;
  s: string;
begin
fn:=trim(lowercase(fn));
i:=indexOf(fn);
if i >= 0 then
  o:=objects[i] as TcachedTplObj
else
  begin
  o:=TcachedTplObj.create();
  if addObject(fn, o) > 100 then
    delete(0);
  end;
result:=o.tpl;
if getMtime(fn) = o.ts then exit;
o.ts:=getMtime(fn);
s:=loadTextFile(fn);
if o.tpl = NIL then
  begin
  result:=Ttpl.create();
  o.tpl:=result;
  end;
o.tpl.fromString(s);
end; // getTplFor

//////////// TusersInVFS

function TusersInVFS.empty():boolean;
begin result:= users = NIL end;

procedure TusersInVFS.reset();
begin
users:=NIL;
pwds:=NIL;
end; // reset

procedure TusersInVFS.track(usr, pwd: string);
var
  i: integer;
begin
if usr = '' then exit;
i:=idxOf(usr, users);
if i < 0 then i:=addString(usr, users);
if i >= length(pwds) then setLength(pwds, i+1);
addString(pwd, pwds[i]);
end; // track

procedure TusersInVFS.drop(usr, pwd: string);
var
  i, j: integer;
begin
i:=idxOf(usr, users);
if i < 0 then exit;
j:=AnsiIndexStr(pwd, pwds[i]);
if j < 0 then exit;
removeString(pwds[i], j);
if assigned(pwds[i]) then exit;
// this username does not exist with any password
removeString(users, i);
while i+1 < length(pwds) do
  begin
  pwds[i]:=pwds[i+1];
  inc(i);
  end;
setLength(pwds, i);
end; // drop

function TusersInVFS.match(usr, pwd:string):boolean;
var
  i: integer;
begin
result:=FALSE;
i:=idxOf(usr, users);
if i < 0 then exit;
result:= 0 <= AnsiIndexStr(pwd, pwds[i]);
end; // match

//////////// TiconsCache

function TiconsCache.idxOf(data:string):integer;
var
  b, e, c: integer;
begin
result:=0;
if n = 0 then exit;
// binary search
b:=0;
e:=n-1;
  repeat
  result:=(b+e) div 2;
  c:=compareStr(data, icons[result].data);
  if c = 0 then exit;
  if c < 0 then e:=result-1;
  if c > 0 then b:=result+1;
  until b > e;
result:=b;
end; // idxOf

function TiconsCache.get(data:string):PcachedIcon;
var
  i: integer;
begin
result:=NIL;
i:=idxOf(data);
if (i >= 0) and (i < n) and (icons[i].data = data) then
  result:=@icons[i];
end; // get

procedure TiconsCache.put(data:string; idx:integer; time:Tdatetime);
var
  i, w: integer;
begin
if length(icons) <= n then setlength(icons, n+50);
w:=idxOf(data);
for i:=n downto w+1 do icons[i]:=icons[i-1]; // shift
icons[w].data:=data;
icons[w].idx:=idx;
icons[w].time:=time;
inc(n);
end; // put

procedure TiconsCache.clear();
begin
icons:=NIL;
n:=0;
end; // clear

procedure TiconsCache.purge(olderThan:Tdatetime);
var
  i, m: integer;
begin
exit;
m:=0;
for i:=0 to n-1 do
  if icons[i].time < olderThan then dec(n) // this does not shorten the loop
  else
    begin
    if m < i then icons[m]:=icons[i];
    inc(m);
    end;
end; // purge

//////////// TfastStringAppend

function TfastStringAppend.length():integer;
begin result:=n end;

function TfastStringAppend.get():string;
begin
setlength(buff, n);
result:=buff;
end; // get

function TfastStringAppend.reset():string;
begin
result:=get();
buff:='';
n:=0;
end; // reset

function TfastStringAppend.append(s:string):integer;
var
  ls, lb: integer;
begin
ls:=system.length(s);
lb:=system.length(buff);
if n+ls > lb then setlength(buff, lb+ls+20000);
moveChars(s[1], buff[n+1], ls);
inc(n, ls);
result:=n;
end; // append

//////////// TarchiveStream

function TarchiveStream.getTotal():int64;
begin
if cachedTotal < 0 then calculate();
result:=cachedTotal;
end; // getTotal

function TarchiveStream.addFile(src:string; dst:string=''; data:Tobject=NIL):boolean;

  function getMtime(fh:Thandle):int64;
  var
    ctime, atime, mtime: Tfiletime;
    st: TSystemTime;
  begin
  getFileTime(fh, @ctime, @atime, @mtime);
  fileTimeToSystemTime(mtime, st);
  result:=dateTimeToUnix(SystemTimeToDateTime(st));
  end; // getMtime

var
  i, fh: integer;
begin
result:=FALSE;
fh:=fileopen(src, fmOpenRead+fmShareDenyNone);
if fh = -1 then exit;
result:=TRUE;
if dst = '' then
  dst:=extractFileName(src);
i:=length(flist);
setLength(flist, i+1);
flist[i].src:=src;
flist[i].dst:=dst;
flist[i].data:=data;
flist[i].size:=sizeOfFile(fh);
flist[i].mtime:=getMtime(fh);
flist[i].firstByte:=-1;
fileClose(fh);
invalidate();
end; // addFile

procedure TarchiveStream.invalidate();
begin cachedTotal:=-1 end;

constructor TarchiveStream.create;
begin
inherited;
reset();
end; // create

destructor TarchiveStream.destroy;
begin
if assigned(onDestroy) then onDestroy(self);
inherited;
end; // destroy

procedure TarchiveStream.reset();
begin
flist:=NIL;
cur:=0;
pos:=0;
invalidate();
end; // reset

function TarchiveStream.count():integer;
begin result:=length(flist) end;

//////////// TtarStream

constructor TtarStream.create;
begin
block:=TStringStream.create('');
lastSeekFake:=-1;
where:=TW_HEADER;
fileNamesOEM:=FALSE;
inherited;
end; // create

destructor TtarStream.destroy;
begin
freeAndNIL(fs);
inherited;
end; // destroy

procedure TtarStream.reset();
begin
inherited;
block.size:=0;
end; // reset

function TtarStream.fsInit():boolean;
begin
if assigned(fs) and (fs.FileName = flist[cur].src) then
  begin
  result:=TRUE;
  exit;
  end;
result:=FALSE;
try
  freeAndNIL(fs);
  fs:=TfileStream.Create(flist[cur].src, fmOpenRead+fmShareDenyWrite);
  result:=TRUE;
except
  fs:=NIL;
  end;
end; // fsInit

procedure TtarStream.headerInit();

  function num(i:int64; fieldLength:integer):ansistring;
  const
    CHARS : array [0..7] of ansichar = '01234567';
  var
    d: integer;
  begin
  d:=fieldLength-1;
  result:=ansistring(dupeString('0', d))+#0;
  while d > 0 do
    begin
    result[d]:=CHARS[i and 7];
    dec(d);
    i:=i shr 3;
    if i = 0 then break;
    end;
  end; // num

  function str(s:ansistring; fieldLength:integer; fill:ansistring=#0):ansistring;
  begin
  setLength(s, min(length(s), fieldLength-1));
  result:=s+ansistring( dupeString(fill, fieldLength-length(s)) );
  end; // str

  function sum(s:ansistring):integer;
  var
    i: integer;
  begin
  result:=0;
  for i:=1 to length(s) do
    inc(result, ord(s[i]));
  end; // sum

  procedure applyChecksum(var s:ansistring);
  var
    chk: ansistring;
  begin
  chk:=num(sum(s), 7)+' ';
  chk[7]:=#0;
  move(chk[1], s[100+24+12+12+1], length(chk));
  end; // applyChecksum

const
  FAKE_CHECKSUM = '        ';
  USTAR = 'ustar'#0'00';
  PERM = '0100777'#0'0000000'#0'0000000'#0; // file mode, uid, gid
var
  fn, s, pre: ansistring;
  ufn: string;
begin
ufn:=replaceStr(flist[cur].dst,'\','/');
if fileNamesOEM then
  fn:=strToOem(ufn)
else
  fn:=UTF8encode(ufn);
pre:='';
if length(fn) >= 100 then
  begin
  pre:=str('././@LongLink', 100)+PERM
    +num(length(fn)+1, 12)+num(flist[cur].mtime, 12)
    +FAKE_CHECKSUM+'L';
  pre:=str(pre, 256)+str(#0+USTAR,256);
  applyChecksum(pre);
  pre:=pre+str(fn, 512);
  end;
s:=str(fn, 100)+PERM
  +num(flist[cur].size, 12) // file size
  +num(flist[cur].mtime, 12)  // mtime
  +FAKE_CHECKSUM
  +'0'+str('', 100)       // link properties
  +USTAR;
applyChecksum(s);
s:=str(s, 512); // pad
block.Size:=0;
block.WriteString(pre+s);
block.seek(0, soBeginning);
end; // headerInit

function TtarStream.write(const Buffer; Count: Longint): Longint;
begin raise EWriteError.Create('write unsupproted') end;

function gap512(i:int64):word; inline;
begin
result:=i and 511;
if result > 0 then
  result:=512-result;
end; // gap512

procedure TtarStream.padInit(full:boolean=FALSE);
begin
block.Size:=0;
block.WriteString(dupeString(#0, if_(full,512,gap512(pos)) ));
block.Seek(0, soBeginning);
end; // padInit

function TtarStream.headerLengthForFilename(ufn:string):integer;
var
  fn: ansistring;
begin
if fileNamesOEM then
  fn:=strToOem(ufn)
else
  fn:=UTF8encode(ufn);
result:=length(fn);
result:=512*if_(result<100, 1, 3+result div 512);
end; // headerLengthForFilename

procedure TtarStream.calculate();
var
  pos: int64;
  i: integer;
begin
pos:=0;
for i:=0 to length(flist)-1 do
  with flist[i] do
    begin
    firstByte:=pos;
    inc(pos, size+headerLengthForFilename(dst));
    inc(pos, gap512(pos));
    end;
inc(pos, 512); // last empty block
cachedTotal:=pos;
end; // calculate

function TtarStream.seek(const Offset: Int64; Origin: TSeekOrigin): Int64;

  function left():int64;
  begin result:=offset-pos end;

  procedure fineSeek(s:Tstream);
  begin inc(pos, s.seek(left(), soBeginning)) end;

  function skipMoreThan(size:int64):boolean;
  begin
  result:=left() > size;
  if result then inc(pos, size);
  end;

var
  bak: int64;
  prevCur: integer;
begin
{ The lastSeekFake trick is a way to fastly manage a sequence of
  seek(0,soCurrent); seek(0,soEnd); seek(0,soBeginning);
  such sequence called very often, while it is used to just read
  the size of the stream, no real seeking requirement.
}
bak:=lastSeekFake;
lastSeekFake:=-1;
if (origin = soCurrent) and (offset <> 0) then
  seek(pos+offset, soBeginning);
if origin = soEnd then
  if offset < 0 then
    seek(totalSize+offset, soBeginning)
  else
    begin
    lastSeekFake:=pos;
    pos:=totalsize;
    end;
result:=pos;
if origin <> soBeginning then exit;
if bak >= 0 then
  begin
  pos:=bak;
  exit;
  end;

// here starts the normal seeking algo

prevCur:=cur;
cur:=0;  // flist index
pos:=0;  // current position in the file
block.size:=0;
while (left() > 0) and (cur < length(flist)) do
  begin
  // are we seeking inside this header?
  if not skipMoreThan(headerLengthForFilename(flist[cur].dst)) then
    begin
    if (prevCur <> cur) or (where <> TW_HEADER) or eos(block) then
      headerInit();
    fineSeek(block);
    where:=TW_HEADER;
    break;
    end;
  // are we seeking inside this file?
  if not skipMoreThan(flist[cur].size) then
    begin
    if not fsInit() then
      raise Exception.Create('TtarStream.seek: cannot open '+flist[cur].src);
    fineSeek(fs);
    where:=TW_FILE;
    break;
    end;
  // are we seeking inside this pad?
  if not skipMoreThan(gap512(pos)) then
    begin
    padInit();
    fineSeek(block);
    where:=TW_PAD;
    break;
    end;
  inc(cur);
  end;//while
if left() > 0 then
  begin
  padInit(TRUE);
  fineSeek(block);
  end;
result:=pos;
end; // seek

function TtarStream.read(var Buffer; Count: Longint): Longint;
var
  p: Pbyte;

  procedure goForth(d: int64);
  begin
  dec(count, d);
  inc(pos, d);
  inc(p, d);
  end; // goForth

  procedure goRead(s:Tstream);
  begin goForth( s.read(p^, count) ) end;

var
  i, posBak: int64;
begin
posBak:=pos;
p:=@buffer;
while (count > 0) and (cur < length(flist)) do
  case where of
    TW_HEADER:
      begin
      if block.size = 0 then
        headerInit();
      goRead(block);
      if not eos(block) then continue;
      where:=TW_FILE;
      freeAndNIL(fs); // in case the same files appear twice in a row, we must be sure to reinitialize the reader stream
      block.size:=0;
      end;
    TW_FILE:
      begin
      fsInit();
      if assigned(fs) then
        goRead(fs);
      { We reserved a fixed space for this file in the archive, but the file
        may not exist anymore, or its size may be shorter than expected,
        so we can't rely on eos(fs) to know if we are done in this section.
        Lets calculate how far we are from the theoretical end of the file,
        and decide after it.
      }
      i:=headerLengthForFilename(flist[cur].dst);
      i:=flist[cur].firstByte+i+flist[cur].size-pos;
      if count >= i then
        where:=TW_PAD;
      // In case the file is shorter, we pad the rest with NUL bytes
      i:=min(count, max(0,i));
      fillChar(p^,i,0);
      goForth(i);
      end;
    TW_PAD:
      begin
      if block.size = 0 then padInit();
      goRead(block);
      if not eos(block) then continue;
      where:=TW_HEADER;
      block.size:=0;
      inc(cur);
      end;
    end;//case

// last empty block
if count > 0 then
  begin
  padInit(TRUE);
  goRead(block);
  end;
result:=pos-posBak;
end; // read

//////////// Thasher

procedure Thasher.loadFrom(path:string);
var
  sr: TsearchRec;
  s, l, h: string;
begin
if path='' then exit;
path:=includeTrailingPathDelimiter(lowercase(path));
if findFirst(path+'*.md5', faAnyFile-faDirectory, sr) <> 0 then exit;
  repeat
  s:=loadTextfile(path+sr.name);
  while s > '' do
    begin
    l:=chopline(s);
    h:=trim(chop('*',l));
    if h = '' then break;
    if l = '' then
      // assume it is referring to the filename without the extention
      l:=copy(sr.name, 1, length(sr.name)-4);
    add(path+lowercase(l)+'='+h);
    end;
  until findnext(sr) <> 0;
sysutils.findClose(sr);
end; // loadFrom

function Thasher.getHashFor(fn:string):string;
begin
try result:=values[lowercase(fn)]
except result:='' end
end;

//////////// TstringToIntHash

constructor TstringToIntHash.create;
begin
inherited create;
sorted:=TRUE;
duplicates:=dupIgnore;
end; // create

function TstringToIntHash.getIntByIdx(idx:integer):integer;
begin if idx < 0 then result:=0 else result:=integer(objects[idx]) end;

function TstringToIntHash.getInt(s:string):integer;
begin result:=getIntByIdx(indexOf(s)) end;

procedure TstringToIntHash.setInt(s:string; int:integer);
begin
beginUpdate();
objects[add(s)]:=Tobject(int);
endUpdate();
end; // setInt

function TstringToIntHash.incInt(s:string):integer;
var
  i: integer;
begin
beginUpdate();
i:=add(s);
result:=integer(objects[i]);
inc(result);
objects[i]:=Tobject(result);
endUpdate();
end; // autoupdatedFiles_getCounter

//////////// Ttpl

constructor Ttpl.create(txt:string=''; over:Ttpl=NIL);
begin
sections:=Tstr2pointer.Create();
fullText:=txt;
self.over:=over;
end;

destructor Ttpl.destroy;
begin
fullText:=''; // this will cause the disposing
inherited;
end; // destroy

function Ttpl.getStrByID(id:string):string;
begin
if strTable = NIL then
  begin
  strTable:=THashedStringList.create;
  strTable.text:=txt['special:strings'];
  end;
result:=strTable.values[id];
if (result = '') and assigned(over) then
  result:=over.getStrByID(id)
end; // getStrByID

function Ttpl.newSection(section:string):PtplSection;
begin
new(result);
sections.Add(section, result);
end; // newSection

function Ttpl.sectionExist(section:string):boolean;
begin
result:=assigned(getSection(section));
if not result and assigned(over) then
  result:=over.sectionExist(section);
end;

function Ttpl.getSection(section:string; inherit:boolean=TRUE):PtplSection;
begin
if sections.containsKey(section) then
  result:=sections[section]
else
  result:=NIL;
if inherit and assigned(over) and ((result = NIL) or (trim(result.txt) = '')) then
  result:=over.getSection(section);
end; // getSection

function Ttpl.getTxt(section:string):string;
var p: PtplSection;
begin
p:=getSection(section);
if p = NIL then
  result:=''
else
  result:=p.txt
end; // getTxt

function Ttpl.getTxtByExt(fileExt:string):string;
begin result:=getTxt('file.'+fileExt) end;

procedure Ttpl.fromString(txt:string);
var
  p: PtplSection;
begin
src:='';
for p in sections.values do
  dispose(p);
sections.clear();
freeAndNIL(strTable);  // mod by mars

appendString(txt);
end; // fromString

procedure Ttpl.appendString(txt:string);
var
  ptxt, bos: Pchar;
  cur_section, next_section: string;

  function pred(p:pchar):pchar; inline;
  begin
  result:=p;
  if p <> NIL then
    dec(result);
  end;

  function succ(p:pchar):pchar; inline;
  begin
  result:=p;
  if p <> NIL then
    inc(result);
  end;

  procedure findNextSection();
  begin
  // find start
  bos:=ptxt;
    repeat
    if bos^ <> '[' then bos:=ansiStrPos(bos, #10'[');
    if bos = NIL then exit;
    if bos^ = #10 then inc(bos);
    if getSectionAt(bos, next_section) then
      exit;
    inc(bos);
    until false;
  end; // findNextSection

  procedure saveInSection();
  var
    ss: TStringDynArray;
    s: string;
    i: integer;
    base: TtplSection;
    till: pchar;
    append: boolean;
    sect, from: PtplSection;
  begin
  till:=pred(bos);
  if till = NIL then till:=pred(strEnd(ptxt));
  if till^ = #10 then dec(till);
  if till^ = #13 then dec(till);

  base.txt:=getStr(ptxt, till);
  // there may be flags after |
  s:=cur_section;
  cur_section:=chop('|', s);
  base.nolog:=ansiPos('no log', s) > 0;
  base.nourl:=ansiPos('private', s) > 0;
  base.cache:=ansiPos('cache', s) > 0;
  base.ts:=now();

  s:=cur_section;
  append:=ansiStartsStr('+', s);
  if append then
    delete(s,1,1);

  // there may be several section names separated by =
  ss:=split('=', s);
  // handle the main section specific case
  if ss = NIL then addString('', ss);
  // assign to every name the same txt
  for i:=0 to length(ss)-1 do
    begin
    s:=trim(ss[i]);
    sect:=getSection(s, FALSE);
    from:=NIL;
    if sect = NIL then // not found
      begin
      if append then
        from:=getSection(s);
      sect:=newSection(s);
      end
    else
      if append then
        from:=sect;
    if from<>NIL then
      begin // inherit from it
      sect.txt:=from.txt+base.txt;
      sect.nolog:=from.nolog or base.nolog;
      sect.nourl:=from.nourl or base.nourl;
      continue;
      end;
    sect^:=base;
    sect.name:=s; // restore this lost attribute
    end;
  end; // saveInSection

const
  BOM = #$EF#$BB#$BF;
var
  first: boolean;
begin
// this is used by some unicode files. at the moment we just ignore it.
if ansiStartsStr(BOM, txt) then
  delete(txt, 1, length(BOM));
  
if txt = '' then exit;
src:=src+txt;
cur_section:='';
ptxt:=@txt[1];
first:=TRUE;
  repeat
  findNextSection();
  if not first or (trim(getStr(ptxt, pred(bos))) > '') then
    saveInSection();
  if bos = NIL then break;
  cur_section:=next_section;
  inc(bos, length(cur_section)); // get faster to the end of line
  ptxt:=succ(ansiStrPos(bos, #10)); // get to the end of line (and then beyond)
  first:=FALSE;
  until ptxt = NIL;
if assigned(onChange) then
  onChange(self);
end; // appendString

procedure Ttpl.setOver(v:Ttpl);
begin
fOver:=v;
end; // setOver

function Ttpl.getSections():TStringDynArray;
begin result:=sections.Keys.ToArray() end;

function Ttpl.me():Ttpl;
begin result:=self end;



procedure Ttlv.parse(data:ansistring);
begin
whole:=data;
cur:=1;
bound:=length(data);
stackTop:=0;
end; // parse

function Ttlv.pop(var value:string; var raw:ansistring):integer;
var
  n: integer;
begin
result:=-1;
if isOver() then exit; // finished
result:=integer((@whole[cur])^);
n:=Pinteger(@whole[cur+4])^;
raw:=copy(whole, cur+8, n);
lastRaw:=raw;
if result and TLV_UTF8_FLAG = 0 then
  value:=string(raw)
else
  begin
  dec(result, TLV_UTF8_FLAG);
  value:=UTF8toString(raw);
  end;
inc(cur, 8+n);
end; // pop

function Ttlv.down():boolean;
begin
// do we have anything to recur on?
if (cur = 1) then
  begin
  result:=false;
  exit;
  end;
// push into the stack
if (stackTop = length(stack)) then // space over
  setLength(stack, stackTop+10); // make space
stack[stackTop]:=cur;
inc(stackTop);
stack[stackTop]:=bound;
inc(stackTop);

bound:=cur;
dec(cur, length(lastRaw));
result:=true;
end; // down

function Ttlv.up():boolean;
begin
if stackTop = 0 then
  begin
  result:=false;
  exit;
  end;
dec(stackTop);
bound:=stack[stackTop];
dec(stackTop);
cur:=stack[stackTop];
result:=true;
end; // up

function Ttlv.getTotal():integer;
begin result:=length(whole) end;

function Ttlv.getCursor():integer;
begin result:=cur end;

function Ttlv.getPerc():real;
begin
if length(whole) = 0 then result:=0
else result:=cur/length(whole)
end; // getPerc

function Ttlv.isOver():boolean;
begin result:=(cur+8 > bound) end;

function Ttlv.getTheRest():ansistring;
begin result:=copy(whole, cur, bound-cur+1) end;

end.
