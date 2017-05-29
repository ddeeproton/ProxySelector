; Setup ProxySelector
!define /file VERSION version.txt

;--------------------------------
;Include Modern UI

!include "MUI2.nsh"

;--------------------------------

; The name of the installer
Name "ProxySelector ${VERSION}"

; The file to write
OutFile "ProxySelectorSetup_${VERSION}.exe"

; The default installation directory
;InstallDir "$PROGRAMFILES\ProxySelector"
InstallDir "C:\ProxySelector"

ShowInstDetails show

; Set to silent mode
;SilentInstall silent

; Request application privileges for Windows Vista
;RequestExecutionLevel admin


BGGradient 000000 000080 FFFFFF 
InstallColors 8080FF 000030 
XPStyle on

;--------------------------------
;Interface Settings

!define MUI_ABORTWARNING

!define MUI_ICON "proxy.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "NSISBanner.bmp"
!define MUI_HEADERIMAGE_LEFT
;--------------------------------

; Pages

#Page directory
#Page instfiles

;--------------------------------
;Languages

  #!insertmacro MUI_LANGUAGE "English" ;first language is the default language
  !insertmacro MUI_LANGUAGE "French"
  !define MUI_LANGDLL_ALLLANGUAGES
;--------------------------------
;Pages
  #!insertmacro MUI_PAGE_WELCOME
  #!insertmacro MUI_PAGE_LICENSE "${NSISDIR}\Docs\Modern UI\License.txt"
  !insertmacro MUI_PAGE_LICENSE "License.txt"
  #!insertmacro MUI_PAGE_COMPONENTS
  
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  #!insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  #!insertmacro MUI_UNPAGE_FINISH

;--------------------------------

; The stuff to install
Section "" ;No components page, name is not important
  Call IsSilent
  Pop $0
  StrCmp $0 1 goSilent1 goNotSilent1
  goSilent1:
	Sleep 5000
  goNotSilent1:
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File "ProxySelector.exe"
  File "FICHIERPROXY.txt"
  File "ProxySelector(source).zip"
  
  
  
  CreateDirectory "$SMPROGRAMS\ProxySelector"
  #CreateShortCut "$SMPROGRAMS\ProxySelector\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0
  CreateShortCut "$SMPROGRAMS\ProxySelector\ProxySelector.lnk" "$INSTDIR\ProxySelector.exe" "" "$INSTDIR\ProxySelector.exe" 0
  CreateShortCut "$DESKTOP\ProxySelector.lnk" "$INSTDIR\ProxySelector.exe" "" "$INSTDIR\ProxySelector.exe" 0
  CreateShortCut "$SMPROGRAMS\ProxySelector\Uninstall.lnk" "$INSTDIR\uninstall_ProxySelector.exe" "" "$INSTDIR\uninstall_ProxySelector.exe" 0

  WriteRegStr HKLM "SOFTWARE\ProxySelector" "" $INSTDIR
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ProxySelector" "DisplayName" "ProxySelector (remove only)"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ProxySelector" "UninstallString" '"$INSTDIR\uninstall_ProxySelector.exe"'
  
  
  
  WriteUninstaller "uninstall_ProxySelector.exe"
  #ExecShell "open"  '"${NSISDIR}\ProxySelector_TestVersion.exe"'
  #ExecWait '"${NSISDIR}\ProxySelector_TestVersion.exe"'
  #Exec '"${NSISDIR}\ProxySelector_TestVersion.exe"'

  StrCmp $0 1 goSilent2 goNotSilent2
  goSilent2:
	  Exec 'ProxySelector.exe /background' # equivaut à IF is silent /S
	  Quit
	  
  goNotSilent2:
  Exec 'ProxySelector.exe /autostart'
  Quit
SectionEnd ; end the section

Function .onInit

  !insertmacro MUI_LANGDLL_DISPLAY

FunctionEnd




 
Section
  # do stuff
SectionEnd
 
Function IsSilent
  Push $0
  Push $CMDLINE
  Push "/S"
  Call StrStr
  Pop $0
  StrCpy $0 $0 3
  StrCmp $0 "/S" silent
  StrCmp $0 "/S " silent
    StrCpy $0 0
    Goto notsilent
  silent: StrCpy $0 1
  notsilent: Exch $0
FunctionEnd
 
Function StrStr
  Exch $R1 ; st=haystack,old$R1, $R1=needle
  Exch    ; st=old$R1,haystack
  Exch $R2 ; st=old$R1,old$R2, $R2=haystack
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1=needle
  ; $R2=haystack
  ; $R3=len(needle)
  ; $R4=cnt
  ; $R5=tmp
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 done
    StrCmp $R5 "" done
    IntOp $R4 $R4 + 1
    Goto loop
  done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1
FunctionEnd





# Uninstall section.

Section "Uninstall"


	  DeleteRegKey HKLM "SOFTWARE\ProxySelector"
	  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\ProxySelector"

	  RMDir /r "$SMPROGRAMS\ProxySelector"


	  #Delete "$INSTDIR\ProxySelector.exe"
	  #Delete "$INSTDIR\uninstall_ProxySelector.exe"
	  Delete "$DESKTOP\ProxySelector.lnk"


	  RMDir /r $INSTDIR

SectionEnd
