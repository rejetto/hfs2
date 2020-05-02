{
Copyright (C) 2002-2008  Massimo Melina (www.rejetto.com)

This file is part of Http File Server (HFS).

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
unit traylib;

interface

uses
  forms, ShellAPI, Messages, windows, graphics, sysutils, classes;

const
  WM_TRAY = WM_USER+1;
type
  TtrayEvent = (TE_CLICK, TE_2CLICK, TE_RCLICK);
  TtrayMessageType = (
    TM_NONE = NIIF_NONE,
    TM_INFO = NIIF_INFO,
    TM_WARNING = NIIF_WARNING,
    TM_ERROR = NIIF_ERROR
  );

  TNotifyIconDataEx = record
    cbSize: DWORD;
    wnd: HWND;
    uID: UINT;
    uFlags: UINT;
    uCallbackMessage: UINT;
    hIcon: HICON;
    szTip: array [0..127] of AnsiChar;
    dwState: DWORD;
    dwStateMask: DWORD;
    szInfo: array[0..255] of AnsiChar;
    uVersion: UINT;
    szInfoTitle: array[0..63] of AnsiChar;
    dwInfoFlags: DWORD;
    end;

  TmyTrayIcon=class
    private
      icondata: TNotifyIconDataEx;
      shown: boolean;
      procedure wndProc(var Message: TMessage);
      procedure notify(ev:TtrayEvent);
    public
      data: pointer;  // user data
      onEvent: procedure(sender:Tobject; ev:TtrayEvent) of object;
      constructor create(form:Tform);
      destructor Destroy; override;
      procedure minimize;
      procedure update;
      procedure hide;
      procedure show;
      procedure setIcon(icon:Ticon);
      procedure setTip(s:string);
      function  balloon(msg:string; secondsTimeout:real=3; kind:TtrayMessageType=TM_NONE; title:string=''):boolean;
      procedure setIconFile(fn:string);
      procedure updateHandle(handle:HWND);
    end; // TmyTrayIcon

implementation

var
  maxTipLength: integer;

constructor TmyTrayIcon.create(form:Tform);
begin
with icondata do
  begin
  uCallbackMessage := WM_TRAY;
  cbSize := sizeof(icondata);
  Wnd := classes.AllocateHWnd(wndproc);
  uID := 1;
  uFlags := NIF_MESSAGE + NIF_ICON + NIF_TIP;
  uVersion:=3;
  end;
setIcon(application.icon);
setTip(application.title);
end; // create

destructor TmyTrayIcon.destroy;
begin
classes.DeallocateHWnd(icondata.wnd);
hide;
end;

procedure TmyTrayIcon.updateHandle(handle:HWND);
begin
if not shown then
  begin
  icondata.wnd:=handle;
  exit;
  end;
hide;
icondata.wnd:=handle;
Shell_NotifyIcon(NIM_ADD, @icondata)
end;

procedure TmyTrayIcon.update();
begin
if shown then
  if not Shell_NotifyIcon(NIM_MODIFY, @icondata) then
    Shell_NotifyIcon(NIM_ADD, @icondata);
end; { update }

procedure TmyTrayIcon.setIcon(icon:Ticon);
begin
if icon=NIL then exit;
icondata.hIcon:=icon.handle;
update();
end; { setIcon }

procedure TmyTrayIcon.setIconFile(fn:string);
var
  ico:Ticon;
begin
ico:=Ticon.create;
try
  ico.loadFromFile(fn);
  setIcon(ico);
finally ico.free end;  // is this ok, or should we ensure the system resource is not deallocated?
end; // setIconFile

procedure TmyTrayIcon.setTip(s:string);
begin
s:=stringReplace(s,'&','&&',[rfReplaceAll]);
if length(s) > maxTipLength then setlength(s,maxTipLength);
if string(icondata.szTip) = s then exit;
strPLCopy(icondata.szTip, ansiString(s), sizeOf(icondata.szTip)-1);
update();
end; // setTip

procedure TmyTrayIcon.minimize();
begin
show();
Application.ShowMainForm := False;
// Toolwindows dont have a TaskIcon. (Remove if TaskIcon is to be show when form is visible)
SetWindowLong(Application.Handle, GWL_EXSTYLE, WS_EX_TOOLWINDOW);
end; // minimizeToTray

procedure TmyTrayIcon.show();
begin
if shown then exit;
shown:=true;
Shell_NotifyIcon(NIM_ADD, @icondata);
Shell_NotifyIcon(NIM_SETVERSION, @iconData);
end; // show

procedure TmyTrayIcon.hide();
begin
if not shown then exit;
shown:=FALSE;
Shell_NotifyIcon(NIM_DELETE, @icondata);
end; // hide

procedure TmyTrayIcon.wndproc(var Message: TMessage);
begin
case message.msg of
  WM_TRAY:
    case message.lParam of
      WM_RBUTTONUP: notify(TE_RCLICK);
      WM_LBUTTONUP: notify(TE_CLICK);
      WM_LBUTTONDBLCLK: notify(TE_2CLICK);
      end;
  WM_QUERYENDSESSION:
    message.result := 1;
  WM_ENDSESSION:
    if TWmEndSession(Message).endSession then
      hide();
  NIN_BALLOONHIDE,
  NIN_BALLOONTIMEOUT:
    icondata.uFlags := icondata.uFlags and not NIF_INFO;
  end;
message.result:=1;
end;

procedure TmyTrayIcon.notify(ev:TtrayEvent);
begin if assigned(onEvent) then onEvent(self, ev) end;

function TmyTrayIcon.balloon(msg:string; secondsTimeout:real; kind:TtrayMessageType; title:string):boolean;
begin
case kind of
  TM_WARNING: icondata.dwInfoFlags:=NIIF_WARNING;
  TM_ERROR: icondata.dwInfoFlags:=NIIF_ERROR;
  TM_INFO: icondata.dwInfoFlags:=NIIF_INFO;
  else icondata.dwInfoFlags:=NIIF_NONE;
end;
strPLCopy(icondata.szInfo, ansiString(msg), sizeOf(icondata.szInfo)-1);
strPLCopy(icondata.szInfoTitle, ansiString(title), sizeOf(icondata.szInfoTitle)-1);
icondata.uVersion:=round(secondsTimeout*1000);
icondata.uFlags := icondata.uFlags or NIF_INFO;
update();
icondata.uFlags := icondata.uFlags and not NIF_INFO;
result:=TRUE;
end; // balloon

INITIALIZATION
if byte(getVersion()) < 5 then maxTipLength:=63
else maxTipLength:=127;

end.
