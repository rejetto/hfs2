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
unit newuserpassDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, utilLib;

type
  TnewuserpassFrm = class(TForm)
    userBox: TLabeledEdit;
    pwdBox: TLabeledEdit;
    pwd2Box: TLabeledEdit;
    okBtn: TButton;
    resetBtn: TButton;
    procedure okBtnClick(Sender: TObject);
    procedure resetBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    function prompt(var usr,pwd:string):boolean;
  end;

var
  newuserpassFrm: TnewuserpassFrm;

implementation

{$R *.dfm}

procedure TnewuserpassFrm.okBtnClick(Sender: TObject);
var
  error: string;
begin
userBox.text:=trim(userBox.text);
pwdBox.text:=trim(pwdBox.text);
error:='';
if (userBox.text > '') and not validUsername(userBox.Text)
or (pwdBox.text > '') and not validUsername(pwdBox.text) then
  error:='The characters below are not allowed'#13'/\:?*"<>|;&&@'
else if (pwdBox.text > '') and (userBox.text = '') then
  error:='User is mandatory'
else if pwdBox.text <> pwd2Box.text then
  error:='The two passwords you entered don''t match';

if error = '' then ModalResult:=mrOk
else msgDlg(error, MB_ICONERROR);
end;

procedure TnewuserpassFrm.resetBtnClick(Sender: TObject);
begin
userBox.text:='';
pwdBox.text:='';
pwd2Box.text:='';
end;

procedure TnewuserpassFrm.FormShow(Sender: TObject);
begin userBox.SetFocus() end;

function TnewuserpassFrm.prompt(var usr,pwd:string):boolean;
begin
userBox.Text:=usr;
pwdBox.text:=pwd;
pwd2Box.text:=pwd;
result:= ShowModal() = mrOk;
usr:=userBox.Text;
pwd:=pwdBox.text;
end;

end.
