unit purgeDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TpurgeFrm = class(TForm)
    rmFilesChk: TCheckBox;
    Label1: TLabel;
    rmRealFoldersChk: TCheckBox;
    rmEmptyFoldersChk: TCheckBox;
    Button1: TButton;
    Button2: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  purgeFrm: TpurgeFrm;

implementation

{$R *.dfm}

end.
