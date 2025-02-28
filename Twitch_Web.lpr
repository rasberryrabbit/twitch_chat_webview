program Twitch_Web;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, Windows,
  Twitchweb_main, uniqueinstance_package, rxnew
  { you can add units after this };

{$R *.res}

{$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}

begin
  RequireDerivedFormResource:=True;
  IsMultiThread:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TFormTwitchWeb, FormTwitchWeb);
  Application.Run;
end.

