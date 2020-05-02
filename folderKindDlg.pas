unit folderKindDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, strUtils, ExtCtrls;

type
  TfolderKindFrm = class(TForm)
    realLbl: TLabel;
    virtuaLbl: TLabel;
    realBtn: TBitBtn;
    virtuaBtn: TBitBtn;
    Label3: TLabel;
    hintLbl: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.dfm}

procedure TfolderKindFrm.FormCreate(Sender: TObject);
begin
realBtn.Font.Style:=[fsBold];
with hintLbl do caption:=ansiReplaceStr(caption,'? ','?'#13);
end;

end.
