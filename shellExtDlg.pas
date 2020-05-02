unit shellExtDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, GIFImage, utilLib;

type
  TshellExtFrm = class(TForm)
    Image1: TImage;
    Panel1: TPanel;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  shellExtFrm: TshellExtFrm;

implementation

{$R *.dfm}

procedure TshellExtFrm.FormCreate(Sender: TObject);
var
  gif: TGIFImage;
begin
// turbo delphi doesn't allow me to load a gif from the form designer, so i do it run-time
gif:=stringToGif(getRes('shell', 'GIF'));
try image1.picture.assign(gif);
finally gif.free end;
end;

end.
