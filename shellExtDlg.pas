unit shellExtDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, utilLib, Vcl.Imaging.GIFImg;

type
  TshellExtFrm = class(TForm)
    Image1: TImage;
    Panel1: TPanel;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  shellExtFrm: TshellExtFrm;

implementation

{$R *.dfm}

end.
