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


}
unit progFrmLib;

interface

uses
  ComCtrls, Forms, controls, ExtCtrls, buttons, graphics;

type
  TprogressForm = class
  private
    prog: TProgressBar;
    frm: Tform;
    msgPnl: Tpanel;
    cancelBtn: TbitBtn;
    btnPnl: Tpanel;
    stack: array of record ofs,length:real end;
    partialLength: real;
    canceled: boolean;
    function getPos():real;
    procedure setPos(x:real);
    function getGlobalPos():real;
    procedure setGlobalPos(x:real);
    function getCaption():string;
    procedure setCaption(x:string);
    function getVisible():boolean;
    procedure onCancel(Sender: TObject);
    procedure onResize(Sender: TObject);
  public
    preventBackward: boolean;
    constructor create;
    procedure show(caption_:string=''; cancel:boolean=FALSE);
    procedure hide();
    property progress:real read getPos write setPos;
    property globalPosition:real read getGlobalPos write setGlobalPos;
    property caption:string read getCaption write setCaption;
    property visible:boolean read getVisible;
    property cancelRequested:boolean read canceled;
    procedure push(sublength:real);
    procedure pop();
    procedure showCancel();
    procedure hideCancel();
    procedure reset();
    end;

implementation

function max(a,b:integer):integer;
begin if a > b then result:=a else result:=b end;

constructor TprogressForm.create;
begin
frm:=Tform.create(NIL);
frm.Position:=poScreenCenter;
frm.Width:=200;
frm.BorderStyle:=bsNone;
frm.BorderWidth:=15;
frm.Height:=25+frm.BorderWidth*2;
frm.OnResize:=onResize;
//frm.FormStyle:=fsStayOnTop;

msgPnl:=Tpanel.create(frm);
msgPnl.Parent:=frm;
msgPnl.align:=alTop;
msgPnl.height:=20;
msgPnl.BevelOuter:=bvLowered;

prog:=TProgressBar.Create(frm);
prog.Parent:=frm;
prog.BorderWidth:=3;
prog.Min:=0;
prog.max:=100; // resolution
prog.Align:=alClient;
prog.smooth:=TRUE;

btnPnl:=Tpanel.create(frm);
btnPnl.parent:=frm;
btnPnl.Align:=alBottom;
btnPnl.BevelOuter:=bvLowered;

cancelBtn:=TbitBtn.create(frm);
cancelBtn.parent:=btnPnl;
cancelBtn.Kind:=bkCancel;
cancelBtn.top:=10;
cancelBtn.OnClick:=onCancel;

btnPnl.Height:=cancelBtn.Height+cancelBtn.top*2;
btnPnl.Hide();

partialLength:=1;
push(1); // init stack
frm.Height:=frm.Height+msgPnl.Height;
end; // constructor

function TprogressForm.getVisible():boolean;
begin result:=frm.Visible end;

procedure TprogressForm.showCancel();
begin
if btnPnl.visible then exit;
frm.Height:=frm.Height+btnPnl.Height;
btnPnl.show();
end; // showCancel

procedure TprogressForm.hideCancel();
begin
if not btnPnl.visible then exit;
frm.Height:=frm.Height-btnPnl.Height;
btnPnl.hide();
end; // hideCancel

procedure TprogressForm.show(caption_: string; cancel:boolean);
begin
canceled:=FALSE;
if not frm.visible then reset();
if caption_ > '' then caption:=caption_;
if cancel then showCancel();
frm.Show();
end; // show

procedure TprogressForm.hide();
begin
frm.hide();
hideCancel();
end;

function TprogressForm.getCaption():string;
begin result:=msgPnl.caption end;

procedure TprogressForm.setCaption(x:string);
begin
msgPnl.caption:=x;
frm.Width:=max(200,
  frm.Canvas.TextWidth(x)+(msgPnl.BorderWidth+frm.BorderWidth)*2+20 );
end;

procedure TprogressForm.setGlobalPos(x:real);
begin
x:=x*prog.max;
if preventBackward and (prog.position > x) then x:=prog.position;
prog.position:=round(x);
end; // setGlobalPos

function TprogressForm.getGlobalPos():real;
begin result:=prog.position/prog.max end;

procedure TprogressForm.setPos(x:real);
begin setGlobalPos(stack[length(stack)-1].ofs + x*partialLength ) end;

function TprogressForm.getPos():real;
begin result:=getGlobalPos()/partialLength + stack[length(stack)-1].ofs end;

procedure TprogressForm.push(sublength:real);
var
  i: integer;
begin
assert(sublength <= 1,'TprogressForm.push(X): X>1');
i:=length(stack);
setLength(stack, i+1);
stack[i].ofs:=globalPosition;
stack[i].length:=partialLength;
partialLength:=partialLength*sublength;
end; // push

procedure TprogressForm.pop();
var
  i: integer;
begin
assert(length(stack) > 1, 'TprogressForm.pop(): empty stack');
progress:=1;
i:=length(stack)-1;
partialLength:=stack[i].length;
setlength(stack, i);
end; // pop

procedure TprogressForm.onCancel(Sender: TObject);
begin canceled:=TRUE end;

procedure TprogressForm.onResize(Sender: TObject);
begin cancelBtn.left:=(frm.width-cancelBtn.width) div 2-frm.borderWidth end;

procedure TprogressForm.reset();
begin prog.position:=0 end;

end.
