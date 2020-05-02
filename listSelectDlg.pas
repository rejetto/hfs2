unit listSelectDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, CheckLst, types, utilLib, strutils;

type
  TlistSelectFrm = class(TForm)
    listBox: TCheckListBox;
    Panel1: TPanel;
    okBtn: TButton;
    cancelBtn: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

function listSelect(title:string; var options:TstringList):boolean;

implementation

{$R *.dfm}

function listSelect(title:string; var options:TstringList):boolean;
var
  dlg: TlistSelectFrm;
  i: integer;
begin
result:=FALSE;
dlg:=TlistSelectFrm.Create(NIL);
with dlg do
  try
    caption:=title;
    listBox.items.assign(options);
    for i:=0 to options.count-1 do
      if options.objects[i] <> NIL then
        listbox.Checked[i]:=TRUE;
    clientHeight:=clientHeight-listBox.ClientHeight+listBox.ItemHeight*minmax(5,15, listbox.count);
    if showModal() = mrCancel then exit;
    for i:=0 to listbox.Count-1 do
      options.Objects[i]:=if_(listbox.Checked[i], PTR1, NIL);
    result:=TRUE;
  finally dlg.free end;
end;

end.
