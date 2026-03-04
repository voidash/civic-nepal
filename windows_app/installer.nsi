; Nagarik Patro — Windows Installer
; Built with NSIS (Nullsoft Scriptable Install System)

Unicode True

!define APP_NAME    "Nagarik Patro"
!define APP_EXE     "NagarikPatro.exe"
!define FLUTTER_EXE "nagarik_calendar.exe"
!define PUBLISHER   "Nagarik Patro"
!define REG_UNINST  "Software\Microsoft\Windows\CurrentVersion\Uninstall\NagarikPatro"
!define REG_APATHS  "SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\${FLUTTER_EXE}"

; Version injected at build time via /DAPP_VERSION=x.y.z
!ifndef APP_VERSION
  !define APP_VERSION "1.0.0"
!endif

Name          "${APP_NAME} ${APP_VERSION}"
OutFile       "NagarikPatro-windows-x64-v${APP_VERSION}-setup.exe"
InstallDir    "$LOCALAPPDATA\Programs\NagarikPatro"
InstallDirRegKey HKCU "${REG_UNINST}" "InstallLocation"

; User-level install — no UAC prompt required
RequestExecutionLevel user

;---------------------------------------------------------------------------
; Pages
;---------------------------------------------------------------------------
!include "MUI2.nsh"

!define MUI_ABORTWARNING
!define MUI_WELCOMEPAGE_TITLE  "Install ${APP_NAME} ${APP_VERSION}"
!define MUI_WELCOMEPAGE_TEXT   "This will install the ${APP_NAME} system tray calendar and the full Nagarik Patro app on your computer.$\r$\n$\r$\nClick Next to continue."
!define MUI_FINISHPAGE_RUN          "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT     "Launch Nagarik Patro"
!define MUI_FINISHPAGE_SHOWREADME   ""
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

;---------------------------------------------------------------------------
; Install
;---------------------------------------------------------------------------
Section "Nagarik Patro" SEC_MAIN
  SectionIn RO  ; Required section

  ; Stop any running instance before overwriting files
  ExecWait 'taskkill /F /IM "${APP_EXE}"'      $0
  ExecWait 'taskkill /F /IM "${FLUTTER_EXE}"'  $0

  SetOutPath "$INSTDIR"
  ; PUBLISH_DIR is passed as an absolute path by the build script
  File /r "${PUBLISH_DIR}\*"

  ; Start Menu shortcut
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortCut  "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" \
                  "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0

  ; Register App Paths so the tray widget's registry lookup finds the Flutter exe
  WriteRegStr HKCU "${REG_APATHS}" "" "$INSTDIR\${FLUTTER_EXE}"
  WriteRegStr HKCU "${REG_APATHS}" "Path" "$INSTDIR"

  ; Add/Remove Programs entry
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  WriteRegStr   HKCU "${REG_UNINST}" "DisplayName"     "${APP_NAME}"
  WriteRegStr   HKCU "${REG_UNINST}" "DisplayVersion"  "${APP_VERSION}"
  WriteRegStr   HKCU "${REG_UNINST}" "Publisher"       "${PUBLISHER}"
  WriteRegStr   HKCU "${REG_UNINST}" "InstallLocation" "$INSTDIR"
  WriteRegStr   HKCU "${REG_UNINST}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKCU "${REG_UNINST}" "NoModify"        1
  WriteRegDWORD HKCU "${REG_UNINST}" "NoRepair"        1
SectionEnd

;---------------------------------------------------------------------------
; Uninstall
;---------------------------------------------------------------------------
Section "Uninstall"
  ExecWait 'taskkill /F /IM "${APP_EXE}"'     $0
  ExecWait 'taskkill /F /IM "${FLUTTER_EXE}"' $0

  RMDir /r "$INSTDIR"

  Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
  RMDir  "$SMPROGRAMS\${APP_NAME}"

  ; Remove launch-at-login entry if set
  DeleteRegValue HKCU "Software\Microsoft\Windows\CurrentVersion\Run" "NagarikPatro"

  DeleteRegKey HKCU "${REG_APATHS}"
  DeleteRegKey HKCU "${REG_UNINST}"
SectionEnd
