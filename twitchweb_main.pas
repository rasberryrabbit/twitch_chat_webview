unit Twitchweb_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, XMLConf, Forms, Controls, Graphics, Dialogs, StdCtrls,
  LMessages, ExtCtrls, ActnList, Menus, XMLPropStorage, Buttons, UniqueInstance,
  UExceptionLogger, uWVWindowParent, uWVBrowser, RxVersInfo, Messages,
  uWVTypeLibrary, uWVEvents, uWVTypes;


const
  MSGVISITDOM = LM_USER+$102;

type

  { TFormTwitchWeb }

  TFormTwitchWeb = class(TForm)
    ActionLogging: TAction;
    ActionOpenUserList: TAction;
    ActionWSockUnique: TAction;
    ActionOpenChatFull: TAction;
    ActionChatTime: TAction;
    ActionDebugLog: TAction;
    ActionOpenNotify: TAction;
    ActionOpenChat: TAction;
    ActionWSPort: TAction;
    ActionList1: TActionList;
    ButtonBack: TBitBtn;
    ButtonReload: TBitBtn;
    ButtonGoChat: TButton;
    ButtonHome: TButton;
    ButtonGo: TButton;
    Editurl: TEdit;
    ExceptionLogger1: TExceptionLogger;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    RxVersionInfo1: TRxVersionInfo;
    Timer1: TTimer;
    Timer2: TTimer;
    UniqueInstance1: TUniqueInstance;
    WVBrowser1: TWVBrowser;
    WVWindowParent1: TWVWindowParent;
    XMLConfig1: TXMLConfig;
    XMLPropStorage1: TXMLPropStorage;
    procedure ActionChatTimeExecute(Sender: TObject);
    procedure ActionDebugLogExecute(Sender: TObject);
    procedure ActionLoggingExecute(Sender: TObject);
    procedure ActionOpenChatExecute(Sender: TObject);
    procedure ActionOpenChatFullExecute(Sender: TObject);
    procedure ActionOpenNotifyExecute(Sender: TObject);
    procedure ActionOpenUserListExecute(Sender: TObject);
    procedure ActionWSockUniqueExecute(Sender: TObject);
    procedure ActionWSockUniqueUpdate(Sender: TObject);
    procedure ActionWSPortExecute(Sender: TObject);
    procedure ButtonBackClick(Sender: TObject);
    procedure ButtonGoChatClick(Sender: TObject);
    procedure ButtonHomeClick(Sender: TObject);
    procedure ButtonReloadClick(Sender: TObject);
    procedure ButtonRunClick(Sender: TObject);
    procedure ButtonGoClick(Sender: TObject);
    procedure EditurlKeyPress(Sender: TObject; var Key: char);

    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure WVBrowser1AddScriptToExecuteOnDocumentCreatedCompleted(
      Sender: TObject; aErrorCode: HRESULT; const aResult: wvstring);
    procedure WVBrowser1AfterCreated(Sender: TObject);
    procedure WVBrowser1ExecuteScriptWithResultCompleted(Sender: TObject;
      errorCode: HResult; const aResult: ICoreWebView2ExecuteScriptResult;
      aExecutionID: integer);
    procedure WVBrowser1NavigationCompleted(Sender: TObject;
      const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2NavigationCompletedEventArgs);
    procedure WVBrowser1NavigationStarting(Sender: TObject;
      const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2NavigationStartingEventArgs);
    procedure WVBrowser1SourceChanged(Sender: TObject;
      const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2SourceChangedEventArgs);
    procedure WVBrowser1WebMessageReceived(Sender: TObject;
      const aWebView: ICoreWebView2;
      const aArgs: ICoreWebView2WebMessageReceivedEventArgs);
    procedure XMLPropStorage1SaveProperties(Sender: TObject);
  private
    procedure CheckChatting(var Msg:TLMessage); message MSGVISITDOM;

  protected
    procedure WMMove(var Message: TMessage); message WM_MOVE;
    procedure WMMoving(var Message: TMessage); message WM_MOVING;
  public
    procedure SetFormCaption;

    procedure SetUpWebSocketPort;
    procedure ReplaceWSPortHTML(const fname, port1, port2: string);

  end;

var
  FormTwitchWeb: TFormTwitchWeb;

implementation

uses
  uWVLoader, Windows, uWebsockSimple, ShellApi, DateUtils, StrUtils,
  regexpr, ActiveX;


{$R *.lfm}

const
  MaxLength = 2048;
  cqueryjs = 'var obser=document.querySelector("div.chat-scrollable-area__message-container");'+
             'if(obser) {'+
             'window.chrome.webview.postMessage("!Observer Start!");'+
             'const observer = new MutationObserver((mutations) => {'+
             'mutations.forEach(mutat => {'+
             'mutat.addedNodes.forEach(node => {'+
             'window.chrome.webview.postMessage(node.outerHTML);'+
             '});'+
             '});'+
             '});'+
             'observer.observe(obser, {'+
             '    subtree: false,'+
             '    attributes: false,'+
             '    childList: true,'+
             '    characterData: false,'+
             '    });'+
             'observer.start();'+
             'window.addEventListener(''unload'', function() {'+
             '  observer.disconnect();'+
             '});'+
             '}';

  syschat_str = '0SGhw live_chatting_list';
  syschat_guide = 'live_chatting_guide_';

  TwitchURL ='www.twitch.tv/';


var
  WSPortChat: string = '61002';
  WSPortSys: string = '61003';
  WSPortUnique: Boolean = False;
  SockServerChat: TSimpleWebsocketServer;
  SockServerSys: TSimpleWebsocketServer;
  ProcessSysChat: Boolean = False;
  iCountVisit: Integer = 0;
  IncludeChatTime: Boolean = False;
  chatlog_full: string = 'doc\webchatlog_list.html';
  chatlog_full_unique: string = 'doc\webchatlog_list_unique.html';
  chatlog_donation: string = 'doc\webchatlog_donation_sub.html';
  chatlog_chatonly: string = 'doc\webchatlog_chatbox.html';
  chatlog_userid: string = 'doc\webchatlog_user_unique.html';
  stripusertooltip: TRegExpr;
  PageLoaded: Boolean = False;
  observer_started: Boolean = False;


{ TFormTwitchWeb }

procedure TFormTwitchWeb.ButtonHomeClick(Sender: TObject);
begin
  WVBrowser1.Navigate('https://www.twitch.tv/');
end;

procedure TFormTwitchWeb.ButtonReloadClick(Sender: TObject);
begin
  WVBrowser1.Refresh;
end;

procedure TFormTwitchWeb.ActionWSPortExecute(Sender: TObject);
var
  ir, i: Integer;
  port: string;
begin
  ir:=InputCombo('웹소켓 포트','웹소켓 포트를 지정',['61002','61010','61020','61030','61040']);
  case ir of
  0: WSPortChat:='61002';
  1: WSPortChat:='61010';
  2: WSPortChat:='61020';
  3: WSPortChat:='61030';
  4: WSPortChat:='61040';
  end;
  if ir<>-1 then
    begin
      try
        SetUpWebSocketPort;
        ReplaceWSPortHTML(chatlog_chatonly,WSPortChat,'');
        ReplaceWSPortHTML(chatlog_donation,WSPortSys,'');
        ReplaceWSPortHTML(chatlog_userid,WSPortChat,'');
        ReplaceWSPortHTML(chatlog_full_unique,WSPortChat,'');
        ReplaceWSPortHTML(chatlog_full,WSPortChat,WSPortSys);
        XMLConfig1.SetValue('WS/PORT',WSPortChat);
        XMLConfig1.SetValue('WS/PORTSYS',WSPortSys);
        SetFormCaption;
      except
        on e:exception do
          ShowMessage(e.Message);
      end;
    end;
end;

procedure TFormTwitchWeb.ButtonBackClick(Sender: TObject);
begin
  WVBrowser1.GoBack;
end;

procedure TFormTwitchWeb.ButtonGoChatClick(Sender: TObject);
begin
  if (Pos(TwitchURL,Editurl.Text)>0) and (Pos('/chat',Editurl.Text)=0) then
  begin
    Editurl.Text:=Editurl.Text+'/chat';
    ButtonGo.Click;
  end;
end;

procedure TFormTwitchWeb.ActionOpenChatExecute(Sender: TObject);
begin
  ShellExecuteW(0,'open',pwidechar(ExtractFilePath(Application.ExeName)+UTF8Decode(chatlog_chatonly)),nil,nil,SW_SHOWNORMAL);
end;

procedure TFormTwitchWeb.ActionOpenChatFullExecute(Sender: TObject);
begin
  if not WSPortUnique then
   ShellExecuteW(0,'open',pwidechar(ExtractFilePath(Application.ExeName)+UTF8Decode(chatlog_full)),nil,nil,SW_SHOWNORMAL)
   else
    ShellExecuteW(0,'open',pwidechar(ExtractFilePath(Application.ExeName)+UTF8Decode(chatlog_full_unique)),nil,nil,SW_SHOWNORMAL)
end;

procedure TFormTwitchWeb.ActionDebugLogExecute(Sender: TObject);
begin
  ActionDebugLog.Checked:=not ActionDebugLog.Checked;
end;

procedure TFormTwitchWeb.ActionLoggingExecute(Sender: TObject);
begin
  ActionLogging.Checked:=not ActionLogging.Checked;
  Timer2.Enabled:=ActionLogging.Checked;
end;

procedure TFormTwitchWeb.ActionChatTimeExecute(Sender: TObject);
begin
  ActionChatTime.Checked:=not ActionChatTime.Checked;
  IncludeChatTime:=ActionChatTime.Checked;
  XMLConfig1.SetValue('IncludeTime',IncludeChatTime);
end;

procedure TFormTwitchWeb.ActionOpenNotifyExecute(Sender: TObject);
begin
  ShellExecuteW(0,'open',pwidechar(ExtractFilePath(Application.ExeName)+UTF8Decode(chatlog_donation)),nil,nil,SW_SHOWNORMAL);
end;

procedure TFormTwitchWeb.ActionOpenUserListExecute(Sender: TObject);
begin
  ShellExecuteW(0,'open',pwidechar(ExtractFilePath(Application.ExeName)+UTF8Decode(chatlog_userid)),nil,nil,SW_SHOWNORMAL);
end;

procedure TFormTwitchWeb.ActionWSockUniqueExecute(Sender: TObject);
begin
  ActionWSockUnique.Checked:=not ActionWSockUnique.Checked;
  WSPortUnique:=ActionWSockUnique.Checked;
  XMLConfig1.SetValue('WS/UNIQUE',WSPortUnique);
end;

procedure TFormTwitchWeb.ActionWSockUniqueUpdate(Sender: TObject);
begin
  ActionWSockUnique.Checked:=WSPortUnique;
end;

procedure TFormTwitchWeb.ButtonRunClick(Sender: TObject);
begin

end;

procedure TFormTwitchWeb.ButtonGoClick(Sender: TObject);
begin
  if Editurl.Text='' then
    Editurl.Text:='https://www.twitch.tv/';
  WVBrowser1.Navigate(UTF8Decode(Editurl.Text));
end;

procedure TFormTwitchWeb.EditurlKeyPress(Sender: TObject; var Key: char);
begin
  if Key=#13 then
    begin
      Key:=#0;
      ButtonGo.Click;
    end;
end;

procedure TFormTwitchWeb.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin

end;

procedure TFormTwitchWeb.FormDestroy(Sender: TObject);
begin
  stripusertooltip.Free;
  SockServerChat.Free;
  SockServerSys.Free;
  XMLConfig1.SetValue('CHAT/FULL',UTF8Decode(chatlog_full));
  XMLConfig1.SetValue('CHAT/FULLUNIQUE',UTF8Decode(chatlog_full_unique));
  XMLConfig1.SetValue('CHAT/CHAT',UTF8Decode(chatlog_chatonly));
  XMLConfig1.SetValue('CHAT/DONATION',UTF8Decode(chatlog_donation));
  XMLConfig1.SetValue('CHAT/USERID',UTF8Decode(chatlog_userid));
  if XMLConfig1.Modified then
    XMLConfig1.SaveToFile('config.xml');
  Sleep(200);
end;

procedure TFormTwitchWeb.FormShow(Sender: TObject);
begin
  stripusertooltip:=TRegExpr.Create('\<span\sclass\="badge_tooltip.+\/span\>');

  if FileExists('config.xml') then
    XMLConfig1.LoadFromFile('config.xml');

  IncludeChatTime:=XMLConfig1.GetValue('IncludeTime',False);
  WSPortChat:=XMLConfig1.GetValue('WS/PORT','61002');
  WSPortSys:=XMLConfig1.GetValue('WS/PORTSYS','61003');
  WSPortUnique:=XMLConfig1.GetValue('WS/UNIQUE',WSPortUnique);
  ActionChatTime.Checked:=IncludeChatTime;
  ActionWSockUnique.Checked:=WSPortUnique;

  chatlog_full:=UTF8Encode(XMLConfig1.GetValue('CHAT/FULL',UTF8Decode(chatlog_full)));
  chatlog_full_unique:=UTF8Encode(XMLConfig1.GetValue('CHAT/FULLUNIQUE',UTF8Decode(chatlog_full_unique)));
  chatlog_chatonly:=UTF8Encode(XMLConfig1.GetValue('CHAT/CHAT',UTF8Decode(chatlog_chatonly)));
  chatlog_donation:=UTF8Encode(XMLConfig1.GetValue('CHAT/DONATION',UTF8Decode(chatlog_donation)));
  chatlog_userid:=UTF8Encode(XMLConfig1.GetValue('CHAT/USERID',UTF8Decode(chatlog_userid)));

  SetUpWebSocketPort;
  SetFormCaption;

  if GlobalWebView2Loader.InitializationError then
    showmessage(UTF8Encode(GlobalWebView2Loader.ErrorMessage))
   else
    if GlobalWebView2Loader.Initialized then
      WVBrowser1.CreateBrowser(WVWindowParent1.Handle)
     else
      Timer1.Enabled := True;
end;

procedure TFormTwitchWeb.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled:=False;
  if GlobalWebView2Loader.InitializationError then
    showmessage(UTF8Encode(GlobalWebView2Loader.ErrorMessage))
   else
    if GlobalWebView2Loader.Initialized then
      WVBrowser1.CreateBrowser(WVWindowParent1.Handle)
     else
      Timer1.Enabled := True;
end;

procedure TFormTwitchWeb.Timer2Timer(Sender: TObject);
begin
  if not observer_started then
    PostMessage(Handle, MSGVISITDOM, 0, 0);
end;

procedure TFormTwitchWeb.WVBrowser1AddScriptToExecuteOnDocumentCreatedCompleted(
  Sender: TObject; aErrorCode: HRESULT; const aResult: wvstring);
begin

end;

procedure TFormTwitchWeb.WVBrowser1AfterCreated(Sender: TObject);
begin
  WVWindowParent1.UpdateSize;
  ButtonGo.Click;
  // We need to a filter to enable the TWVBrowser.OnWebResourceRequested event
  //WVBrowser1.AddWebResourceRequestedFilter('*', COREWEBVIEW2_WEB_RESOURCE_CONTEXT_IMAGE);
end;

procedure TFormTwitchWeb.WVBrowser1ExecuteScriptWithResultCompleted(
  Sender: TObject; errorCode: HResult;
  const aResult: ICoreWebView2ExecuteScriptResult; aExecutionID: integer);
begin

end;

procedure TFormTwitchWeb.WVBrowser1NavigationCompleted(Sender: TObject;
  const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2NavigationCompletedEventArgs);
begin
  PageLoaded:=True;
end;

procedure TFormTwitchWeb.WVBrowser1NavigationStarting(Sender: TObject;
  const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2NavigationStartingEventArgs);
begin
  PageLoaded:=False;
  observer_started:=False;
end;

procedure TFormTwitchWeb.WVBrowser1SourceChanged(Sender: TObject;
  const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2SourceChangedEventArgs);
begin
  observer_started:=False;
  Editurl.Text:=UTF8Encode(WVBrowser1.Source);
  ButtonBack.Enabled:=WVBrowser1.CanGoBack;
end;

procedure TFormTwitchWeb.WVBrowser1WebMessageReceived(Sender: TObject;
  const aWebView: ICoreWebView2;
  const aArgs: ICoreWebView2WebMessageReceivedEventArgs);
var
  res: PWideChar;
  buf: UnicodeString;
begin
  if Failed(aArgs.TryGetWebMessageAsString(res)) then
    exit;
  buf:=res;
  CoTaskMemFree(res);
  if (not observer_started) and (buf='!Observer Start!') then
  begin
    observer_started:=True;
  end
  else
  begin
    if (Pos(UTF8Decode(syschat_str),buf)>0) and
       (Pos(UTF8Decode(syschat_guide),buf)=0) then
    begin
      SockServerSys.BroadcastMsg(UTF8Encode(buf));
      if WSPortUnique then
        SockServerChat.BroadcastMsg(UTF8Encode(buf));
    end
    else
      SockServerChat.BroadcastMsg(UTF8Encode(buf));
  end;
end;

procedure TFormTwitchWeb.XMLPropStorage1SaveProperties(Sender: TObject);
begin

end;

procedure TFormTwitchWeb.CheckChatting(var Msg: TLMessage);
begin
  if not PageLoaded then
    exit;
  if POS(TwitchURL,WVBrowser1.Source)=0 then
    exit;
  if not observer_started then
    WVBrowser1.ExecuteScript(UTF8Decode(cqueryjs));
end;

procedure TFormTwitchWeb.WMMove(var Message: TMessage);
begin
  inherited;

  if (WVBrowser1 <> nil) then
    WVBrowser1.NotifyParentWindowPositionChanged;
end;

procedure TFormTwitchWeb.WMMoving(var Message: TMessage);
begin
  inherited;

  if (WVBrowser1 <> nil) then
    WVBrowser1.NotifyParentWindowPositionChanged;
end;

procedure TFormTwitchWeb.SetFormCaption;
var
  cefVer: Cardinal;
begin
  cefVer:=GetFileVersion('WebVew2Loader');
  Caption:='TwitchWeb_WebView2'+RxVersionInfo1.FileVersion+' '+IntToHex(cefVer,8)+' @'+WSPortChat;
end;

procedure TFormTwitchWeb.SetUpWebSocketPort;
var
  i, j: Integer;
begin
  // start websocket server
  if Assigned(SockServerChat) then
    SockServerChat.Free;
  if Assigned(SockServerSys) then
    SockServerSys.Free;
  j:=0;
  if not TryStrToInt(WSPortChat,i) then
  begin
    WSPortChat:='61002';
    i:=61002;
  end;
  while j<8 do begin
    try
      SockServerChat:=TSimpleWebsocketServer.Create(WSPortChat);
      try
        WSPortSys:=IntToStr(i+1);
        SockServerSys:=TSimpleWebsocketServer.Create(WSPortSys);
        break;
      except
        SockServerChat.Free;
        raise;
      end;
    except
      Inc(j,2);
      Inc(i,j);
      WSPortChat:=IntToStr(i);
    end;
  end;
end;

procedure TFormTwitchWeb.ReplaceWSPortHTML(const fname, port1, port2: string);
const
  rport = '(?-s)(WebSocket\(\"ws\:.+)(\:\d+)(\",\"chat\"\);)';
var
  fs: TStringStream;
  regport: TRegExpr;
  res: string;
  i, j: Integer;
begin
  res:='';
  i:=1;
  fs := TStringStream.Create('');
  try
    fs.LoadFromFile(fname);
    regport:=TRegExpr.Create(rport);
    try
      // first item
      if (port1<>'') and regport.Exec(fs.DataString) then
      begin
        j:=regport.MatchPos[2];
        res:=res+Copy(fs.DataString,i,j-i+1)+port1;
        i:=regport.MatchPos[3];
      end;
      // second item
      if (port2<>'') and regport.ExecNext then
      begin
        j:=regport.MatchPos[2];
        res:=res+Copy(fs.DataString,i,j-i+1)+port2;
        i:=regport.MatchPos[3];
      end;
      res:=res+Copy(fs.DataString,i);
      // save to file
      fs.Clear;
      fs.WriteString(res);
      fs.SaveToFile(fname);
    finally
      regport.Free;
    end;
  finally
    fs.Free;
  end;
end;


initialization
  GlobalWebView2Loader                := TWVLoader.Create(nil);
  GlobalWebView2Loader.UserDataFolder := UTF8Decode(ExtractFileDir(Application.ExeName) + '\CustomCache');

  // Set GlobalWebView2Loader.BrowserExecPath if you don't want to use the evergreen version of WebView Runtime
  //GlobalWebView2Loader.BrowserExecPath := 'c:\WVRuntime';

  // Uncomment these lines to enable the debug log in 'CustomCache\EBWebView\chrome_debug.log'
  //GlobalWebView2Loader.DebugLog       := TWV2DebugLog.dlEnabled;
  //GlobalWebView2Loader.DebugLogLevel  := TWV2DebugLogLevel.dllInfo;

  GlobalWebView2Loader.StartWebView2;


end.

