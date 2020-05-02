unit filepropDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, CheckLst, utilLib, main, types, Grids,
  ValEdit, strutils, hslib, math;

type
  TfilepropFrm = class(TForm)
    pages: TPageControl;
    permTab: TTabSheet;
    flagsTab: TTabSheet;
    diffTab: TTabSheet;
    commentTab: TTabSheet;
    maskTab: TTabSheet;
    hiddenChk: TCheckBox;
    hidetreeChk: TCheckBox;
    archivableChk: TCheckBox;
    browsableChk: TCheckBox;
    dontlogChk: TCheckBox;
    nodlChk: TCheckBox;
    dontconsiderChk: TCheckBox;
    hideemptyChk: TCheckBox;
    hideextChk: TCheckBox;
    Panel1: TPanel;
    okBtn: TButton;
    cancelBtn: TButton;
    difftplBox: TMemo;
    commentBox: TMemo;
    actionTabs: TTabControl;
    newaccBtn: TButton;
    anyAccChk: TCheckBox;
    anonChk: TCheckBox;
    allBtn: TButton;
    accountsBox: TListView;
    filesfilterBox: TLabeledEdit;
    foldersfilterBox: TLabeledEdit;
    deffileBox: TLabeledEdit;
    uploadfilterBox: TLabeledEdit;
    dontconsiderBox: TLabeledEdit;
    otherTab: TTabSheet;
    realmBox: TLabeledEdit;
    anyoneChk: TCheckBox;
    iconBox: TComboBoxEx;
    Label1: TLabel;
    addiconBtn: TButton;
    goToAccountsBtn: TButton;
    applyBtn: TButton;
    procedure accountsBoxGetImageIndex(Sender: TObject; Item: TListItem);
    procedure actionTabsChange(Sender: TObject);
    procedure newaccBtnClick(Sender: TObject);
    procedure allBtnClick(Sender: TObject);
    procedure accountsBoxChange(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure anonChkClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure textinputEnter(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure addiconBtnClick(Sender: TObject);
    procedure goToAccountsBtnClick(Sender: TObject);
    procedure applyBtnClick(Sender: TObject);
  private
    iconOfs: integer;
  public
    firstActionChange: boolean;
    users: array [TfileAction] of TStringDynArray;
    savePerm: array [TfileAction] of boolean; // should we apply/save permissions for this TfileAction ?
    currAction, prevAction: TfileAction;
    procedure updateAccountsBox;
  end;

var
  filepropFrm: TfilepropFrm;

implementation

uses optionsDlg;

{$R *.dfm}

procedure TfilepropFrm.accountsBoxChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
if (change = ctState)
and (item.caption > '')
and (stringExists(item.caption, users[currAction]) <> item.checked) then
  begin
  savePerm[currAction]:=TRUE;
  toggleString(item.caption, users[currAction])
  end;
end;

procedure TfilepropFrm.accountsBoxGetImageIndex(Sender: TObject; Item: TListItem);
begin item.ImageIndex:=accountIcon(item.data) end;

function str2fileaction(s:string):TfileAction;
begin
for result:=low(result) to high(result) do
  if FILEACTION2STR[result] = s then
    exit;
result:=TfileAction(-1);
end; // str2fileaction

procedure TfilepropFrm.actionTabsChange(Sender: TObject);
var
  l: TstringList;
  i: integer;
  ar: TstringDynArray;
begin
currAction:=str2fileaction(actionTabs.tabs[actionTabs.tabIndex]);
if not firstActionChange then
  begin
  // we must save current selection before updating the checkmarks
  ar:=users[prevAction];
  // now 'ar' is actually an alias, no duplication
  setLength(ar, 0);
  if anonChk.checked then addString(USER_ANONYMOUS, ar);
  if anyAccChk.checked then addString(USER_ANY_ACCOUNT, ar);
  if anyoneChk.checked then addString(USER_ANYONE, ar);
  for i:=0 to accountsBox.Items.Count-1 do
    with accountsBox.Items[i] do
      if checked then
        addString(caption, ar);

  prevAction:=currAction;
  end;
firstActionChange:=FALSE;

l:=arrayToList(users[currAction]);
try
  for i:=0 to accountsBox.Items.Count-1 do
    with accountsBox.Items[i] do
      checked:=l.IndexOf(caption) >= 0;
  anonChk.checked:=l.IndexOf(USER_ANONYMOUS) >= 0;
  anyAccChk.checked:=l.indexOf(USER_ANY_ACCOUNT) >= 0;
  anyoneChk.checked:=l.indexOf(USER_ANYONE) >= 0;
finally l.free end;

end;

procedure TfilepropFrm.addiconBtnClick(Sender: TObject);
var
  fn: string;
  i: integer;
begin
if not promptForFileName(fn) then exit;
i:=getImageIndexForFile(fn);
if i < 0 then exit;
iconBox.itemsEx.addItem(idx_label(i), i, i, -1, 0, NIL);
iconBox.itemIndex:=iconOfs+i;
end;

procedure TfilepropFrm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
if (action = caHide) and (modalResult = mrOk) then
  applyBtnClick(applyBtn);
end;

procedure TfilepropFrm.FormKeyPress(Sender: TObject; var Key: Char);
begin
if pages.focused then
  if key in ['1'..'9'] then
    try pages.TabIndex:=ord(key)-ord('0')-1
    except end;
end;

procedure TfilepropFrm.FormShow(Sender: TObject);
var
  i: integer;
  f: Tfile;

  procedure setFlag(flag:TfileAttribute; cb:TCheckBox);
  var
    should: TCheckBoxState;
  begin
  cb.enabled:=TRUE;
  if flag in f.flags then
    should:=cbChecked
  else
    should:=cbUnchecked;
  if i = 0 then
    cb.state:=should
  else
    if (cb.state <> cbGrayed) and (cb.state <> should) then
      cb.state:=cbGrayed;
  end; // setFlag

  procedure setText(var v:string; box:TCustomEdit);
  const
    COLOR = clInfoBk;
  var
    n: integer;
  begin
  n:=countSubstr(#0, box.hint);
  box.enabled:=TRUE;
  if n = 0 then
    begin // init this edit box
    box.text:=v;
    box.hint:=box.hint+#0;
    exit;
    end;
  if (pos(#0+v+#0, box.hint) > 0)
  or (box.hint = #0) and (v = box.text) then
    exit; // the value is already there
  if n > 1 then
    begin // add the value to the list of values
    box.hint:=box.hint+v+#0;
    exit;
    end;
  box.hint:=box.hint+box.text+#0+v+#0; // init the list of values
  box.text:='(more values)'; // message to be shown
  // these properties are unhappily kept unaccessible through TcustomEdit interface
  try (box as Tlabelededit).color:=COLOR except end;
  try (box as Tmemo).color:=COLOR except end;
  end; // setText

  procedure setCaption();
  const
    MAX = 2;
  var
    a: TStringDynArray;
    i: integer;
  begin
  a:=NIL;
  for i:=0 to min(mainFrm.filesBox.SelectionCount, MAX)-1 do
    addString(mainFrm.filesBox.Selections[i].Text, a);
  if mainFrm.filesBox.SelectionCount > MAX then
    addString('...', a);
  caption:='Properties for '+join(', ', a);
  end; // setCaption

var
  act: TfileAction;
  actions: set of TfileAction;
begin
firstActionChange:=TRUE;

accountsBox.smallImages:=mainfrm.images;
updateAccountsBox();

maskTab.tabVisible:=FALSE;
diffTab.tabVisible:=FALSE;

iconBox.clear();
iconBox.Enabled:=FALSE;
addiconBtn.Enabled:=FALSE;
i:=if_(mainfrm.filesBox.SelectionCount > 1, -1, selectedFile.getIconForTreeview());
iconBox.itemsEx.addItem('Default', i, i, -1, 0, NIL);
iconOfs:=iconBox.ItemsEx.count;
for i:=0 to mainfrm.images.Count-1 do
  iconBox.itemsEx.addItem(idx_label(i), i, i, -1, 0, NIL);

actions:=[FA_ACCESS];
for i:=0 to mainFrm.filesBox.SelectionCount-1 do
  begin
  f:=mainFrm.filesBox.Selections[i].data;

  setText(f.comment, commentBox);
  setText(f.realm, realmBox);

  if f.isRealFolder() then
    begin
    include(actions, FA_UPLOAD);
    setText(f.uploadFilterMask, uploadfilterBox);
    end;

  if f.isFileOrFolder() then
    setFlag(FA_DONT_LOG, dontlogChk);

  if f.isFile() or f.isRealFolder() then
    setFlag(FA_DL_FORBIDDEN, nodlChk);

  if not f.isRoot() then
    begin
    setFlag(FA_HIDDEN, hiddenChk);
    if not iconBox.enabled then
      begin
      iconBox.enabled:=TRUE;
      iconBox.itemIndex:=f.icon+iconOfs;
      addiconBtn.Enabled:=TRUE;
      end
    else
      if iconBox.itemIndex <> f.icon+iconOfs then
        iconBox.itemIndex:=-1;
    end;

  if f.isFile() then
    setFlag(FA_DONT_COUNT_AS_DL, dontconsiderChk);

  if f.isFolder() then
    begin
    include(actions, FA_DELETE);

    diffTab.tabVisible:=TRUE;
    maskTab.tabVisible:=TRUE;
    setText(f.filesFilter, filesfilterBox);
    setText(f.foldersFilter, foldersfilterBox);
    setText(f.defaultFileMask, deffileBox);
    setText(f.dontCountAsDownloadMask, dontconsiderBox);
    setText(f.diffTpl, difftplBox);

    setFlag(FA_HIDDENTREE, hidetreeChk);
    setFlag(FA_HIDE_EXT, hideextChk);
    setFlag(FA_BROWSABLE, browsableChk);
    setFlag(FA_ARCHIVABLE, archivableChk);
    setFlag(FA_HIDE_EMPTY_FOLDERS, hideemptyChk);

    end;

  // collect usernames
  for act:=low(act) to high(act) do
    addUniqueArray(users[act], f.accounts[act]);
  end;

for act:=low(act) to high(act) do
  begin
  savePerm[act]:=FALSE;
  if act in actions then
    actionTabs.tabs.add(FILEACTION2STR[act]);
  end;

if easyMode then
  onlyForExperts([browsableChk, commentTab, realmBox, dontconsiderChk, maskTab, dontlogChk, hideextChk]);

actionTabs.tabIndex:=0;
actionTabsChange(NIL);
setCaption();
pages.TabIndex:=0;
end;

procedure TfilepropFrm.goToAccountsBtnClick(Sender: TObject);
begin
showOptions(optionsFrm.accountsPage);
updateAccountsBox();
actionTabsChange(NIL);
end;

procedure TfilepropFrm.allBtnClick(Sender: TObject);
var
  i: integer;
  b: boolean;
begin
if accountsBox.items.Count = 0 then exit;
with accountsBox.Items[0] do
  begin
  b:=not checked;
  checked:=b;
  end;
for i:=1 to accountsBox.items.count-1 do
  accountsBox.Items[i].checked:=b;
end;

procedure TfilepropFrm.anonChkClick(Sender: TObject);
var
  s: string;
begin
savePerm[currAction]:=TRUE;
if sender = anonChk then s:=USER_ANONYMOUS
else if sender = anyAccChk then
  begin
  s:=USER_ANY_ACCOUNT;
  accountsBox.enabled:=not anyAccChk.Checked;
  end
else if sender = anyoneChk then
  begin
  s:=USER_ANYONE;
  accountsBox.enabled:=not anyoneChk.Checked;
  anonChk.enabled:=accountsBox.enabled;
  anyAccChk.enabled:=accountsBox.enabled;
  newaccBtn.Enabled:=accountsBox.enabled;
  end;
allBtn.Enabled:=accountsBox.enabled;
with sender as Tcheckbox do
  if checked then addUniqueString(s, users[currAction])
  else removeString(s, users[currAction]);
end;

procedure TfilepropFrm.applyBtnClick(Sender: TObject);
var
  i: integer;
  f: Tfile;
  act: TfileAction;

  procedure applyFlag(flag:TfileAttribute; cb:TCheckBox);
  begin
  if (cb.State = cbGrayed)
  or not cb.Enabled
  or not cb.Visible then exit;

  if cb.Checked then include(f.flags, flag)
  else exclude(f.flags, flag);
  end; // applyFlag

  procedure applyText(var v:string; box:TCustomEdit);
  begin
  if box.modified then
    v:=box.Text;
  end; // applyText

begin
for act:=low(act) to high(act) do
  sortArray(users[act]);

for i:=0 to mainFrm.filesBox.SelectionCount-1 do
  begin
  f:=mainFrm.filesBox.Selections[i].data;

  for act:=low(act) to high(act) do
    if savePerm[act]
    and ((act <> FA_UPLOAD) or f.isRealFolder())
    and ((act <> FA_DELETE) or f.isFolder()) then
      begin

      // The following is because we monitor every upload path
      if (act = FA_UPLOAD)
      and ((f.accounts[act] = NIL) <> (users[act] = NIL)) then // something has changed
        // WARNING: toggleString() can't be used here, it's not equivalent
        if users[act] <> NIL then addString(f.resource, uploadPaths)
        else removeString(f.resource, uploadPaths);

      f.accounts[act]:=users[act];
      end;

  applyText(f.comment, commentBox);
  applyText(f.realm, realmBox);

  if f.isFile() then
    applyFlag(FA_DONT_COUNT_AS_DL, dontconsiderChk);

  if f.isFolder() then
    begin
    applyText(f.diffTpl, difftplBox);
    applyText(f.filesFilter, filesfilterBox);
    applyText(f.foldersFilter, foldersfilterBox);
    applyText(f.defaultFileMask, deffileBox);
    applyText(f.dontCountAsDownloadMask, dontconsiderBox);

    applyFlag(FA_HIDDENTREE, hidetreeChk);
    applyFlag(FA_HIDE_EXT, hideextChk);
    applyFlag(FA_HIDE_EMPTY_FOLDERS, hideemptyChk);
    applyFlag(FA_BROWSABLE, browsableChk);
    applyFlag(FA_ARCHIVABLE, archivableChk);
    end;

  if not f.isRoot() then
    begin
    applyFlag(FA_HIDDEN, hiddenChk);
    if iconBox.itemIndex > -1 then
      f.setupImage(iconBox.itemIndex-iconOfs);
    end;

  if f.isRealFolder() then
    applyText(f.uploadFilterMask, uploadfilterBox);

  if f.isFileOrFolder() then
    applyFlag(FA_DONT_LOG, dontlogChk);

  if f.isFile() or f.isRealFolder() then
    applyFlag(FA_DL_FORBIDDEN, nodlChk);
  end;
end;

procedure TfilepropFrm.newaccBtnClick(Sender: TObject);
var
  acc: Paccount;
begin
acc:=createAccountOnTheFly();
if acc = NIL then exit;
with accountsBox.Items.add() do
  begin
  caption:=acc.user;
  data:=acc;
  checked:=TRUE;
  end;
end;

procedure TfilepropFrm.textinputEnter(Sender: TObject);

  function chooseValue(var s:string):boolean;
  var
    l: string;
  begin
  l:=s;
  repeat s:=chop(#0, l)
  until (s > '') or (l = '');
  result:=TRUE;
  end; // chooseValue

var
  box: TcustomEdit;
  s, h: string;
begin
box:=sender as TcustomEdit;
if countSubstr(#0, box.hint) < 2 then exit;

s:=box.hint;
h:=chop(#0, s);
if not chooseValue(s) then exit;
box.text:=s;
box.hint:=h;
// these properties are unhappily kept unaccessible through TcustomEdit interface
try (box as Tlabelededit).color:=clWindow except end;
try (box as Tmemo).color:=clWindow except end;
end;

procedure TfilepropFrm.updateAccountsBox;
var
  i: integer;
  a: Paccount;
begin
accountsBox.clear();
for i:=0 to length(accounts)-1 do
  begin
  a:=@accounts[i];
  if not a.enabled then continue;
  accountsBox.addItem(a.user, Tobject(a));
  end;
end; // updateAccountsBox

end.
