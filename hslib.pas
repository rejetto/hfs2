{
Copyright (C) 2002-2020 Massimo Melina (www.rejetto.com)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


HTTP Server Lib

==== TO DO
* https
* upload bandwidth control (can it be done without multi-threading?)

}
{$I- }

unit HSlib;

interface

uses
  OverbyteIcsWSocket, classes, messages, winprocs, forms, extctrls, sysutils, system.contnrs, strUtils, winsock, inifiles, types;

const
  VERSION = '2.11.0';

type
  ThttpSrv=class;

  ThttpConn=class;

  ThttpMethod=( HM_UNK, HM_GET, HM_POST, HM_HEAD );

  ThttpEvent=(
    HE_OPEN,            // server is listening
    HE_CLOSE,           // server does not listen anymore
    HE_CONNECTED,       // a client just connected
    HE_DISCONNECTED,    // client communication terminated
    HE_GOT,             // other peer sent sth
    HE_SENT,            // we sent sth
    HE_REQUESTING,      // a possible new request starts here
    HE_GOT_HEADER,      // header part was fully received
    HE_REQUESTED,       // a full request has been submitted
    HE_STREAM_READY,    // reply stream ready
    HE_REPLIED,         // the reply has been sent
    HE_POST_FILE,       // new file is posted
    HE_POST_MORE_FILE,  // more data has come for the previous file
    HE_POST_END_FILE,   // last file done
    HE_POST_VARS,       // variables are available
    HE_POST_VAR,        // single variable available
    HE_POST_END,        // POST section terminated
    HE_LAST_BYTE_DONE,  // useful to count full downloads
    HE_CANT_OPEN_FILE   // error
  );

  ThttpConnState=(
    HCS_IDLE,               // connected but idle
    HCS_REQUESTING,         // getting request
    HCS_POSTING,            // getting post data
    HCS_REPLYING,           // a reply is pending
    HCS_REPLYING_HEADER,    // sending header
    HCS_REPLYING_BODY,      // sending body
    HCS_DISCONNECTED        // disconnected
  );

  ThttpReplyMode=(
    HRM_REPLY,              // reply header+body
    HRM_REPLY_HEADER,       // reply header only
    HRM_DENY,               // answer a deny code
    HRM_UNAUTHORIZED,       // bad user/pwd
    HRM_NOT_FOUND,          // answer a not-found code
    HRM_BAD_REQUEST,        // answer a bad-request code
    HRM_INTERNAL_ERROR,     // answer an internal-error code
    HRM_CLOSE,              // close connection with no reply
    HRM_IGNORE,             // does nothing, connection remains open
    HRM_METHOD_NOT_ALLOWED, // answer a method-not-allowed code
    HRM_REDIRECT,           // redirection to another URL
    HRM_OVERLOAD,           // server is overloaded, retry later
    HRM_TOO_LARGE,          // the request has exceeded the max length allowed
    HRM_MOVED,              // moved permanently to another url
    HRM_NOT_MODIFIED        // use the one in your cache, client
  );

  ThttpReply = record
    mode: ThttpReplyMode;
    header: ansistring;            // full raw header (optional)
    contentType: ansistring;       // ContentType header (optional)
    additionalHeaders: ansistring; // these are appended to predefined headers (opt)
    bodyMode :(
      RBM_FILE,         // variable body specifies a file
      RBM_STRING,       // variable body specifies byte content
      RBM_STREAM        // refer to bodyStream
    );
    body: ansistring;    // specifies reply body according to bodyMode
    bodyFile: string;
    bodyStream: Tstream;   // note: the stream is automatically freed 
    firstByte, lastByte: int64;  // body interval for partial replies (206)
    realm,           // this will appear in the authentication dialog
    reason,         // customized reason phrase
    url: string;     // used for redirections
    resumeForbidden: boolean;
    end;

  ThttpRequest = record
    full: ansistring;           // the raw request, byte by byte
    method: ThttpMethod;
    url: ansistring;
    ver: ansistring;
    firstByte, lastByte: int64;  // body interval for partial requests
    headers, cookies: ThashedStringList;
    user,pwd: string;
    end;

  ThttpPost = record
    length: int64;          // multipart form-data length
    boundary,               // multipart form-data boundary
    header,                 // contextual header
    data: ansistring;       // misc data
    varname,                // post variable name
    filename: string;       // name of posted file
    mode: (PM_NONE, PM_URLENCODED, PM_MULTIPART);
    end;

  TspeedLimiter = class
  { connections can be bound to a limiter. The limiter is a common limited
  { resource (the bandwidth) that is consumed. }
  protected
    P_maxSpeed: integer;              // this is the limit we set. MAXINT means disabled.
    procedure setMaxSpeed(v:integer);
  public
    availableBandwidth: integer;    // this is the resource itself
    property maxSpeed: integer read P_maxSpeed write setMaxSpeed;
    constructor create(max:integer=MAXINT);
    end;

  ThttpConn = class
  protected
    srv: ThttpSrv;          // reference to the server
    stream: Tstream;
    P_address: string;
    P_port: string;
    brecvd: int64;          // bytes received from the client
    bsent: int64;           // bytes sent to the client
    bsent_body: int64;      // bytes sent to the client (current body only)
    bsent_bodies: int64;    // bytes sent to the client (for all bodies)
    P_requestCount: integer;
    P_destroying: boolean;  // destroying is in progress
    P_sndBuf: integer;
    P_v6: boolean;
    persistent: boolean;
    disconnecting: boolean; // disconnected() has been called
    lockCount: integer;     // prevent freeing of the object
    dontFulFil: boolean;
    firstPostFile: boolean;
    lastPostItemPos, FbytesPostedLastItem: int64;
    // post handling
    inBoundaries: boolean;   // we are between form-data boundaries
    postDataReceived: int64; // bytes received in post data
    // used to calculate actual speed
    lastBsent, lastBrecvd: int64;
    lastSpeedTime: int64;
    P_speedOut, P_speedIn: real;

    buffer: ansistring;       // internal buffer for incoming data
    // event handlers
    procedure disconnected(Sender: TObject; Error: Word);
    procedure dataavailable(Sender: TObject; Error: Word);
    procedure senddata(sender:Tobject; bytes:integer);
    procedure datasent(sender:Tobject; error:word);
    function  fullBodySize():int64;
    function  partialBodySize():int64;
    function  sendNextChunk(max:integer=MAXINT):integer;
    function  getBytesToSend():int64;
    function  getBytesToPost():int64;
    function  getBytesGot():int64;
    procedure notify(ev:ThttpEvent);
    procedure tryNotify(ev:ThttpEvent);
    procedure calculateSpeed();
	  procedure sendheader(h:ansistring='');
		function  replyHeader_mode(mode:ThttpReplyMode):ansistring;
		function  replyHeader_code(code:integer):ansistring;
    function  getDontFree():boolean;
    procedure processInputBuffer();
    procedure clearRequest();
    procedure clearReply();
    procedure setSndbuf(v:integer);
  public
    sock: Twsocket;             // client-server communication socket
    state: ThttpConnState;      // what is doing now with this
    request: ThttpRequest;      // it requests
    reply: ThttpReply;          // we serve
    post: ThttpPost;            // it posts
    data: pointer;              // user data
    paused: boolean;            // while (not paused) do senddata()
    eventData: ansistring;
    ignoreSpeedLimit: boolean;
    limiters: TobjectList;     // every connection can be bound to a number of TspeedLimiter
    constructor create(server:ThttpSrv; acceptingSock:Twsocket);
    destructor Destroy; override;
    procedure disconnect();
    procedure addHeader(s:ansistring; overwrite:boolean=TRUE); // set an additional header line. If overwrite=false will always append.
    function  setHeaderIfNone(s:ansistring):boolean; // set header if not already existing
    procedure removeHeader(name:ansistring);
    function  getHeader(h:ansistring):string;  // extract the value associated to the specified header field
    function  getHeaderA(h:ansistring):ansistring;  // extract the value associated to the specified header field
    function  getCookie(k:string):string;
    procedure setCookie(k, v:string; pairs:array of string; extra:string='');
    procedure delCookie(k:string);
    function getBuffer():ansistring;
    function  initInputStream():boolean;
    property address:string read P_address;      // other peer ip address
    property port:string read P_port;            // other peer port
    property v6:boolean read P_v6;
    property requestCount:integer read P_requestCount;
    property bytesToSend:int64 read getBytesToSend;
    property bytesToPost:int64 read getBytesToPost;
    property bytesSent:int64 read bsent_bodies;
    property bytesSentLastItem:int64 read bsent_body;
    property bytesPartial:int64 read partialBodySize;
    property bytesFullBody:int64 read fullBodySize;
    property bytesGot:int64 read getBytesGot;
    property bytesPosted:int64 read postDataReceived;
    property bytesPostedLastItem:int64 read FbytesPostedLastItem;
    property speedIn:real read P_speedIn;  // (bytes_recvd/s)
    property speedOut:real read P_speedOut;  // (bytes_sent/s)
    property disconnectedByServer:boolean read disconnecting;
    property destroying:boolean read P_destroying;
    property dontFree:boolean read getDontFree;
    property getLockCount:integer read lockCount;
    property sndBuf:integer read P_sndBuf write setSndBuf;
    end;

  ThttpSrv = class
  protected
    timer: Ttimer;
    lockTimerevent: boolean;
    lastHertz: Tdatetime;

    P_port: string;
    P_autoFree: boolean;
    P_speedIn, P_speedOut: real;
    bsent, brecvd: int64;
    procedure setPort(v:string);
    function  getActive():boolean;
    procedure setActive(v:boolean);
    procedure connected(Sender: TObject; Error: Word);
    procedure disconnected(Sender: TObject; Error: Word);
    procedure bgexception(Sender: TObject; E:Exception; var CanClose:Boolean);
    procedure setAutoFree(v:boolean);
    procedure notify(ev:ThttpEvent; conn:ThttpConn);
    procedure hertzEvent();
    procedure timerEvent(sender:Tobject);
    procedure calculateSpeed();
    procedure processDisconnecting();
  public
    sock, sock6: Twsocket;     // listening socket
    conns,          // full list of connected clients
    disconnecting,  // list of pending disconnections
    offlines,       // disconnected clients to be freed
    q,              // clients waiting for data to be sent
    limiters: TobjectList;
    data: pointer;      // user data
    persistentConnections: boolean;  // if FALSE disconnect clients after they're served
    onEvent: procedure(event:ThttpEvent; conn:ThttpConn) of object;
    constructor create(); overload;
    destructor Destroy(); override;
    property active:boolean read getActive write setActive; // r we listening?
    property port:string read P_port write setPort;
    property bytesSent:int64 read bsent;
    property bytesReceived:int64 read brecvd;
    property speedIn:real read P_speedIn;  // (bytes_recvd/s)
    property speedOut:real read P_speedOut;  // (bytes_sent/s)
    property autoFreeDisconnectedClients: boolean read P_autoFree write setAutoFree;
    function start(onAddress:string='*'):boolean; // returns true if all is ok
    procedure stop();
    procedure disconnectAll(wait:boolean=FALSE);
    procedure freeConnList(l:TobjectList);
    end;

const
  TIMER_HZ = 100;
  MINIMUM_CHUNK_SIZE = 2*1024;
  MAXIMUM_CHUNK_SIZE = 1024*1024;
  HRM2CODE: array [ThttpReplyMode] of integer = (200, 200, 403, 401, 404, 400,
  	500, 0, 0, 405, 302, 429, 413, 301, 304 );
  METHOD2STR: array [ThttpMethod] of ansistring = ('UNK','GET','POST','HEAD');
  HRM2STR: array [ThttpReplyMode] of ansistring = ('Head+Body', 'Head only', 'Deny',
    'Unauthorized', 'Not found', 'Bad request', 'Internal error', 'Close',
    'Ignore', 'Unallowed method', 'Redirect', 'Overload', 'Request too large',
    'Moved permanently', 'Not Modified');

{ split S in position where SS is found, the first part is returned
  the second part following SS is left in S }
function chop(ss:string; var s:string):string; overload;
function chop(ss:ansistring; var s:ansistring):ansistring; overload;
// same as before, but separator is I
function chop(i:integer; var s:string):string; overload;
// same as before, but specifying separator length
function chop(i, l:integer; var s:string):string; overload;
function chop(i, l:integer; var s:ansistring):ansistring; overload;
// same as chop(lineterminator, s)
function chopLine(var s:string):string; overload;
// decode/decode url
function decodeURL(url:ansistring; utf8:boolean=TRUE):string;
function encodeURL(url:string; nonascii:boolean=TRUE; spaces:boolean=TRUE;
  htmlEncoding:boolean=FALSE):string;
// returns true if address is not suitable for the internet
function isLocalIP(ip:string):boolean;
// base64 encoding
function base64encode(s:ansistring):ansistring;
function base64decode(s:ansistring):ansistring;
// an ip address where we are listening
function getIP():string;
// ensure a string ends with a specific string
procedure includeTrailingString(var s:string; ss:string);
// gets unicode code for specified character
function charToUnicode(c:char):dword;
// this version of pos() is able to skip the pattern if inside quotes
function nonQuotedPos(ss, s:string; ofs:integer=1; quote:string='"'; unquote:string='"'):integer;
// case insensitive version
function ipos(ss, s:string; ofs:integer=1):integer; overload;

implementation

uses
  Windows, ansistrings;
const
  CRLF = #13#10;
  HEADER_LIMITER: ansistring = CRLF+CRLF;
  MAX_REQUEST_LENGTH = 64*1024;
  MAX_INPUT_BUFFER_LENGTH = 256*1024;
  // used as body content when the user did not specify any
  HRM2BODY: array [ThttpReplyMode] of string = (
  	'200 - OK',
    '200 - OK (header only)',
    '403 - You are not allowed to access this file',
    '401 - You are not authorized to access this file',
    '404 - File not found',
    '400 - Bad request',
    '500 - Internal server error',
    '',
    '',
    '405 - Method not allowed',
    '<html><head><meta http-equiv="refresh" content="url=%url%" /></head><body onload=''window.location="%url%"''>302 - <a href="%url%">Redirection to %url%</a></body></html>',
    '429 - Server is overloaded, retry later',
    '413 - The request has exceeded the max length allowed',
    '301 - Moved permanently to <a href="%url%">%url%</a>',
    '' // RFC2616: The 304 response MUST NOT contain a message-body
  );
var
  freq: int64;

procedure includeTrailingString(var s:string; ss:string); overload;
begin if copy(s, length(s)-length(ss)+1, length(ss)) <> ss then s:=s+ss end;

procedure includeTrailingString(var s:ansistring; ss:ansistring); overload;
begin if copy(s, length(s)-length(ss)+1, length(ss)) <> ss then s:=s+ss end;

function charToUnicode(c:char):dword;
begin stringToWideChar(c,@result,4) end;

function isLocalIP(ip:string):boolean;
var
  r: record d,c,b,a:byte end;
begin
if ip = '::1' then
  exit(TRUE);
dword(r):=WSocket_ntohl(WSocket_inet_addr(ansiString(ip)));
result:=(r.a in [0,10,23,127])
  or (r.a = 192) and ((r.b = 168) or (r.b = 0) and (r.c = 2))
  or (r.a = 169) and (r.b = 254)
  or (r.a = 172) and (r.b in [16..31])
end; // isLocalIP

function ifThen(c:boolean; a:integer; b:integer=0):integer; overload;
begin if c then result:=a else result:=b end;

function min(a,b:integer):integer;
begin if a < b then result:=a else result:=b end;

function ipos(ss, s: string; ofs:integer=1):integer; overload;
var
  rss, rs, rss1, p: pchar;
  l: integer;
begin
result:=0;
l:=length(s);
if (l < ofs) or (l = 0) or (ss = '') then exit;
// every strange thing you may notice here is an optimization based on the produced asm
ss:=uppercase(ss);
rss1:=@ss[1];
rs:=@s[ofs];
for result:=ofs to l do
  begin
  rss:=rss1;
  p:=rs;
  while (rss^ <> #0) and (rss^ = upcase(p^)) do
    begin
    inc(rss);
    inc(p);
    end;
  if rss^ = #0 then exit; // we saw it all, and we saw it was good
  inc(rs);
  end;
result:=0;
end; // ipos

function nonQuotedPos(ss, s:string; ofs:integer=1; quote:string='"'; unquote:string='"'):integer;
var
  qpos: integer;
begin
  repeat
  result:=posEx(ss, s, ofs);
  if result = 0 then exit;
  
    repeat
    qpos:=posEx(quote, s, ofs);
    if qpos = 0 then exit; // there's no quoting, our result will fit
    if qpos > result then exit; // the quoting doesn't affect the piece, accept the result
    ofs:=posEx(unquote, s, qpos+1);
    if ofs = 0 then exit; // it is not closed, we don't consider it quoting
    inc(ofs);
    until ofs > result; // this quoting was short, let's see if we have another
  until false;
end; // nonQuotedPos

// consider using TBase64Encoding.Base64.Encode() in unit netencoding
function base64encode(s:ansistring):ansistring;
const
  TABLE:ansistring='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
type
  Ttriple=array [0..2] of byte;
var
  p: ^Ttriple;
  i: integer;
begin
result:='';
p:=@s[1];
for i:=1 to length(s) div 3 do
  begin
  result:=result+TABLE[1+p[0] shr 2]
  	+TABLE[1+(p[0] and 3) shl 4+p[1] shr 4]
    +TABLE[1+(p[1] and 15) shl 2+p[2] shr 6]
    +TABLE[1+(p[2] and 63)];
  inc(p);
  end;
if length(s) mod 3 = 0 then
  exit;
result:=result
  +TABLE[1+p[0] shr 2]
  +TABLE[1+(p[0] and 3) shl 4+p[1] shr 4];
if length(s) mod 3=1 then
  result:=result+'=='
else
  result:=result+TABLE[1+(p[1] and 15) shl 2+p[2] shr 6]+'=';
end; // base64encode

function base64decode(s:ansistring):ansistring;

  function if_(cond:boolean; c:ansichar):ansistring;
  begin
  if cond then
    result:=c
  else
    result:=''
  end;

const
  TABLE:array[#43..#122] of byte=(
  	62,0,0,0,63,52,53,54,55,56,57,58,59,60,61,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,
    8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,0,0,0,0,0,0,26,27,28,
    29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51);
var
  i: integer;
  p1, p2: byte;
begin
result:='';
i:=1;
while i <= length(s) do
  begin
  p1:=TABLE[s[i+1]];
  p2:=TABLE[s[i+2]];
	result:=result
  	+ansichar(TABLE[s[i]] shl 2+p1 shr 4)
    +if_(s[i+2]<>'=', ansichar(p1 shl 4+p2 shr 2))
    +if_(s[i+3]<>'=', ansichar(p2 shl 6+TABLE[s[i+3]]));
  inc(i,4);
  end;
end; // base64decode

function validUTF8(s:rawbytestring):boolean;
var
  i, more, len: integer;
  c: byte;
begin
len:=length(s);
i:=0;
while i < len do
  begin
  inc(i);
  c:=ord(s[i]);
  if c < $80 then
    continue;
  if c >= $FE then
    exit(FALSE);
  if c >= $F0 then
    more:=3
  else if c >= $E0 then
    more:=2
  else if c >= $C0 then
    more:=1
  else
    exit(FALSE);
  if i+more > len then
    exit(FALSE);
  while more > 0 do
    begin
    inc(i);
    c:=ord(s[i]);
    if (c < $80) or (c > $C0) then
      exit(FALSE);
    dec(more);
    end;
  end;
result:=TRUE;
end; // validUTF8

function decodeURL(url:ansistring; utf8:boolean=TRUE):string;
var
  i, j: integer;
begin
j:=0;
i:=0;
while i<length(url) do
  begin
  inc(i);
  inc(j);
  if (url[i] = '%') and (i+2 <= length(url)) then
    try
      url[j]:=ansichar(strToInt( '$'+url[i+1]+url[i+2] ));
      inc(i,2); // three chars for one
    except url[j]:='_' end
  else if i>j then
    url[j]:=url[i];
  end;
setLength(url, j);
if utf8 and validUTF8(url)  then
  begin
  result:=utf8ToString(url);
  // if the string is not UTF8 compliant, the result is empty, or sometimes same length (but ruined)
  if (result='') or (length(result)=length(url)) then
    result:=url;
  end
else
  result:=url;
end; // decodeURL

function encodeURL(url:string; nonascii:boolean=TRUE; spaces:boolean=TRUE;
  htmlEncoding:boolean=FALSE):string;
var
  i: integer;
  encodePerc, encodeHTML: set of char;
  a: ansistring;
begin
result:='';
if url = '' then
  exit;
encodeHTML:=[];
if nonascii then
  encodeHTML:=[#128..#255];
encodePerc:=[#0..#31,'#','%','?','"','''','&','<','>',':'];
// actually ':' needs encoding only in relative url
if spaces then include(encodePerc,' ');
if not htmlEncoding then
  begin
  encodePerc:=encodePerc+encodeHTML;
  encodeHTML:=[];
  end;
if nonascii then
  begin
  a:=UTF8encode(url); // couldn't find a better way to force url to have the UTF8 encoding
  i:=length(a);
  setLength(url, i);
  for i := 1 to i do
    url[i]:=char(a[i]);
  end;
for i:=1 to length(url) do
	if charInSet(url[i], encodePerc) then
    result:=result+'%'+intToHex(ord(url[i]),2)
  else if charInSet(url[i], encodeHTML) then
    result:=result+'&#'+intToStr(charToUnicode(url[i]))+';'
  else
    result:=result+url[i];
end; // encodeURL

function getIP():string;
var
  i: integer;
  ips: Tstrings;
begin
ips:=LocalIPlist();
case ips.count of
  0: result:='';
  1: result:=ips[0];
  else
    i:=0;
    while (i < ips.count-1) and isLocalIP(ips[i]) do
      inc(i);
    result:=ips[i];
  end;
end; // getIP

function replyHeader_IntPositive(name:ansistring; int:int64):ansistring;
begin
result:='';
if int >= 0 then
  result:=name+': '+ansistring(intToStr(int))+CRLF;
end;

function replyHeader_Str(name:ansistring; str:ansistring):ansistring;
begin
result:='';
if str > '' then result:=name+': '+str+CRLF;
end;

function chop(i, l:integer; var s:string):string; overload;
begin
if i=0 then
  begin
  result:=s;
  s:='';
  exit;
  end;
result:=copy(s,1,i-1);
delete(s,1,i-1+l);
end; // chop

function chop(i, l:integer; var s:ansistring):ansistring; overload;
begin
if i=0 then
  begin
  result:=s;
  s:='';
  exit;
  end;
result:=copy(s,1,i-1);
delete(s,1,i-1+l);
end; // chop

function chop(ss:string; var s:string):string; overload;
begin result:=chop(pos(ss,s),length(ss),s) end;

function chop(ss:ansistring; var s:ansistring):ansistring; overload;
begin result:=chop(pos(ss,s),length(ss),s) end;

function chop(i:integer; var s:string):string;
begin result:=chop(i,1,s) end;

function chopLine(var s:string):string; overload;
begin
result:=chop(#10,s);
if (result>'') and (result[length(result)]=#13) then
  setlength(result, length(result)-1);
end; // chopline

function chopLine(var s:ansistring):ansistring; overload;
begin
result:=chop(#10,s);
if (result>'') and (result[length(result)]=#13) then
  setlength(result, length(result)-1);
end; // chopline

/////// SERVER

function ThttpSrv.start(onAddress:string='*'):boolean;
begin
result:=FALSE;
if active or not assigned(sock) then exit;
try
  if onAddress = '' then
    onAddress:='*';
  sock.addr:=ifThen(onAddress = '*', '0.0.0.0', onAddress);
  sock.port:=port;
  sock.listen();
  if port = '0' then
    P_port:=sock.getxport();
  result:=TRUE;

  if onAddress = '*' then
    with sock6 do
      begin
      addr:='::';
      Port:=sock.port;
      try listen except end;
      end;
  notify(HE_OPEN, NIL);
except
  end;
end; // start

procedure ThttpSrv.stop();
begin
if sock = NIL then exit;
try sock.Close() except end;
try sock6.Close() except end;
end;

procedure ThttpSrv.connected(Sender: TObject; Error: Word);
begin if error=0 then ThttpConn.create(self, sender as Twsocket) end;

procedure ThttpSrv.disconnected(Sender: TObject; Error: Word);
begin notify(HE_CLOSE, NIL) end;

constructor ThttpSrv.create();
begin
sock:=TWSocket.create(NIL);
sock.OnSessionAvailable:=connected;
sock.OnSessionClosed:=disconnected;
sock.OnBgException:=bgexception;
sock6:=TWSocket.create(NIL);
sock6.OnSessionAvailable:=connected;
sock6.OnBgException:=bgexception;

conns:=TobjectList.create;
conns.OwnsObjects:=FALSE;
offlines:=TobjectList.create;
offlines.OwnsObjects:=FALSE;
q:=TobjectList.create;
q.OwnsObjects:=FALSE;
disconnecting:=TobjectList.create;
disconnecting.OwnsObjects:=FALSE;
limiters:=TobjectList.create;
limiters.OwnsObjects:=FALSE;
timer:=Ttimer.create(NIL);
timer.OnTimer:=timerEvent;
timer.Interval:=1000 div TIMER_HZ;
timer.Enabled:=TRUE;
Port:='80';
autoFreeDisconnectedClients:=TRUE;
persistentConnections:=TRUE;
end; // create

destructor ThttpSrv.destroy();
begin
freeAndNIL(timer);
stop();
disconnectAll(TRUE);
processDisconnecting();
freeAndNIL(sock);
freeConnList(conns);
freeAndNIL(conns);
freeAndNIL(disconnecting);
freeAndNIL(offlines);
freeAndNIL(q);
freeAndNIL(limiters);
inherited;
end; // destroy

procedure ThttpSrv.hertzEvent();
var
  i: integer;
begin
if now()-lastHertz < 1/(24*60*60) then exit;
lastHertz:=now();
calculateSpeed();
for i:=0 to limiters.Count-1 do
  try
    with limiters[i] as TspeedLimiter do
      availableBandwidth:=maxSpeed;
  except end;
end; // hertzEvent

procedure ThttpSrv.processDisconnecting();
var
  c: ThttpConn;
  i: integer;
begin
i:=0;
while i < disconnecting.Count do
  begin
  c:=disconnecting[i] as ThttpConn;
  inc(i);
  if c.dontFree then continue;
  c.processInputBuffer(); // serve, till the end.
  disconnecting.delete(i-1);
  q.remove(c);
  conns.remove(c);
  offlines.add(c);
  notify(HE_DISCONNECTED, c);
  end;
end; // processDisconnecting

procedure ThttpSrv.timerEvent(sender:Tobject);

  procedure processPipelines();
  var
    i: integer;
  begin
  for i:=0 to conns.count-1 do
    try
      with ThttpConn(conns[i]) do
        if (state in [HCS_IDLE, HCS_DISCONNECTED]) and (buffer > '') then
          processInputBuffer();
    except end;
  end; // processPipelines

  procedure processQ();
  var
    c: ThttpConn;
    toQ: Tobjectlist;
    i, chunkSize: integer;
  begin
  toQ:=Tobjectlist.create;
  try
    toQ.ownsObjects:=FALSE;
    while q.count > 0 do
      begin
      c:=NIL;
      try
        c:=q.first() as ThttpConn; // got an AV here, had no better solution than adding a try statement www.rejetto.com/forum/?topic=6204
        q.delete(0);
      except end;
      if c = NIL then continue;

      try
        chunkSize:=ifThen(c.paused, 0, MAXINT);
        if not c.ignoreSpeedLimit then
          for i:=0 to c.limiters.Count-1 do
            with c.limiters[i] as TspeedLimiter do
              if availableBandwidth >= 0 then
                chunkSize:=min(chunkSize, availableBandwidth);
        if chunkSize <= 0 then
          begin
          toQ.add(c);
          continue;
          end;
        if c.destroying or (c.state = HCS_DISCONNECTED)
        or (c.sock = NIL) or (c.sock.State <> wsConnected) then
          continue;
        // serve the pending connection with a data chunk
        chunkSize:=c.sendNextChunk(chunkSize);
        for i:=0 to c.limiters.Count-1 do
          with c.limiters[i] as TspeedLimiter do
            dec(availableBandwidth, chunkSize);
      except end;
      end;
    q.assign(toQ, laOR);
  finally toQ.Free end;
  end; // processQ

begin
hertzEvent();

lockTimerevent:=TRUE;
try
  processDisconnecting();
  if autoFreeDisconnectedClients then freeConnList(offlines);
  processPipelines();
  processQ();
finally
  lockTimerevent:=FALSE
  end;
end; // timerEvent

procedure ThttpSrv.notify(ev:ThttpEvent; conn:ThttpConn);
begin
if not assigned(onEvent) then exit;
if assigned(conn) then
  begin
  inc(conn.lockCount);
  conn.sock.pause();
  end;
// event handler shall not break our thing
try onEvent(ev, conn);
finally
  //if assigned(sock) then sock.resume();
  if assigned(conn) then
    begin
    dec(conn.lockCount);
    conn.sock.resume();
    end;
  end;
end;

function Thttpsrv.getActive():boolean;
begin result:=assigned(sock) and (sock.State=wsListening) end;

procedure ThttpSrv.setActive(v:boolean);
begin
if v <> active then
  if v then start() else stop()
end; // setactive

procedure ThttpSrv.freeConnList(l:TobjectList);
begin
while l.count > 0 do
  with l.first() as ThttpConn do
    try
      try l.delete(0)
      finally free end
    except end;
end; // freeConnList

procedure ThttpSrv.calculateSpeed();
var
  i: integer;
begin
P_speedOut:=0;
P_speedIn:=0;
i:=0;
while i < conns.count do
  begin
  ThttpConn(conns[i]).calculateSpeed();
  P_speedOut:=P_speedOut+ThttpConn(conns[i]).speedOut;
  P_speedIn:=P_speedIn+ThttpConn(conns[i]).speedIn;
  inc(i);
  end;
end; // calculateSpeed

procedure ThttpSrv.setPort(v:string);
begin
if active then
  raise Exception.Create(classname+': cannot change port while active');
P_port:=v
end; // setPort

procedure ThttpSrv.disconnectAll(wait:boolean=FALSE);
var
  i: integer;
  clone: Tlist;
begin
// on disconnection <conns> list changes. clone it for safer enumeration.
clone:=Tlist.Create;
clone.Assign(conns);
// cast disconnection
for i:=0 to clone.count-1 do
  ThttpConn(clone[i]).disconnect();
if wait then
  for i:=0 to clone.count-1 do
    if conns.IndexOf(clone[i]) >= 0 then
      ThttpConn(clone[i]).sock.WaitForClose();
clone.free;
end; // disconnectAll

procedure ThttpSrv.setAutoFree(v:boolean);
begin P_autofree:=v end;

procedure ThttpSrv.bgexception(Sender: TObject; E: Exception; var CanClose: Boolean);
begin canClose:=FALSE end;

////////// CLIENT

constructor ThttpConn.create(server:ThttpSrv; acceptingSock:Twsocket);
var
  i: integer;
begin
// init socket
sock:=Twsocket.create(NIL);
sock.Dup(acceptingSock.accept());
sock.OnDataAvailable:=dataavailable;
sock.OnSessionClosed:=disconnected;
sock.onSendData:=senddata;
sock.onDataSent:=datasent;
sock.LineMode:=FALSE;

request.headers:=ThashedStringList.create;
request.headers.nameValueSeparator:=':';
limiters:=TObjectList.create;
limiters.ownsObjects:=FALSE;
P_address:=sock.GetPeerAddr();
P_port:=sock.GetPeerPort();
P_v6:=pos(':', address) > 0;
state:=HCS_IDLE;
srv:=server;
srv.conns.add(self);
clearRequest();
clearReply();
QueryPerformanceCounter(lastSpeedTime);

i:=sizeOf(P_sndBuf);
if WSocket_getsockopt(sock.HSocket, SOL_SOCKET, SO_SNDBUF, @P_sndBuf, i) <> NO_ERROR then
  P_sndBuf:=0;

server.notify(HE_CONNECTED, self);
if reply.mode <> HRM_CLOSE then exit;
dontFulFil:=TRUE;
disconnect();
end;

destructor ThttpConn.destroy;
begin
if dontFree then
  raise exception.Create('still in use');
P_destroying:=TRUE;
if assigned(sock) then
  try
    sock.Shutdown(SD_BOTH);
    sock.WaitForClose();
  except
    end;
if assigned(srv) and assigned(srv.offlines) then
  srv.offlines.remove(self);
freeAndNIL(request.headers);
freeAndNIL(request.cookies);
freeAndNil(stream);
freeAndNIL(sock);
freeAndNIL(limiters);
inherited;
end; // destroy

procedure ThttpConn.calculateSpeed();
var
	bytes: int64;
  now: int64;
  elapsed: Tdatetime;
begin
if freq = 0 then exit;

QueryPerformanceCounter(now);
elapsed:=(now-lastSpeedTime)/freq;
lastSpeedTime:=now;

bytes:=bsent-lastBsent;
lastBsent:=bsent;
P_speedOut:=bytes/elapsed;

bytes:=brecvd-lastBrecvd;
lastBrecvd:=brecvd;
P_speedIn:=bytes/elapsed;
end; // calculateSpeed

procedure ThttpConn.disconnected(Sender: TObject; Error: Word);
begin
state:=HCS_DISCONNECTED;
srv.disconnecting.Add(self);
end;

function ThttpConn.getHeader(h:ansistring):string;
begin
result:='';
if request.method <> HM_UNK then
  result:=trim(UTF8toString(rawByteString(request.headers.values[h])));
end; // getHeader

function ThttpConn.getHeaderA(h:ansistring):ansistring;
begin
result:='';
if request.method <> HM_UNK then
  result:=ansistrings.trim(ansistring(request.headers.values[h]));
end; // getHeaderA

function ThttpConn.getBuffer():ansistring;
begin result:=buffer end;

function ThttpConn.getCookie(k:string):string;
begin
result:='';
if request.method = HM_UNK then exit;
if request.cookies = NIL then
  begin
  request.cookies:=ThashedStringList.create;
  request.cookies.delimiter:=';';
  request.cookies.QuoteChar:=#0;
  request.cookies.delimitedText:=getHeader('cookie');
  end;
result:=decodeURL(ansistring(trim(request.cookies.values[k])));
end; // getCookie

procedure ThttpConn.delCookie(k:string);
begin setCookie(k,'', ['expires','Thu, 01-Jan-70 00:00:01 GMT']) end;

procedure ThttpConn.setCookie(k, v:string; pairs:array of string; extra:string='');
var
  i: integer;
begin
v:='Set-Cookie: '+k+'='+v+'; ';
i:=0;
while i < length(pairs)-1 do
  begin
  v:=v+lowerCase(pairs[i])+'='+pairs[i+1]+'; ';
  inc(i,2);
  end;
addHeader(UTF8encode(v+extra));
end; // setCookie

procedure ThttpConn.clearRequest();
begin
request.method:=HM_UNK;
request.ver:='';
request.url:='';
request.firstByte:=-1;
request.lastByte:=-1;
request.headers.clear();
freeAndNIL(request.cookies);
request.user:='';
request.pwd:='';
end; // clearRequest

procedure ThttpConn.clearReply();
begin
reply.header:='';
reply.bodyMode:=RBM_STRING;
reply.body:='';
reply.additionalHeaders:='';
reply.mode:=HRM_IGNORE;
reply.firstByte:=request.firstByte;
reply.lastByte:=request.lastByte;
reply.realm:='Password protected resource';
reply.reason:='';
end; // clearReply

procedure ThttpConn.processInputBuffer();

  function parseHeader():boolean;
  var
    r, s: ansistring;
    u: string;
    i : integer;
  begin
  result:=FALSE;
  r:=request.full;

  // find first blank space
  for i:=1 to 10 do
    if i > length(r) then exit
    else if r[i]=' ' then break;

  clearRequest();
  post.header:='';
  post.mode:=PM_NONE;

  s:=ansiUppercase(chop(i, 1, r));
  if s='GET' then request.method:=HM_GET else
  if s='POST' then request.method:=HM_POST else
  if s='HEAD' then request.method:=HM_HEAD else;

  request.url:=chop(' ', r);

  s:=ansiUppercase(chopLine(r));
  // if 'HTTP/' is not found, chop returns S
  if chop('HTTP/',s) = '' then request.ver:=s;

  request.headers.text:=r;

  s:=getHeaderA('Range');
  if ansiStartsText('bytes=',s) then
    begin
    delete(s,1,6);
    r:=chop('-',s);
    try
      if r>'' then request.firstByte:=strToInt64(r);
      if s>'' then request.lastByte:=strToInt64(s);
    except end;
    end;

  s:=getHeaderA('Authorization');
  if AnsiStartsText('Basic',s) then
    begin
    delete(s,1,6);
    u:=UTF8toString(base64decode(s));
    request.user:=trim(chop(':',u));
    request.pwd:=u;
    end;

  s:=getHeaderA('Connection');
  persistent:=srv.persistentConnections and
    (ansiStartsText('Keep-Alive',s) or (request.ver >= '1.1') and (ipos('close',s)=0));

  s:=ansistring(getHeader('Content-Type'));
  if ansiStartsText('application/x-www-form-urlencoded', s) then
    post.mode:=PM_URLENCODED
  else if ansiStartsText('multipart/form-data', s) then
    begin
    post.mode:=PM_MULTIPART;
    chop('boundary=', s);
    post.boundary:='--'+s;
    end;
  post.length:=StrToInt64Def(getHeader('Content-Length'), 0);
  // the browser may not support 2GB+ files. This workaround works only for files under 4GB.
  if post.length < 0 then inc(post.length, int64(2) shl 31);

  result:=TRUE;
  end; // parseHeader

  procedure handlePostMultipart();

    procedure handleLeftData(i:integer);
    begin
    // the data processed below is related to the previous file
    post.data:=chop(i, length(post.boundary), buffer);
    // if data was found, we must trim the CRLF between data and boundary
    setlength(post.data, length(post.data)-2);
    // we expect this data to have a filename, otherwise it is just discarded
    if post.filename > '' then
      tryNotify(HE_POST_MORE_FILE)
    else if post.varname > '' then
      tryNotify(HE_POST_VAR);
    FbytesPostedLastItem:=bytesPosted-length(buffer)-lastPostItemPos-length(post.boundary)-2;
    if post.filename > '' then
      tryNotify(HE_POST_END_FILE);
    end; // handleLeftData

  var
    i: integer;
    s, l, k, v: ansistring;
    ws: widestring;
  begin
    repeat
    { When the buffer is stuffed with file bytes only, we can avoid calling pos() and chop().
    { Unexpectedly this did not speed up anything. I report the try so you don't waste your time.
    if (bytesPosted < post.length-length(post.boundary)) and (post.filename > '') then
      begin
      post.data:=buffer;
      buffer:='';
      notify(HE_POST_MORE_FILE);
      break;
      end;
    }

    // a boundary point at a (sub)header or to the end of the post section
    i:=pos(post.boundary, buffer);
    if i = 0 then
      begin
      if post.filename = '' then
        post.data:=post.data+chop(length(buffer)-length(post.boundary), 0, buffer)
      else
        { no boundary, this is a chunk of the file we are receiving. notify the listener
        { only about the data we are sure it doesn't overlap a possibly coming boundary }
        begin
        post.data:=chop(length(buffer)-length(post.boundary), 0, buffer);
        if post.data > ''
          then tryNotify(HE_POST_MORE_FILE);
        end;
      break;
      end;
    // was it the end of the post section?
    if copy(buffer, i+length(post.boundary), 4) = '--'+CRLF then
      begin
      handleLeftData(i);
      chop('--'+CRLF, buffer);
      tryNotify(HE_POST_END);
      state:=HCS_REPLYING;
      post.filename:='';
      break;
      end;
    // we wait for the header to be complete
    if posEx(HEADER_LIMITER, buffer, i+length(post.boundary)) = 0 then
      break;
    handleLeftData(i);
    post.filename:='';
    post.data:='';
    post.header:=chop(HEADER_LIMITER, buffer);
    chopLine(post.header);
    // parse the header part
    s:=post.header;
    while s > '' do
      begin
      l:=chopLine(s);
      if l = '' then continue;
      k:=chop(':', l);
      if not sameText(k, 'Content-Disposition') then // we are only interested in content-disposition: form-data
        continue;
      k:=trim(chop(';', l));
      if not sameText(k, 'form-data') then
        continue;
      while l > '' do
        begin
        v:=chop(nonQuotedPos(';', l), 1, l);
        k:=trim(chop('=', v));
        ws:=UTF8toString(ansiDequotedStr(v,'"'));
        if sameText(k, 'filename') then
          begin
          delete(ws, 1, lastDelimiter('/\',ws));
          post.filename:=ws;
          end
        else if sameText(k, 'name') then
          post.varname:=ws;
        end;
      end;
    lastPostItemPos:=bytesPosted-length(buffer);
    if post.filename = '' then
      continue;
    firstPostFile:=FALSE;
    tryNotify(HE_POST_FILE);
    until false;
  end; // handlePostMultipart

  procedure handlePostData();
  begin
  case post.mode of
    PM_MULTIPART: handlePostMultipart();
    PM_URLENCODED:
      if bytesToPost <= 0 then
        begin
        post.data:=chop(bytesPosted+1, 0, buffer);
        tryNotify(HE_POST_VARS);
        end;
    end;
  if bytesToPost <= 0 then
    begin
    tryNotify(HE_POST_END);
    state:=HCS_REPLYING
    end;
  end; // handlePostData

  procedure handleHeaderData();
  var
    i, sepLen: integer;
  begin
  // try to identify header length and position
  i:=pos(CRLF+CRLF, buffer);
  sepLen:=4;
  if i <= 0 then
    begin
    // support for non-standard line separator
    i:=pos(#13#13, buffer);
    sepLen:=2;
    end;
  if i <= 0 then
    begin
    // no full header yet
    if pos(#3,buffer) > 0 then // search for a CTRL+C issued with a telnet session
      begin
      reply.mode:=HRM_CLOSE;
      disconnect();
      end;
    if length(buffer) > MAX_REQUEST_LENGTH then // and check for max length
      begin
      reply.mode:=HRM_TOO_LARGE;
      sendHeader(replyheader_mode(reply.mode));
      end;
    exit;
    end;
  request.full:=chop(i,sepLen,buffer);
  if not parseHeader() then exit;
  notify(HE_GOT_HEADER);
  if request.method <> HM_POST then
    begin
    state:=HCS_REPLYING;
    exit;
    end;
  state:=HCS_POSTING;
  firstPostFile:=TRUE;
  postDataReceived:=length(buffer);
  handlePostData();
  end; // handleHeaderData

  function replyHeader_OK(contentLength:int64=-1):ansistring;
  begin
  result:=replyheader_code(200)
    +ansistring(format('Content-Length: %d'+CRLF, [contentLength]));
  end; // replyHeader_OK

  function replyHeader_PARTIAL( firstB, lastB, totalB:int64):ansistring;
  begin
  result:=replyheader_code(206)
    +ansistring(format('Content-Range: bytes %d-%d/%d'+CRLF+'Content-Length: %d'+CRLF,
          [firstB, lastB, totalB, lastB-firstB+1 ]))
  end; // replyheader_PARTIAL

begin
if buffer = '' then exit;
if state = HCS_IDLE then
  begin
  state:=HCS_REQUESTING;
  reply.contentType:='text/html; charset=utf-8';
  notify(HE_REQUESTING);
  end;
case state of
  HCS_REPLYING,
  HCS_REPLYING_HEADER,
  HCS_REPLYING_BODY: exit; // wait until the job is done
  HCS_POSTING: handlePostData();
  HCS_REQUESTING: handleHeaderData();
  end;
if state <> HCS_REPLYING then exit;
// handle reply
clearReply();
inc(P_requestCount);
notify(HE_REQUESTED);
if not initInputStream() then
  begin
  reply.mode:=HRM_INTERNAL_ERROR;
  reply.contentType:='text/html; charset=utf-8';
  notify(HE_CANT_OPEN_FILE);
  end;
notify(HE_STREAM_READY);
case reply.mode of
  HRM_CLOSE: disconnect();
  HRM_IGNORE: ;
  HRM_NOT_FOUND,
  HRM_BAD_REQUEST,
  HRM_METHOD_NOT_ALLOWED,
  HRM_INTERNAL_ERROR,
  HRM_OVERLOAD,
  HRM_NOT_MODIFIED,
  HRM_DENY: sendHeader( replyheader_mode(reply.mode) );
  HRM_UNAUTHORIZED:
    sendHeader(replyheader_mode(reply.mode)
      +replyHeader_Str('WWW-Authenticate','Basic realm="'+UTF8encode(reply.realm)+'"') );
  HRM_REDIRECT, HRM_MOVED:
    sendHeader(replyheader_mode(reply.mode)+'Location: '+UTF8encode(reply.url) );
  HRM_REPLY, HRM_REPLY_HEADER:
    if stream = NIL then
      sendHeader( replyHeader_code(404) )
    else if (request.firstByte >= bytesFullBody) or (request.lastByte >= bytesFullBody) then
      sendHeader( replyHeader_code(400) )
    else if reply.header > '' then
        sendHeader()
    else if partialBodySize = fullBodySize then
      sendHeader( replyHeader_OK(bytesFullBody) )
    else
      with reply do
        sendHeader( replyHeader_PARTIAL(firstByte, lastByte, bytesFullBody) );
  end;//case
end; // processInputBuffer

procedure ThttpConn.dataavailable(Sender: TObject; Error: Word);
var
  s: ansistring;
begin
if error <> 0 then exit;
s:=sock.ReceiveStrA();
inc(brecvd, length(s));
inc(srv.brecvd, length(s));
if (s = '') or dontFulFil then
  exit;
if state = HCS_POSTING then
  inc(postDataReceived, length(s));
if length(buffer)+length(s) > MAX_INPUT_BUFFER_LENGTH then
  begin
  disconnect();
  try sock.Abort() except end; // please, brutally
  exit;
  end;
buffer:=buffer+s;
eventData:=s;
notify(HE_GOT);
processInputBuffer();
end; // dataavailable

procedure ThttpConn.senddata(sender:Tobject; bytes:integer);
begin
if bytes <= 0 then exit;
inc(bsent, bytes);
inc(srv.bsent, bytes);
if state = HCS_REPLYING_BODY then
  begin
  inc(bsent_body, bytes);
  inc(bsent_bodies, bytes);
  end;
notify(HE_SENT);
end; // senddata

procedure ThttpConn.datasent(sender:Tobject; error:word);

  function toBeQueued():boolean;
  var
    i: integer;
  begin
  result:=TRUE;
  if paused then exit;
  for i:=0 to limiters.Count-1 do
    with limiters[i] as TspeedLimiter do
      if maxSpeed < MAXINT then
        exit;
  result:=FALSE;
  end; // toBeQueued

var
  notifyReplied: boolean;
begin
if not (state in [HCS_REPLYING_HEADER, HCS_REPLYING_BODY]) then exit;

if (state = HCS_REPLYING_HEADER) and (reply.mode <> HRM_REPLY_HEADER) then
  begin // the header is never sent splitted, so we know that at this stage we already sent it all
  state:=HCS_REPLYING_BODY;
  // set up a default body for errors with no body set
  if ((stream = NIL) or (stream.size = 0)) and (reply.mode <> HRM_REPLY) then
    begin
    reply.bodyMode:=RBM_STRING;
    reply.body:=UTF8encode(HRM2BODY[reply.mode]);
    if reply.mode in [HRM_REDIRECT, HRM_MOVED] then
      reply.body:=ansistrings.replaceStr(reply.body, '%url%', UTF8encode(reply.url));
    initInputStream();
    end;
  end;
if (state = HCS_REPLYING_BODY) and (bytesToSend > 0) then
  begin
  if toBeQueued() then srv.q.add(self)
  else sendNextChunk();
  exit;
  end;
notifyReplied:=FALSE;
if (state in [HCS_REPLYING_HEADER, HCS_REPLYING_BODY, HCS_DISCONNECTED])
and (bytesToSend = 0) then
  begin
  notifyReplied:=TRUE;
  state:=HCS_IDLE;
  end;

if not persistent or not (reply.mode in [HRM_REPLY, HRM_REPLY_HEADER]) then
  disconnect()
else
  { we must check the socket state, because a disconnection could happen while
  { this method is executing }
  if sock.State <> wsClosed then state:=HCS_IDLE;
if notifyReplied then
  begin
  notify(HE_REPLIED);
  if stream.position = stream.size then
    begin
    freeAndNil(stream); // free file handle
    notify(HE_LAST_BYTE_DONE);
    end;
  end;
// once the event has been notified, we reset the current counter
if state = HCS_IDLE then bsent_body:=0;

freeAndNil(stream);
end; // datasent

procedure ThttpConn.disconnect();
begin
if disconnecting then exit;
disconnecting:=TRUE;
if sock = NIL then exit;
try
  sock.Shutdown(SD_BOTH);
  sock.CloseDelayed();
except
  end;
end; // disconnect

function ThttpConn.fullBodySize():int64;
begin if stream = NIL then result:=0 else result:=stream.Size end;

function ThttpConn.partialBodySize():int64;
begin
if (reply.lastByte<0) and (reply.firstByte<0) then result:=bytesFullBody
else result:=reply.lastByte-reply.firstByte+1
end; // partialBodySize

function ThttpConn.initInputStream():boolean;
var
  i: integer;
begin
result:=FALSE;
FreeAndNil(stream);
try
  case reply.bodyMode of
    RBM_STRING:
      begin
      stream:=TmemoryStream.create();
      stream.write(reply.body[1], length(reply.body));
      stream.Seek(0, soFromBeginning);
      end;
    RBM_FILE:
      begin
      i:=fileopen(reply.bodyFile, fmOpenRead+fmShareDenyNone);
      if i = -1 then exit;
      stream:=TFileStream.Create(i);
      end;
    RBM_STREAM: stream:=reply.bodyStream;
    end;
  with reply do
    if resumeForbidden or (firstByte < 0) and (lastByte < 0) then
      begin
      firstByte:=0;
      lastbyte:=bytesFullBody-1;
      end
    else
      if lastByte < 0 then lastbyte:=bytesFullBody-1
      else
        if firstbyte < 0 then
          begin
          firstByte:=bytesFullBody-lastByte;
          lastByte:=bytesFullBody;
          end;

  if (reply.firstByte > 0) and (reply.mode = HRM_REPLY) then
    stream.Seek(request.firstByte, soBeginning);

  result:=TRUE;
except end;
end; // initInputStream

function ThttpConn.sendNextChunk(max:integer=MAXINT):integer;
var
  n: int64;
  buf: ansistring;
begin
result:=0;
if stream = NIL then exit;
n:=trunc(speedOut*1.5);
// the following line helps fast networks to reach max speed sooner.
// in a test, a 3MB file has been downloaded locally at doubled speed.
if (n = 0) or (bytesSentLastItem = 0) then n:=max;
if n > MAXIMUM_CHUNK_SIZE then n:=MAXIMUM_CHUNK_SIZE;
if n < MINIMUM_CHUNK_SIZE then n:=MINIMUM_CHUNK_SIZE;
if n > max then n:=max;
if n > bytesToSend then n:=bytesToSend;
if n = 0 then exit;
setLength(buf, n);
n:=stream.read(buf[1], n);
setLength(buf, n);
try result:=sock.SendStr(buf)
except end; // the socket may be accidentally closed
if result < n then stream.Seek(n-result, soCurrent);
end; // sendNextChunk

function ThttpConn.getBytesToSend():int64;
begin result:=bytesPartial-bsent_body end;

function ThttpConn.getBytesToPost():int64;
begin result:=post.length-bytesPosted end;

function ThttpConn.getbytesGot():int64;
begin result:=length(buffer) end;

procedure ThttpConn.notify(ev:ThttpEvent);
begin srv.notify(ev, self) end;

procedure ThttpConn.tryNotify(ev:ThttpEvent);
begin try srv.notify(ev, self) except end end;

procedure ThttpConn.sendheader(h:ansistring='');
begin
state:=HCS_REPLYING_HEADER;
if reply.header = '' then
  reply.header:=h;
includeTrailingString(reply.header, CRLF);
reply.header:=reply.header+reply.additionalHeaders;
includeTrailingString(reply.header, CRLF);
try sock.sendStr(reply.header+CRLF);
except end;
end; // sendHeader

function replycode2reason(code:integer):string;
begin
case code of
  200: result:='OK';
  206: result:='Partial Content';
  301: result:='Moved Permanently';
  302: result:='Found';
  400: result:='Bad Request';
  401: result:='Unauthorized';
  403: result:='Forbidden';
  404: result:='Not Found';
  405: result:='Method Not Allowed';
  413: result:='Payload Too Large';
  500: result:='Internal Server Error';
  503: result:='Service Unavailable';
  else result:='';
  end;
end; // replycode2reason

function ThttpConn.replyHeader_code(code:integer):ansistring;
begin
if reply.reason = '' then
  reply.reason:=replycode2reason(code);
result:=UTF8encode(format('HTTP/1.1 %d %s'+CRLF, [code,reply.reason]))
  + replyHeader_Str('Content-Type',reply.contentType)
end;

function ThttpConn.replyHeader_mode(mode:ThttpReplyMode):ansistring;
begin result:=replyHeader_code(HRM2CODE[mode]) end;

function getNameOf(s:ansistring):ansistring; // colon included
begin result:=copy(s, 1, pos(':', s)) end;

// return 0 if not found
function namePos(name:string; headers:string; from:integer=1):integer;
begin
result:=from;
  repeat
  result:=ipos(name, headers, result);
  until (result<=1) // both not found and found at the start of the string
    or (headers[result-1] = #10) // or start of the line
end; // namePos

// return true if the operation succeded
function ThttpConn.setHeaderIfNone(s:ansistring):boolean;
var
  name: ansistring;
begin
name:=getNameOf(s);
if name = '' then
  raise Exception.Create('Missing colon');
result:=namePos(name, reply.additionalHeaders) = 0; // empty text will also be considered as existing
if result then
  addHeader(s, FALSE); // with FALSE it's faster
end; // setHeaderIfNone

procedure ThttpConn.removeHeader(name:ansistring);
var
    i, eol: integer;
    s: ansistring;
begin
s:=reply.additionalHeaders;
includeTrailingString(name,':');
// see if it already exists
i:=1;
  repeat
  i:=namePos(name, s, i);
  if i = 0 then break;
  // yes it does
  eol:=posEx(#10, s, i);
  if eol = 0 then // this never happens, unless the string is corrupted. Just to be sounder.
    eol:=length(s);
  delete(s, i, eol-i+1); // remove it
  until false;
reply.additionalHeaders:=s;
end; // removeHeader

procedure ThttpConn.addHeader(s:ansistring; overwrite:boolean=TRUE);
begin
if overwrite then
  removeHeader(getNameOf(s));
reply.additionalHeaders:=reply.additionalHeaders+ s+CRLF;
end; // addHeader

function ThttpConn.getDontFree():boolean;
begin result:=lockCount > 0 end;

procedure ThttpConn.setSndbuf(v:integer);
begin
if P_sndBuf = v then exit;
P_sndBuf:=v;
WSocket_setsockopt(sock.HSocket, SOL_SOCKET , SO_SNDBUF, @v, SizeOf(v));
end;

constructor TspeedLimiter.create(max:integer=MAXINT);
begin maxSpeed:=max end;

procedure TspeedLimiter.setMaxSpeed(v:integer);
begin
P_maxSpeed:=v;
availableBandwidth:=min(availableBandwidth, v);
end;

INITIALIZATION
queryPerformanceFrequency(freq);

end.
