#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\..\..\..\Program Files (x86)\AutoIt3\Icons\au3.ico
#AutoIt3Wrapper_Outfile=AutoItProjectCreator64.exe
#AutoIt3Wrapper_Res_Description=Project creator/editor for AutoItV3
#AutoIt3Wrapper_Res_Fileversion=1.0.0.4
#AutoIt3Wrapper_Res_LegalCopyright=Released under GPLv2
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 5
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/gd /sci 1 /kv 5/ /bdir Backup
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
Opt("MustDeclareVars", 1)

#cs ----------------------------------------------------------------------------
	
	AutoIt Version .: 3.3.6.1
	Author .........: Chris Brunner
	Script Version .: 1.0.0.4
	Name ...........: AutoItProjectCreator.au3
	Date ...........: 12/17/2010
	Modified .......: 02/14/2011
	Company ........: CyrusBuilt
	Copyright ......: Released under GPLv2
	Script Function : An AutoIt project creator and editor tool. This tool is
	meant to be integrated with SciTE4AutoIt3 (see README), but can be used
	standalone. Creating and editing the project itself will work fine, but after
	changes are made, this tool attempts to launch the main script of the project
	in SciTE.  If SciTE cannot be found, an error message will appear.
	
	Several of the functions in this script make use of a project info array
	structure and a "references" array structure. These arrays are defined as
	follows:
	
	Project Info Array:
	$aProjectInfo[0] - Should always be 9. This is the count of elements (only used for validation).
	$aProjectInfo[1] - The minimum version of AutoIt the script is compatible with (default is current).
	$aProjectInfo[2] - The author's name.
	$aProjectInfo[3] - The script (project) version (example: 1.0.0.5).
	$aProjectInfo[4] - The name of the project (or script).
	$aProjectInfo[5] - The date the project was created (defaults to current date) in YYYY/MM/DD format.
	$aProjectInfo[6] - The date the project was modified (defaults to current date) in YYYY/MM/DD format.
	$aProjectInfo[7] - The name of the company associated with the project.
	$aProjectInfo[8] - The copyright information.
	$aProjectInfo[9] - A synopsis of what the script (project) does. This is the description.
	Unless otherwise stated, all version strings should be 4-octets period delimited.
	
	References info array:
	$aReferences[0] - The count of elements in the array (used for iteration, etc).
	$aReferences[1] - Element1
	$aReferences[2] - Element2
	...
	$aReferences[n] - ElementN
	And so on. The references should not be full include statements. They should
	just be the name and/or path to the include (ie. "Array.au3" or "lib\mylib.au3").
	If the include is a name only, then it is assumed that it exists in the
	standard includes folder in AutoIt's installation path. If a relative path
	is provided (ie. "lib\mylib.au3"), it is assumed that it exists as a child
	of the project folder. Note: adding the main script of the project to itself
	as an include is prohibited... as it should be. Full paths are supported
	(ie. "C:\my libs folder\mylib\mylib.au3").
	
	Command-line arguments supported:
	filename.au3proj - If an AutoIt3 project file (*.au3proj) is specified,
	it will be opened by AutoItProjectCreator.
	
	/opendlg - This causes AutoItProject creator to prompt the user with file
	browser dialog to browse for an existing AutoIt3 project file to open.
	
#ce ----------------------------------------------------------------------------

#Region Includes
#include <Array.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <Date.au3>
#include <DateTimeConstants.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GuiComboBox.au3>
#include <GUIConstantsEx.au3>
#include <GUIDateTimePicker.au3>
#include <GuiListView.au3>
#include <ListViewConstants.au3>
#include <StaticConstants.au3>
#include <TabConstants.au3>
#include <WindowsConstants.au3>
#include <lib\FileLib.au3>
#EndRegion Includes

#Region Script Constants
Global Const $MY_NAME = "AutoItProjectCreator"
Global Const $HOME = @ScriptDir & "\"
Global Const $CONFIG = $HOME & $MY_NAME & ".ini"
Global Const $PROJECT_FILE_EXT = "au3proj"
#EndRegion Script Constants

#Region Project Type Constants
Global Const $PROJ_TYPE_APP = 1
Global Const $PROJ_TYPE_LIB = 2
#EndRegion Project Type Constants

#Region Copy Include Policy Constants
Global Const $CP_IFNEWER = 0
Global Const $CP_ALWAYS = 1
Global Const $CP_IFNOTEXIST = 2
#EndRegion Copy Include Policy Constants

#Region Script Globals
Global $iWasLoaded = False
Global $iOpenFromCmdLine = False
Global $projectFile = ""
Global $FormMain = 0
Global $TabMain = 0
Global $TabSheet1 = 0
Global $GroupType = 0
Global $RadioLib = 0
Global $RadioApp = 0
Global $GroupName = 0
Global $InputProjName = 0
Global $LabelName = 0
Global $InputLocation = 0
Global $ButtonProjectBrowse = 0
Global $LabelProjectsDir = 0
Global $LabelFullPath = 0
Global $InputFullPath = 0
Global $CheckboxMakeDefault = 0
Global $TabSheet2 = 0
Global $ListViewSourceLibs = 0
Global $ListViewTargetLibs = 0
Global $ButtonAddLib = 0
Global $ButtonRemoveLib = 0
Global $ButtonBrowseLib = 0
Global $TabSheet3 = 0
Global $LabelAutoItVer = 0
Global $InputAuthor = 0
Global $LabelAuthor = 0
Global $LabelScriptVer = 0
Global $InputAutoItVer = 0
Global $InputScriptVer = 0
Global $LabelDate = 0
Global $LabelDateModified = 0
Global $InputCompany = 0
Global $LabelCompany = 0
Global $InputCopyright = 0
Global $LabelCopyright = 0
Global $EditDescription = 0
Global $LabelDescription = 0
Global $DateCreated = 0
Global $DateModified = 0
Global $ButtonCancel = 0
Global $ButtonCreate = 0
Global $InputMainScript = 0
Global $LabelMainScript = 0
Global $CheckboxRequireAdmin = 0
Global $CheckboxHasGui = 0
Global $ButtonOpenProj = 0
Global $InputConfigName = 0
Global $LabelConfigName = 0
Global $CheckboxUseConfig = 0
Global $ComboCopyPolicy = 0
Global $LabelCopyLibPolicy = 0
Global $ButtonCurrDateNow = 0
Global $ButtonModDateNow = 0
#EndRegion Script Globals

#Region Utility Functions
; #FUNCTION# ====================================================================================================================
; Name...........: _GetMyVersion
; Description ...: Gets the version of this script. If not compiled, the file version of the script file is retrieved. If compiled,
;                  the running version of the .exe is retrieved.
; Syntax.........: _GetMyVersion()
; Parameters ....: None.
; Return values .: The current version of this script.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GetMyVersion()
	If (@Compiled) Then
		Return FileGetVersion(@AutoItExe)
	EndIf
	Return FileGetVersion(@ScriptFullPath)
EndFunc   ;==>_GetMyVersion

; #FUNCTION# ====================================================================================================================
; Name...........: _ProjectInfoArrayInit
; Description ...: Initializes an instance of the project info array structure.
; Syntax.........: _ProjectInfoArrayInit()
; Parameters ....: None.
; Return values .: An instance of the project info array structure.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......: This should not be called until *after* the GUI has been initialized.
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ProjectInfoArrayInit()
	Local $aProjectInfo[10]
	$aProjectInfo[0] = 9
	$aProjectInfo[1] = ""
	$aProjectInfo[2] = GUICtrlRead($InputAuthor)
	$aProjectInfo[3] = ""
	$aProjectInfo[4] = GUICtrlRead($InputProjName)
	$aProjectInfo[5] = ""
	$aProjectInfo[6] = ""
	$aProjectInfo[7] = ""
	$aProjectInfo[8] = ""
	$aProjectInfo[9] = GUICtrlRead($EditDescription)
	Return $aProjectInfo
EndFunc   ;==>_ProjectInfoArrayInit

; #FUNCTION# ====================================================================================================================
; Name...........: _GetReferences
; Description ...: Gets an array of references (includes) from the $ListViewTargetLibs listview control.
; Syntax.........: _GetReferences()
; Parameters ....: None.
; Return values .: An array of references (includes) with total count being stored at element zero.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......: This should not be called until *after* the GUI has been initialized.
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GetReferences()
	Local $nRefCount = 0
	Local $aReferences = 0
	Local $hTargHandle = GUICtrlGetHandle($ListViewTargetLibs)
	Local $nTotalReferences = _GUICtrlListView_GetItemCount($hTargHandle)
	If ($nTotalReferences > 0) Then
		Dim $aReferences[1]
		$aReferences[0] = 0
		For $nRefCount = 1 To $nTotalReferences
			$aReferences[0] += 1
			ReDim $aReferences[$nRefCount + 1]
			$aReferences[$nRefCount] = _GUICtrlListView_GetItemText($hTargHandle, $nRefCount - 1)
		Next
	EndIf
	$hTargHandle = 0
	Return $aReferences
EndFunc   ;==>_GetReferences

; #FUNCTION# ====================================================================================================================
; Name...........: _CreateApplicationConfig
; Description ...: Generates an application configuration file.
; Syntax.........: _CreateApplicationConfig($sConfigPath, $aProjectInfo)
; Parameters ....: $sConfigPath  - The full path to the configuration file to create.
;                  $aProjectInfo - An array containing project info. See _WriteApplicationScript for definition.
; Return values .: None. On error, sets @error to one of the following:
;                  |1 - $aProjectInfo is not a valid project info array structure.
;                  |2 - $sConfigPath is not a valid config file path or is a file that already exists.
;                  |3 - The config file could not be created or opened for writing.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 1/26/2011
; Remarks .......: If $sConfigPath already exists, it will not be overwritten or modified.
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _CreateApplicationConfig($sConfigPath, $aProjectInfo)
	If ((Not IsArray($aProjectInfo)) Or ($aProjectInfo[0] <> 9)) Then
		Return SetError(1)
	EndIf

	If ((IsString($sConfigPath)) And (StringLen($sConfigPath) > 0) And (Not FileExists($sConfigPath))) Then
		Local $hFile = FileOpen($sConfigPath, 2)
		If ($hFile == -1) Then
			Return SetError(3)
		EndIf

		FileWriteLine($hFile, "; *** This file was generated by a tool. " & $MY_NAME & " v" & _GetMyVersion() & ".")
		FileWriteLine($hFile, "; *** " & $aProjectInfo[4] & " configuration file.")
		FileWriteLine($hFile, "; *** This file may be freely modified to suit your needs.")
		FileWriteLine($hFile, "")
		FileWriteLine($hFile, "")
		FileWriteLine($hFile, "; *** Add sections and keys here as need. The following section was generated automatically.")
		FileWriteLine($hFile, "[Main]")
		FileFlush($hFile)
		FileClose($hFile)
	Else
		SetError(2)
	EndIf
	Return
EndFunc   ;==>_CreateApplicationConfig

; #FUNCTION# ====================================================================================================================
; Name...........: _MultiLineDescriptionToArray
; Description ...: Breaks a multi-line description string into an array of strings. If the specified string does not contain
;                  any carriage returns or line breaks, then an array with only one string element will be returned.
; Syntax.........: _MultiLineDescriptionToArray($sDescription[, $isLib])
; Parameters ....: $sDescription - The description text to convert to an array.
;                  $isLib        - (Optional) Set True if the project script is a library (default is False).
; Return values .: An array with the following structure:
;                  $aDescLines[0] = N (element count)
;                  $aDescLines[1] = Description line 1
;                  $aDescLines[2] = Description line 2
;                  ...
;                  $aDescLines[3] = Description line N
;
;                  If $sDescription is a null or empty string, then $aDescLines will only contain element zero, which will be
;                  set equal to zero ($aDescLines[0] = 0).
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _MultiLineDescriptionToArray($sDescription, $isLib = False)
	; Initialize the array to be returned.
	Local $aDescLines[1]
	$aDescLines[0] = 0
	; Is the description string null or empty?
	If (StringLen($sDescription) > 0) Then
		; Does the description contain any carriage returns/line feeds?
		If (StringInStr($sDescription, @CRLF) > 0) Then
			; Build an array of description lines, then sift through them, formatting as we go.
			Local $sDescLine = ""
			Local $nRefIdx = 0
			Local $aLines = StringSplit($sDescription, @CRLF)
			For $nRefIdx = 1 To $aLines[0]
				$sDescLine = $aLines[$nRefIdx]
				If (StringLen($sDescLine) > 0) Then
					; Fixup for the first line of the description.
					If ($nRefIdx == 1) Then
						If ($isLib) Then
							$sDescLine = "; Description ...: " & $sDescLine
						Else
							$sDescLine = "Script Function : " & $sDescLine
						EndIf
					EndIf

					; Fixup the line start.
					If ($isLib) Then
						If (StringRight($sDescLine, 1) <> ";") Then
							$sDescLine = "; " & $sDescLine
						EndIf
					Else
						$sDescLine = @TAB & $sDescLine
					EndIf
					; Append the new line element.
					If (_ArrayAdd($aDescLines, $sDescLine) <> -1) Then
						$aDescLines[0] += 1
					EndIf
				EndIf
			Next
		Else
			; The description is just one line, so we simply set the element value.
			ReDim $aDescLines[2]
			$aDescLines[0] = 1
			If ($isLib) Then
				$aDescLines[1] = "; Description ...: " & $sDescription
			Else
				$aDescLines[1] = @TAB & "Script Function : " & $sDescription
			EndIf
		EndIf
	EndIf
	Return $aDescLines
EndFunc   ;==>_MultiLineDescriptionToArray

; #FUNCTION# ====================================================================================================================
; Name...........: _WriteApplicationScript
; Description ...: Generates an application script at the specified path using the specified project information.
; Syntax.........: _WriteApplicationScript($hFileHandle, $aProjectInfo[, $aReferences[, $iHasGui[, $iRequireAdmin[, $sConfigName]]]])
; Parameters ....: $hFileHandle   - The handle to the file we are going to write to. This should be a handle created by FileOpen().
;                  $aProjectInfo  - An array containing project info in the following format:
;                                   |$aProjectInfo[0] - Should always be 9. This is the count of elements (only used for validation).
;                                   |$aProjectInfo[1] - The minimum version of AutoIt the script is compatible with (default is current).
;                                   |$aProjectInfo[2] - The author's name.
;                                   |$aProjectInfo[3] - The script (project) version (example: 1.0.0.5).
;                                   |$aProjectInfo[4] - The name of the project (or script).
;                                   |$aProjectInfo[5] - The date the project was created (defaults to current date) in YYYY/MM/DD format.
;                                   |$aProjectInfo[6] - The date the project was modified (defaults to current date) in YYYY/MM/DD format.
;                                   |$aProjectInfo[7] - The name of the company associated with the project.
;                                   |$aProjectInfo[8] - The copyright information.
;                                   |$aProjectInfo[9] - A synopsis of what the script (project) does. This is the description.
;                  $aReferences   - Optional. An array of project references (includes) to be imported by the main script (using #include<>).
;                                   This array should use the following format:
;                                   |$aReferences[0] - The count of elements in the array (used for iteration, etc).
;                                   |$aReferences[1] - Element1
;                                   |$aReferences[2] - Element2
;                                   |...
;                                   |$aReferences[n] - ElementN
;                  $iHasGui       - Optional. Indicates that the script has/will have a GUI (default is False).
;                  $iRequireAdmin - Optional. Indicates that the script requires/will require administrative privileges (default is False).
;                  $sConfigName   - Optional. The name of the configuration file associated with the application.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 02/14/2011
; Remarks .......: This is meant to be called from _GenerateScript().
; Related .......: _WriteLibScript, _GenerateScript
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _WriteApplicationScript($hFileHandle, $aProjectInfo, $aReferences = 0, $iHasGui = False, $iRequireAdmin = False, $sConfigName = "")
	If ($hFileHandle <> -1) Then
		; Write out the script header with the project info.
		If ($iRequireAdmin) Then
			FileWriteLine($hFileHandle, "#RequireAdmin")
		EndIf
		FileWriteLine($hFileHandle, 'Opt("MustDeclareVars", 1)')
		FileWriteLine($hFileHandle, "#region ;**** Directives created by AutoIt3Wrapper_GUI ****")
		;*** CB_NOTE: Can't really put a multi-line description block here. Should probably just let the user do this using AutoIt3Wrapper.
		;FileWriteLine($hFileHandle, "#AutoIt3Wrapper_Res_Description=" & $aProjectInfo[9])
		FileWriteLine($hFileHandle, "#AutoIt3Wrapper_Res_Fileversion=" & $aProjectInfo[3])
		FileWriteLine($hFileHandle, "#AutoIt3Wrapper_Res_LegalCopyright=" & $aProjectInfo[8])
		FileWriteLine($hFileHandle, "#endregion ;**** Directives created by AutoIt3Wrapper_GUI ****")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "#cs ----------------------------------------------------------------------------")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, @TAB & "AutoIt Version .: " & $aProjectInfo[1])
		FileWriteLine($hFileHandle, @TAB & "Author .........: " & $aProjectInfo[2])
		FileWriteLine($hFileHandle, @TAB & "Script Version .: " & $aProjectInfo[3])
		FileWriteLine($hFileHandle, @TAB & "Name ...........: " & $aProjectInfo[4])
		FileWriteLine($hFileHandle, @TAB & "Date ...........: " & $aProjectInfo[5])
		FileWriteLine($hFileHandle, @TAB & "Modified .......: " & $aProjectInfo[6])
		FileWriteLine($hFileHandle, @TAB & "Company ........: " & $aProjectInfo[7])
		FileWriteLine($hFileHandle, @TAB & "Copyright ......: " & $aProjectInfo[8])

		; Print one or more description lines in the header comments.
		Local $i = 0
		Local $aDescLines = _MultiLineDescriptionToArray($aProjectInfo[9], False)
		For $i = 1 To $aDescLines[0]
			FileWriteLine($hFileHandle, $aDescLines[$i])
		Next

		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "#ce ----------------------------------------------------------------------------")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "#region Includes")

		; If an array of references (includes) was provided, go ahead and fill them in here.
		If ((IsArray($aReferences)) And ($aReferences[0] > 0)) Then
			Local $sLibStr = ""
			For $i = 1 To $aReferences[0]
				$sLibStr = $aReferences[$i]
				FileWriteLine($hFileHandle, '#include <' & $sLibStr & '>')
			Next
		Else
			FileWriteLine($hFileHandle, "")
		EndIf

		FileWriteLine($hFileHandle, "#endregion")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "#region Script Constants")
		FileWriteLine($hFileHandle, 'Global Const $MY_NAME = "' & $aProjectInfo[4] & '"')
		FileWriteLine($hFileHandle, 'Global Const $HOME = @ScriptDir & "\"')
		If (StringLen($sConfigName) > 0) Then
			FileWriteLine($hFileHandle, 'Global Const $CONFIG = $HOME & "' & $sConfigName & '"')
		EndIf
		FileWriteLine($hFileHandle, "#endregion")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "#region Script Globals")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "#endregion")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "#region Utility Functions")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "#endregion")
		FileWriteLine($hFileHandle, "")

		; If this script is going to have a GUI then write a region for event handlers here.
		If ($iHasGui) Then
			FileWriteLine($hFileHandle, "#region Event Handlers")
			FileWriteLine($hFileHandle, "")
			FileWriteLine($hFileHandle, "#endregion")
			FileWriteLine($hFileHandle, "")
		EndIf

		FileWriteLine($hFileHandle, "#region Main Script")
		FileWriteLine($hFileHandle, "; *********************** MAIN ENTRY POINT ****************************")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "Exit")
		FileWriteLine($hFileHandle, "#endregion")
	EndIf
	Return
EndFunc   ;==>_WriteApplicationScript

; #FUNCTION# ====================================================================================================================
; Name...........: _WriteLibScript
; Description ...: Generates a library (include) script at the specified path with the specified project information.
; Syntax.........: _WriteLibScript($hFileHandle, $aProjectInfo[, $aReferences])
; Parameters ....: $hFileHandle   - The handle to the file we are going to write to. This should be a handle created by FileOpen().
;                  $aProjectInfo  - An array containing project info. See _WriteApplicationScript() for definition.
;                  $aReferences   - Optional. An array of project references (includes) to be imported by the main script (using #include<>).
;                                   See _WriteApplicationScript() for definition.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 02/14/2011
; Remarks .......: This is meant to be called from _GenerateScript().
; Related .......: _WriteApplicationScript, _GenerateScript
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _WriteLibScript($hFileHandle, $aProjectInfo, $aReferences = 0)
	If ($hFileHandle <> -1) Then
		FileWriteLine($hFileHandle, "#include-once")
		FileWriteLine($hFileHandle, "")

		; Write the library info header.
		FileWriteLine($hFileHandle, "; #INDEX# =======================================================================================================================")
		FileWriteLine($hFileHandle, "; Title .........: " & $aProjectInfo[4])

		; Print one or more description lines in the header comments.
		Local $i = 0
		Local $aDescLines = _MultiLineDescriptionToArray($aProjectInfo[9], True)
		For $i = 1 To $aDescLines[0]
			FileWriteLine($hFileHandle, $aDescLines[$i])
		Next

		FileWriteLine($hFileHandle, "; Author(s) .....: " & $aProjectInfo[2])
		FileWriteLine($hFileHandle, "; ===============================================================================================================================")
		FileWriteLine($hFileHandle, "")

		; If an array of references (includes) was provided, go ahead and fill them in here.
		If ((IsArray($aReferences)) And ($aReferences[0] > 0)) Then
			FileWriteLine($hFileHandle, "#region Includes")
			Local $idx = 0
			For $idx = 1 To $aReferences[0]
				FileWriteLine($hFileHandle, "#include <" & $aReferences[$idx] & ">")
			Next
			FileWriteLine($hFileHandle, "#endregion")
			FileWriteLine($hFileHandle, "")
		EndIf

		; Write the variables section.
		FileWriteLine($hFileHandle, "; #VARIABLES# ===================================================================================================================")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "; ===============================================================================================================================")
		FileWriteLine($hFileHandle, "")

		; Write the constants section.
		FileWriteLine($hFileHandle, "; #CONSTANTS# ===================================================================================================================")
		FileWriteLine($hFileHandle, "")
		FileWriteLine($hFileHandle, "; ===============================================================================================================================")
		FileWriteLine($hFileHandle, "")

		; Write the no-doc functions section.
		FileWriteLine($hFileHandle, "; #NO_DOC_FUNCTION# =============================================================================================================")
		FileWriteLine($hFileHandle, ";")
		FileWriteLine($hFileHandle, "; ===============================================================================================================================")
		FileWriteLine($hFileHandle, "")

		; Write the current list of functions section.
		FileWriteLine($hFileHandle, "; #CURRENT# =====================================================================================================================")
		FileWriteLine($hFileHandle, ";")
		FileWriteLine($hFileHandle, "; ===============================================================================================================================")
		FileWriteLine($hFileHandle, "")

		; Write the internal-use-only functions section.
		FileWriteLine($hFileHandle, "; #INTERNAL_USE_ONLY# ===========================================================================================================")
		FileWriteLine($hFileHandle, ";")
		FileWriteLine($hFileHandle, "; ===============================================================================================================================")
		FileWriteLine($hFileHandle, "")

		; Write out a template function with info header.
		FileWriteLine($hFileHandle, "; #FUNCTION# ====================================================================================================================")
		FileWriteLine($hFileHandle, "; Name...........: _FuncName")
		FileWriteLine($hFileHandle, "; Description ...: A template function. This is a placeholder for a real function and is just here to demonstrate the format")
		FileWriteLine($hFileHandle, ";                  of the function description header and proper function naming syntax.")
		FileWriteLine($hFileHandle, "; Syntax.........: _FuncName()")
		FileWriteLine($hFileHandle, "; Parameters ....: None.")
		FileWriteLine($hFileHandle, "; Return values .: None.")
		FileWriteLine($hFileHandle, "; Author ........: " & $aProjectInfo[2])
		FileWriteLine($hFileHandle, "; Modified.......: ")
		FileWriteLine($hFileHandle, "; Remarks .......: ")
		FileWriteLine($hFileHandle, "; Related .......: ")
		FileWriteLine($hFileHandle, "; Link ..........: ")
		FileWriteLine($hFileHandle, "; Example .......: ")
		FileWriteLine($hFileHandle, "; ===============================================================================================================================")
		FileWriteLine($hFileHandle, "Func _FuncName()")
		FileWriteLine($hFileHandle, @TAB & "Return")
		FileWriteLine($hFileHandle, "EndFunc   ;==>_FuncName")
		FileWriteLine($hFileHandle, "")
	EndIf
	Return
EndFunc   ;==>_WriteLibScript

; #FUNCTION# ====================================================================================================================
; Name...........: _ModifyScript
; Description ...: Modifies the project info in the specified script to match the specified parameters.
; Syntax.........: _ModifyScript($sScriptPath, $aProjectInfo[, $aReferences[, $iHasGui[, $iRequireAdmin[, $isLib[, $sConfigName]]]]])
; Parameters ....: $scriptPath    - The full path include filename where the script is to be generated.
;                  $aProjectInfo  - An array containing project info. See _WriteApplicationScript() for definition.  Any existing
;                                   project info will be replaced by the info in this array.
;                  $aReferences   - Optional. An array of project references (includes) to be imported by the main script (using #include<>).
;                                   See _WriteApplicationScript() for definition.  Specified includes will only be added if they
;                                   do not already exist in the script. If the specified array is null or empty, it will simply
;                                   be ignored and any existing includes will be left untouched.
;                  $iHasGui       - Optional. Indicates that the script has/will have a GUI (default is False). Ignored if $isLib = True.
;                                   If set True, an "Event Handlers" region will be added to the script (if it does not already exist).
;                                   If set False, and an "Event Handlers" region and any code defined within that region will be removed.
;                  $iRequireAdmin - Optional. Indicates that the script requires/will require administrative privileges (default is False).
;                                   This parameter is ignored if $isLib = True.  If $iRequireAdmin is True, then the "#RequireAdmin"
;                                   directive will be inserted at the beginning of the script if it does not already exist. If the
;                                   $iRequireAdmin parameter is False and the "#RequireAdmin" directive exists, then it will be
;                                   removed from the script.
;                  $isLib         - Optional. Set True if the script being generated is a library (include). If True, then
;                                   the $iHasGui, $iRequireAdmin, and $sConfigName parameters will be ignored.
;                  $sConfigName   - Optional. The name of the config file associated with the application script.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 02/14/2011
; Remarks .......: This is meant to be called from _GenerateScript(). It is basically one big array manipulation routine, as it
;                  just loads the existing script file into an array structure which is then manipulated in memory before being
;                  written to disk.
; Related .......: _GenerateScript, _WriteLibScript, _WriteApplicationScript
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ModifyScript($sScriptPath, $aProjectInfo, $aReferences = 0, $iHasGui = False, $iRequireAdmin = False, $isLib = False, $sConfigName = "")
	If (FileExists($sScriptPath)) Then
		Local $aLines
		Local $nRefIdx = 0
		Local $nInsertPosition = -1
		Local $nHeaderStart = -1
		Local $nEndIndex = -1
		Local $nElementCount = 0

		; Try to read each line of the script into an array.
		If (_FileReadToArray($sScriptPath, $aLines)) Then
			; Handle the header first.
			If ($isLib) Then
				$nHeaderStart = _ArraySearch($aLines, "#INDEX#", 0, 0, 0, 1)
				$aLines[$nHeaderStart + 1] = "; Title .........: " & $aProjectInfo[4]
				$nInsertPosition = $nHeaderStart + 2
				$nEndIndex = _ArraySearch($aLines, "; Author(s)", $nInsertPosition, 0, 0, 1) - 1
				$aLines[$nEndIndex + 1] = "; Author(s) .....: " & $aProjectInfo[2]
			Else
				; First we overwrite the header with current values.
				$nHeaderStart = _ArraySearch($aLines, "#cs", 0, 0, 0, 1)
				$aLines[$nHeaderStart + 2] = @TAB & "AutoIt Version .: " & $aProjectInfo[1]
				$aLines[$nHeaderStart + 3] = @TAB & "Author .........: " & $aProjectInfo[2]
				$aLines[$nHeaderStart + 4] = @TAB & "Script Version .: " & $aProjectInfo[3]
				$aLines[$nHeaderStart + 5] = @TAB & "Name ...........: " & $aProjectInfo[4]
				$aLines[$nHeaderStart + 6] = @TAB & "Date ...........: " & $aProjectInfo[5]
				$aLines[$nHeaderStart + 7] = @TAB & "Modified .......: " & $aProjectInfo[6]
				$aLines[$nHeaderStart + 8] = @TAB & "Company ........: " & $aProjectInfo[7]
				$aLines[$nHeaderStart + 9] = @TAB & "Copyright ......: " & $aProjectInfo[8]
				$nInsertPosition = $nHeaderStart + 10
				$nEndIndex = _ArraySearch($aLines, "#ce", $nInsertPosition, 0, 0, 1)
			EndIf

			; Here we handle the description text regardless of whether this is an application script or library script.
			; We have to start 2 positions back if this is an application.
			If (Not $isLib) Then
				$nEndIndex -= 2
			EndIf

			; Get the project description text
			Local $aDescLines = _MultiLineDescriptionToArray($aProjectInfo[9], $isLib)
			If ($aDescLines[0] > 0) Then
				If ($aDescLines[0] > 1) Then
					; Since there are multiple description lines and each line is an element in $aLines,
					; we have to first delete the entire description section from the header, then split
					; the new description into an array, which we will then format and then insert the contents
					; of it into the $aLines array starting at the index of the description start in $aLines.
					If ($nInsertPosition <> -1) Then
						; Count all the elements to delete.
						For $nRefIdx = $nInsertPosition To $nEndIndex
							$nElementCount += 1
						Next

						; Delete all the description elements.
						For $nRefCount = 1 To $nElementCount
							If (_ArrayDelete($aLines, $nInsertPosition) <> 0) Then
								$aLines[0] -= 1
							EndIf
						Next

						; Iterate through the description lines array and insert into the $aLines array.
						For $nRefIdx = 1 To $aDescLines[0]
							; We have to advance the insertion positiion or the lines will be inserted in reverse order.
							If ($nRefIdx > 1) Then
								$nInsertPosition += 1
							EndIf

							; Insert the new line element.
							If (_ArrayInsert($aLines, $nInsertPosition, $aDescLines[$nRefIdx]) <> 0) Then
								$aLines[0] += 1
							EndIf
						Next
					EndIf
				Else
					; The description is just one line, so we simply set the element value.
					If ($isLib) Then
						$aLines[$nHeaderStart + 2] = $aDescLines[1]
					Else
						$aLines[$nHeaderStart + 10] = $aDescLines[1]
					EndIf
				EndIf
			Else
				; No description provided.
				If ($isLib) Then
					$aLines[$nHeaderStart + 2] = "; Description ...: "
				Else
					$aLines[$nHeaderStart + 10] = @TAB & "Script Function : "
				EndIf
			EndIf
			$aDescLines = 0

			; Now we have to handle inserting/removing the "Event Handlers" region here.
			; First, make sure this isn't a library script, then look to see if the "Event Handlers"
			; region already exists.
			$nInsertPosition = -1
			Local $nRegionIndex = -1
			If (Not $isLib) Then
				$nRegionIndex = _ArraySearch($aLines, "#region Event Handlers", 0, 0, 0, 1)
				If ($nRegionIndex == -1) Then
					If ($iHasGui) Then
						; Build an array of regions (working backward) we'll use to insert after.
						Local $aRegions[6] = [5, _
								"#region Utility Functions", _
								"#region Script Globals", _
								"#region Script Constants", _
								"#region Includes", _
								"#cs"]

						; Iterate through the array, stopping after the first reqion we find.
						For $nRefIdx = 1 To $aRegions[0]
							$nRegionIndex = _ArraySearch($aLines, $aRegions[$nRefIdx], 0, 0, 0, 1)
							If ($nRegionIndex <> -1) Then
								$nInsertPosition = _ArraySearch($aLines, "#endregion", $nRegionIndex, $aLines[0], 0, 1) + 1
								ExitLoop
							EndIf
						Next

						; Now insert the "Event Handlers" region right after the last region we found.
						If ($nInsertPosition <> -1) Then
							_ArrayInsert($aLines, $nInsertPosition, "")
							_ArrayInsert($aLines, $nInsertPosition + 1, "#region Event Handlers")
							_ArrayInsert($aLines, $nInsertPosition + 2, "")
							_ArrayInsert($aLines, $nInsertPosition + 3, "#endregion")
							_ArrayInsert($aLines, $nInsertPosition + 4, "")
							$aLines[0] += 5
						EndIf
						$aRegions = 0
					EndIf
				Else
					; If the application script is not to have a GUI but a "Event Handler" region currently
					; exists, then we'll remove the entire region here.
					If (Not $iHasGui) Then
						$nElementCount = 0
						$nRegionIndex -= 1
						$nEndIndex = _ArraySearch($aLines, "#endregion", $nRegionIndex, 0, 0, 1) - 1
						For $nRefIdx = $nRegionIndex To $nEndIndex
							$nElementCount += 1
						Next

						For $nRefCount = 1 To $nElementCount
							If (_ArrayDelete($aLines, $nRegionIndex) <> 0) Then
								$aLines[0] -= 1
							EndIf
						Next
					EndIf
				EndIf

				; Check admin directive.
				$nInsertPosition = -1
				$nRegionIndex = _ArraySearch($aLines, "#RequireAdmin", 0, 0, 0, 1)
				If ($nRegionIndex == -1) Then
					If ($iRequireAdmin) Then
						; Directive not found. Insert at the beginning.
						If (_ArrayInsert($aLines, 1, "#RequireAdmin") <> 0) Then
							$aLines[0] += 1
						EndIf
					EndIf
				Else
					If (Not $iRequireAdmin) Then
						; We need to remove the directive if it exists.
						If (_ArrayDelete($aLines, $nRegionIndex) <> 0) Then
							$aLines[0] -= 1
						EndIf
					EndIf
				EndIf

				; Add/update config reference if specified.
				If (StringLen($sConfigName) > 0) Then
					Local $nGlobalConstIdx = _ArraySearch($aLines, "Global Const $CONFIG", 0, 0, 0, 1)
					If ($nGlobalConstIdx <> -1) Then
						$aLines[$nGlobalConstIdx] = 'Global Const $CONFIG = $HOME & "' & $sConfigName & '"'
					EndIf
				EndIf
			EndIf

			; Do we have any references to add?
			Local $nIncludesRegionIndex = -1
			Local $nStartPosition = -1
			$nEndIndex = -1
			If ((IsArray($aReferences)) And ($aReferences[0] > 0)) Then
				; We need to add references. Does an "Includes" region already exist?
				$nIncludesRegionIndex = _ArraySearch($aLines, "#region Includes")
				If ($nIncludesRegionIndex == -1) Then
					; No region. We need to insert one.
					If ($isLib) Then
						$nInsertPosition = _ArraySearch($aLines, "#INDEX#", 0, 0, 0, 1) + 7
					Else
						$nInsertPosition = _ArraySearch($aLines, "#ce", 0, 0, 0, 1) + 3
					EndIf
					_ArrayInsert($aLines, $nInsertPosition, "#region Includes")
					_ArrayInsert($aLines, $nInsertPosition + 1, "#endregion")
					$aLines[0] += 2
					$nStartPosition = $nInsertPosition + 1
				Else
					; Blow away any inlcudes currently in the region, we will repopulate from scratch.
					; To do this, first we need to calculate the start and end positions (elements),
					; then calculate the total number of elements to be deleted.
					$nElementCount = 0
					$nStartPosition = $nIncludesRegionIndex + 1
					$nEndIndex = _ArraySearch($aLines, "#endregion", $nStartPosition, 0, 0, 1) - 1
					For $nRefCount = $nStartPosition To $nEndIndex
						$nElementCount += 1
					Next

					; Delete all the existing elements.
					For $nRefIdx = 1 To $nElementCount
						If (_ArrayDelete($aLines, $nStartPosition) <> 0) Then
							$aLines[0] -= 1
						EndIf
					Next
				EndIf

				; Insert all the current includes as new elements in the array,
				; starting at the first element between the start and end of the region.
				; We re-sort the array descending first, so that the elements actually
				; appear in *ascending* order once they are inserted in to the array.
				Local $sLib = ""
				Local $sProjPath = ""
				_ArraySort($aReferences, 1, 1, $aReferences[0])
				For $nRefIdx = 1 To $aReferences[0]
					$sLib = $aReferences[$nRefIdx]
					$sProjPath = _FileGetDirFromPath($projectFile)
					; If the library is located somewhere in the project directory, then build a relative path string.
					If (StringInStr($sLib, $sProjPath) > 0) Then
						$sLib = StringMid($sLib, StringLen($sProjPath) + 1)
					EndIf

					If (_ArrayInsert($aLines, $nStartPosition, "#include <" & $sLib & ">") <> 0) Then
						$aLines[0] += 1
					EndIf
				Next
			EndIf

			; We're going to replace the current file contents with the array contents.
			Local $hFile = FileOpen($sScriptPath, 2)
			If ($hFile <> -1) Then
				_FileWriteFromArray($hFile, $aLines, 1)
				FileFlush($hFile)
				FileClose($hFile)
			EndIf
		EndIf
	EndIf
	Return
EndFunc   ;==>_ModifyScript

; #FUNCTION# ====================================================================================================================
; Name...........: _GenerateScript
; Description ...: Generates a script at the specified path using the specified project info.
; Syntax.........: _GenerateScript($scriptPath, $aProjectInfo[, $aReferences[, $iHasGui[, $iRequireAdmin[, $isLib]]]])
; Parameters ....: $scriptPath    - The full path include filename where the script is to be generated.
;                  $aProjectInfo  - An array containing project info. See _WriteApplicationScript() for definition.
;                  $aReferences   - Optional. An array of project references (includes) to be imported by the main script (using #include<>).
;                                   See _WriteApplicationScript() for definition.
;                  $iHasGui       - Optional. Indicates that the script has/will have a GUI (default is False). Ignored if $isLib = True.
;                  $iRequireAdmin - Optional. Indicates that the script requires/will require administrative privileges (default is False).
;                                   This parameter is ignored if $isLib = True.
;                  $isLib         - Optional. Set True if the script being generated is a library (include).
;                  $sConfigName   - Optional. The name of the config file to use with the application script. Ignored if $isLib = True.
; Return values .: None. On error, sets @error to one of the following:
;                  |1 - The provided script path is null, empty, or not a string.
;                  |2 - The parent directory does not exist. Cannot create a script in a non-existent directory.
;                  |3 - A valid project information array was not provided.
;                  |4 - Unable to create the file or open in write mode.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/05/2011
; Remarks .......:
; Related .......: _WriteLibScript, _WriteApplicationScript, _ModifyScript
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GenerateScript($scriptPath, $aProjectInfo, $aReferences = 0, $iHasGui = False, $iRequireAdmin = False, $isLib = False, $sConfigName = "")
	; Do we have a valid path?
	If ((Not IsString($scriptPath)) Or (StringLen($scriptPath) == 0)) Then
		Return SetError(1)
	EndIf

	; Does the directory container of the script exist?
	If (Not FileExists(_FileGetDirFromPath($scriptPath))) Then
		Return SetError(2)
	EndIf

	; Make sure we have the proper file extension.
	If (StringLower(_FileExtension($scriptPath)) <> "au3") Then
		$scriptPath &= ".au3"
	EndIf

	; Were we given a proper project info array?
	If ((Not IsArray($aProjectInfo)) Or ($aProjectInfo[0] <> 9)) Then
		Return SetError(3)
	EndIf

	; If the script was loaded as part of an existing project, then we're just modifying existing data.
	; Otherwise, create a new script as part of the new project.
	If ($iWasLoaded) Then
		_ModifyScript($scriptPath, $aProjectInfo, $aReferences, $iHasGui, $iRequireAdmin, $isLib, $sConfigName)
	Else
		; Open/create the file.
		Local $hFile = FileOpen($scriptPath, 2)
		If ($hFile == -1) Then
			Return SetError(4)
		EndIf

		; If this is library, then generate a library script. Otherwise, generate an application script.
		If ($isLib) Then
			_WriteLibScript($hFile, $aProjectInfo, $aReferences)
		Else
			_WriteApplicationScript($hFile, $aProjectInfo, $aReferences, $iHasGui, $iRequireAdmin, $sConfigName)
		EndIf

		; Flush the buffers to disk and close the file.
		FileFlush($hFile)
		FileClose($hFile)
	EndIf
	Return
EndFunc   ;==>_GenerateScript

; #FUNCTION# ====================================================================================================================
; Name...........: _GetAutoItPath
; Description ...: Gets the path to the AutoItV3 installation on the local machine.
; Syntax.........: _GetAutoItPath()
; Parameters ....: None.
; Return values .: Success - The path path to the AutoItV3 installation directory.
;                  Failure - An empty string.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 12/28/2010
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GetAutoItPath()
	Local $sAutoItPath = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\AutoIt v3\AutoIt", "InstallDir")
	If ((@error) Or (StringLen($sAutoItPath) == 0)) Then
		; Couldn't get the path from the registry. Let's see if it exists in it's usual spot.
		$sAutoItPath = @ProgramFilesDir & "\AutoIt3"
		If (Not _FileIsDir($sAutoItPath)) Then
			; Still can't find it. Are we on a 64bit host?
			If (@OSArch <> "x86") Then
				$sAutoItPath = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\AutoIt v3\AutoIt", "InstallDir")
				If ((@error) Or (StringLen($sAutoItPath) == 0)) Then
					; WTF? Let's try this.... if we still don't find it, then assume it isn't there.
					$sAutoItPath = EnvGet("programfiles(x86)") & "\AutoIt3"
				EndIf
			EndIf
		EndIf
	EndIf
	; Make sure the path exists and is a directory.
	If (Not _FileIsDir($sAutoItPath)) Then
		$sAutoItPath = ""
	EndIf
	Return $sAutoItPath
EndFunc   ;==>_GetAutoItPath

; #FUNCTION# ====================================================================================================================
; Name...........: _GetAutoItIncludesDir
; Description ...: Gets the full path to the AutoItV3 Includes directory where all the AutoIt standard libraries are stored.
; Syntax.........: _GetAutoItIncludesDir()
; Parameters ....: None.
; Return values .: Success - The full path to the AutoItV3 Includes directory.
;                  Failure - An empty string.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......: _GetAutoItPath
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GetAutoItIncludesDir()
	; First get the path to the AutoIt installation directory.
	Local $sIncludesPath = ""
	Local $sAutoItPath = _GetAutoItPath()
	If (StringLen($sAutoItPath) > 0) Then
		; AutoIt exists. Build the path to the Includes folder and make sure it exists.
		$sIncludesPath = $sAutoItPath & "\Include"
		If (Not (_FileIsDir($sIncludesPath))) Then
			$sIncludesPath = ""
		EndIf
	EndIf
	Return $sIncludesPath
EndFunc   ;==>_GetAutoItIncludesDir

; #FUNCTION# ====================================================================================================================
; Name...........: _GetSciteExec
; Description ...: Gets the full path to the SciTE code editor for AutoItV3 executable.
; Syntax.........: _GetSciteExec()
; Parameters ....: None.
; Return values .: Success - The full path to the SciTE executable.
;                  Failure - An empty string.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......: _GetAutoItPath, _GetAutoItIncludesDir
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GetSciteExec()
	; First get the path to the AutoIt installation directory.
	Local $sSciteExec = ""
	Local $sAutoItPath = _GetAutoItPath()
	If (StringLen($sAutoItPath) > 0) Then
		;AutoIt exists. Build the path to the executable and make sure it exists.
		$sSciteExec = $sAutoItPath & "\SciTE\SciTE.exe"
		If (Not FileExists($sSciteExec)) Then
			$sSciteExec = ""
		EndIf
	EndIf
	Return $sSciteExec
EndFunc   ;==>_GetSciteExec

; #FUNCTION# ====================================================================================================================
; Name...........: _LoadGlobalConfig
; Description ...: Loads the global application configuration from the main configuration file (if present).
; Syntax.........: _LoadGlobalConfig()
; Parameters ....: None.
; Return values .: None. Loaded settings are immediately applied to the UI.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......: _SaveGlobalConfig
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _LoadGlobalConfig()
	If (FileExists($CONFIG)) Then
		Local $sBaseDir = IniRead($CONFIG, "Main", "ProjectsDir", "")
		If (_FileIsDir($sBaseDir)) Then
			GUICtrlSetData($InputLocation, $sBaseDir)
			If (StringLower(StringStripWS(IniRead($CONFIG, "Main", "ProjectsDirIsDefault", ""), 8)) == "true") Then
				GUICtrlSetState($CheckboxMakeDefault, $GUI_CHECKED)
				GUICtrlSetState($InputLocation, $GUI_DISABLE)
				GUICtrlSetState($ButtonProjectBrowse, $GUI_DISABLE)
			EndIf
		EndIf
	EndIf
	Return
EndFunc   ;==>_LoadGlobalConfig

; #FUNCTION# ====================================================================================================================
; Name...........: _SaveGlobalConfig
; Description ...: Saves the global configuration. If the config file does not exist, it will be created.
; Syntax.........: _SaveGlobalConfig()
; Parameters ....: None.
; Return values .: None. The options are immediately written to the config file.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......: _LoadGlobalConfig
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _SaveGlobalConfig()
	Local $sProjectsDir = GUICtrlRead($InputLocation)
	If (_FileIsDir($sProjectsDir)) Then
		IniWrite($CONFIG, "Main", "ProjectsDir", $sProjectsDir)
		If (GUICtrlRead($CheckboxMakeDefault) == $GUI_CHECKED) Then
			IniWrite($CONFIG, "Main", "ProjectsDirIsDefault", "True")
		Else
			IniWrite($CONFIG, "Main", "ProjectsDirIsDefault", "False")
		EndIf
	EndIf
	Return
EndFunc   ;==>_SaveGlobalConfig

; #FUNCTION# ====================================================================================================================
; Name...........: _DisplayAutoItStandardLibs
; Description ...: Enumerates and displays all the all the standard includes that were installed with AutoItV3 in the "AutoItV3
;                  Standard Includes" listview control.
; Syntax.........: _DisplayAutoItStandardLibs()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _DisplayAutoItStandardLibs()
	; First get the Includes directory and make sure it exists.
	Local $sLibsDir = _GetAutoItIncludesDir()
	If (_FileIsDir($sLibsDir)) Then
		; Get a handle for the source listview control.
		Local $hSrcHandle = GUICtrlGetHandle($ListViewSourceLibs)
		If (IsHWnd($hSrcHandle)) Then
			; Block repainting of the listview and clear its contents.
			_GUICtrlListView_BeginUpdate($hSrcHandle)
			_GUICtrlListView_DeleteAllItems($hSrcHandle)
			; Enumerate the libraries in the Includes directory and add the filename of each one to the listview.
			Local $idx = 0
			Local $aLibs[1]
			$aLibs[0] = 0
			$aLibs = _FileRecurseBuildList($sLibsDir, $aLibs, "*.au3")
			For $idx = 1 To $aLibs[0]
				_GUICtrlListView_AddItem($hSrcHandle, _FileGetFileName($aLibs[$idx]))
			Next
			; Repaint the listview.
			_GUICtrlListView_EndUpdate($hSrcHandle)
		EndIf
		$hSrcHandle = 0
	EndIf
	Return
EndFunc   ;==>_DisplayAutoItStandardLibs

; #FUNCTION# ====================================================================================================================
; Name...........: _ClearSourceLibs
; Description ...: Clears the contents of the "AutoItV3 Standard Includes" listview control.
; Syntax.........: _ClearSourceLibs()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/08/2011
; Remarks .......:
; Related .......: _ClearTargetLibs
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ClearSourceLibs()
	Local $hSrcHandle = GUICtrlGetHandle($ListViewSourceLibs)
	If (IsHWnd($hSrcHandle)) Then
		_GUICtrlListView_BeginUpdate($hSrcHandle)
		_GUICtrlListView_DeleteAllItems($hSrcHandle)
		_GUICtrlListView_EndUpdate($hSrcHandle)
	EndIf
	$hSrcHandle = 0
	Return
EndFunc   ;==>_ClearSourceLibs

; #FUNCTION# ====================================================================================================================
; Name...........: _ClearTargetLibs
; Description ...: Clears the contents of the "Project Includes" listview control.
; Syntax.........: _ClearTargetLibs()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/08/2011
; Remarks .......:
; Related .......: _ClearSourceLibs
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ClearTargetLibs()
	Local $hSrcHandle = GUICtrlGetHandle($ListViewTargetLibs)
	If (IsHWnd($hSrcHandle)) Then
		_GUICtrlListView_BeginUpdate($hSrcHandle)
		_GUICtrlListView_DeleteAllItems($hSrcHandle)
		_GUICtrlListView_EndUpdate($hSrcHandle)
	EndIf
	$hSrcHandle = 0
	Return
EndFunc   ;==>_ClearTargetLibs

; #FUNCTION# ====================================================================================================================
; Name...........: _ResetForm
; Description ...: Resets all the form controls back to their default states and reloads the global configuration.
; Syntax.........: _ResetForm()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/04/2011
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ResetForm()
	GUICtrlSetState($RadioApp, $GUI_CHECKED)
	GUICtrlSetData($InputProjName, "")
	GUICtrlSetData($InputLocation, "")
	GUICtrlSetState($InputLocation, $GUI_ENABLE)
	GUICtrlSetState($CheckboxMakeDefault, $GUI_UNCHECKED)
	GUICtrlSetData($InputFullPath, "")
	GUICtrlSetData($InputMainScript, "")
	_DisplayAutoItStandardLibs()
	_ClearTargetLibs()
	GUICtrlSetData($ListViewTargetLibs, "")
	GUICtrlSetData($InputAutoItVer, @AutoItVersion)
	GUICtrlSetData($InputAuthor, @UserName)
	GUICtrlSetData($InputScriptVer, "1.0.0.0")
	GUICtrlSetData($DateCreated, _NowCalcDate())
	GUICtrlSetData($DateModified, _NowCalcDate())
	GUICtrlSetData($InputCompany, "")
	GUICtrlSetData($InputCopyright, "")
	GUICtrlSetData($EditDescription, "")
	GUICtrlSetState($CheckboxRequireAdmin, $GUI_UNCHECKED)
	GUICtrlSetState($CheckboxHasGui, $GUI_ENABLE + $GUI_UNCHECKED)
	GUICtrlSetState($CheckboxUseConfig, $GUI_UNCHECKED)
	GUICtrlSetData($InputConfigName, "")
	GUICtrlSetState($InputConfigName, $GUI_DISABLE)
	_GUICtrlComboBox_SetCurSel($ComboCopyPolicy, 0)
	_LoadGlobalConfig()
	Return
EndFunc   ;==>_ResetForm

; #FUNCTION# ====================================================================================================================
; Name...........: _LoadReferencesFromProject
; Description ...: Loads all library references (includes) from the project file and load them into the target listview control.
; Syntax.........: _LoadReferencesFromProject($sProjectFile)
; Parameters ....: $sProjectFile - The full path to the project file to load the references from.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 02/08/2011
; Remarks .......: This is meant to be called from _LoadProject().
; Related .......: _LoadProject, _LoadDetailsFromProject
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _LoadReferencesFromProject($sProjectFile)
	; Make sure the project file exists and read all the key-value pairs of the References section into an array.
	If (FileExists($sProjectFile)) Then
		Local $aLibs = IniReadSection($sProjectFile, "References")
		If ((Not @error) And (IsArray($aLibs))) Then
			Local $sLocalLib = ""
			Local $x = 0
			; Get handles for the source and target listview controls and block repainting of both listviews until we're done.
			Local $hSrcHandle = GUICtrlGetHandle($ListViewSourceLibs)
			Local $hTargHandle = GUICtrlGetHandle($ListViewTargetLibs)
			_GUICtrlListView_BeginUpdate($hSrcHandle)
			_GUICtrlListView_BeginUpdate($hTargHandle)
			; Iterate through the array of Includes.
			For $x = 1 To $aLibs[0][0]
				; Build the default parent directory.
				$sLocalLib = $aLibs[$x][1]
				Local $sParent = $HOME
				Local $sTemp = ""
				If ($InputFullPath <> 0) Then
					$sTemp = GUICtrlRead($InputFullPath)
				Else
					$sTemp = _FileGetDirFromPath($sProjectFile)
				EndIf

				If (StringLen($sTemp) > 0) Then
					$sParent = $sTemp
				EndIf

				If (StringRight($sParent, 1) <> "\") Then
					$sParent &= "\"
				EndIf

				; Does the string contain a path delimiter?
				If (StringInStr($sLocalLib, "\")) Then
					; Does the path include a drive letter?
					If (StringInStr($sLocalLib, ":") == 0) Then
						; Assume the path is a child of the project directory.
						If (StringLeft($sLocalLib, 1) == "\") Then
							$sLocalLib = $sParent & StringRight($sLocalLib, StringLen($sLocalLib) - 1)
						Else
							$sLocalLib = $sParent & $sLocalLib
						EndIf
					EndIf

					If (Not FileExists($sLocalLib)) Then
						; CB_TODO: Consider giving the user the option to abort loading the project here.
						MsgBox(16, $MY_NAME, "Unable to locate project reference: " & $aLibs[$x][1])
						ContinueLoop
					EndIf
				Else
					; Only a filename was provided. Is it in the directory we executed from?
					$sLocalLib = $sParent & $sLocalLib
					If (Not FileExists($sLocalLib)) Then
						; Nope. Wasn't in there. Is it in AutoIt's "Include" directory?
						$sLocalLib = _GetAutoItIncludesDir() & "\" & $aLibs[$x][1]
						If (Not FileExists($sLocalLib)) Then
							; CB_TODO: Consider giving the user the option to abort loading the project here.
							MsgBox(16, $MY_NAME, "Unable to locate project reference: " & $aLibs[$x][1])
							ContinueLoop
						EndIf
					EndIf
					$sLocalLib = $aLibs[$x][1]
				EndIf

				; Add it to the target references listview.
				_GUICtrlListView_AddItem($hTargHandle, $sLocalLib)
				; See if it exists in the source references listview. If so, remove it from source.
				Local $nLocatedIndex = _GUICtrlListView_FindText($hSrcHandle, $aLibs[$x][1], -1)
				If ($nLocatedIndex <> -1) Then
					_GUICtrlListView_DeleteItem($hSrcHandle, $nLocatedIndex)
				EndIf
			Next
			; Repaint both listviews and release the handles.
			_GUICtrlListView_EndUpdate($hSrcHandle)
			_GUICtrlListView_EndUpdate($hTargHandle)
			$hSrcHandle = 0
			$hTargHandle = 0
		EndIf
	EndIf
	Return
EndFunc   ;==>_LoadReferencesFromProject

; #FUNCTION# ====================================================================================================================
; Name...........: _LoadDetailsFromProject
; Description ...: Loads the project details from the project file.
; Syntax.........: _LoadDetailsFromProject($sProjectFile)
; Parameters ....: $sProjectFile - The full path to the project file to load the references from.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......: This is meant to be called from _LoadProject().
; Related .......: _LoadProject, _LoadReferencesFromProject
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _LoadDetailsFromProject($sProjectFile)
	If (FileExists($sProjectFile)) Then
		Local $sAutoItVer = StringStripWS(IniRead($sProjectFile, "Details", "AutoItVer", @AutoItVersion), 8)
		Local $sAuthor = IniRead($sProjectFile, "Details", "Author", "")
		Local $sScriptVer = StringStripWS(IniRead($sProjectFile, "Details", "ScriptVer", "1.0.0.0"), 8)
		Local $sDateCreated = StringStripWS(IniRead($sProjectFile, "Details", "Date", _NowCalcDate()), 8)
		Local $sDateModified = StringStripWS(IniRead($sProjectFile, "Details", "Modified", _NowCalcDate()), 8)
		Local $sCompany = IniRead($sProjectFile, "Details", "Company", "")
		Local $sCopyright = IniRead($sProjectFile, "Details", "Copyright", "")
		Local $sDescription = IniRead($sProjectFile, "Details", "Description", "")
		Local $sRequireAdmin = StringStripWS(IniRead($sProjectFile, "Details", "RequireAdmin", "False"), 8)
		Local $iRequireAdmin = False
		If (StringLower($sRequireAdmin) == "true") Then
			$iRequireAdmin = True
		EndIf

		If (StringInStr($sDescription, "|") > 0) Then
			$sDescription = StringReplace($sDescription, "|", @CRLF)
		EndIf

		Local $sHasGui = StringStripWS(IniRead($sProjectFile, "Details", "HasGUI", "False"), 8)
		Local $iHasGui = False
		If (StringLower($sHasGui) == "true") Then
			$iHasGui = True
		EndIf

		; CB_TODO: Probably need to do some validation here.

		GUICtrlSetData($InputAutoItVer, $sAutoItVer)
		GUICtrlSetData($InputAuthor, $sAuthor)
		GUICtrlSetData($InputScriptVer, $sScriptVer)
		GUICtrlSetData($DateCreated, $sDateCreated)
		GUICtrlSetData($DateModified, $sDateModified)
		GUICtrlSetData($InputCompany, $sCompany)
		GUICtrlSetData($InputCopyright, $sCopyright)
		GUICtrlSetData($EditDescription, $sDescription)
		If ($iRequireAdmin) Then
			GUICtrlSetState($CheckboxRequireAdmin, $GUI_CHECKED)
		Else
			GUICtrlSetState($CheckboxRequireAdmin, $GUI_UNCHECKED)
		EndIf

		If ($iHasGui) Then
			GUICtrlSetState($CheckboxHasGui, $GUI_CHECKED)
		Else
			GUICtrlSetState($CheckboxHasGui, $GUI_UNCHECKED)
		EndIf
	EndIf
	Return
EndFunc   ;==>_LoadDetailsFromProject

; #FUNCTION# ====================================================================================================================
; Name...........: _LoadProject
; Description ...: Loads all of the project settings from the specified project file.
; Syntax.........: _LoadProject($sProjectFile)
; Parameters ....: $sProjectFile - The full path to the project file to load the references from.
; Return values .: Success - True.
;                  Failure - False.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/06/2011
; Remarks .......:
; Related .......: _LoadReferencesFromProject, _LoadDetailsFromProject
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _LoadProject($sProjectFile)
	; Make sure the file exists and see if the project info section exists (validate).
	If (FileExists($sProjectFile)) Then
		Local $aSection = IniReadSection($sProjectFile, "AutoItProject")
		If ((@error) Or ($aSection[0][0] == 0)) Then
			MsgBox(16, $MY_NAME, "The specified file is not a valid " & $MY_NAME & " project file.")
			_ResetForm()
			Return False
		Else
			; Get the project type.
			$aSection = 0
			Local $nProjType = Int(StringStripWS(IniRead($sProjectFile, "AutoItProject", "ProjectType", ""), 8))
			If ($nProjType == $PROJ_TYPE_LIB) Then
				GUICtrlSetState($RadioLib, $GUI_CHECKED)
			EndIf

			; Get the project name.
			Dim $sProjName = IniRead($sProjectFile, "AutoItProject", "Name", "")
			GUICtrlSetData($InputProjName, $sProjName)
			If (StringLen($sProjName) == 0) Then
				MsgBox(16, $MY_NAME, "The specified project file does not define a project name." & @CRLF & _
						"The specified project is invalid.")
				_ResetForm()
				Return False
			EndIf

			; Get the project path.
			Local $sProjPath = IniRead($sProjectFile, "AutoItProject", "Path", "")
			If (StringLen($sProjPath) == 0) Then
				MsgBox(16, $MY_NAME, "The specified project file does not contain a project path.")
				_ResetForm()
				Return False
			EndIf

			; Make sure the project path is a directory.
			If (Not _FileIsDir($sProjPath)) Then
				MsgBox(16, $MY_NAME, "The specified project path does not exist:" & @CRLF & $sProjPath)
				_ResetForm()
				Return False
			EndIf

			; Fixup the path string.
			If (StringRight($sProjPath, 1) <> "\") Then
				$sProjPath &= "\"
			EndIf
			GUICtrlSetData($InputFullPath, $sProjPath)

			; Get the full path to the main project script.
			Local $sMainScript = IniRead($sProjectFile, "AutoItProject", "MainScriptName", "")
			If (StringLen($sMainScript) == 0) Then
				MsgBox(16, $MY_NAME, "The specified project file does not define the main script source file to use.")
				_ResetForm()
				Return False
			EndIf

			; See if the main script is a child of the project directory.
			If (StringLeft($sMainScript, 1) == "\") Then
				$sMainScript = StringRight($sMainScript, StringLen($sMainScript) - 1)
			EndIf
			GUICtrlSetData($InputMainScript, $sMainScript)

			; Get the config file name if present.
			If (GUICtrlRead($RadioApp) == $GUI_CHECKED) Then
				Local $sConfigFile = IniRead($sProjectFile, "AutoItProject", "ConfigFileName", "")
				If (StringLen($sConfigFile) > 0) Then
					If (StringLeft($sConfigFile, 1) == "\") Then
						$sConfigFile = StringRight($sConfigFile, StringLen($sConfigFile) - 1)
					EndIf
					GUICtrlSetData($InputConfigName, $sConfigFile)
					GUICtrlSetState($InputConfigName, $GUI_ENABLE)
					GUICtrlSetState($CheckboxUseConfig, $GUI_ENABLE + $GUI_CHECKED)
				EndIf
			EndIf

			; Get the Include copy policy.
			Local $nCopyMode = Int(StringStripWS(IniRead($sProjectFile, "AutoItProject", "CopyLibPolicy", 0), 8))
			If (($nCopyMode == $CP_ALWAYS) Or ($nCopyMode == $CP_IFNEWER) Or ($nCopyMode == $CP_IFNOTEXIST)) Then
				_GUICtrlComboBox_SetCurSel($ComboCopyPolicy, $nCopyMode)
			EndIf

			; Load all the project references.
			_LoadReferencesFromProject($sProjectFile)

			; Load the project details.
			_LoadDetailsFromProject($sProjectFile)
		EndIf
	EndIf
	Return True
EndFunc   ;==>_LoadProject

; #FUNCTION# ====================================================================================================================
; Name...........: _CreateNewProjectFile
; Description ...: Creates a default project file at the specified path.
; Syntax.........: _CreateNewProjectFile($sProjectFilePath)
; Parameters ....: $sProjectFilePath - The full path to the project file to write to. If it exists, it will be overwritten.
; Return values .: None. On error, sets @error to the following:
;                  |1 - The specified project file path could not be written to.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _CreateNewProjectFile($sProjectFilePath)
	ConsoleWrite($MY_NAME & ": Project file doesn't exist. Creating...." & @CRLF)
	Local $hProjFileHandle = FileOpen($sProjectFilePath, 2)
	If ($hProjFileHandle == -1) Then
		Return SetError(1)
	EndIf

	FileWriteLine($hProjFileHandle, "; *** This file was generated by a tool. " & $MY_NAME & " v" & _GetMyVersion() & ".")
	FileWriteLine($hProjFileHandle, "; *** " & $MY_NAME & " project descriptor file. Unless you know what you are doing,")
	FileWriteLine($hProjFileHandle, "; *** DO NOT modify any of the lines below. Please refer to the documentation.")
	FileWriteLine($hProjFileHandle, "")
	FileWriteLine($hProjFileHandle, "[AutoItProject]")
	FileWriteLine($hProjFileHandle, "; Acceptable values: 1 = application script, 2 = library (include) script")
	FileWriteLine($hProjFileHandle, "ProjectType=" & $PROJ_TYPE_APP)
	FileWriteLine($hProjFileHandle, "Name=")
	FileWriteLine($hProjFileHandle, "; The full path to the project directory.")
	FileWriteLine($hProjFileHandle, "Path=")
	FileWriteLine($hProjFileHandle, "; The main script name (filename only).")
	FileWriteLine($hProjFileHandle, "MainScriptName=")
	FileWriteLine($hProjFileHandle, "ConfigFileName=")
	FileWriteLine($hProjFileHandle, "; Acceptable values: 0 = if newer, 1 = always (overwrite), 2 = if not exist in project")
	FileWriteLine($hProjFileHandle, "CopyLibPolicy=0")
	FileWriteLine($hProjFileHandle, "")
	FileWriteLine($hProjFileHandle, "[References]")
	FileWriteLine($hProjFileHandle, "; Each include should be prefixed with the word 'Lib' followed by a sequential number.")
	FileWriteLine($hProjFileHandle, "; Example: Lib1=Array.au3")
	FileWriteLine($hProjFileHandle, "; Example: Lib2=Date.au3")
	FileWriteLine($hProjFileHandle, "Lib1=")
	FileWriteLine($hProjFileHandle, "")
	FileWriteLine($hProjFileHandle, "[Details]")
	FileWriteLine($hProjFileHandle, "; Must be a four-octet version string. Example: 1.0.2.1")
	FileWriteLine($hProjFileHandle, "AutoItVer=" & @AutoItVersion)
	FileWriteLine($hProjFileHandle, "Author=")
	FileWriteLine($hProjFileHandle, "; Must be a four-octet version string. Example: 1.0.2.1")
	FileWriteLine($hProjFileHandle, "ScriptVer=1.0.0.0")
	FileWriteLine($hProjFileHandle, "; Dates must be in YYYY/MM/DD format or they will be ignored.")
	FileWriteLine($hProjFileHandle, "Date=" & _NowCalcDate())
	FileWriteLine($hProjFileHandle, "Modified=" & _NowCalcDate())
	FileWriteLine($hProjFileHandle, "Company=")
	FileWriteLine($hProjFileHandle, "Copyright=")
	FileWriteLine($hProjFileHandle, "; Any line breaks or carriage returns (multi-line) in the description must be replaced with the pipe character '|'.")
	FileWriteLine($hProjFileHandle, "Description=")
	FileWriteLine($hProjFileHandle, "; Acceptable values: True - the main script will contain GUI code. False - the main script will not have a GUI.")
	FileWriteLine($hProjFileHandle, "HasGUI=False")
	FileWriteLine($hProjFileHandle, "; Acceptable values: True - the main script requires administrative rights, False - user rights are sufficient.")
	FileWriteLine($hProjFileHandle, "RequireAdmin=False")
	FileFlush($hProjFileHandle)
	FileClose($hProjFileHandle)
	Return
EndFunc   ;==>_CreateNewProjectFile

; #FUNCTION# ====================================================================================================================
; Name...........: _WriteProjectFile
; Description ...: Writes project settings to the specified project file. If the file does not exist, it will be created.
; Syntax.........: _WriteProjectFile($sProjectFile, $aProjectInfo[, $aReferences[, $iHasGui[, $iRequireAdmin[, $isLib]]]])
; Parameters ....: $sProjectFile  - The full path to the project file to write to. If it does not exist, it will be created.
;                  $aProjectInfo  - An array containing project info. See _WriteApplicationScript() for definition.
;                  $aReferences   - Optional. An array containing project references (includes). See _WriteApplicationScript for definition.
;                  $iHasGui       - Optional. Set True if the project has/will have a GUI.
;                  $iRequireAdmin - Optional. Set True if the project requires/will require administrative privileges.
;                  $isLib         - Optional. Set True if this project is a library (include). This will cause $iRequireAdmin and
;                                   $iHasGui to be ignored.
;                  $sConfigName   - Optional. The name of the config file to associate with the application script.
;                                   Ignored if $isLib = True.
; Return values .: None. On error, sets @error to one of the following:
;                  |1 - The project file path was not specified.
;                  |2 - The specified file is not an AutoIt project file.
;                  |3 - An invalid project info array was specified.
;                  |4 - The specified project file could not be written to.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 02/14/2011
; Remarks .......:
; Related .......: _LoadProject, _CreateNewProjectFile
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _WriteProjectFile($sProjectFilePath, $aProjectInfo, $aReferences = 0, $iHasGui = False, $iRequireAdmin = False, $isLib = False, $sConfigName = "")
	ConsoleWrite($MY_NAME & ": Saving project file..." & @CRLF)
	; Was a file path specified?
	If (StringLen($sProjectFilePath) == 0) Then
		Return SetError(1)
	EndIf

	; Does the path have a valid extension?
	If (_FileExtension($sProjectFilePath) <> $PROJECT_FILE_EXT) Then
		Return SetError(2)
	EndIf

	; Do we have a valid project info array?
	If ((Not IsArray($aProjectInfo)) Or ($aProjectInfo[0] <> 9)) Then
		Return SetError(3)
	EndIf

	; If the project file doesn't already exist, generate one at the specified path.
	If (Not FileExists($sProjectFilePath)) Then
		_CreateNewProjectFile($sProjectFilePath)
		If (@error) Then
			Return SetError(4)
		EndIf
	EndIf

	; Write all the settings to the project file.
	If ($isLib) Then
		IniWrite($sProjectFilePath, "AutoItProject", "ProjectType", $PROJ_TYPE_LIB)
	Else
		IniWrite($sProjectFilePath, "AutoItProject", "ProjectType", $PROJ_TYPE_APP)
	EndIf
	IniWrite($sProjectFilePath, "AutoItProject", "Name", $aProjectInfo[4])
	IniWrite($sProjectFilePath, "AutoItProject", "Path", GUICtrlRead($InputFullPath))
	IniWrite($sProjectFilePath, "AutoItProject", "MainScriptName", GUICtrlRead($InputMainScript))

	If (StringLen($sConfigName) > 0) Then
		IniWrite($sProjectFilePath, "AutoItProject", "ConfigFileName", $sConfigName)
	Else
		IniWrite($sProjectFilePath, "AutoItProject", "ConfigFileName", "")
	EndIf

	Local $nPolicy = _GUICtrlComboBox_GetCurSel($ComboCopyPolicy)
	If (($nPolicy == $CP_ALWAYS) Or ($nPolicy == $CP_IFNEWER) Or ($nPolicy == $CP_IFNOTEXIST)) Then
		IniWrite($sProjectFilePath, "AutoItProject", "CopyLibPolicy", $nPolicy)
	Else
		IniWrite($sProjectFilePath, "AutoItProject", "CopyLibPolicy", 0)
	EndIf

	; Remove all the includes currently in the project file.
	Local $k = 0
	Local $aKeys = IniReadSection($sProjectFilePath, "References")
	If ((Not @error) And (IsArray($aKeys))) Then
		For $k = 1 To $aKeys[0][0]
			IniDelete($sProjectFilePath, "References", $aKeys[$k][0])
		Next
	EndIf

	; Write the current contents of the includes array to the config file.
	If ((IsArray($aReferences)) And ($aReferences[0] > 0)) Then
		For $k = 1 To $aReferences[0]
			IniWrite($sProjectFilePath, "References", "Lib" & $k, $aReferences[$k])
		Next
	EndIf

	IniWrite($sProjectFilePath, "Details", "AutoItVer", $aProjectInfo[1])
	IniWrite($sProjectFilePath, "Details", "Author", $aProjectInfo[2])
	IniWrite($sProjectFilePath, "Details", "ScriptVer", $aProjectInfo[3])
	IniWrite($sProjectFilePath, "Details", "Date", $aProjectInfo[5])
	IniWrite($sProjectFilePath, "Details", "Modified", $aProjectInfo[6])
	IniWrite($sProjectFilePath, "Details", "Company", $aProjectInfo[7])
	IniWrite($sProjectFilePath, "Details", "Copyright", $aProjectInfo[8])

	Local $sDescription = $aProjectInfo[9]
	If (StringInStr($sDescription, @CRLF) > 0) Then
		$sDescription = StringReplace($sDescription, @CRLF, "|")
	EndIf
	IniWrite($sProjectFilePath, "Details", "Description", $sDescription)

	If ($iHasGui) Then
		IniWrite($sProjectFilePath, "Details", "HasGUI", "True")
	Else
		IniWrite($sProjectFilePath, "Details", "HasGUI", "False")
	EndIf

	If ($iRequireAdmin) Then
		IniWrite($sProjectFilePath, "Details", "RequireAdmin", "True")
	Else
		IniWrite($sProjectFilePath, "Details", "RequireAdmin", "False")
	EndIf
	Return
EndFunc   ;==>_WriteProjectFile

; #FUNCTION# ====================================================================================================================
; Name...........: _EditScript
; Description ...: Opens the specified script file in the SciTE code editor.
; Syntax.........: _EditScript($sScript)
; Parameters ....: $sScript - The full path to the script file to edit.
; Return values .: None. On error, sets @error to one of the following:
;                  |1 - The specified script does not exist.
;                  |2 - The SciTE executable could not be found.
;                  |3 - The editor could not be launched.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......: If the editor (SciTE) is not already running, it will be launched and then the script will be opened in it.
;                  If the editor is already running, then the script will be opened in a new tab.
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _EditScript($sScript)
	; Make sure the script exists.
	If (Not FileExists($sScript)) Then
		Return SetError(1)
	EndIf

	; Make sure the SciTE editor exists.
	Local $sSciteExecPath = _GetSciteExec()
	If (StringLen($sSciteExecPath) == 0) Then
		Return SetError(2)
	EndIf

	; Open the script in SciTE.
	Local $result = ShellExecute($sSciteExecPath, '"' & $sScript & '"', GUICtrlRead($InputLocation))
	If ($result == 0) Then
		Return SetError(3)
	EndIf
	Return
EndFunc   ;==>_EditScript

; #FUNCTION# ====================================================================================================================
; Name...........: _GetScriptEditResult
; Description ...: Gets the error description message associated with the specified script edit error code.
; Syntax.........: _GetScriptEditResult($nResultCode)
; Parameters ....: $nResultCode - The @error code returned by _EditScript.
; Return values .: Success - The error message associated with the specified code.
;                  Failure - "(unknown)" if the specified value is not an integer or valid result code.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......: _EditScript
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GetScriptEditResult($nResultCode)
	Local $sResult = "(unknown)"
	If (IsInt($nResultCode)) Then
		Switch $nResultCode
			Case 1
				$sResult = "The script path could not be found."
			Case 2
				$sResult = "Could not locate SciTE. Please make sure SciTE4AutoIt3 is installed."
			Case 3
				$sResult = "Failed to execute SciTE."
		EndSwitch
	EndIf
	Return $sResult
EndFunc   ;==>_GetScriptEditResult

; #FUNCTION# ====================================================================================================================
; Name...........: _GetAppConfigGenerationResult
; Description ...: Gets the error description message associated with the specified app config generation error code.
; Syntax.........: _GetAppConfigGenerationResult($nResultCode)
; Parameters ....: $nResultCode - The @error code returned by _CreateApplicationConfig.
; Return values .: Success - The error message associated with the specified code.
;                  Failure - "(unknown)" if the specified value is not an integer or valid result code.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......: _CreateApplicationConfig
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GetAppConfigGenerationResult($nResultCode)
	Local $sResult = "(unknown)"
	If (IsInt($nResultCode)) Then
		Switch $nResultCode
			Case 1
				$sResult = "The specified param value ($aProjectInfo) is not a valid project info array structure."
			Case 2
				$sResult = "The specified configuration path is not a valid config file path or is a file that already exists."
			Case 3
				$sResult = "The config file could not be created or opened for writing."
		EndSwitch
	EndIf
	Return $sResult
EndFunc   ;==>_GetAppConfigGenerationResult

; #FUNCTION# ====================================================================================================================
; Name...........: _GetScriptGenerationResult
; Description ...: Gets the error description message associated with the specified script generation error code.
; Syntax.........: _GetScriptGenerationResult($nResultCode)
; Parameters ....: $nResultCode - The @error code returned by _WriteProjectFile().
; Return values .: Success - The error message associated with the specified code.
;                  Failure - "(unknown)" if the specified value is not an integer or valid result code.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......: _WriteProjectFile
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GetScriptGenerationResult($nResultCode)
	Local $sResult = "(unknown)"
	If (IsInt($nResultCode)) Then
		Switch $nResultCode
			Case 1
				$sResult = "The provided script path is null, empty, or not a string."
			Case 2
				$sResult = "The parent directory does not exist. Cannot create a script in a non-existent directory."
			Case 3
				$sResult = "A valid project information array was not provided."
			Case 4
				$sResult = "Unable to create the file or open in write mode."
		EndSwitch
	EndIf
	Return $sResult
EndFunc   ;==>_GetScriptGenerationResult

; #FUNCTION# ====================================================================================================================
; Name...........: _GetProjectGenerationResult
; Description ...: Gets the error description message associated with the specified project file generation error code.
; Syntax.........: _GetProjectGenerationResult($nResultCode)
; Parameters ....: $nResultCode - The @error code returned by _GenerateScript()
; Return values .: Success - The error message associated with the specified code.
;                  Failure - "(unknown)" if the specified value is not an integer or valid result code.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......: _GenerateScript
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _GetProjectGenerationResult($nResultCode)
	Local $sResult = "(unknown)"
	If (IsInt($nResultCode)) Then
		Switch $nResultCode
			Case 1
				$sResult = "The project file path was not specified."
			Case 2
				$sResult = "The specified file is not an AutoIt project file."
			Case 3
				$sResult = "An invalid project info array was specified."
			Case 4
				$sResult = "The specified project file could not be written to."
		EndSwitch
	EndIf
	Return $sResult
EndFunc   ;==>_GetProjectGenerationResult

; #FUNCTION# ====================================================================================================================
; Name...........: _CopyLibs
; Description ...: Copies an array of includes the the project.
; Syntax.........: _CopyLibs($aReferences, $sTarget[, $iCopyMode])
; Parameters ....: $aReferences - An array of includes. Only the includes that are non-standard and not sourced from a child
;                                 directory of the project will be copied to the target.
;                  $sTarget     - The target directory to copy the includes to.
;                  $iCopyMode   - Optional. Can be one of the copy mode constants:
;                                 |$CP_IFNEWER    - The include will only be copied if the file does not already exist in the target
;                                                   directory. If the file does exist, then the file will be copied if the source is
;                                                   newer than the target. This is the default.
;                                 |$CP_ALWAYS     - Copies the source file to the target, overwriting the target file if it exists.
;                                 |$CP_IFNOTEXIST - The source file will only be copied if it does not already exist in the target.
; Return values .: None. On error, sets @error to one of the following:
;                  |1 - A file copy was attempted, but failed.
;                  Sets @extended to the index in $aReferences, which represents the file that could not be copied.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/26/2011
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _CopyLibs($aReferences, $sTarget, $iCopyMode = $CP_IFNEWER)
	If ((IsArray($aReferences)) And ($aReferences[0] > 0)) Then
		If (StringRight($sTarget, 1) <> "\") Then
			$sTarget &= "\"
		EndIf

		Local $sFile = ""
		Local $fileIdx = 0
		For $fileIdx = 1 To $aReferences[0]
			; We only try to copy non-standard libraries that were not sourced from a child directory of the project.
			$sFile = $aReferences[$fileIdx]
			If (StringRegExp($sFile, "[[:alpha:]]\:\\.+", 0) == 1) Then
				If (FileExists($sFile)) Then
					Local $flagCopy = 8 ; We're going to attempt to create the target directory structure regardless.
					Local $iProceed = True ; We're assuming that we're going to proceed with the copy by default.
					Local $sTargetFile = $sTarget & _FileGetFileName($sFile)
					Switch $iCopyMode
						Case $CP_ALWAYS
							; Attempt to copy no matter what.
							$flagCopy += 1

						Case $CP_IFNEWER
							; If the target already exists, then we only copy if the source is newer than the target.
							If (FileExists($sTargetFile)) Then
								; Get and encode the source file modified time.
								Local $aSourceTime = FileGetTime($sFile)
								Local $tSourceTime = _Date_Time_EncodeFileTime($aSourceTime[1], $aSourceTime[2], $aSourceTime[0], _
										$aSourceTime[3], $aSourceTime[4], $aSourceTime[5])
								Local $pSourceTime = DllStructGetPtr($tSourceTime)
								$aSourceTime = 0

								; Get and encode the target file modified time.
								Local $aTargetTime = FileGetTime($sTargetFile)
								Local $tTargetTime = _Date_Time_EncodeFileTime($aTargetTime[1], $aTargetTime[2], $aTargetTime[0], _
										$aTargetTime[3], $aTargetTime[4], $aTargetTime[5])
								Local $pTargetTime = DllStructGetPtr($tTargetTime)
								$aTargetTime = 0

								; Check to see if the source file is newer than the target. If so, then we'll overwrite the target.
								If (_Date_Time_CompareFileTime($pSourceTime, $pTargetTime) == 1) Then
									$flagCopy += 1
								Else
									$iProceed = False
								EndIf
							EndIf

						Case $CP_IFNOTEXIST
							; If the target file exists, then we don't try to copy at all.
							If (FileExists($sTargetFile)) Then
								$iProceed = False
							EndIf
					EndSwitch

					; If we are still ok to proceed, then go ahead and copy the file.
					If ($iProceed) Then
						ConsoleWrite($MY_NAME & ": Copying '" & $sFile & "' to '" & $sTarget & "' ..." & @CRLF)
						If (FileCopy($sFile, $sTarget, $flagCopy) == 0) Then
							Return SetError(1, $fileIdx)
						EndIf
					EndIf
				EndIf
			EndIf
		Next
	EndIf
	Return
EndFunc   ;==>_CopyLibs
#EndRegion Utility Functions


#Region Event Handlers
; #FUNCTION# ====================================================================================================================
; Name...........: _ButtonProjectBrowseClick
; Description ...: Handler for the "browse for projects location" button click event. Presents the user with a folder selection
;                  dialog and then populates the location InputTextbox.
; Syntax.........: _ButtonProjectBrowseClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ButtonProjectBrowseClick()
	; Present the user with a folder selection/browse dialog.
	Local $sProjectsDir = FileSelectFolder("Select the projects folder", "", 1 + 2 + 4, @MyDocumentsDir, $FormMain)
	If ((Not @error) And (StringLen($sProjectsDir) > 0)) Then
		; If the user didn't cancel and we got a valid path, populate the project location Inputbox and call the
		; _InputLocationChange event handler (GUICtrlSetData() does not trigger the event automatically).
		GUICtrlSetData($InputLocation, $sProjectsDir)
		_InputLocationChange()
	EndIf
	Return
EndFunc   ;==>_ButtonProjectBrowseClick

; #FUNCTION# ====================================================================================================================
; Name...........: _ButtonAddLibClick
; Description ...: Handler for the add library button click event. Moves the selected libraries from the source listview control
;                  to the target listview control.
; Syntax.........: _ButtonAddLibClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/09/2011
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ButtonAddLibClick()
	Local $i = 0
	Local $sItemText = ""
	; Get handles for both listview controls.
	Local $hSrcHandle = GUICtrlGetHandle($ListViewSourceLibs)
	Local $hTargHandle = GUICtrlGetHandle($ListViewTargetLibs)
	; Block repainting of the listviews until we are done.
	_GUICtrlListView_BeginUpdate($hSrcHandle)
	_GUICtrlListView_BeginUpdate($hTargHandle)
	; Get a list of selected items from the source listview control.
	Local $aSelectedIndices = _GUICtrlListView_GetSelectedIndices($hSrcHandle, True)
	If ((IsArray($aSelectedIndices)) And ($aSelectedIndices[0] > 0)) Then
		; Add each selected item in the source listview to the target listview, if it does not already exist.
		For $i = 1 To $aSelectedIndices[0]
			$sItemText = _GUICtrlListView_GetItemText($hSrcHandle, $aSelectedIndices[$i])
			If (_GUICtrlListView_FindText($hTargHandle, $sItemText, -1, True) == -1) Then
				_GUICtrlListView_AddItem($hTargHandle, $sItemText)
			EndIf
		Next
		; Now remove each selected item from the source listview control.
		_GUICtrlListView_SetItemSelected($hSrcHandle, -1, False)
		For $i = $aSelectedIndices[0] To 1 Step -1
			_GUICtrlListView_DeleteItem($hSrcHandle, $aSelectedIndices[$i])
		Next
	EndIf
	; All done. Repaint the listview controls, clear the array, and free the handles.
	_GUICtrlListView_EndUpdate($hTargHandle)
	_GUICtrlListView_EndUpdate($hSrcHandle)
	$aSelectedIndices = 0
	$hTargHandle = 0
	$hSrcHandle = 0
	Return
EndFunc   ;==>_ButtonAddLibClick

; #FUNCTION# ====================================================================================================================
; Name...........: _ButtonBrowseLibClick
; Description ...: Handler for the "browse for library" button click event. Presents the user with a file selection dialog, then
;                  adds the selected library to the target library listview control.
; Syntax.........: _ButtonBrowseLibClick()
; Parameters ....: None.
; Return values .: Mone.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 02/08/2011
; Remarks .......:
; Related .......: _ButtonAddLibClick
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ButtonBrowseLibClick()
	; If we opened a project (instead of creating one) then we'll start in the project directory,
	; otherwise we start in directory we executed from.
	Local $startDir = $HOME
	If ($iWasLoaded) Then
		$startDir = _FileGetDirFromPath($projectFile)
	EndIf

	; Present the user with an open file dialog.
	Local $sSelectedLib = FileOpenDialog("Select AutoItV3 Include File", $startDir, "AutoItV3 Script (*.au3)", 1 + 4, "", $FormMain)
	If ((Not @error) And (StringLen($sSelectedLib) > 0)) Then
		; If the user didn't cancel and we have a valid path, then get the project path (if defined).
		Local $sParent = $HOME
		Local $sTemp = GUICtrlRead($InputFullPath)
		If (StringLen($sTemp) > 0) Then
			$sParent = $sTemp
			If (StringRight($sParent, 1) <> "\") Then
				$sParent &= "\"
			EndIf
		EndIf

		; Get a handle to the target listview control and block repainting it until we are done.
		Local $hTargHandle = GUICtrlGetHandle($ListViewTargetLibs)
		_GUICtrlListView_BeginUpdate($hTargHandle)
		Local $sRelativePath = ""
		Local $sLibToAdd = ""

		; Did the user select multiple files?
		If (StringInStr($sSelectedLib, "|") > 0) Then
			; Multiple files returned. The first path in the array is the containing directory.
			; All subsequent array elements are the selected filenames in that directory.
			; Here we iterate through the array and build the full path to each library and
			; make sure we aren't trying to reference the main script of the project.
			Local $j = 0
			Local $sFilePath = ""
			Local $aFiles = StringSplit($sSelectedLib, "|")
			For $j = 2 To $aFiles[0]
				$sFilePath = $aFiles[1] & "\" & $aFiles[$j]
				If (StringLower($sFilePath) == StringLower(GUICtrlRead($InputMainScript))) Then
					; You can't import yourself, dummy.
					MsgBox(16, $MY_NAME, "The main script cannot be added as a reference to itself.")
					Return
				EndIf
				; If the script is located somewhere in the project directory (either the root or a subdirectory)
				; then build a relative path string (to keep our #import statements short).
				If (StringInStr($sFilePath, $sParent) > 0) Then
					$sRelativePath = StringMid($sFilePath, StringLen($sParent) + 1)
					$sLibToAdd = $sRelativePath
				Else
					$sLibToAdd = $sFilePath
				EndIf

				If (_GUICtrlListView_FindText($hTargHandle, $sLibToAdd, -1, True) == -1) Then
					_GUICtrlListView_AddItem($hTargHandle, $sLibToAdd)
				EndIf
			Next
			$aFiles = 0
		Else
			; A single file was selected.
			If (StringLower($sSelectedLib) == StringLower(GUICtrlRead($InputMainScript))) Then
				; You can't import yourself, dummy.
				MsgBox(16, $MY_NAME, "The main script cannot be added as a reference to itself.")
				Return
			EndIf
			; If the script is located somewhere in the project directory (either the root or a subdirectory)
			; then build a relative path string (to keep our #import statements short).
			If (StringInStr($sSelectedLib, $sParent) > 0) Then
				$sRelativePath = StringMid($sSelectedLib, StringLen($sParent) + 1)
				$sLibToAdd = $sRelativePath
			Else
				$sLibToAdd = $sSelectedLib
			EndIf

			If (_GUICtrlListView_FindText($hTargHandle, $sLibToAdd, -1, True) == -1) Then
				_GUICtrlListView_AddItem($hTargHandle, $sLibToAdd)
			EndIf
		EndIf
		_GUICtrlListView_EndUpdate($hTargHandle)
		$hTargHandle = 0
	EndIf
	Return
EndFunc   ;==>_ButtonBrowseLibClick

; #FUNCTION# ====================================================================================================================
; Name...........: _ButtonRemoveLibClick
; Description ...: Handler for the "Remove Library" button click event. Moves the selected libraries from the target listview
;                  control back to the source libraries listview control. Any selected target libraries that are not part of the
;                  AutoItV3 standard base will just be removed from the target listview control.
; Syntax.........: _ButtonRemoveLibClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/09/2011
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ButtonRemoveLibClick()
	Local $i = 0
	Local $sItemText = ""
	; Get handles for both listview controls.
	Local $hSrcHandle = GUICtrlGetHandle($ListViewSourceLibs)
	Local $hTargHandle = GUICtrlGetHandle($ListViewTargetLibs)
	; Block repainting of the listviews until we are done.
	_GUICtrlListView_BeginUpdate($hSrcHandle)
	_GUICtrlListView_BeginUpdate($hTargHandle)
	; Get a list of selected items from the target listview control.
	Local $aSelectedIndices = _GUICtrlListView_GetSelectedIndices($hTargHandle, True)
	If ((IsArray($aSelectedIndices)) And ($aSelectedIndices[0] > 0)) Then
		; Add each selected item in the target listview to the source listview if it is an AutoItV3 standard library
		; and does not already exist in the source listview.
		For $i = 1 To $aSelectedIndices[0]
			$sItemText = _GUICtrlListView_GetItemText($hTargHandle, $aSelectedIndices[$i])
			If (StringInStr($sItemText, "\") == 0) Then
				If (_GUICtrlListView_FindText($hSrcHandle, $sItemText, -1, True) == -1) Then
					_GUICtrlListView_AddItem($hSrcHandle, $sItemText)
				EndIf
			EndIf
		Next
		; Now remove each selected item from the source listview control.
		_GUICtrlListView_SetItemSelected($hTargHandle, -1, False)
		For $i = 1 To $aSelectedIndices[0]
			_GUICtrlListView_DeleteItem($hTargHandle, $aSelectedIndices[$i])
		Next
	EndIf
	; All done. Repaint the listview controls, clear the array, and free the handles.
	_GUICtrlListView_EndUpdate($hSrcHandle)
	_GUICtrlListView_EndUpdate($hTargHandle)
	$aSelectedIndices = 0
	$hSrcHandle = 0
	$hTargHandle = 0
	Return
EndFunc   ;==>_ButtonRemoveLibClick

; #FUNCTION# ====================================================================================================================
; Name...........: _ButtonCancelClick
; Description ...: Handler for the "cancel and close" button click event. This discards any and all changes, destroys the GUI and
;                  terminates the application.
; Syntax.........: _ButtonCancelClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ButtonCancelClick()
	_OnFormMainClose()
EndFunc   ;==>_ButtonCancelClick

; #FUNCTION# ====================================================================================================================
; Name...........: _ButtonCreateClick
; Description ...: Handler for the create/save project button click event. This is where most of the real work is done.
;                  This creates or saves the defined project and then loads the main script file of the project in the SciTE editor.
; Syntax.........: _ButtonCreateClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/31/2011
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ButtonCreateClick()
	ConsoleWrite($MY_NAME & ": Creating/saving project..." & @CRLF)
	; Do we have a project name?
	Local $sProjName = GUICtrlRead($InputProjName)
	If (StringLen($sProjName) == 0) Then
		MsgBox(48, $MY_NAME, "You must provide a name for your project.")
		GUICtrlSetState($InputProjName, $GUI_FOCUS)
		Return
	EndIf

	; Do we have the project's parent location?
	Local $sProjectParent = GUICtrlRead($InputLocation)
	If (StringLen($sProjectParent) == 0) Then
		MsgBox(48, $MY_NAME, "You must specify the parent directory of your project.")
		GUICtrlSetState($InputLocation, $GUI_FOCUS)
		Return
	EndIf

	; Fixup the path.
	Local $sProjectHome = GUICtrlRead($InputFullPath)
	If (StringRight($sProjectHome, 1) <> "\") Then
		$sProjectHome &= "\"
	EndIf

	; Do we have the name of the main script file?
	Local $sMainScript = GUICtrlRead($InputMainScript)
	If (StringLen($sMainScript) == 0) Then
		MsgBox(48, $MY_NAME, "You must provide a name for the main script in your project.")
		GUICtrlSetState($InputMainScript, $GUI_FOCUS)
		Return
	EndIf

	; Fixup the file name.
	If (_FileExtension($sMainScript) <> "au3") Then
		$sMainScript &= ".au3"
	EndIf

	; Build the full paths to the project file and the main script file.
	Local $sScriptPath = $sProjectHome & $sMainScript
	ConsoleWrite($MY_NAME & ": Script path: " & $sScriptPath & @CRLF)
	Local $sProjectFilePath = $sProjectHome & $sProjName & "." & $PROJECT_FILE_EXT
	ConsoleWrite($MY_NAME & ": Project file: " & $sProjectFilePath & @CRLF)

	; Determine if we are creating a project, or updating one.
	If (StringInStr(GUICtrlRead($ButtonCreate), "create") > 0) Then
		; We are creating a project.  See if the folder for the specified project already exists.
		If (FileExists($sProjectHome)) Then
			If (MsgBox(4 + 32, $MY_NAME, "The specified project directory already exists. Are you sure you want to use it?") == 7) Then
				GUICtrlSetState($InputProjName, $GUI_FOCUS)
				Return
			EndIf
		EndIf

		; See if an existing project file exists.  If so, ask the user if we can overwrite it.
		; By "overwrite", what we really mean is that we'll delete it now, then generate a new
		; project file a little bit later.
		If (FileExists($sProjectFilePath)) Then
			If (MsgBox(4 + 32, $MY_NAME, "The specified project already exists.  Overwrite?" & _
					@CRLF & @CRLF & "This operation cannot be undone.") == 6) Then
				FileDelete($sProjectFilePath)
			Else
				GUICtrlSetState($InputProjName, $GUI_FOCUS)
				Return
			EndIf
		EndIf
	EndIf

	; Create the project folder if it doesn't already exist.
	If (Not _FileIsDir($sProjectHome)) Then
		If (DirCreate($sProjectHome) == 0) Then
			MsgBox(16, $MY_NAME, "Failed to create project folder:" & @CRLF & $sProjectHome)
			GUICtrlSetState($InputLocation, $GUI_FOCUS)
			Return
		EndIf
	EndIf

	; If the "create/use configuration" checkbox is checked, then make sure the config file name has been specified.
	Local $iHasConfig = False
	Local $sConfigFile = ""
	If (GUICtrlRead($CheckboxUseConfig) == $GUI_CHECKED) Then
		$sConfigFile = GUICtrlRead($InputConfigName)
		If (StringLen($sConfigFile) == 0) Then
			MsgBox(48, $MY_NAME, "You must provide a name for the configuration file.")
			GUICtrlSetState($InputConfigName, $GUI_FOCUS)
			Return
		Else
			; Make sure the file name has the correct extension. If not, append the default.
			Local $sExtension = _FileExtension($sConfigFile)
			If (($sExtension <> "ini") And ($sExtension <> "cgf") And ($sExtension <> "config") And ($sExtension <> "dat")) Then
				$sConfigFile &= ".ini"
			EndIf
			; Build the full path.
			$sConfigFile = $sProjectHome & $sConfigFile
			ConsoleWrite($MY_NAME & ": Config file: " & $sConfigFile & @CRLF)
			$iHasConfig = True
		EndIf
	EndIf

	; Initialize the project info array structure.
	Local $aProjectInfo = _ProjectInfoArrayInit()
	$aProjectInfo[4] = $sProjName

	; Build an array of target references from the listview.
	Local $aReferences = _GetReferences()

	Local $aDirs[4]
	Local $nDirNum = 0
	Local $sErrMsg = ""
	Local $sLibDir = ""
	; Is this going to be an application script or a library?
	If (GUICtrlRead($RadioApp) == $GUI_CHECKED) Then
		; We're creating an application script project.
		ConsoleWrite($MY_NAME & ": Project type: application script." & @CRLF)
		; Get the AutoIt version and script version.
		$aProjectInfo[1] = StringStripWS(GUICtrlRead($InputAutoItVer), 8)
		$aProjectInfo[3] = StringStripWS(GUICtrlRead($InputScriptVer), 8)
		; Get the created and modified dates.
		Local $aCreatedMonth = _GUICtrlDTP_GetSystemTime(GUICtrlGetHandle($DateCreated))
		Local $aModifiedMonth = _GUICtrlDTP_GetSystemTime(GUICtrlGetHandle($DateModified))
		$aProjectInfo[5] = $aCreatedMonth[0] & "/" & $aCreatedMonth[1] & "/" & $aCreatedMonth[2]
		$aProjectInfo[6] = $aModifiedMonth[0] & "/" & $aModifiedMonth[1] & "/" & $aModifiedMonth[2]
		$aCreatedMonth = 0
		$aModifiedMonth = 0
		; Get the company and copyright.
		$aProjectInfo[7] = GUICtrlRead($InputCompany)
		$aProjectInfo[8] = GUICtrlRead($InputCopyright)

		; This application has/will have a GUI.
		Local $iHasGui = False
		If (GUICtrlRead($CheckboxHasGui) == $GUI_CHECKED) Then
			$iHasGui = True
		EndIf

		; This application requires/will require administrative privileges.
		Local $iRequireAdmin = False
		If (GUICtrlRead($CheckboxRequireAdmin) == $GUI_CHECKED) Then
			$iRequireAdmin = True
		EndIf

		; Create the configuration file and check for errors. Continue if an error occurs.
		If (($iHasConfig) And (StringLen($sConfigFile) > 0)) Then
			_CreateApplicationConfig($sConfigFile, $aProjectInfo)
			If (@error) Then
				Local $nError = @error
				$sErrMsg = _GetAppConfigGenerationResult($nError)
				If ($nError == 2) Then
					$sErrMsg &= " Skipping..."
				EndIf

				ConsoleWrite($MY_NAME & ": " & $sErrMsg & @CRLF)
				If ($nError <> 2) Then
					MsgBox(48, $MY_NAME, "Could not generate application config file:" & @CRLF & $sErrMsg)
				EndIf
			EndIf
		EndIf

		; Create/save project file and check for errors. Stop if an error occurs.
		_WriteProjectFile($sProjectFilePath, $aProjectInfo, $aReferences, $iHasGui, $iRequireAdmin, False, _FileGetFileName($sConfigFile))
		If (@error) Then
			$sErrMsg = _GetProjectGenerationResult(@error)
			ConsoleWrite($MY_NAME & ": " & $sErrMsg & @CRLF)
			MsgBox(16, $MY_NAME, "Failed to save/create project:" & @CRLF & $sErrMsg)
			Return
		EndIf

		; Generate/modify the script and check for errors. Stop if an error occurs.
		_GenerateScript($sScriptPath, $aProjectInfo, $aReferences, $iHasGui, $iRequireAdmin, False, _FileGetFileName($sConfigFile))
		If (@error) Then
			$sErrMsg = _GetScriptGenerationResult(@error)
			ConsoleWrite($MY_NAME & ": " & $sErrMsg & @CRLF)
			MsgBox(16, $MY_NAME, "Failed to generate/modify script:" & @CRLF & $sErrMsg)
			Return
		EndIf

		; Create additional child directories (lib, installer, backup).
		$aDirs[0] = 3
		$aDirs[1] = $sProjectHome & "lib"
		$aDirs[2] = $sProjectHome & "installer"
		$aDirs[3] = $sProjectHome & "Backup"
		For $nDirNum = 1 To $aDirs[0]
			If (Not _FileIsDir($aDirs[$nDirNum])) Then
				DirCreate($aDirs[$nDirNum])
			EndIf
		Next
		$sLibDir = $aDirs[1]
		$aDirs = 0
	Else
		; We're creating a library script.
		ConsoleWrite($MY_NAME & ": Project type: library script." & @CRLF)
		; Create/save project file and check for errors. Stop if an error occurs.
		_WriteProjectFile($sProjectFilePath, $aProjectInfo, $aReferences, False, False, True)
		If (@error) Then
			$sErrMsg = _GetProjectGenerationResult(@error)
			ConsoleWrite($MY_NAME & ": " & $sErrMsg & @CRLF)
			MsgBox(16, $MY_NAME, "Failed to save/create project:" & @CRLF & $sErrMsg)
			Return
		EndIf

		; Generate/modify the script and check for errors. Stop if an error occurs.
		_GenerateScript($sScriptPath, $aProjectInfo, $aReferences, False, False, True)
		If (@error) Then
			$sErrMsg = _GetScriptGenerationResult(@error)
			ConsoleWrite($MY_NAME & ": " & $sErrMsg & @CRLF)
			MsgBox(16, $MY_NAME, "Failed to generate/modify script:" & @CRLF & $sErrMsg)
			Return
		EndIf

		; Create additional child directories (lib, help).
		ReDim $aDirs[3]
		$aDirs[0] = 2
		$aDirs[1] = $sProjectHome & "help"
		$aDirs[2] = $sProjectHome & "lib"
		For $nDirNum = 1 To $aDirs[0]
			If (Not _FileIsDir($aDirs[$nDirNum])) Then
				DirCreate($aDirs[$nDirNum])
			EndIf
		Next
		$sLibDir = $aDirs[2]
		$aDirs = 0
	EndIf

	; Create distribution child directory.
	Local $sDistDir = $sProjectHome & "dist"
	If (Not _FileIsDir($sDistDir)) Then
		DirCreate($sDistDir)
	EndIf

	; Copy any non-standard includes.
	If (StringLen($sLibDir) > 0) Then
		; Get the copy include policy.
		Local $policy = $CP_IFNEWER
		Local $sCopyMode = StringLower(GUICtrlRead($ComboCopyPolicy))
		If ((StringInStr($sCopyMode, "always") > 0) Or (StringInStr($sCopyMode, "overwrite") > 0)) Then
			$policy = $CP_ALWAYS
		ElseIf (StringInStr($sCopyMode, "exist") > 0) Then
			$policy = $CP_IFNOTEXIST
		EndIf

		; Copy the includes (if needed).
		_CopyLibs($aReferences, $sLibDir, $policy)
		If (@error) Then
			ConsoleWrite($MY_NAME & ": Failed to copy file: '" & $aReferences[@extended] & "' to '" & $sLibDir & "'" & @CRLF)
			MsgBox(16, $MY_NAME, "Failed to copy one or more non-standard includes to your project.")
		EndIf
	EndIf

	; Open the created/modified script in SciTE.
	ConsoleWrite($MY_NAME & ": Project created/updated. Opening script in editor..." & @CRLF)
	_EditScript($sScriptPath)
	If (@error) Then
		$sErrMsg = _GetScriptEditResult(@error)
		ConsoleWrite($MY_NAME & ": Could not open script: " & $sErrMsg & @CRLF)
		MsgBox(16, $MY_NAME, "Failed to open script:" & @CRLF & $sErrMsg)
	EndIf

	; All done. Close the application.
	$aProjectInfo = 0
	$aReferences = 0
	_OnFormMainClose()
EndFunc   ;==>_ButtonCreateClick

; #FUNCTION# ====================================================================================================================
; Name...........: _CheckboxMakeDefaultClick
; Description ...: Handler for the "this directory is the default for all projects" checkbox click event. This will enable or
;                  disable the project parent location InputTextbox and browse button based on checkbox state.
; Syntax.........: _CheckboxMakeDefaultClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 1/31/2011
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _CheckboxMakeDefaultClick()
	If (GUICtrlRead($CheckboxMakeDefault) == $GUI_CHECKED) Then
		If (StringLen(GUICtrlRead($InputLocation)) > 0) Then
			GUICtrlSetState($InputLocation, $GUI_DISABLE)
			GUICtrlSetState($ButtonProjectBrowse, $GUI_DISABLE)
		Else
			MsgBox(48, $MY_NAME, "No parent project directory specified.")
			GUICtrlSetState($CheckboxMakeDefault, $GUI_UNCHECKED)
		EndIf
	Else
		GUICtrlSetState($InputLocation, $GUI_ENABLE)
		GUICtrlSetState($ButtonProjectBrowse, $GUI_ENABLE)
	EndIf
	Return
EndFunc   ;==>_CheckboxMakeDefaultClick

; #FUNCTION# ====================================================================================================================
; Name...........: _InputProjNameChange
; Description ...: Handler for the "project name" InputTextbox change event. Whenever the text in the "project name" InputTextbox
;                  control changes, the main script name and full project path are re-validated and their respective InputTextbox
;                  controls are repopulated with current data.
; Syntax.........: _InputProjNameChange()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _InputProjNameChange()
	GUICtrlSetData($InputMainScript, GUICtrlRead($InputProjName) & ".au3")
	Local $sProjectsDir = GUICtrlRead($InputLocation)
	If (StringLen($sProjectsDir) > 0) Then
		If (StringRight($sProjectsDir, 1) <> "\") Then
			$sProjectsDir &= "\"
		EndIf
		GUICtrlSetData($InputFullPath, $sProjectsDir & GUICtrlRead($InputProjName))
	EndIf
	Return
EndFunc   ;==>_InputProjNameChange

; #FUNCTION# ====================================================================================================================
; Name...........: _InputLocationChange
; Description ...: Handler for the "project parent location" InputTextbox change event. This re-validates the project full path
;                  whenever the project parent location path changes.
; Syntax.........: _InputLocationChange()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _InputLocationChange()
	Local $sProjectsDir = GUICtrlRead($InputLocation)
	Local $sMainScriptName = GUICtrlRead($InputMainScript)
	Local $sProjectName = GUICtrlRead($InputProjName)
	If (StringLen($sMainScriptName) == 0) Then
		If (StringLen($sProjectName) > 0) Then
			$sMainScriptName = $sProjectName & ".au3"
			GUICtrlSetData($InputMainScript, $sMainScriptName)
		EndIf
	EndIf

	If ((StringLen($sProjectsDir) > 0) And (StringLen($sMainScriptName) > 0)) Then
		If (StringRight($sProjectsDir, 1) <> "\") Then
			$sProjectsDir &= "\"
		EndIf
		GUICtrlSetData($InputFullPath, $sProjectsDir & $sProjectName & "\")
	EndIf
	Return
EndFunc   ;==>_InputLocationChange

; #FUNCTION# ====================================================================================================================
; Name...........: _OnFormMainClose
; Description ...: Handler for the main form close event. This saves the global configuration settings, destroys the GUI and
;                  terminates the application.
; Syntax.........: _OnFormMainClose()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _OnFormMainClose()
	GUIRegisterMsg($WM_NOTIFY, "")
	_SaveGlobalConfig()
	_ClearSourceLibs()
	_ClearTargetLibs()
	If (IsHWnd($FormMain)) Then
		GUIDelete($FormMain)
	EndIf
	Exit
EndFunc   ;==>_OnFormMainClose

; #FUNCTION# ====================================================================================================================
; Name...........: _RadioAppClick
; Description ...: Handler for the "Application" radio button click event. This enables all the controls associated with an
;                  application type of script.
; Syntax.........: _RadioAppClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/04/2011
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _RadioAppClick()
	GUICtrlSetState($InputAutoItVer, $GUI_ENABLE)
	GUICtrlSetState($InputScriptVer, $GUI_ENABLE)
	GUICtrlSetState($DateCreated, $GUI_ENABLE)
	GUICtrlSetState($DateModified, $GUI_ENABLE)
	GUICtrlSetState($InputCompany, $GUI_ENABLE)
	GUICtrlSetState($InputCopyright, $GUI_ENABLE)
	GUICtrlSetState($CheckboxRequireAdmin, $GUI_ENABLE)
	GUICtrlSetState($CheckboxHasGui, $GUI_ENABLE)
	GUICtrlSetState($CheckboxUseConfig, $GUI_ENABLE)
	Return
EndFunc   ;==>_RadioAppClick

; #FUNCTION# ====================================================================================================================
; Name...........: _RadioLibClick
; Description ...: Handler for the "Library" radio button click event.  This disables all the controls associated with an
;                  application type of script, which are unnecessary for library scripts.
; Syntax.........: _RadioLibClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 01/05/2011
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _RadioLibClick()
	GUICtrlSetState($InputAutoItVer, $GUI_DISABLE)
	GUICtrlSetState($InputScriptVer, $GUI_DISABLE)
	GUICtrlSetState($DateCreated, $GUI_DISABLE)
	GUICtrlSetState($DateModified, $GUI_DISABLE)
	GUICtrlSetState($InputCompany, $GUI_DISABLE)
	GUICtrlSetState($InputCopyright, $GUI_DISABLE)
	GUICtrlSetState($CheckboxRequireAdmin, $GUI_UNCHECKED + $GUI_DISABLE)
	GUICtrlSetState($CheckboxHasGui, $GUI_DISABLE)
	GUICtrlSetState($CheckboxUseConfig, $GUI_DISABLE)
	If (GUICtrlRead($CheckboxUseConfig) == $GUI_CHECKED) Then
		GUICtrlSetData($InputConfigName, "")
		GUICtrlSetState($InputConfigName, $GUI_DISABLE)
		GUICtrlSetState($CheckboxUseConfig, $GUI_UNCHECKED + $GUI_DISABLE)
	EndIf
	Return
EndFunc   ;==>_RadioLibClick

; #FUNCTION# ====================================================================================================================
; Name...........: _ButtonOpenProjClick
; Description ...: Handler for the "open project" button click event. This presents the user with a dialog to load a project file.
; Syntax.........: _ButtonOpenProjClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......: 02/08/2011
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ButtonOpenProjClick()
	; Try to get the starting point from the $InputLocation field. If the user has not input anything yet
	; or the control has not yet been created (script called with /opendlg), then try to get our starting
	; path from the config file.
	Local $sStartDir = GUICtrlRead($InputLocation)
	If (Not _FileIsDir($sStartDir)) Then
		If (FileExists($CONFIG)) Then
			Local $sProjDir = IniRead($CONFIG, "Main", "ProjectsDir", "")
			If (_FileIsDir($sProjDir)) Then
				$sStartDir = $sProjDir
				$sProjDir = ""
			EndIf
		EndIf

		; We fall back to the user's "My Documents" dir if all else fails.
		If (StringLen($sStartDir) == 0) Then
			$sStartDir = @MyDocumentsDir
		EndIf
	EndIf

	Local $sProject = FileOpenDialog("Open AutoItV3 Project", $sStartDir, "AutoIt Projects (*." & $PROJECT_FILE_EXT & ")", 1 + 2, "", $FormMain)
	If ((Not @error) And (StringLen($sProject) > 0)) Then
		If (FileExists($sProject)) Then
			_ResetForm()
			ConsoleWrite($MY_NAME & ": Loading project file: " & $sProject & @CRLF)
			If (_LoadProject($sProject)) Then
				$iWasLoaded = True
				$projectFile = $sProject
				$sProject = ""
				GUICtrlSetData($ButtonCreate, "Save and Load")
			EndIf
		EndIf
	Else
		; If this handler was called as a result of the "/opendlg" switch being present on the command line
		; but the user then subsequently canceled the open project dialog, then we terminate here.
		If ($iOpenFromCmdLine) Then
			Exit
		EndIf
	EndIf
	Return
EndFunc   ;==>_ButtonOpenProjClick

; #FUNCTION# ====================================================================================================================
; Name...........: _CheckboxUseConfigClick
; Description ...: Handler for the "create/use configuration file" checkbox click event. Enables/disables the config file name
;                  inputbox control based on checkbox state. If checked, this will also append an acceptable file extension if
;                  it does not already have one.
; Syntax.........: _CheckboxUseConfigClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _CheckboxUseConfigClick()
	If (GUICtrlRead($CheckboxUseConfig) == $GUI_CHECKED) Then
		GUICtrlSetState($InputConfigName, $GUI_ENABLE)
		Local $sConfigName = GUICtrlRead($InputConfigName)
		If (StringLen($sConfigName) == 0) Then
			$sConfigName = GUICtrlRead($InputProjName)
		EndIf
		If (StringLen($sConfigName) > 0) Then
			Local $sExtension = _FileExtension($sConfigName)
			If (($sExtension <> "ini") And ($sExtension <> "cfg") And ($sExtension <> "config") And ($sExtension <> "dat")) Then
				$sConfigName &= ".ini"
			EndIf
			GUICtrlSetData($InputConfigName, $sConfigName)
		EndIf
	Else
		GUICtrlSetState($InputConfigName, $GUI_DISABLE)
	EndIf
	Return
EndFunc   ;==>_CheckboxUseConfigClick

; #FUNCTION# ====================================================================================================================
; Name...........: _ButtonCurrDateNowClick
; Description ...: Handler for the "Now" button click event on the "Date" field in the "Details" tab. Sets the date field to the
;                  current date of the host system.
; Syntax.........: _ButtonCurrDateNowClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ButtonCurrDateNowClick()
	GUICtrlSetData($DateCreated, _NowCalcDate())
	Return
EndFunc   ;==>_ButtonCurrDateNowClick

; #FUNCTION# ====================================================================================================================
; Name...........: _ButtonModDateNowClick
; Description ...: Handler for the "Now" button click event on the "Modified" field in the "Details" tab. Sets the date field to
;                  the current date of the host system.
; Syntax.........: _ButtonModDateNowClick()
; Parameters ....: None.
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _ButtonModDateNowClick()
	GUICtrlSetData($DateModified, _NowCalcDate())
	Return
EndFunc   ;==>_ButtonModDateNowClick

; #FUNCTION# ====================================================================================================================
; Name...........: _WM_Notify_Events
; Description ...: Handler for WM_NOTIFY events.  Currently, this function handles the double-click events for both ListView
;                  controls in the "References" tab.
; Syntax.........: _WM_Notify_Events($hWndGUI, $MsgID, $wParam, $lParam)
; Parameters ....: $hWndGUI -
;                  $MsgID   -
;                  $wParam  -
;                  $lParam  -
; Return values .: None.
; Author ........: Cyrus <cyrusbuilt at gmail dot com>
; Modified.......:
; Remarks .......:
; Related .......:
; Link ..........;
; Example .......;
; ===============================================================================================================================
Func _WM_Notify_Events($hWndGUI, $MsgID, $wParam, $lParam)
	#forceref $hWndGUI, $MsgID, $wParam
	ConsoleWrite("Event fired" & @CRLF)
	Local $tagNMLISTVIEW, $event, $hwndFrom, $code
	$tagNMLISTVIEW = DllStructCreate("int;int;int", $lParam)
	If @error Then Return
	$event = DllStructGetData($tagNMLISTVIEW, 3)
	; CB_TODO - FIXME:
	; According to WindowConstants.au3, the event ID we want to intercept is: -3
	; All the events being received are positive integer values on my 64bit Win7 dev box, but not
	; on my 32bit Win7 dev box...... WTF?
	ConsoleWrite("Event: " & $event & @CRLF)
	Switch $wParam
		Case $ListViewSourceLibs
			Switch $event
				Case $NM_DBLCLK
					_ButtonAddLibClick()
			EndSwitch
		Case $ListViewTargetLibs
			Switch $event
				Case $NM_DBLCLK
					_ButtonRemoveLibClick()
			EndSwitch
	EndSwitch
	$tagNMLISTVIEW = 0
	$event = 0
	$lParam = 0
EndFunc   ;==>_WM_Notify_Events
#EndRegion Event Handlers


#Region Main Script
; *********************** MAIN ENTRY POINT ****************************
Opt("GUIOnEventMode", 1)
If (@Compiled) Then
	Opt("TrayMenuMode", 1)
	Opt("TrayIconHide", 1)
EndIf

; Check script args for a valid project file. If not found or not valid, check to see if the
; open dialog switch was provided.
ConsoleWrite($MY_NAME & ": Processing cmdline args..." & @CRLF)
Dim $i = 0
If ($CmdLine[0] > 0) Then
	For $i = 1 To $CmdLine[0]
		If (FileExists($CmdLine[$i])) Then
			$projectFile = _PathFull($CmdLine[$i])
			If (StringLower(_FileExtension($projectFile)) <> $PROJECT_FILE_EXT) Then
				ConsoleWrite($MY_NAME & ": Invalid project file: " & $projectFile & @CRLF)
				MsgBox(16, $MY_NAME, "The specified file is not a valid " & $MY_NAME & " project file.")
				$projectFile = ""
			EndIf
			ExitLoop
		EndIf

		If (StringLower($CmdLine[$i]) == "/opendlg") Then
			$iOpenFromCmdLine = True
			_ButtonOpenProjClick()
			ExitLoop
		EndIf
	Next
EndIf

; Create the GUI.
ConsoleWrite($MY_NAME & ": Generating GUI..." & @CRLF)
Dim $sCaption = $MY_NAME & " v" & _GetMyVersion()
$FormMain = GUICreate($sCaption, 633, 420, 192, 124)
GUISetOnEvent($GUI_EVENT_CLOSE, "_OnFormMainClose")
$TabMain = GUICtrlCreateTab(8, 8, 617, 369)
GUICtrlSetResizing($TabMain, $GUI_DOCKWIDTH + $GUI_DOCKHEIGHT)
$TabSheet1 = GUICtrlCreateTabItem("Type and Name")
$GroupType = GUICtrlCreateGroup("Project Type", 24, 40, 233, 73)
$RadioLib = GUICtrlCreateRadio("Library", 136, 64, 113, 17)
GUICtrlSetOnEvent($RadioLib, "_RadioLibClick")
$RadioApp = GUICtrlCreateRadio("Application", 40, 64, 81, 17)
GUICtrlSetState($RadioApp, $GUI_CHECKED)
GUICtrlSetOnEvent($RadioApp, "_RadioAppClick")
$CheckboxHasGui = GUICtrlCreateCheckbox("GUI Application", 40, 88, 97, 17)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$GroupName = GUICtrlCreateGroup("Name and Location", 24, 120, 585, 225)
$InputProjName = GUICtrlCreateInput("", 136, 152, 385, 21)
GUICtrlSetOnEvent($InputProjName, "_InputProjNameChange")
$LabelName = GUICtrlCreateLabel("Name:", 40, 152, 35, 17)
$InputLocation = GUICtrlCreateInput("", 136, 184, 337, 21)
GUICtrlSetOnEvent($InputLocation, "_InputLocationChange")
$ButtonProjectBrowse = GUICtrlCreateButton("...", 480, 184, 35, 25, $WS_GROUP)
GUICtrlSetFont($ButtonProjectBrowse, 8, 800, 0, "MS Sans Serif")
GUICtrlSetOnEvent($ButtonProjectBrowse, "_ButtonProjectBrowseClick")
$LabelProjectsDir = GUICtrlCreateLabel("Projects Directory:", 40, 184, 90, 17)
$LabelFullPath = GUICtrlCreateLabel("Project Path:", 40, 240, 65, 17)
$InputFullPath = GUICtrlCreateInput("", 136, 240, 385, 21)
GUICtrlSetState($InputFullPath, $GUI_DISABLE)
$CheckboxMakeDefault = GUICtrlCreateCheckbox("This directory is the default for all projects", 136, 208, 225, 17)
GUICtrlSetOnEvent($CheckboxMakeDefault, "_CheckboxMakeDefaultClick")
$InputMainScript = GUICtrlCreateInput("", 136, 272, 177, 21)
$LabelMainScript = GUICtrlCreateLabel("Main Script Name:", 40, 272, 91, 17)
$InputConfigName = GUICtrlCreateInput("", 136, 304, 177, 21)
GUICtrlSetState($InputConfigName, $GUI_DISABLE)
$LabelConfigName = GUICtrlCreateLabel("Config File Name:", 40, 304, 87, 17)
$CheckboxUseConfig = GUICtrlCreateCheckbox("Create/Use Configuration File", 328, 304, 169, 17)
GUICtrlSetOnEvent($CheckboxUseConfig, "_CheckboxUseConfigClick")
GUICtrlCreateGroup("", -99, -99, 1, 1)
$ButtonOpenProj = GUICtrlCreateButton("Open Project", 504, 56, 99, 25, $WS_GROUP)
GUICtrlSetOnEvent($ButtonOpenProj, "_ButtonOpenProjClick")
$TabSheet2 = GUICtrlCreateTabItem("References")
$ListViewSourceLibs = GUICtrlCreateListView("AutoItV3 Standard Includes", 24, 56, 250, 230, BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS, $LVS_SORTASCENDING, $WS_VSCROLL), BitOR($WS_EX_CLIENTEDGE, $LVS_EX_TRACKSELECT, $LVS_EX_FULLROWSELECT))
GUICtrlSendMsg($ListViewSourceLibs, $LVM_SETCOLUMNWIDTH, 0, 225)
$ListViewTargetLibs = GUICtrlCreateListView("Project Includes", 360, 56, 250, 230, BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS, $LVS_SORTASCENDING, $WS_VSCROLL), BitOR($WS_EX_CLIENTEDGE, $LVS_EX_TRACKSELECT, $LVS_EX_FULLROWSELECT))
GUICtrlSendMsg($ListViewTargetLibs, $LVM_SETCOLUMNWIDTH, 0, 240)
$ButtonAddLib = GUICtrlCreateButton("Add -->", 280, 104, 75, 25, $WS_GROUP)
GUICtrlSetOnEvent($ButtonAddLib, "_ButtonAddLibClick")
$ButtonRemoveLib = GUICtrlCreateButton("<-- Remove", 280, 160, 75, 25, $WS_GROUP)
GUICtrlSetOnEvent($ButtonRemoveLib, "_ButtonRemoveLibClick")
$ButtonBrowseLib = GUICtrlCreateButton("Browse Other...", 360, 296, 99, 25, $WS_GROUP)
GUICtrlSetOnEvent($ButtonBrowseLib, "_ButtonBrowseLibClick")
$ComboCopyPolicy = GUICtrlCreateCombo("", 24, 328, 145, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
GUICtrlSetData($ComboCopyPolicy, "If Newer|Always (Overwrite)|If Not Exist In Project", "If Newer")
$LabelCopyLibPolicy = GUICtrlCreateLabel("Copy Non-Standard Includes Policy:", 24, 304, 174, 17)
$TabSheet3 = GUICtrlCreateTabItem("Details")
$LabelAutoItVer = GUICtrlCreateLabel("AutoItV3 Version:", 24, 48, 86, 17)
$InputAuthor = GUICtrlCreateInput("", 144, 80, 369, 21)
$LabelAuthor = GUICtrlCreateLabel("Author:", 24, 80, 38, 17)
$LabelScriptVer = GUICtrlCreateLabel("Script Version:", 24, 112, 72, 17)
$InputAutoItVer = GUICtrlCreateInput("", 144, 48, 121, 21)
$InputScriptVer = GUICtrlCreateInput("", 144, 112, 121, 21)
$LabelDate = GUICtrlCreateLabel("Date:", 24, 144, 30, 17)
$LabelDateModified = GUICtrlCreateLabel("Modfied:", 24, 176, 45, 17)
$InputCompany = GUICtrlCreateInput("", 144, 208, 209, 21)
$LabelCompany = GUICtrlCreateLabel("Company:", 24, 208, 51, 17)
$InputCopyright = GUICtrlCreateInput("", 144, 240, 369, 21)
$LabelCopyright = GUICtrlCreateLabel("Copyright:", 24, 240, 51, 17)
$EditDescription = GUICtrlCreateEdit("", 144, 272, 465, 89, BitOR($ES_AUTOVSCROLL, $ES_AUTOHSCROLL, $ES_WANTRETURN, $WS_VSCROLL))
GUICtrlSetData($EditDescription, "")
$LabelDescription = GUICtrlCreateLabel("Description/Function:", 24, 272, 106, 17)
$DateCreated = GUICtrlCreateDate(_NowCalcDate(), 144, 144, 186, 21)
$DateModified = GUICtrlCreateDate(_NowCalcDate(), 144, 176, 186, 21)
$CheckboxRequireAdmin = GUICtrlCreateCheckbox("Require admin", 24, 344, 97, 17)
$ButtonCurrDateNow = GUICtrlCreateButton("Now", 336, 144, 43, 25, $WS_GROUP)
GUICtrlSetOnEvent($ButtonCurrDateNow, "_ButtonCurrDateNowClick")
$ButtonModDateNow = GUICtrlCreateButton("Now", 336, 176, 43, 25, $WS_GROUP)
GUICtrlSetOnEvent($ButtonModDateNow, "_ButtonModDateNowClick")
GUICtrlCreateTabItem("")
$ButtonCancel = GUICtrlCreateButton("Cancel", 552, 384, 75, 25, $WS_GROUP)
GUICtrlSetOnEvent($ButtonCancel, "_ButtonCancelClick")
$ButtonCreate = GUICtrlCreateButton("Create Project", 248, 384, 123, 25, $WS_GROUP)
GUICtrlSetOnEvent($ButtonCreate, "_ButtonCreateClick")
GUISetState(@SW_SHOW)

; Init default control states.
_ResetForm()

; Load the project if one was specified and the file if it exists.
If ((StringLen($projectFile) > 0) And (FileExists($projectFile))) Then
	If (Not $iWasLoaded) Then
		ConsoleWrite($MY_NAME & ": Loading project file: " & $projectFile & @CRLF)
	EndIf
	If (_LoadProject($projectFile)) Then
		$iWasLoaded = True
		GUICtrlSetData($ButtonCreate, "Save and Load")
	EndIf
EndIf

; Register WM_NOTIFY events.
; CB_TODO - FIXME:
; This used to work.... now suddenly it doesn't.... the events are fired and handled by
; _WM_Notify_events, but we never recieve the expected message ID.
GUIRegisterMsg($WM_NOTIFY, "_WM_Notify_Events")

; Enter the message loop.
While 1
	Sleep(100)
WEnd

; We should never actually get here.
Exit
#EndRegion Main Script