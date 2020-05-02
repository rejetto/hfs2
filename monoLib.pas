{
Copyright (C) 2002-2008 Massimo Melina (www.rejetto.com)

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


This lib ensures only one instance of the software does run
}
unit monoLib;

interface

uses
  windows, messages, forms, classes, sysUtils;

type
  Tmono = class
  private
    msgID: Thandle;
    Fmaster: boolean;
    Ferror: string;
    Fworking: boolean;
    function hook(var msg:TMessage):boolean;
  public
    onSlaveParams: procedure(params:string);
    property error:string read Ferror;
    property master:boolean read Fmaster;
    property working:boolean read Fworking;

    function init(id:string):boolean; // FALSE on error
    procedure sendParams();
    end;

var
  mono: Tmono;
  initialPath: string;
  
implementation

const
  //MSG_WHEREAREYOU = 1;
  //MSG_HEREIAM = 2;
  MSG_PARAMS = 3;

function atomToStr(atom:Tatom):string;
begin
setlength(result, 5000);
setlength(result, globalGetAtomName(atom, @result[1], length(result)));
end; // atomToStr

function Tmono.hook(var msg:TMessage):boolean;
begin
result:=master and (msg.msg = msgID) and (msg.wparam = MSG_PARAMS);
if not result or not assigned(onSlaveParams) then exit;
msg.Result:=1;
onSlaveParams(atomToStr(msg.lparam));
GlobalDeleteAtom(msg.LParam);
end; // hook

function Tmono.init(id:string):boolean;
begin
result:=FALSE;
msgID:=registerWindowMessage(pchar(id));
application.HookMainWindow(hook);
// the mutex is auto-released when the application terminates
if createMutex(nil, True, pchar(id)) = 0 then
  begin
  setlength(Ferror,1000);
  setlength(Ferror, FormatMessage(
    FORMAT_MESSAGE_FROM_SYSTEM+FORMAT_MESSAGE_IGNORE_INSERTS, NIL,
    GetLastError(), 0, @Ferror[1], length(Ferror), NIL) );
  exit;
  end;
Fmaster:= GetLastError() <> ERROR_ALREADY_EXISTS;
Fworking:=TRUE;
result:=TRUE;
end; // init

procedure Tmono.sendParams();
var
  s: string;
  i: integer;
begin
s:=initialPath+#13+paramStr(0);
for i:=1 to paramCount() do
  s:=s+#13+paramStr(i);
// the master will delete the atom
postMessage(HWND_BROADCAST, msgId, MSG_PARAMS, globalAddAtom(pchar(s)));
end; // sendParams

initialization
initialPath:=getCurrentDir();
mono:=Tmono.create;

finalization
mono.free;

end.
