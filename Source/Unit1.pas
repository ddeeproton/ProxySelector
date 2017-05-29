unit Unit1;

interface

uses
  ShellApi, Registry, StdCtrls, Classes, Controls, CheckLst,
  Windows, Messages, SysUtils, Graphics, Forms,
  Dialogs, ComCtrls, Menus, IdTCPClient, IdHTTP,
  IdTCPConnection, IdComponent, IdBaseComponent, ImgList, ExtCtrls;

type
  TForm1 = class(TForm)
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    N8: TMenuItem;
    N9: TMenuItem;
    IdHTTP1: TIdHTTP;
    Ligne1: TMenuItem;
    Cocher1: TMenuItem;
    Outils1: TMenuItem;
    Quitter1: TMenuItem;
    Fichier1: TMenuItem;
    Ajouter1: TMenuItem;
    Ajouter2: TMenuItem;
    Dcocher1: TMenuItem;
    Apropos1: TMenuItem;
    Quitter2: TMenuItem;
    Modifier1: TMenuItem;
    Modifier2: TMenuItem;
    ListView1: TListView;
    MainMenu1: TMainMenu;
    Supprimer1: TMenuItem;
    Supprimer2: TMenuItem; 
    Affichage1: TMenuItem;
    outdcocher1: TMenuItem;
    PopupMenu1: TPopupMenu;
    Rafraichir1: TMenuItem;
    ImageList1: TImageList;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    outactualiser1: TMenuItem;
    Dernierlienentr1: TMenuItem;
    Dfinircommeproxy1: TMenuItem;
    Dernierlienentre1: TMenuItem;
    Importerlisteproxy1: TMenuItem;
    Exporterlisteproxy1: TMenuItem;
    Importerlisteproxy2: TMenuItem;
    Exporterlisteproxy2: TMenuItem;
    TimerSauvegarderProxies: TTimer;
    Rafraichirlaslection1: TMenuItem;
    Arrterlactualisation1: TMenuItem;
    Actualiserlaslection1: TMenuItem;
    Arrterlactualisation2: TMenuItem;
    OuvrirInternetExplorer1: TMenuItem;
    InternetExplorerPagededmarrage1: TMenuItem;
    N10: TMenuItem;
    Editerlalistedesproxydansleblocnote1: TMenuItem;
    Editerlesproxiesdepuisleblocnote1: TMenuItem;
    procedure ButtonAjouterClick(Sender: TObject);
    procedure ButtonSupprimerClick(Sender: TObject);
    procedure ToutRafraichir1Click(Sender: TObject);
    procedure Dcocher1Click(Sender: TObject);
    procedure Modifier1Click(Sender: TObject);
    procedure OuvrirInternetExplorer1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Dernierlienentre1Click(Sender: TObject);
    function ExtraitPort(S:string):Integer;
    function ExtraitAdresseIP(S:string):string;  
    procedure AjouterUneColone(NewColumn: TListColumn; Titre:string; Largeur:integer);
    procedure EditerLigne(ListItem: TListItem; Ligne:integer; ImageNum:integer = -1;
      Colone1: string = ''; Colone2: string = '');
    procedure ListView1DblClick(Sender: TObject);
    procedure SauvegarderProxies();
    procedure ChargerProxies();
    procedure ListView1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure TesterTousLesProxies();
    procedure RafraichirProxies();
    procedure ListView1Edited(Sender: TObject; Item: TListItem;
      var S: String);
    procedure TimerSauvegarderProxiesTimer(Sender: TObject);
    procedure ListView1ContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure TesterLeProxy(LigneATester:integer; AttendreAvantDeTester:integer);
    procedure Rafraichirlaslection1Click(Sender: TObject);
    procedure Arrterlactualisation1Click(Sender: TObject);
    procedure StoperTousLesTest();
    procedure Dfinircommeproxy1Click(Sender: TObject);
    procedure AProposClick(Sender: TObject);
    procedure Quitter1Click(Sender: TObject);
    procedure Importerlisteproxy1Click(Sender: TObject);
    procedure Exporterlisteproxy1Click(Sender: TObject);
    procedure Editerlalistedesproxydansleblocnote1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  TTestProxy = class(TThread) 
  protected
    procedure TestProxy(Ligne: integer);
    function TempsEcoule(ElipsedTime: extended):integer;
    function RequeteAuProxy(ProxyAdresse:string; ProxyPort:integer; URL:string;
      TextATrouver:string):boolean;    
    procedure Execute; override;
  public
    ProxyIndex: integer;
    WaitB4Test: integer;
    { Public declarations }
  end;

var
  Form1: TForm1;
  TestProxy: array of TTestProxy;
  IdHTTPArray: array of TIdHTTP;
  FermetureDemandee: boolean;

const
  INCONNU     = 0;
  LENT        = 1;
  ETEINT      = 2;
  ACTIF       = 3;
  FORMATERROR = 4;
  TESTENCOURS = 5;
  TIMEOUT     = 6;
  StatusProxy: array[0..6] of string =  ('Etat inconnu',
                                         'Lent',
                                         'Eteint (rejeté)',
                                         'Actif',
                                         'Fausse adresse',
                                         'Test en cours',
                                         'Eteint (timedout)');

const
  // Fichier où sera sauvegarde les adresses des proxy
  FICHIERPROXY = 'FICHIERPROXY.txt';

  // Chemin dans le registre des parametres d'Internet
  INTERNETSETTINGSREGPATH = '\Software\Microsoft\Windows\CurrentVersion\Internet Settings\';

  // Chemin dans le registre des derniers liens entres dans le navigateur
  LASTURLTYPEDPATH = 'Software\Microsoft\Internet Explorer\TypedURLs';

implementation

{$R *.dfm}

// Procedure executee au demarrage de l'application
procedure TForm1.FormCreate(Sender: TObject);
var HauteurMinimum, HauteurMaximum: integer;
begin
  // Affecte le dossier de l'executable comme répertoire par défaut
  SetCurrentDirectory(PChar(ExtractFileDir(Application.Exename)));
  // On créer la première colone dans ListView1
  AjouterUneColone(ListView1.Columns.Add,
                   'Proxy',
                   ListView1.Width div 2 + 30);
  // On créer la seconde colone dans ListView1
  AjouterUneColone(ListView1.Columns.Add,
                   'Status',
                   ListView1.Width div 2 - 50);
  // On charge la liste des proxy dans ListView1
  ChargerProxies;
  // On coche la case du proxy actuel
  RafraichirProxies();
  // Calcul de la hauteur minimum de la fenêtre
  // en fonction du nombre d'elements dans la liste des proxy
  // et de la taille des caracteres.
  HauteurMinimum := 30 + ( ListView1.items.count *50);
  // Calcul de la hauteur maximum de la fenêtre
  // en fonction de la position de la fenetre par rapport au bas de l'ecran
  HauteurMaximum := Screen.DesktopHeight - 20;
  // Si la hauteur de la fenêtre est inferieur a la hauteur minimum
  // et la hauteur minimum est plus petite que la taille maximum de la fenetre (vous me suivez:P)
  if (Height < HauteurMinimum) and (HauteurMinimum < HauteurMaximum) then
    // On ajuste la fenetre a la hauteur minimum
    Height := HauteurMinimum;
  if HauteurMinimum >= HauteurMaximum then
    Height := HauteurMaximum;  
  // On place la fenêtre en bas a droite de l'ecran
  Top := Screen.DesktopHeight - Height - 10;
  Left := Screen.DesktopWidth - Width - 15;
  // On lance le test de la connection aux proxies
  TesterTousLesProxies();
end;


// Procedure appellee quand on ferme le programme
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  StoperTousLesTest();
  // Il arrive que parfois des messages d'erreurs apparaîssent quand
  // on ferme le programme (pendant les tests des proxies au démarrage), alors pour
  // limiter le nombre de messages d'erreurs, on force la fermeture de l'application.
  TerminateProcess(Application.Handle,4);                               
end;

//=============================================================
//         LES FONCTIONS DE TRAITEMENT DE CARACTERES
//=============================================================

// Teste si les caractères d'une chaine sont des chiffres
function IsNumeric(s:String): Boolean;
var
    Code: Integer;
    Value: Double;
begin
  val(s, Value, Code);
  Result := (Code = 0)
end;


// Supprime les caracteres qui ne sont pas entre A et Z, a et z, 0 et 9 ou egale a ":" ou "."
function NettoyeAdresseProxyEntreParUtilisateur(AdresseProxy:string):string;
var
  ValeurAscii, i: integer;
begin
  result := '';
  for i:=1 to length(AdresseProxy) do
  begin
    ValeurAscii := ord(AdresseProxy[i]);
    if (ValeurAscii >= ord('A')) and (ValeurAscii <= ord('Z'))
    or (ValeurAscii >= ord('a')) and (ValeurAscii <= ord('z'))
    or (ValeurAscii >= ord('0')) and (ValeurAscii <= ord('9'))
    or (AdresseProxy[i] = ':') or (AdresseProxy[i] = '.') then
      result := result + AdresseProxy[i];
  end;
end;


// Sort l'adresse IP depuis une adresse de type "IP:Port"
function TForm1.ExtraitAdresseIP(S:string):string;
begin
  // Retourne tout ce qui se trouve avant ':'
  result := copy(S,1,Pos(':', S)-1);
end;


// Sort le port depuis une adresse de type "IP:Port"
function TForm1.ExtraitPort(S:string):Integer;
var Port:string;
begin
  // Retourne tout ce qui se trouve après ':'
  Port := copy(S,Pos(':', S)+1, Length(S)-Pos(':', S));
  // Le port doit être obligatoirement un chiffre entier
  if IsNumeric(Port) then
    result := StrToInt(Port)
  else
    result := 0;
end;


//=============================================================
//                 LES FONCTIONS DU REGISTRE
//=============================================================

// Lit une valeur String dans le registre
function LireStringDansRegistre(Chemin:string; Cle:string):string;
var
  Registre : TRegistry ;
begin
  registre := TRegistry.Create ;
  Registre.RootKey := HKEY_CURRENT_USER;
  if Registre.openkey(Chemin,true) then
  begin
    if Registre.ValueExists(Cle) then
    begin
      result := Registre.ReadString(Cle);
    end;
  end;
  Registre.Free;
end;


// Lit une valeur Integer dans le registre
function LireIntegerDansRegistre(Chemin:string; Cle:string):integer;
var
  Registre : TRegistry ;
begin
  registre := TRegistry.Create ;
  Registre.RootKey := HKEY_CURRENT_USER;
  result := 0;
  if Registre.openkey(Chemin,true) then
  begin
    if Registre.ValueExists(Cle) then
    begin
      result := Registre.ReadInteger(Cle);
    end;
  end;
  Registre.Free;
end;


// Ecrit une valeur String dans le registre
procedure EcrireStringDansRegistre(Chemin:string; Cle:string; Valeur:string);
var
registre : TRegistry ;
begin
  registre := TRegistry.Create ;
  registre.RootKey := HKEY_CURRENT_USER;
  if registre.openkey(Chemin,true) then
  begin
    if registre.ValueExists(Cle) then
    begin
      registre.WriteString( Cle, Valeur);
    end;
 end;
 registre.Free;
end;


// Ecrit une valeur Integer dans le registre
procedure EcrireIntegerDansRegistre(Chemin:string; Cle:string; Valeur:integer);
var registre : TRegistry ;
begin
  registre := TRegistry.Create ;
  registre.RootKey := HKEY_CURRENT_USER;
  if registre.openkey(Chemin,true) then
  begin
    if registre.ValueExists(Cle) then
    begin
      registre.WriteInteger( Cle, Valeur);
    end;
 end;
 registre.Free;
end;


//=============================================================
//         LES FONCTIONS EN RAPPORT AVEC LE LISTVIEW
//=============================================================

// Charge les proxies dans le listView
procedure TForm1.ChargerProxies();
var
  Fichier        : textfile;
  texte          : string;
begin
  if not FileExists(FICHIERPROXY) then exit;
  ListView1.Items.Clear;
  assignFile(Fichier, FICHIERPROXY);
  reset(Fichier); // ouvre en lecture
  while not eof(Fichier) do
  begin
    readln(Fichier, texte);
    // On ajoute le proxy en fin de liste
    EditerLigne(ListView1.Items.Add,       // Item (ou ligne) du listView
                ListView1.Items.Count,     // Numéro de ligne
                INCONNU,                   // Numéro de l'image
                texte,                     // Adresse du proxy
                StatusProxy[INCONNU]);     // Texte du status

  end;
  closefile(Fichier);
end;


// Sauvegarde les proxies du listView
procedure TForm1.SauvegarderProxies();
var
  i: Integer;
  Fp : textfile;
begin
  assignFile(Fp, FICHIERPROXY);
  reWrite(Fp);
  for i := 0 to ListView1.items.count - 1 do
  begin
    Writeln(Fp, ListView1.Items.Item[i].Caption);
  end;
  closefile(Fp);
end;


// Ajoute une colone dans le listView
procedure TForm1.AjouterUneColone(NewColumn: TListColumn; Titre:string; Largeur:integer);
begin
  // Titre de la colone
  NewColumn.Caption := Titre;
  // Largeur de la colone
  NewColumn.Width   := Largeur;
end;


// Edite (ou ajoute) une ligne dans le listView
procedure TForm1.EditerLigne(ListItem: TListItem; Ligne:integer; ImageNum:integer = -1;
  Colone1: string = ''; Colone2: string = '');
begin
  // Met dans le listView l'adresse IP si on en indique une
  if Colone1 <> '' then
    Listitem.Caption    := Colone1;
  // Met dans le listView le status si on l'indique
  if Colone2 <> '' then
  begin
    // Si la ligne vient à l'instant d'être créer
    // (donc que la deuxième colone n'a pas encore une valeure)
    if ListView1.Items.Item[Ligne].SubItems.Count = 0 then
      // On ajoute le status dans la deuxième colone
      ListView1.Items.Item[Ligne].SubItems.Add(Colone2)
    else // Si la ligne a déjà été crée
      // On édite le status de la deuxième colone
      ListView1.Items.Item[Ligne].SubItems.Strings[0] := Colone2;
  end;
  // Si on a indiqué un numéro d'image
  if ImageNum > -1 then
    // On change d'image
    ListItem.ImageIndex := ImageNum;
end;


// Coche la ligne selectionnee si on double clique dessus
procedure TForm1.ListView1DblClick(Sender: TObject);
var i: integer;
Begin
  // Si aucune ligne selectionnee, on sort de la procedure
  if ListView1.SelCount = 0 then exit;
  // Recupere la ligne selectionnee
  i := ListView1.Selected.Index;
  // On ecrit dans le registre l'adresse IP du proxy selectionne
  EcrireStringDansRegistre(INTERNETSETTINGSREGPATH,
                           'ProxyServer',
                           ListView1.Items.Item[i].Caption);
  // On active le proxy
  EcrireIntegerDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyEnable', 1);
  // On rafraichit la fenêtre des proxy et coche le proxy actuel
  RafraichirProxies();
end;


// Quand on coche ou decoche une case dans la liste des proxy
// On active ou désactive le proxy dans la base de registre
procedure TForm1.ListView1Click(Sender: TObject);
var
  ListItem:TListItem;
  CurPos:TPoint;
begin
  // Si on clique dans la case à cocher, on séléctionne la ligne
  // Donc on récupère la position de la souris sur l'écran
  GetcursorPos(CurPos);
  // on indique sa position en fonction du ListView
  CurPos:=ListView1.ScreenToClient(CurPos);
  // On récupère la ligne du listView où se trouve la souris
  ListItem:=ListView1.GetItemAt(CurPos.x,CurPos.y);
  // Si on récupère bien une ligne et pas un espace blanc
  if Assigned(ListItem) then
  begin
    // Si on se trouve bien dans la case à cocher
    if (CurPos.x >= 5) and (CurPos.x <= 20) then
      if ListItem.Checked then
      begin
        // On definit le proxy dans le registre
        EcrireStringDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyServer', ListItem.Caption);
        // On active le proxy dans le registre
        EcrireIntegerDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyEnable', 1);
      end
      // Si on a décoche la case
      else begin
        // On désactive le proxy dans le registre
        EcrireIntegerDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyEnable', 0);
      end;
    end;
  // On rafraîchit la liste des proxy
  RafraichirProxies();
end;


// On sauvegarde si l'adresse d'un proxy est modifié
// directement dans le listview en cliquant deux fois lentement
// comme pour modifier le nom d'un fichier sous windows
procedure TForm1.ListView1Edited(Sender: TObject; Item: TListItem;
  var S: String);
begin
  // On fait appel à un Timer car la procedure est appellé juste
  // avant l'effectation de la modification de l'adressse dans le ListView
  // donc sans ça, quand on sauvegarde, ça ne sauvegarde aucune modification
  // alors on utilise un timer qui sauvegardera la modification
  TimerSauvegarderProxies.Enabled := True;
end;


// On vient de modifier le proxy, donc on sauvegarde et on rafraichit son status
procedure TForm1.TimerSauvegarderProxiesTimer(Sender: TObject);
begin
  // Arrête le Timer car on n'a pas besoin de boucle
  TimerSauvegarderProxies.Enabled := False;
  // Sauvegarde les adresses des proxies
  SauvegarderProxies;
  // Lance le test de la connection au proxy
  TesterLeProxy(ListView1.Selected.Index, 0);
end;


// On a cliqué droit dans le listView, on cherche le dernier lien entré
// dans Internet Explorer et on l'affiche dans le menu.
procedure TForm1.ListView1ContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  DernierLienEntre: string;
begin
  // On recupere le dernier lien entre dans Internet Explorer
  DernierLienEntre := LireStringDansRegistre(LASTURLTYPEDPATH,'url1');
  // On cache le bouton s'il n'y a aucun lien en memoire
  Dernierlienentre1.Visible := DernierLienEntre <> '';
  // Si on a un lien
  if DernierLienEntre <> '' then
  begin
    // On affiche un maximum de 35 caracteres du lien
    if Length(DernierLienEntre) > 35 then
      DernierLienEntre := Copy(DernierLienEntre,0, 35)+'...';
    // Affecte le titre au bouton
    Dernierlienentre1.Caption := DernierLienEntre;
  end;
end;


procedure TForm1.TesterLeProxy(LigneATester:integer; AttendreAvantDeTester:integer);
var
  i: Integer;
begin
  // On prend la dernière position du tableau TestProxy
  i := Length(TestProxy);
  // On agrandi le tableau
  SetLength(TestProxy, i+1);
  // Créer le thread du test de la connection
  TestProxy[i] := Unit1.TTestProxy.Create(True);
  // Indique qu'on n'attend pas avant de tester
  TestProxy[i].WaitB4Test := AttendreAvantDeTester;
  // On teste la première ligne car on vient de l'insèrer au début
  TestProxy[i].ProxyIndex := LigneATester;
  // Lance le test
  TestProxy[i].Resume;
end;

// Teste la connection à tous les proxy dans le ListView
procedure TForm1.TesterTousLesProxies();
var
  i: Integer;
begin
  // Pour tous les proxy du ListView
  for i:=0 to Form1.ListView1.items.count-1 do
  begin
    // Si on ferme le programme (FormCloseQuery), on arrête la boucle
    if FermetureDemandee then exit;
    // Lance le test de la connection au proxy
    TesterLeProxy(i, 2500 * i);
  end;
end;


// Met une croix au proxy actuel et enlève la croix aux autres
procedure TForm1.RafraichirProxies();
var
  CurrProxy : String;
  ProxyActive: boolean;
   i: integer;
begin
  // Si une sauvegarde des proxy existe
  if FileExists(FICHIERPROXY) then
  begin
    // Récupère si le proxy est actif dans Internet Explorer
    ProxyActive := LireIntegerDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyEnable') = 1;
    // On recupere l'adresse du proxy
    CurrProxy := LireStringDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyServer');
    // Pour chaques adresses de la liste des proxy
    for i := 0 to ListView1.items.count - 1 do
    begin
      // On coche la case du proxy actuel (si actif) et decoche les autres
      ListView1.Items.Item[i].Checked := (ListView1.Items.Item[i].Caption = CurrProxy) and ProxyActive;
    end;
  end;
  Application.ProcessMessages;
end;


// Stop tous les tests de connection aux proxies
procedure TForm1.StoperTousLesTest();
var i:integer;
begin
  // Arrête la boucle dans la procedure TesterTousLesProxies();
  FermetureDemandee := True;
  // Ferme toutes les connections
  for i:=0 to Length(IdHTTPArray) do
  begin
    try
      if Assigned(IdHTTPArray[i]) then
        if IdHTTPArray[i].Connected then
          IdHTTPArray[i].Disconnect;
    except
    end;
  end;
  // Stope tous les threads
  for i:=0 to Length(TestProxy) do
  begin
    try
      if Assigned(TestProxy[i]) then
      begin
        TestProxy[i].Suspend;
        TestProxy[i].Terminate;
      end;
    except
    end;
  end;
end;         

//=============================================================
//                DEBUT DES FONCTIONS DU THREAD
//=============================================================
// Retourne le temps écoulé en secondes entre deux dates
function TTestProxy.TempsEcoule(ElipsedTime: extended):integer;
resourcestring
  strSec = 'ss';
begin
  if ElipsedTime > 0 then
    Result := StrToInt(FormatDateTime(strSec,ElipsedTime))
  else
    Result := 0;
end;

// Execution du thread
procedure TTestProxy.Execute;
begin
  Sleep(WaitB4Test);
  // Libère le thread de la mémoire à la fin de l'execution
  FreeOnTerminate:=True;
  // On teste la connection au proxy
  TestProxy(ProxyIndex);
end;

// Fonction qui teste un proxy
function TTestProxy.RequeteAuProxy(ProxyAdresse:string; ProxyPort:integer; URL:string; TextATrouver:string):boolean;
var
  Reponse:string;
  i: integer;
begin
  // Ajout d'une ligne dans le tableau des connections
  i :=  Length(IdHTTPArray);
  SetLength(IdHTTPArray, i+2);
  // Creation d'une connection avec IdHTTP de Indy 9
  // On met dans un tableau dynamique pour pouvoir tester tous les proxy à la fois
  IdHTTPArray[i] := TIdHTTP.Create(nil);
  IdHTTPArray[i].HandleRedirects := True;
  IdHTTPArray[i].RedirectMaximum := 30;
  IdHTTPArray[i].ReadTimeout := 0;
  IdHTTPArray[i].AllowCookies := True;
  IdHTTPArray[i].AuthRetries := 10;
  IdHTTPArray[i].ProxyParams.ProxyServer := ProxyAdresse;
  IdHTTPArray[i].ProxyParams.ProxyPort := ProxyPort;
  try
    // On récupère le contenu du lien au travers du proxy
    Reponse := IdHTTPArray[i].Get(URL);    
  except
    // if idhttp1.ResponseCode = 200 then  // Code erreur
    //   showmessage('Temps de reponse accorde depasse (timeout)');
  end;
  // On libère dans la mémoire la connection IdHTTP
  IdHTTPArray[i].Free;
  // On retourne si on trouve bien le bon contenu dans la page
  result := Pos(TextATrouver, Reponse) > 0;
end;


// On teste le proxy sur un site web qui fontionnera tout le temps (Google^^)
// Donc on va sur l'adresse 'http://www.google.com' et on verifie
// que le contenu de comporte '<title>Google</title>'
procedure TTestProxy.TestProxy(Ligne: integer);
var
  i, ProxPort: integer;
  ProxAddr, URL, TextATrouver: string;
  Start:TDateTime;
  Stop:TDateTime;
  Diff:extended;
begin
  With Form1 do
  begin
    i := Ligne;
    // On affiche le proxy comme étant en cours de test
    EditerLigne(ListView1.Items.Item[i],    // Item (ou ligne) du listView
                i,                          // Numéro de ligne
                INCONNU,                    // Numéro de l'image
                '',                         // Adresse du proxy
                StatusProxy[TESTENCOURS]);  // Texte du status
    // On prend l'IP du proxy selectionne
    ProxAddr := ExtraitAdresseIP(ListView1.Items.Item[i].Caption);
    // On prend le port du proxy selectionne
    // Extrait port retourne 0 si le format du port n'est pas un entier
    ProxPort := ExtraitPort(ListView1.Items.Item[i].Caption);
    if ProxPort = 0 then
      // Affiche que l'adresse du proxy est incorrecte
      EditerLigne(ListView1.Items.Item[i],   // Item (ou ligne) du listView
                  i,                         // Numéro de ligne
                  FORMATERROR,               // Numéro de l'image
                  '',                        // Adresse du proxy
                  StatusProxy[FORMATERROR]); // Texte du status
    if ProxPort <> 0 then
    begin
      // On teste le proxy en ouvrant ce lien
      URL := 'http://www.google.com';
      // On verifie le contenu que le proxy nous donne
      TextATrouver := '<title>Google</title>';     
      // Pour déterminer le temps de réponse du proxy,
      // on mémorise l'heure (à la seconde près) avant le test
      Start := Now();
      // On lance le teste du proxy
      if RequeteAuProxy(ProxAddr, ProxPort, URL, TextATrouver) then
      begin
        // On mémorise l'heure de fin du test
        Stop := Now();
        // On calcul le temps écoulé
        Diff := Stop - Start;
        // Si le proxy à répondu avant 5 secondes
        if TempsEcoule(Diff) <= 5 then
          // On affiche le proxy en vert pour indiquer que c'est un bon proxy
          EditerLigne(ListView1.Items.Item[i], // Item (ou ligne) du listView
                      i,                       // Numéro de ligne
                      ACTIF,                   // Numéro de l'image
                      '',                      // Adresse du proxy
                      StatusProxy[ACTIF])      // Texte du status
        else
          // Le proxy à répondu après 5 secondes, on l'affiche comme étant lent
          EditerLigne(ListView1.Items.Item[i], // Item (ou ligne) du listView
                      i,                       // Numéro de ligne
                      LENT,                    // Numéro de l'image
                      '',                      // Adresse du proxy
                      StatusProxy[LENT]);      // Texte du status
      end
      // Le proxy n'a pas répondu
      else begin
        // On mémorise l'heure de fin du test
        Stop := Now();
        // On calcul le temps écoulé
        Diff := Stop - Start;
        // Si on a un status rapide en moins de 5 secondes,
        if TempsEcoule(Diff) <= 5 then
        // Le proxy n'a pas répondu, on l'affiche éteint
        EditerLigne(ListView1.Items.Item[i],  // Item (ou ligne) du listView
                    i,                        // Numéro de ligne
                    ETEINT,                   // Numéro de l'image
                    '',                       // Adresse du proxy
                    StatusProxy[ETEINT])     // Texte du status
        else
        // Le proxy n'a pas répondu, on l'affiche éteint
        EditerLigne(ListView1.Items.Item[i],  // Item (ou ligne) du listView
                    i,                        // Numéro de ligne
                    ETEINT,                   // Numéro de l'image
                    '',                       // Adresse du proxy
                    StatusProxy[TIMEOUT]);     // Texte du status
      end;
    end;
  end;
end;

//=============================================================
//                 LES FONCTIONS DES BOUTONS
//=============================================================

// Bouton "Ajouter" un proxy dans la liste
procedure TForm1.ButtonAjouterClick(Sender: TObject);
var
  i: integer;
  AddProxy: string;
begin
  AddProxy := '';
  // On demande a l'utilisateur d'entrer un proxy
  if not inputQuery('Proxy (AdresseIP:Port) :',
                    'Entrer l''adresse du proxy sous forme AdresseIP:Port',
                    AddProxy) then
     // Si on appuye sur la touche "Annuler", on sort
     exit;
  // On supprime les caracteres non autorises comme les espaces
  AddProxy := NettoyeAdresseProxyEntreParUtilisateur(AddProxy);
  // On verifie que l'utilisateur a bien rentre le caractere de delimitation ':' 
  if Pos(':',AddProxy) = 0 then
  begin
    ShowMessage('Adresse invalide ');
    exit;
  end;
  // Ajoute le proxy en debut de liste
  EditerLigne(ListView1.Items.Insert(0), // Item (ou ligne) du listView
              0,                         // Numéro de ligne
              INCONNU,                   // Numéro de l'image
              AddProxy,                  // Adresse du proxy
              StatusProxy[INCONNU]);     // Texte du status
  // Sauvegarde la liste
  SauvegarderProxies();
  // Coche la case du proxy actuel
  RafraichirProxies();
  // Vérifie la connection au proxy
  // On prend la dernière position du tableau TestProxy
  i := Length(TestProxy);
  // On agrandi le tableau
  SetLength(TestProxy, i+1);
  // Créer le thread du test de la connection
  TestProxy[i] := Unit1.TTestProxy.Create(True);
  // Indique qu'on n'attend pas avant de tester
  TestProxy[i].WaitB4Test := 0;
  // On teste la première ligne car on vient de l'insèrer au début
  TestProxy[i].ProxyIndex := 0;
  // Lance le test
  TestProxy[i].Resume;
end;


// Bouton "Modifier" un proxy dans la liste
procedure TForm1.Modifier1Click(Sender: TObject);
var
  ModifProxy: string;
  i: integer;
begin
  // Recupere la ligne selectionnee
  i := ListView1.Selected.Index;
  // Si aucune ligne selectionnee, on sort de la procedure
  if i = -1 then exit;
  // On recupere le text de la ligne selectionne
  ModifProxy := ListView1.Items.Item[i].Caption;
  // On fait apparaitre la zone text pour modifier la ligne
  if not inputQuery('Proxy (AdresseIP:Port) :',
              'Entrer l''adresse du proxy sous forme AdresseIP:Port',
              ModifProxy) then
    // Si on appuye sur la touche "Annuler", on sort
    exit;
  // On supprime les caracteres non autorises comme les espaces 
  ModifProxy := NettoyeAdresseProxyEntreParUtilisateur(ModifProxy);
  // On verifie que l'utilisateur a bien rentre le caractere de delimitation ':'
  if Pos(':',ModifProxy) = 0 then
  begin
    ShowMessage('Adresse invalide '+ModifProxy);
    exit;
  end;
  // On modifie l'adresse du proxy
  ListView1.Items.Item[i].Caption := ModifProxy;
  // On sauvegarde la liste des proxy
  SauvegarderProxies();
  // Si on a modifie le proxy en cours d'utilisation dans Internet Explorer
  if  ListView1.Items.Item[i].Checked then
    // On indique la nouvelle adresse du proxy
    EcrireStringDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyServer', ListView1.Items.Item[i].Caption);
  // Lance le test de la connection au proxy
  TesterLeProxy(0, 0);
end;


// Bouton "Supprimer" un proxy dans la liste
procedure TForm1.ButtonSupprimerClick(Sender: TObject);
var
  i: integer;
  Question: string;
begin
  // Si aucune ligne selectionnee, on sort de la procedure
  if ListView1.SelCount = 0 then exit;
  // Demande de confirmation de suppression
  MessageBeep(MB_ICONQUESTION);
  Question := 'Etes-vous sur de vouloir supprimer ces '+IntToStr(ListView1.SelCount)+' serveurs proxy?';
  if MessageDlg(Question, mtConfirmation, [mbYes, mbNo], 0) = IDYes then
  begin
    for i:=0 to ListView1.Items.Count-1 do
      if ListView1.Items.Item[i].Selected then
      begin
        // Si l'element a supprimer etait le proxy actuel
        if ListView1.Items.Item[i].Checked then
          // On desactive le proxy dans le registre
          EcrireIntegerDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyEnable', 0);
        // On efface l'element selectionne
        ListView1.Items.Item[i].Delete;
       // On sauvegarde la liste des proxy
       SauvegarderProxies;
     end;
  end;
end;


// Bouton "Rafraichir" la liste des proxy
procedure TForm1.ToutRafraichir1Click(Sender: TObject);
begin
  // Arrête la boucle dans la procedure TesterTousLesProxies();
  FermetureDemandee := True;
  // Ferme toutes les connections HTTP et les threads
  StoperTousLesTest();
  // Coche la case au proxy actuel
  RafraichirProxies();
  // Teste la connection au proxy
  FermetureDemandee := False;
  TesterTousLesProxies();
end;

// Bouton cocher
procedure TForm1.Dfinircommeproxy1Click(Sender: TObject);
begin
  // Si aucune ligne selectionnee, on sort de la procedure
  if ListView1.SelCount = 0 then exit;
  // On ecrit dans le registre l'adresse IP du proxy selectionne
  EcrireStringDansRegistre(INTERNETSETTINGSREGPATH,
                           'ProxyServer',
                           ListView1.Items.Item[ListView1.Selected.Index].Caption);
  // On active le proxy
  EcrireIntegerDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyEnable', 1);

  RafraichirProxies;
end;


// Bouton "Tout decocher" de la liste des proxy
procedure TForm1.Dcocher1Click(Sender: TObject);
begin
  // On desactive les proxy dans le registre
  EcrireIntegerDansRegistre(INTERNETSETTINGSREGPATH, 'ProxyEnable', 0);
  // On rafraichit
  form1.RafraichirProxies();
end;


// Bouton Ouvrir Internet Explorer sur la page d'acueil
procedure TForm1.OuvrirInternetExplorer1Click(Sender: TObject);
begin
  ShellExecute(0,'OpEn','iexplore.exe','','null',SW_NORMAL);
end;


// Bouton Ouvrir Internet Explorer sur le dernier lien ouvert
procedure TForm1.Dernierlienentre1Click(Sender: TObject);
begin
  ShellExecute(0,'OpEn','iexplore.exe',PChar(LireStringDansRegistre(LASTURLTYPEDPATH,'url1')),'null',SW_NORMAL);
end;


// Bouton Rafraichir la sélection
procedure TForm1.Rafraichirlaslection1Click(Sender: TObject);
var
  i, NdrProxyATester: integer;
begin
  // Si aucune ligne selectionnee, on sort de la procedure
  if ListView1.SelCount = 0 then exit;
  // Arrête la boucle dans la procedure TesterTousLesProxies();
  FermetureDemandee := True;
  // Ferme toutes les connections HTTP et les threads
  StoperTousLesTest();
  NdrProxyATester := 0;
  FermetureDemandee := False;
  FermetureDemandee := False;
  for i:=0 to ListView1.Items.Count-1 do
    if ListView1.Items.Item[i].Selected then
    begin
      TesterLeProxy(i, NdrProxyATester * 2500);
      inc(NdrProxyATester);
    end;
end;


// Bouton "Arrêter l'actualisation"
procedure TForm1.Arrterlactualisation1Click(Sender: TObject);
begin
  // Arrête la boucle dans la procedure TesterTousLesProxies();
  FermetureDemandee := True;
  // Ferme toutes les connections HTTP et les threads
  StoperTousLesTest();   
end;


// Bouton '?' à propos
procedure TForm1.AProposClick(Sender: TObject);
var Question: string;
begin
  MessageBeep(MB_ICONQUESTION);
  Question := 'Vous aller être redirigé sur le site DelphiFr, voulez-vous continuer?';
  if MessageDlg(Question, mtConfirmation, [mbYes, mbNo], 0) = IDYes then
    ShellExecute(0,'OpEn','iexplore.exe',PChar('http://www.delphifr.com/codes/PROXY-SELECTOR-PRATIQUE-SI-VOUS-UTILISEZ-PLUS-PROXY_45233.aspx'),'null',SW_NORMAL);
end;


// Bouton quitter
procedure TForm1.Quitter1Click(Sender: TObject);
begin
  StoperTousLesTest();
  Application.Terminate;
end;


// Import de la liste des proxy depuis un fichier
procedure TForm1.Importerlisteproxy1Click(Sender: TObject);
var
  Fichier        : textfile;
  texte          : string;
  Question: string;
begin
  if not OpenDialog1.Execute then exit;
  MessageBeep(MB_ICONQUESTION);
  Question := 'Voulez-vous importer ce fichier à la fin de la liste existante?'+#13#10
             +'Cliquez sur Oui pour importer le fichier à la fin de la liste.'+#13#10
             +'Cliquez sur Non pour tout effacer avant d''importer.';
  if MessageDlg(Question, mtConfirmation, [mbYes, mbNo], 0) = IDNo then
    ListView1.Items.Clear;

  assignFile(Fichier, OpenDialog1.FileName);
  reset(Fichier); // ouvre en lecture
  while not eof(Fichier) do
  begin
    readln(Fichier, texte);
    // On ajoute le proxy en fin de liste
    EditerLigne(ListView1.Items.Add,       // Item (ou ligne) du listView
                ListView1.Items.Count,     // Numéro de ligne
                INCONNU,                   // Numéro de l'image
                texte,                     // Adresse du proxy
                StatusProxy[INCONNU]);     // Texte du status

  end;
  closefile(Fichier);
end;


// Export de la liste des proxy dans un fichier
procedure TForm1.Exporterlisteproxy1Click(Sender: TObject);
var
  i: Integer;
  Fp : textfile;
  Question: string;  
begin
  if not SaveDialog1.Execute then exit;
  if FileExists(SaveDialog1.FileName) then
  begin
    MessageBeep(MB_ICONQUESTION);
    Question := 'Le fichier "'+SaveDialog1.FileName+'" exists déjà.'#13#10
               +'Voulez-vous le remplacer?';
    if MessageDlg(Question, mtConfirmation, [mbYes, mbNo], 0) = IDNo then
      exit
  end;
  assignFile(Fp, SaveDialog1.FileName);
  reWrite(Fp);
  for i := 0 to ListView1.items.count - 1 do
  begin
    Writeln(Fp, ListView1.Items.Item[i].Caption);
  end;
  closefile(Fp);
end;

// Fonction qui execute un programme et attend sa fermeture
function LaunchAndWait(sFile: String; wShowWin: Word): Boolean;
var
  cExe: array [0..255] of Char;
  sExe: string;
  pcFile: PChar;
  StartInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  Result:=True;
  FindExecutable(PChar(ExtractFileName(sFile)), PChar(ExtractFilePath(sFile)), cExe);
  sExe:= string(cExe);
  if UpperCase(ExtractFileName(sExe))<>UpperCase(ExtractFileName(sFile))
  then pcFile:=PChar(' "'+sFile+'"')
  else pcFile:=nil;
  ZeroMemory(@StartInfo, SizeOf(StartInfo));
  with StartInfo do begin
    cb:=SizeOf(StartInfo);
    dwFlags:=STARTF_USESHOWWINDOW;
    wShowWindow:=wShowWin;
  end;
  if CreateProcess(PChar(sExe), pcFile, nil, nil, True, 0, nil, nil, StartInfo, ProcessInfo)
  then WaitForSingleObject(ProcessInfo.hProcess, INFINITE)
  else Result:=False;
end;


// Bouton "Editer les proxies depuis le bloc-note"
procedure TForm1.Editerlalistedesproxydansleblocnote1Click(
  Sender: TObject);
begin
  ShowMessage('La liste des proxies sera rechargée automatiquement à la fermeture du bloc-note.');
  LaunchAndWait(ExtractFileDir(Application.Exename)+'\'+FICHIERPROXY, SW_SHOWNORMAL);
  StoperTousLesTest();
  // On charge la liste des proxy dans le listView
  ChargerProxies();
  // On coche la case du proxy actuel
  RafraichirProxies();
  // Permet d'executer la boucle dans TesterTousLesProxies();
  FermetureDemandee := False;
  // On lance le test de la connection aux proxies
  TesterTousLesProxies();
end;

end.
