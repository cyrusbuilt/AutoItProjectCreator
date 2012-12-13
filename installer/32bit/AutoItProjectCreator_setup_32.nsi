# ----------------------------------------------------------------------------
# Name ...........: AutoItProjectCreator_setup_64.nsi
# Script Version .: 1.0.9.2
# NSIS Version ...: 2.46
# Date ...........: 1/25/2011
# Modified .......: 2/14/2011
# Author .........: Chris Brunner (CyrusBuilt)
# Copyright ......: Released under GPL v2.
# Script Function : Installer for the 32bit version of AutoItProjectCreator.
# Dependencies ...: MultiUser.nsh, Sections.nsh, MUI2.nsh, LogicLib.nsh and
# FileAssociation.nsh (3rd party).
# ----------------------------------------------------------------------------

Name AutoItProjectCreator

SetCompressor zlib

# General Symbol Definitions
!define REGKEY "SOFTWARE\$(^Name)"
!define VERSION 1.0.0.4
!define COMPANY CyrusBuilt
!define URL http://www.cyrusbuilt.net
!define PRODUCT_NAME "AutoItProjectCreator"

# MultiUser Symbol Definitions
!define MULTIUSER_EXECUTIONLEVEL Highest
!define MULTIUSER_MUI
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME MultiUserInstallMode
!define MULTIUSER_INSTALLMODE_COMMANDLINE
!define MULTIUSER_INSTALLMODE_INSTDIR "${PRODUCT_NAME}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY "${REGKEY}"
!define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_VALUE "Path"

# MUI Symbol Definitions
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_LICENSEPAGE_RADIOBUTTONS
!define MUI_STARTMENUPAGE_REGISTRY_ROOT HKLM
!define MUI_STARTMENUPAGE_REGISTRY_KEY ${REGKEY}
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME StartMenuGroup
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "AutoIt v3\SciTE\${PRODUCT_NAME}"
!define MUI_FINISHPAGE_RUN "$INSTDIR\AutoItProjectCreator32.exe"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.txt"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

# Included files
!include "MultiUser.nsh"
!include "Sections.nsh"
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileAssociation.nsh"

# Variables
Var StartMenuGroup

# Installer pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\license.txt"
!insertmacro MULTIUSER_PAGE_INSTALLMODE
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

# Installer languages
!insertmacro MUI_LANGUAGE English

# Installer attributes
OutFile AutoItProjectCreator_setup_32.exe
InstallDir "${PRODUCT_NAME}"
CRCCheck on
XPStyle on
ShowInstDetails show
VIProductVersion ${VERSION}
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductVersion" "${VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "${COMPANY}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyWebsite" "${URL}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" ""
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Released under GPLv2."
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalTrademarks" ""
InstallDirRegKey HKLM "${REGKEY}" Path
ShowUninstDetails show

# Main installation section.
Section -Main SEC0000
    # First we have to determine where SciTE4AutoIt3 is installed. Since AutoItProject creator
    # is meant to be an addon to AutoItV3 and SciTE, we are going to install into a subdirectory
    # of the SciTE installation path by default.
    DetailPrint "Getting SciTE4AutoIt3 path..."
    Call getSciteDir
    Pop $0
    ${If} $0 == ""
        MessageBox MB_OK|MB_ICONEXCLAMATION \
        "Unable to locate SciTE for AutoItV3.$\r$\n Either AutoItV3 or the SciTE script editor was not found."
        Abort
    ${Else}
        # We have a valid path, modify our installation path accordingly.
        StrCpy $INSTDIR "$0\${PRODUCT_NAME}"
    ${EndIf}

    # Unpack the files into the installation directory and write the reg keys.
    SetOutPath $INSTDIR
    SetOverwrite on
    File "..\..\AutoItProjectCreator.au3"
    File "..\..\AutoItProjectCreator32.exe"
    File "..\..\AutoItProjectCreator.ini"
    File "..\..\BaseApplicationConfig.ini"
    File "..\..\BaseProjectDefinition.au3proj"
    File "..\..\license.txt"
    File "..\..\README.txt"
    File "..\..\changelog.txt"
    File "..\..\au3.properties.aipc32"
    WriteRegStr HKLM "${REGKEY}\Components" Main 1
    
    # Check to see if the AutoIt properties file for SciTE exists. If so, ask the user if they want to
    # integrate AutoItProjectCreator with SciTE. If the user chooses "Yes" then we backup the original
    # au3.properties file to au3.properties.old and then copy the new properties file in its place.
    # The new au3.properties file contains added code that puts additional entries in the "Tools"
    # menu in SciTE for creating a new project or opening an existing one.
    IfFileExists "$0\Properties\au3.properties" propsExist propsNotExist
    propsExist:
        MessageBox MB_YESNO|MB_ICONQUESTION \
        "Do you wish to integrate ${PRODUCT_NAME} with SciTE?$\r$\nIf yes, your existing au3.properites file will be copied to au3.properites.old." \
        IDNO noIntegrate
            Rename "$0\Properties\au3.properties" "$0\Properties\au3.properties.old"
            SetOutPath "$0\Properties"
            File "..\..\au3.properties.aipc32"
            Rename "$0\Properties\au3.properties.aipc32" "$0\Properties\au3.properties"
        noIntegrate:
    propsNotExist:
SectionEnd

# Post-installation section.
Section -post SEC0001
    # Create the uninstaller.
    WriteRegStr HKLM "${REGKEY}" Path $INSTDIR
    SetOutPath $INSTDIR
    WriteUninstaller "$INSTDIR\uninstall.exe"
    
    # Create short cuts.
    SetOutPath "$SMPROGRAMS\$StartMenuGroup"
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Create New Project.lnk" "$INSTDIR\AutoItProjectCreator32.exe"
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Open Existing Project.lnk" "$INSTDIR\AutoItProjectCreator32.exe" "/opendlg"
    DetailPrint "Writing file $INSTDIR\${PRODUCT_NAME}.url..."
    WriteIniStr "$INSTDIR\${PRODUCT_NAME}.url" "InternetShortcut" "URL" "${URL}"
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Website.lnk" "$INSTDIR\${PRODUCT_NAME}.url"
    CreateShortcut "$SMPROGRAMS\$StartMenuGroup\Uninstall $(^Name).lnk" "$INSTDIR\uninstall.exe"
    
    # Write the apropriate registry keys.
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayName "$(^Name)"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayVersion "${VERSION}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" Publisher "${COMPANY}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" URLInfoAbout "${URL}"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" DisplayIcon "$INSTDIR\uninstall.exe"
    WriteRegStr HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" UninstallString "$INSTDIR\uninstall.exe"
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" NoModify 1
    WriteRegDWORD HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)" NoRepair 1
    
    # Associate *.autoitproj files with AutoItProjectCreator.
    DetailPrint "Registering *.au3proj filetype..."
    ${registerExtension} "$INSTDIR\AutoItProjectCreator32.exe" ".au3proj" "AutoIt Project File (.au3proj)"
SectionEnd

# Macro for selecting uninstaller sections
!macro SELECT_UNSECTION SECTION_NAME UNSECTION_ID
    Push $R0
    ReadRegStr $R0 HKLM "${REGKEY}\Components" "${SECTION_NAME}"
    StrCmp $R0 1 0 next${UNSECTION_ID}
    !insertmacro SelectSection "${UNSECTION_ID}"
    GoTo done${UNSECTION_ID}
next${UNSECTION_ID}:
    !insertmacro UnselectSection "${UNSECTION_ID}"
done${UNSECTION_ID}:
    Pop $R0
!macroend

# Main uninstaller section.
Section /o -un.Main UNSEC0000
    # Delete all application files and reg keys.
    Delete /REBOOTOK "$INSTDIR\license.txt"
    Delete /REBOOTOK "$INSTDIR\README.txt"
    Delete /REBOOTOK "$INSTDIR\BaseProjectDefinition.au3proj"
    Delete /REBOOTOK "$INSTDIR\BaseApplicationConfig.ini"
    Delete /REBOOTOK "$INSTDIR\AutoItProjectCreator.ini"
    Delete /REBOOTOK "$INSTDIR\AutoItProjectCreator32.exe"
    Delete /REBOOTOK "$INSTDIR\AutoItProjectCreator.au3"
    Delete /REBOOTOK "$INSTDIR\changelog.txt"
    Delete /REBOOTOK "$INSTDIR\au3.properties.aipc32"
    Delete /REBOOTOK "$INSTDIR\${PRODUCT_NAME}.url"
    DeleteRegValue HKLM "${REGKEY}\Components" Main
    
    # Restore the original au3.properties file if the backup exists.
    Call un.getSciteDir
    Pop $0
    ${IfNot} $0 == ""
        IfFileExists "$0\Properties\au3.properties.old" restore doNotRestore
        restore:
            Delete "$0\Properties\au3.properties"
            Rename "$0\Properties\au3.properties.old" "$0\Properties\au3.properties"
        doNotRestore:
    ${EndIf}
SectionEnd

# Post-uninstallation section.
Section -un.post UNSEC0001
    # Disassociate the *.autoproj filetype.
    DetailPrint "Unregistering *.au3proj filetype..."
    ${unregisterExtension} ".au3proj" "AutoIt Project File (.au3proj)"

    # Remove all shortcuts and uninstaller.
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\Uninstall $(^Name).lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\Create New Project.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\Open Existing Project.lnk"
    Delete /REBOOTOK "$SMPROGRAMS\$StartMenuGroup\Website.lnk"
    Delete /REBOOTOK "$INSTDIR\uninstall.exe"
    
    # Remove all reg keys.
    DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$(^Name)"
    DeleteRegValue HKLM "${REGKEY}" Path
    DeleteRegKey /IfEmpty HKLM "${REGKEY}\Components"
    DeleteRegKey /IfEmpty HKLM "${REGKEY}"
    
    # Remove start menu and application directories.
    RmDir /REBOOTOK $SMPROGRAMS\$StartMenuGroup
    RmDir /REBOOTOK $INSTDIR
SectionEnd

# Installer init callback.
Function .onInit
    InitPluginsDir
    !insertmacro MULTIUSER_INIT
    !insertmacro MUI_LANGDLL_DISPLAY
    StrCpy $StartMenuGroup "AutoIt v3\SciTE\${PRODUCT_NAME}"
FunctionEnd

# Gets the AutoItV3 installation directory.
# Returns: Success - The full path to the AutoItV3 directory at the top the stack.
#          Failure - An empty string at the top of the stack.
Function getAutoItDir
    # First we check to see if we have the normal path key.
    ReadRegStr $0 HKLM "SOFTWARE\AutoIt" "InstallDir"
    IfErrors 0 firstPathFound
        ClearErrors
        StrCpy $0 "$PROGRAMFILES\AutoIt3"
        # The key did not exist, see if it exists at its normal physical location.
        IfFileExists $0 secondDirExist secondDirNotExist
        secondDirExist:
            StrCpy $1 $0
            GoTo ret
        secondDirNotExist:
            # We did not find it. If the host is 64bit, check the appropriate key.
            ReadRegStr $0 HKLM "SOFTWARE\Wow6432Node\AutoIt v3\AutoIt" "InstallDir"
            IfErrors 0 thirdDirNotFound
                # Key not found. See if the physical path exists.
                ClearErrors
                ExpandEnvStrings $3 "%programfiles(x86)%"
                StrCpy $0 "$3\AutoIt3"
                IfFileExists $0 lastDirFound lastDirNotFound
                lastDirFound:
                    # Found the path, push to top of stack.
                    StrCpy $1 $0
                    GoTo ret
                lastDirNotFound:
                    # Still didn't find it. At this point, we give up and push a blank string.
                    StrCpy $1 ""
                    GoTo ret
            thirdDirNotFound:
                # We found the key, now we just fall through to check its existence.
    firstPathFound:
        # Got the first path we tried. Make sure it exists.
        IfFileExists $0 pathExist pathNotExist
        pathExist:
            # Path found. Push to the top of the stack.
            StrCpy $1 $0
            GoTo ret
        pathNotExist:
            # Not found, blank string goes to the top of the stack.
            StrCpy $1 ""
    ret:
    Push $1
    Return
FunctionEnd

# Gets the SciTE4AutoItV3 installation directory.
# Returns: Success - The full path to the SciTE4AutoIt3 at the top of the stack.
#          Failure - A blank string at the top of the stack.
Function getSciteDir
    # Get the AutoIt3 install path.
    Call getAutoItDir
    Pop $0
    ${If} $0 == ""
        # Could not locate AutoIt. Push a blank string to top of stack.
        StrCpy $R1 ""
        GoTo getSciteRet
    ${Else}
        # SciTE is typically installed in a subdirectory of the AutoIt installation path.
        # Make sure it exists.
        StrCpy $R1 "$0\SciTE"
        IfFileExists $R1 sciteDirExists sciteDirNotExist
        sciteDirExists:
            # Found it. Push the path to the top of the stack.
            GoTo getSciteRet
        sciteDirNotExist:
            # Path not found. Push a blank string.
            StrCpy $R1 ""
            Goto getSciteRet
    ${EndIf}
    getSciteRet:
        Push $R1
        Return
FunctionEnd

# Uninstaller init callback.
Function un.onInit
    StrCpy $StartMenuGroup "AutoIt v3\SciTE\${PRODUCT_NAME}"
    !insertmacro MULTIUSER_UNINIT
    !insertmacro SELECT_UNSECTION Main ${UNSEC0000}
FunctionEnd

# Gets the AutoItV3 installation directory.
# Returns: Success - The full path to the AutoItV3 directory at the top the stack.
#          Failure - An empty string at the top of the stack.
Function un.getAutoItDir
    # First we check to see if we have the normal path key.
    ReadRegStr $0 HKLM "SOFTWARE\AutoIt" "InstallDir"
    IfErrors 0 un_firstPathFound
        ClearErrors
        StrCpy $0 "$PROGRAMFILES\AutoIt3"
        # The key did not exist, see if it exists at its normal physical location.
        IfFileExists $0 un_secondDirExist un_secondDirNotExist
        un_secondDirExist:
            StrCpy $1 $0
            GoTo un_ret
        un_secondDirNotExist:
            # We did not find it. If the host is 64bit, it check the appropriate key.
            ReadRegStr $0 HKLM "SOFTWARE\Wow6432Node\AutoIt v3\AutoIt" "InstallDir"
            IfErrors 0 un_thirdDirNotFound
                # Key not found. See if the physical path exists.
                ClearErrors
                ExpandEnvStrings $3 "%programfiles(x86)%"
                StrCpy $0 "$3\AutoIt3"
                IfFileExists $0 un_lastDirFound un_lastDirNotFound
                un_lastDirFound:
                    # Found the path, push to top of stack.
                    StrCpy $1 $0
                    GoTo un_ret
                un_lastDirNotFound:
                    # Still didn't find it. At this point, we give up and push a blank string.
                    StrCpy $1 ""
                    GoTo un_ret
            un_thirdDirNotFound:
                # We found they key, now we just fall through to check its existence.
    un_firstPathFound:
        # Got the first path we tried. Make sure it exists.
        IfFileExists $0 un_pathExist un_pathNotExist
        un_pathExist:
            # Path found. Push to the top of the stack.
            StrCpy $1 $0
            GoTo un_ret
        un_pathNotExist:
            # Not found, blank string goes to the top of the stack.
            StrCpy $1 ""
    un_ret:
    Push $1
    Return
FunctionEnd

# Gets the SciTE4AutoItV3 installation directory.
# Returns: Success - The full path to the SciTE4AutoIt3 at the top of the stack.
#          Failure - A blank string at the top of the stack.
Function un.getSciteDir
    # Get the AutoIt3 install path.
    Call un.getAutoItDir
    Pop $0
    ${If} $0 == ""
        # Could not locate AutoIt. Push a blank string to top of stack.
        StrCpy $R1 ""
        GoTo un_getSciteRet
    ${Else}
        # SciTE is typically installed in a subdirectory of the AutoIt installation path.
        # Make sure it exists.
        StrCpy $R1 "$0\SciTE"
        IfFileExists $R1 un_sciteDirExists un_sciteDirNotExist
        un_sciteDirExists:
            # Found it. Push the path to the top of the stack.
            GoTo un_getSciteRet
        un_sciteDirNotExist:
            # Path not found. Push a blank string.
            StrCpy $R1 ""
            Goto un_getSciteRet
    ${EndIf}
    un_getSciteRet:
        Push $R1
        Return
FunctionEnd
