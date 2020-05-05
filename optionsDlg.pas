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
unit optionsDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Math,
  Dialogs, ExtCtrls, StdCtrls, Grids, ComCtrls, ValEdit, types, main, CheckLst;

type
  ToptionsFrm = class(TForm)
    pageCtrl: TPageControl;
    bansPage: TTabSheet;
    accountsPage: TTabSheet;
    accountpropGrp: TGroupBox;
    accountenabledChk: TCheckBox;
    pwdBox: TLabeledEdit;
    Label1: TLabel;
    deleteaccountBtn: TButton;
    renaccountBtn: TButton;
    mimePage: TTabSheet;
    mimeBox: TValueListEditor;
    trayPage: TTabSheet;
    Label2: TLabel;
    traymsgBox: TMemo;
    Panel1: TPanel;
    Label3: TLabel;
    accountAccessBox: TTreeView;
    Panel2: TPanel;
    okBtn: TButton;
    applyBtn: TButton;
    cancelBtn: TButton;
    bansBox: TValueListEditor;
    addBtn: TButton;
    deleteBtn: TButton;
    Panel3: TPanel;
    noreplybanChk: TCheckBox;
    Button1: TButton;
    a2nPage: TTabSheet;
    Panel4: TPanel;
    Label4: TLabel;
    a2nBox: TValueListEditor;
    ignoreLimitsChk: TCheckBox;
    Panel5: TPanel;
    addMimeBtn: TButton;
    deleteMimeBtn: TButton;
    deleteA2Nbtn: TButton;
    addA2Nbtn: TButton;
    iconsPage: TTabSheet;
    iconMasksBox: TMemo;
    iconsBox: TComboBox;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    redirBox: TLabeledEdit;
    inBrowserIfMIMEchk: TCheckBox;
    traypreviewBox: TMemo;
    Label10: TLabel;
    accountLinkBox: TLabeledEdit;
    groupChk: TCheckBox;
    groupsBtn: TButton;
    addaccountBtn: TButton;
    upBtn: TButton;
    downBtn: TButton;
    sortBtn: TButton;
    notesBox: TMemo;
    Label8: TLabel;
    sortBanBtn: TButton;
    notesWrapChk: TCheckBox;
    accountsBox: TListView;
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure addaccountBtnClick(Sender: TObject);
    procedure deleteaccountBtnClick(Sender: TObject);
    procedure accountsBoxEdited(Sender: TObject; Item: TListItem; var S: String);
    procedure renaccountBtnClick(Sender: TObject);
    procedure accountAccessBoxDblClick(Sender: TObject);
    procedure accountAccessBoxContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure cancelBtnClick(Sender: TObject);
    procedure okBtnClick(Sender: TObject);
    procedure applyBtnClick(Sender: TObject);
    procedure addBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure deleteBtnClick(Sender: TObject);
    procedure addMimeBtnClick(Sender: TObject);
    procedure deleteMimeBtnClick(Sender: TObject);
    procedure addA2NbtnClick(Sender: TObject);
    procedure deleteA2NbtnClick(Sender: TObject);
    procedure iconsBoxDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure iconsBoxDropDown(Sender: TObject);
    procedure iconsBoxChange(Sender: TObject);
    procedure iconMasksBoxChange(Sender: TObject);
    procedure traymsgBoxChange(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure accountLinkBoxExit(Sender: TObject);
    procedure groupChkClick(Sender: TObject);
    procedure groupsBtnClick(Sender: TObject);
    procedure accountenabledChkClick(Sender: TObject);
    procedure upBtnClick(Sender: TObject);
    procedure sortBtnClick(Sender: TObject);
    procedure ListView1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure upBtnMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure sortBanBtnClick(Sender: TObject);
    procedure notesWrapChkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure accountsBoxData(Sender: TObject; Item: TListItem);
    procedure accountsBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure accountsBoxClick(Sender: TObject);
    procedure accountsBoxDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure accountsBoxDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure accountsBoxChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure updateAccessBox();
    procedure accountsBoxDblClick(Sender: TObject);
    procedure redirBoxChange(Sender: TObject);
    procedure accountsBoxKeyPress(Sender: TObject; var Key: Char);
    procedure accountsBoxEditing(Sender: TObject; Item: TListItem;
      var AllowEdit: Boolean);
    procedure pwdBoxMouseEnter(Sender: TObject);
    procedure pwdBoxChange(Sender: TObject);
  public
    procedure checkRedir();
		procedure loadAccountProperties();
		function saveAccountProperties():boolean;
		procedure deleteAccount(idx:integer=-1);
    procedure loadValues();
    function  saveValues():boolean; // it may fail on incorrect input
    function  checkValues():string; // returns an error message
    procedure updateIconMap();
    procedure updateIconsBox();
    procedure selectAccount(i:integer; saveBefore:boolean=TRUE);
  end;

var
  optionsFrm: ToptionsFrm;

implementation

{$R *.dfm}

uses
  utilLib, HSlib, strUtils, classesLib, listSelectDlg;

var
  lastAccountSelected: integer = -1; // stores the previous selection index
  tempAccounts: Taccounts; // the GUI part can't store the temp data
  tempIcons: array of integer;
  renamingAccount: boolean;

procedure ToptionsFrm.selectAccount(i:integer; saveBefore:boolean=TRUE);
begin
if saveBefore then saveAccountProperties();
accountsBox.itemIndex:=i;
accountsBox.ItemFocused:=accountsBox.Selected;
loadAccountProperties();
end; // selectAccount

procedure ToptionsFrm.loadValues();
var
  i:integer;
begin
// bans
noreplybanChk.checked:=noReplyBan;
bansBox.Strings.Clear();
for i:=0 to length(banList)-1 do
	bansBox.strings.Add(banList[i].ip+'='+banlist[i].comment);
// mime types
inBrowserIfMIMEchk.Checked:=inBrowserIfMIME;
mimeBox.Strings.Clear();
for i:=0 to length(mimeTypes) div 2-1 do
	mimeBox.strings.add(mimeTypes[i*2]+'='+mimeTypes[i*2+1]);
for i:=0 to length(DEFAULT_MIME_TYPES) div 2-1 do
  if not stringExists(DEFAULT_MIME_TYPES[i*2], mimeTypes) then
  	mimeBox.strings.add(DEFAULT_MIME_TYPES[i*2]+'='+DEFAULT_MIME_TYPES[i*2+1]);
// address2name
a2nBox.Strings.clear();
for i:=0 to length(address2name) div 2-1 do
	a2nBox.strings.Add(address2name[i*2]+'='+address2name[i*2+1]);
// tray message
traymsgBox.Text:=replaceStr(trayMsg,#13,CRLF);
// accounts
tempAccounts:=accounts;
setLength(tempAccounts, length(tempAccounts)); // unlink from the source
accountsBox.items.count:=length(accounts);
lastAccountSelected:=-1;
loadAccountProperties();
// remember original name for tracking possible later renaming
for i:=0 to length(accounts)-1 do
  with accounts[i] do
    wasUser:=user;
// icons
updateIconsBox();
i:=length(iconMasks);
setLength(tempIcons, i+1);
iconMasksBox.Text:='';
for i:=0 to i-1 do
  begin
  iconMasksBox.lines.Add(iconMasks[i].str);
  tempIcons[i]:=iconMasks[i].int;
  end;
iconMasksBox.SelStart:=0;
end; // loadValues

procedure ToptionsFrm.notesWrapChkClick(Sender: TObject);
begin
notesBox.WordWrap:=notesWrapChk.checked;
if notesBox.WordWrap then
  notesBox.ScrollBars:=ssVertical
else
  notesBox.ScrollBars:=ssBoth
end;

function ToptionsFrm.checkValues():string;
var
  i: integer;
  s: string;
begin
for i:=bansBox.Strings.count downto 1 do
  begin
  bansbox.cells[0,i]:=trim(bansbox.cells[0,i]);
  s:=bansbox.cells[0,i];
  if s = '' then continue;
  if bansBox.strings.indexOfName(s)+1 < i then
    begin
    result:=format('Bans: "%s" is duplicated', [s]);
    exit;
    end;
  if not checkAddressSyntax(s) then
    begin
    result:=format('Bans: syntax error for "%s"', [s]);
    exit;
    end;
  end;
for i:=a2nBox.Strings.count downto 1 do
  begin
  s:=trim(a2nBox.cells[1,i]);
  if trim(s+a2nBox.cells[0,i]) = '' then
    a2nBox.DeleteRow(i)
  else
    if (s>'') and not checkAddressSyntax(s) then
      begin
      result:=format('Address2name: syntax error for "%s"', [s]);
      exit;
      end;
  end;
result:='';
end; // checkValues

function ToptionsFrm.saveValues():boolean;
var
  i, n: integer;
  s: string;
begin
result:=FALSE;
s:=checkValues();
if s > '' then
  begin
  msgDlg(s, MB_ICONERROR);
  exit;
  end;
if not saveAccountProperties() then exit;
// bans
noReplyBan:=noreplybanChk.checked;
i:=bansbox.Strings.Count;
if bansbox.Cells[0,i] = '' then dec(i);
setlength(banlist, i);
n:=0;
for i:=0 to length(banlist)-1 do
  begin
  banlist[n].ip:=trim(bansBox.Cells[0,i+1]); // mod by mars
  if banlist[n].ip = '' then continue;
  banlist[n].comment:=bansBox.Cells[1,i+1];
  inc(n);
  end;
setlength(banlist, n);
kickBannedOnes();
// mime types
inBrowserIfMIME:=inBrowserIfMIMEchk.checked;
mimeTypes:=NIL;
for i:=1 to mimebox.rowCount-1 do
  addArray(mimeTypes, [mimeBox.cells[0,i], mimeBox.cells[1,i]]);

// address2name
address2name:=NIL;
for i:=1 to a2nBox.RowCount-1 do
  begin
  s:=trim(a2nBox.Cells[1,i]);
  if s > '' then addArray(address2name, [a2nBox.Cells[0,i], s]);
  end;
// tray message
trayMsg:=replaceStr(traymsgBox.Text, #10,'');
// accounts
accounts:=tempAccounts;
purgeVFSaccounts();
mainfrm.filesBox.repaint();
// icons
setlength(iconMasks, 0); // mod by mars
n:=0;
for i:=0 to iconMasksBox.Lines.Count-1 do
  begin
  s:=iconMasksBox.Lines[i];
  if trim(s) = '' then continue;
  inc(n);
  setlength(iconMasks, n);
  iconMasks[n-1].str:=s;
  iconMasks[n-1].int:=tempIcons[i];
  end;
result:=TRUE;
end; // saveValues

function ipListComp(list: TStringList; index1, index2: integer):integer;

  function extract(s:string; var o:integer):string;
  var
    i: integer;
  begin
  i:=posEx('.',s,o);
  if i = 0 then i:=length(s)+1;
  result:=substr(s,o,i-1);
  o:=i+1;
  end; // extract

  function compare(a,b:string):integer;
  begin
  try result:=compare_(strToInt(a), strToInt(b));
  except
    result:=compare_(length(a), length(b));
    if result = 0 then
      result:=ansiCompareStr(a,b);
    end;
  end; // compare

var
  o1, o2: integer;
  s1, s2: string;
begin
s1:=getTill('=', list[index1]);
s2:=getTill('=', list[index2]);
o1:=1;
o2:=1;
  repeat
  result:=compare(extract(s1,o1), extract(s2,o2));
  until (result <> 0) or (o1 > length(s1)) and (o2 > length(s2));
end; // ipListComp

procedure ToptionsFrm.sortBanBtnClick(Sender: TObject);
begin
(bansbox.strings as TstringList).customSort(ipListComp);
end;

procedure ToptionsFrm.sortBtnClick(Sender: TObject);

  function sortIt(reverse:boolean=FALSE):boolean;
  var
    s, i, j, l: integer;
  begin
  result:=FALSE;
  s:=accountsBox.ItemIndex;
  l:=length(tempAccounts);
  for i:=0 to l-2 do
    for j:=i+1 to l-1 do
      if reverse XOR (compareText(tempAccounts[i].user, tempAccounts[j].user) > 0) then
        begin
        swapMem(tempAccounts[i], tempAccounts[j], sizeof(tempAccounts[0]));
        if i = s then
          s:=j
        else if j = s then
          s:=i;
        result:=TRUE;
        end;
  accountsBox.ItemIndex:=s;
  end; // sortIt

begin
lastAccountSelected:=-1;
if not sortIt(FALSE) then sortIt(TRUE);
accountsBox.invalidate();
end;

procedure ToptionsFrm.traymsgBoxChange(Sender: TObject);
begin traypreviewBox.text:=mainfrm.getTrayTipMsg(traymsgBox.text) end;

procedure ToptionsFrm.FormShow(Sender: TObject);
var
  i: integer;
  s: string;
begin
// if we do this, any hint window will bring focus to the main form
//setwindowlong(handle, GWL_HWNDPARENT, 0); // get a taskbar button
loadValues();
if pageCtrl.activePage <> a2nPage then exit;
s:=mainfrm.ipPointedInLog();
if s = '' then exit;
// select row or insert new one
i:=length(address2name)-1;
while (i > 0) and not addressmatch(address2name[i], s) do
  dec(i, 2);
if i <= 0 then a2nBox.row:=a2nBox.insertRow('',s,TRUE)
else
  try a2nBox.Row:=i
  except end; // this should not happen, but in case (it was reported once) just skip selecting

a2nBox.SetFocus();
a2nBox.EditorMode:=TRUE;
end;

procedure ToptionsFrm.groupChkClick(Sender: TObject);
begin
pwdBox.visible:=not groupChk.checked;
accountsBox.invalidate();
end;

procedure ToptionsFrm.FormActivate(Sender: TObject);
begin traymsgBoxChange(NIL) end;

procedure ToptionsFrm.FormCreate(Sender: TObject);
begin
notesWrapChk.Checked:=TRUE;
end;

procedure ToptionsFrm.FormResize(Sender: TObject);
begin bansBox.ColWidths[1]:=bansBox.ClientWidth-bansBox.colWidths[0]-2 end;

procedure setEnabledRecur(c:Tcontrol; v:boolean);
var
  i: integer;
begin
c.enabled:=v;
if c is TTreeView then
  (c as TTreeView).items.clear();
if c is TLabeledEdit then
  (c as TLabeledEdit).text:='';
if c is Tmemo then
  (c as Tmemo).text:='';
if c is Tcheckbox then
  (c as Tcheckbox).checked:=FALSE;

if c is Twincontrol then
  with c as Twincontrol do
    for i:=0 to controlCount-1 do
    	setEnabledRecur(controls[i], v);
end; // setEnabledRecur

procedure ToptionsFrm.updateAccessBox();
var
  n: Ttreenode;
  f: Tfile;
  props: TstringDynArray;
  act: TfileAction;
  s: string;
  a, other: Paccount;
begin
accountAccessBox.items.clear();
if lastAccountSelected < 0 then exit;
a:=@tempAccounts[lastAccountSelected];
n:=rootNode;
while n <> NIL do
  begin
  f:=Tfile(n.data);
  n:=n.getNext();
  if f =  NIL then continue;

  props:=NIL;
  for act:=low(TfileAction) to high(TfileAction) do
    begin
    s:=FILEACTION2STR[act];
    // any_account will suffice, otherwise our username (or a linked one) must be there explicitly, otherwise the resource is not protected or we have no access and thus must not be listed
    if not stringExists(USER_ANY_ACCOUNT, f.accounts[act]) then
      begin
      other:=findEnabledLinkedAccount(a, f.accounts[act]);
      if other = NIL then continue;
      if other <> a then
        s:=s+' via '+other.user;
      end;
    addString(s, props);
    end;
  if props = NIL then continue;

  with accountAccessBox.items.addObject(NIL, f.name+' ['+join(', ',props)+']', f.node) do
    begin
    imageIndex:=f.node.imageIndex;
    selectedIndex:=imageIndex;
    end;
  end;
end; // updateAccessBox

procedure ToptionsFrm.checkRedir();
begin // mod by mars
redirBox.color:=blend(clWindow, clRed,
  ifThen((redirBox.text >'') and not fileExistsByURL(redirBox.text), 0.5, 0) );
end; // checkRedir

procedure ToptionsFrm.loadAccountProperties();
var
  a: Paccount;
  b, bakWrap: boolean;
  i: integer;
begin
lastAccountSelected:=accountsBox.ItemIndex;
b:=lastAccountSelected >= 0;
bakWrap:=notesWrapChk.checked;
setEnabledRecur(accountpropGrp, b);
notesWrapChk.checked:=bakWrap;
renAccountBtn.enabled:=b;
deleteAccountBtn.enabled:=b;
upBtn.Enabled:=b;
downBtn.enabled:=b;

if not accountpropGrp.Enabled then exit;
a:=@tempAccounts[lastAccountSelected];
accountEnabledChk.checked:=a.enabled;
pwdBox.Text:=a.pwd;
groupChk.Checked:=a.group;
accountLinkBox.text:=join(';',a.link);
ignoreLimitsChk.Checked:=a.noLimits;
redirBox.Text:=a.redir;
notesBox.text:=a.notes;

groupsBtn.enabled:=FALSE;;
for i:=0 to length(tempAccounts)-1 do
  if tempAccounts[i].group and (i <> accountsBox.itemIndex) then
    groupsBtn.enabled:=TRUE;

updateAccessBox();
accountsBox.invalidate();
end; // loadAccountProperties

function ToptionsFrm.saveAccountProperties():boolean;
const
  MSG_CHARS = 'The characters below are not allowed'
    +#13'/\:?*"<>|;&&@';
  MSG_PWD = 'Invalid password.'#13+MSG_CHARS;
var
  a: Paccount;
begin
result:=TRUE;
if lastAccountSelected < 0 then exit;
result:=FALSE;
if not validUsername(pwdbox.Text, TRUE) then
  begin
	msgDlg(MSG_PWD, MB_ICONERROR);
  exit;
  end;

a:=@tempAccounts[lastAccountSelected];
a.enabled:=accountEnabledChk.checked;
a.pwd:=pwdBox.Text;
a.noLimits:=ignoreLimitsChk.checked;
a.redir:=redirBox.Text;
a.notes:=notesBox.text;
a.link:=split(';', trim(accountLinkBox.text));
a.group:=groupChk.Checked;
uniqueStrings(a.link);
result:=TRUE;
accountsBox.invalidate();
end; // saveAccountProperties

function findUser(user:string):integer;
begin
result:=length(tempAccounts)-1;
while (result >= 0) and not sameText(tempAccounts[result].user, user) do
  dec(result);
end; // findUser

function userExists(user:string):boolean; overload;
begin result:=findUser(user) >= 0 end;

function userExists(user:string; excpt:integer):boolean; overload;
var
  i: integer;
begin
i:=findUser(user);
result:=(i >= 0) and (i <> excpt);
end;

procedure ToptionsFrm.addaccountBtnClick(Sender: TObject);
var
  i: integer;
  a: Taccount;
begin
a.user:=getUniqueName('new user', userExists);
a.pwd:='';
a.enabled:=TRUE;
a.noLimits:=FALSE;
a.redir:='';

i:=length(tempAccounts);
setLength(tempAccounts, i+1);
tempAccounts[i]:=a;
accountsBox.items.add();
selectAccount(i);

renaccountBtnClick(sender);
end;

procedure ToptionsFrm.deleteAccount(idx:integer=-1);
var
  i: integer;
begin
if idx < 0 then
	begin
  idx:=accountsBox.itemIndex;
  if idx < 0 then exit;
 	if msgDlg('Delete?', MB_ICONQUESTION+MB_YESNO) = IDNO then
  	exit;
  end;
// shift
for i:=idx+1 to length(tempAccounts)-1 do
  tempAccounts[i-1]:=tempAccounts[i];
// shorten
with accountsBox.items do count:=count-1; // dunno why, but invoking delete* methods doesn't work
setlength(tempAccounts, length(tempAccounts)-1);
selectAccount(min(idx, length(tempAccounts)-1), FALSE);
end; // deleteAccount

procedure ToptionsFrm.deleteaccountBtnClick(Sender: TObject);
begin deleteAccount() end;

procedure swapItems(i, j:integer);
var
  s: integer;
begin
s:=length(tempAccounts)-1;
if not inRange(i, 0,s) or not inRange(j, 0,s) then exit;
s:=optionsFrm.accountsBox.itemIndex;
lastAccountSelected:=-1; // avoid data saving from fields while moving
swapMem(tempAccounts[i], tempAccounts[j], sizeof(tempAccounts[i]));
if i = s then
  s:=j
else if j = s then
  s:=i;
with optionsFrm.accountsBox do
  begin
  itemIndex:=s;
  selected.focused:=TRUE;
  invalidate();
  end;
end; // swapItems

procedure ToptionsFrm.accountsBoxChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
if (change = ctState) and assigned(item) and item.selected then
  selectAccount(item.index);
end;

procedure ToptionsFrm.accountsBoxClick(Sender: TObject);
begin
selectAccount(accountsBox.itemIndex);
end;

procedure ToptionsFrm.accountsBoxData(Sender: TObject; Item: TListItem);
var
  a: Paccount;
begin
if (item = NIL) or not inRange(item.index, 0,length(tempAccounts)-1) then
  exit;
a:=@tempAccounts[item.index];
item.caption:=a.user;
item.imageIndex:=if_(item.index = lastAccountSelected,
  accountIcon(accountenabledChk.checked, groupChk.checked),
  accountIcon(a)
);
end;

procedure ToptionsFrm.accountsBoxDblClick(Sender: TObject);
begin renaccountBtnClick(renaccountBtn) end;

procedure ToptionsFrm.accountsBoxDragDrop(Sender, Source: TObject; X,
  Y: Integer);
begin
swapItems(accountsBox.getItemAt(x,y).index, accountsBox.itemIndex);
end;

procedure ToptionsFrm.accountsBoxDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
accept:=(sender = source) and assigned(accountsBox.getItemAt(x,y));
end;

procedure ToptionsFrm.accountsBoxEdited(Sender: TObject; Item: TListItem; var S: String);
var
  old, err: string;
  i, idx: integer;
begin
renamingAccount:=FALSE;
try idx:=item.index  // workaround to wine's bug http://www.rejetto.com/forum/index.php/topic,9563.msg1053890.html#msg1053890
except idx:=lastAccountSelected end;
old:=tempAccounts[idx].user;
if not validUsername(s) then
  err:='Invalid username'
else if userExists(s, accountsBox.itemIndex) then
  err:='Username already used'
else
  err:='';

if err > '' then
  begin
  msgDlg(err, MB_ICONERROR);
  s:=old;
  exit;
  end;
// update linkings
for i:=0 to length(tempAccounts)-1 do
  replaceString(tempAccounts[i].link, old, s);
tempAccounts[idx].user:=s;
end;

procedure ToptionsFrm.accountsBoxEditing(Sender: TObject; Item: TListItem;
  var AllowEdit: Boolean);
begin
renamingAccount:=TRUE;
end;

procedure ToptionsFrm.accountsBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if shift = [] then
	case key of
  	VK_F2: renaccountBtn.click();
    VK_INSERT: addaccountBtn.click(); // mod by mars
    VK_DELETE: deleteAccount();
    end;
{mod by mars}
if shift = [ssAlt] then
  case key of
    VK_UP: upBtn.click();
    VK_DOWN: downBtn.click();
    end;
{/mod}
end;

procedure ToptionsFrm.accountsBoxKeyPress(Sender: TObject; var Key: Char);
var
  s, i, ir, n: integer;
begin
if renamingAccount then
  exit;
key:=upcase(key);
if key in ['0'..'9','A'..'Z'] then
  begin
  s:=accountsBox.ItemIndex;
  n:=length(tempAccounts);
  for i:=1 to n-1 do
    begin
    ir:=(s+i) mod n;
    if key = upcase(tempAccounts[ir].user[1]) then
      begin
      selectAccount(ir);
      exit;
      end;
    end;
  end;
end;

procedure ToptionsFrm.redirBoxChange(Sender: TObject);
begin checkRedir() end;

procedure ToptionsFrm.renaccountBtnClick(Sender: TObject);
begin
if accountsBox.selected = NIL then exit;
accountsBox.Selected.editCaption();
end;

procedure ToptionsFrm.accountLinkBoxExit(Sender: TObject);
const
  MSG_MISSING_USERS = 'Cannot find these linked usernames: %s'
    +#13'This is abnormal, but you may add them later.';
var
  users, missing: TStringDynArray;
  i: integer;
begin
users:=split(';', trim(accountLinkBox.text));
// check for non-existent linked account
missing:=NIL;
for i:=0 to length(users)-1 do
  if not userExists(users[i]) then
    addString(users[i], missing);
if assigned(missing) then
  msgDlg(format(MSG_MISSING_USERS, [join(', ', missing)]), MB_ICONWARNING);
// permissions may have been changed
updateAccessBox();
end;

procedure ToptionsFrm.accountAccessBoxDblClick(Sender: TObject);
begin
with sender as Ttreeview do
  begin
  if selected = NIL then exit;
  mainfrm.filesBox.selected:=selected.Data;
  mainfrm.setFocus();
  end;
end;

procedure ToptionsFrm.accountenabledChkClick(Sender: TObject);
begin accountsBox.invalidate() end;

procedure ToptionsFrm.accountAccessBoxContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
with sender as Ttreeview do
  if selected = NIL then handled:=TRUE
  else mainfrm.filesBox.selected:=selected.data;
end;

procedure ToptionsFrm.cancelBtnClick(Sender: TObject);
begin close() end;

procedure ToptionsFrm.applyBtnClick(Sender: TObject);
begin saveValues() end;

procedure ToptionsFrm.okBtnClick(Sender: TObject);
begin if saveValues() then close() end;

procedure ToptionsFrm.Button1Click(Sender: TObject);
begin msgDlg(getRes('invertBan')) end;

procedure ToptionsFrm.groupsBtnClick(Sender: TObject);
var
  i: integer;
  there: TStringDynArray;
  groups: TstringList;
  s: string;
begin
there:=split(';', accountLinkBox.Text);
groups:=TstringList.create;
try
  for i:=0 to length(tempAccounts)-1 do
    if tempAccounts[i].group and (i <> accountsBox.itemIndex) then
      begin
      s:=tempAccounts[i].user;
      groups.AddObject(s, if_(stringExists(s, there), PTR1, NIL));
      end;
  if not listSelect('Select groups', groups) then exit;
  s:='';
  for i:=0 to groups.Count-1 do
    if groups.Objects[i] <> NIL then
      s:=s+groups[i]+';';
  accountLinkBox.Text:=getTill(-1, s);
finally groups.free end;
end;

procedure ToptionsFrm.pwdBoxChange(Sender: TObject);
begin pwdBox.hint:=pwdBox.text end;

procedure ToptionsFrm.pwdBoxMouseEnter(Sender: TObject);
begin pwdBox.hint:=pwdBox.text end;

procedure ToptionsFrm.addBtnClick(Sender: TObject);
begin bansBox.InsertRow('','',TRUE) end;

procedure ToptionsFrm.deleteBtnClick(Sender: TObject);
begin
if bansbox.strings.count > 0 then
  bansBox.Strings.Delete(bansBox.Row-1)
end;

procedure ToptionsFrm.addMimeBtnClick(Sender: TObject);
begin mimeBox.InsertRow('','',TRUE) end;

procedure ToptionsFrm.deleteMimeBtnClick(Sender: TObject);
begin
if mimeBox.strings.count > 0 then
  mimeBox.Strings.Delete(mimeBox.Row-1)
end;

procedure ToptionsFrm.addA2NbtnClick(Sender: TObject);
begin
a2nBox.insertRow('','',TRUE);
a2nBox.setFocus();
end;

procedure ToptionsFrm.deleteA2NbtnClick(Sender: TObject);
begin
if a2nBox.strings.count > 0 then
  a2nBox.Strings.Delete(a2nBox.Row-1)
end;

procedure ToptionsFrm.iconsBoxDrawItem(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  cnv: TCanvas;
  bmp: Tbitmap;
begin
cnv:=iconsBox.Canvas;
bmp:=Tbitmap.create;
try
  mainfrm.images.GetBitmap(index, bmp);
  cnv.FillRect(rect);
  cnv.Draw(rect.Left, rect.Top, bmp);
  cnv.TextOut(rect.Left+mainfrm.images.Width+2, rect.Top, idx_label(index));
finally bmp.free end;
end;

procedure ToptionsFrm.updateIconsBox();
// alloc enough slots. the text is not used, labels are built by the paint event
begin iconsBox.Items.Text:=dupeString(CRLF, mainfrm.images.count) end;

procedure ToptionsFrm.iconsBoxDropDown(Sender: TObject);
begin updateIconsBox() end;

procedure ToptionsFrm.ListView1DragOver(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
accept:=source = sender;
end;

procedure ToptionsFrm.upBtnClick(Sender: TObject);
var
  i, dir: integer;
begin
dir:=if_(sender = upBtn, -1, +1);
i:=accountsBox.itemIndex;
if not inRange(i+dir, 0,length(tempAccounts)-1) then exit;
swapItems(i, i+dir);
end;

procedure ToptionsFrm.upBtnMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
accountsBox.setFocus()
end;

procedure ToptionsFrm.updateIconMap();
begin
if not iconsBox.DroppedDown then
  iconsBox.ItemIndex:=tempIcons[iconMasksBox.CaretPos.Y];
end;

procedure ToptionsFrm.iconsBoxChange(Sender: TObject);
begin tempIcons[iconMasksBox.CaretPos.Y]:=iconsBox.ItemIndex end;

procedure ToptionsFrm.iconMasksBoxChange(Sender: TObject);
begin setLength(tempIcons, iconMasksBox.Lines.count+1) end;

end.
