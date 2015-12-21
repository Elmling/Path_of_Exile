#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.12.0
	Author:         Marc

#ce ----------------------------------------------------------------------------

#include <Misc.au3>
#include <file.au3>

HotKeySet("!^r", "initGui")

Global $gui = ""
Global $pid = ""

Func initGui()
	If ProcessExists($pid) Then
		ProcessClose($pid)
	EndIf
	If $gui = "" Then
		$gui = GUICreate("POE Bot", 360, 300)
		GUICtrlCreateLabel("Choose a Zone", 20, 15, 80, 15)
		Global $zone = GUICtrlCreateList("", 20, 30, 100, 60)
		;Disabled for now
		GUICtrlSetState($zone, 128)
		GUICtrlSetData($zone, "|None|The Coast|The Mud Flats")
		GUICtrlCreateLabel("Wait", 20, 100, 30, 15)
		Global $msStep = GUICtrlCreateInput("2000", 50, 100, 40, 20)
		;Disabled for now
		GUICtrlSetState($msStep, 128)
		GUICtrlCreateLabel("MS before moving in between nodes", 100, 100, 100, 30)
		GUICtrlCreateLabel("On find Enemy do action:", 20, 140, 120, 20)
		Global $onFindEnemyAction = GUICtrlCreateInput("Click Right", 140, 140, 60, 20)
		GUICtrlCreateLabel("Enemy Health Color", 160, 15, 120, 15)
		Global $enemyHealth = GUICtrlCreateInput("Unknown", 160, 30, 80, 20)
		Global $colorPicker = GUICtrlCreateButton("Color Picker", 260, 75, 80, 20)
		Global $myhealth = GUICtrlCreateInput("Unknown", 260, 30, 80, 20)
		GUICtrlCreateLabel("My Health Color", 260, 15, 120, 15)
		GUICtrlCreateLabel("My Mana Color", 160, 60, 120, 15)
		Global $mymana = GUICtrlCreateInput("Unknown", 160, 75, 80, 20)
		GUICtrlCreateLabel("On missing HP do action:", 20, 180, 120, 20)
		Global $onMissingHpAction = GUICtrlCreateInput("1", 140, 180, 60, 20)
		GUICtrlCreateLabel("On missing MP do action:", 20, 220, 120, 20)
		GUICtrlCreateGroup("On Find Values",220,134,120,100)
		GUICtrlCreateLabel("• Click Left" & @CRLF & "• Click Right" & @CRLF & "• A-Z" & @CRLF & "• 0-9",230,(115 + 40),100,60)
		Global $onMissingManaAction = GUICtrlCreateInput("2", 140, 220, 60, 20)
		Global $run = GUICtrlCreateButton("Run Bot", 20, 260, 80, 20)
	EndIf

	If FileExists(@ScriptDir & "/Data/Values.txt") Then
		loadValues()
	EndIf

	GUISetState(True)
	$msgUserColorPicker = True
	While 1
		$guiAction = String(GUIGetMsg())

		If $guiAction <> "-11" And $guiAction <> "0" Then
			ConsoleWrite($guiAction & @CRLF)
		EndIf

		Switch $guiAction
			Case "-3"
				Exit
				;End of case
			Case "3"
				;End of case
			Case $colorPicker
				$hex = ""

				Local $hDLL = DllOpen("user32.dll")

				If $msgUserColorPicker = True Then
					MsgBox(0, "", "Click on a color, the color will be put in your clipboard (so you can paste)")
					$msgUserColorPicker = False
				EndIf

				While 1
					If _IsPressed("01", $hDLL) Then
						$coords = MouseGetPos()
						$hex = Hex(PixelGetColor($coords[0], $coords[1]), 8)
						ExitLoop
					EndIf
				WEnd

				DllClose($hDLL)
				Beep(500, 500)
				ClipPut($hex)
				;End of case
			Case $run
				GUISetState(False)
				TrayTip("POE Bot", "Press ctrl + alt + r to open the GUI", 5)
				saveValues()
				ExitLoop
				;End of case
		EndSwitch
	WEnd
EndFunc   ;==>initGui

Func saveValues()

	If DirGetSize(@ScriptDir & "/Data/") = -1 Then
		DirCreate(@ScriptDir & "/Data/")
	EndIf

	If Not FileExists(@ScriptDir & "/Data/Values.txt") Then
		_FileCreate(@ScriptDir & "/Data/Values.txt")
	EndIf

	$fh = FileOpen(@ScriptDir & "/Data/Values.txt", 2)
	FileWrite($fh, GUICtrlRead($zone) & @CRLF & GUICtrlRead($msStep) & @CRLF & GUICtrlRead($onFindEnemyAction) & @CRLF & GUICtrlRead($enemyHealth) & @CRLF & GUICtrlRead($myhealth) & @CRLF & GUICtrlRead($mymana) & @CRLF & GUICtrlRead($onMissingHpAction) & @CRLF & GUICtrlRead($onMissingManaAction))
	FileClose($fh)
EndFunc   ;==>saveValues

Func loadValues()
	$fh = FileOpen(@ScriptDir & "/Data/Values.txt", 0)
	GUICtrlSetData($zone, FileReadLine($fh))
	GUICtrlSetData($msStep, FileReadLine($fh))
	GUICtrlSetData($onFindEnemyAction, FileReadLine($fh))
	GUICtrlSetData($enemyHealth, FileReadLine($fh))
	GUICtrlSetData($myhealth, FileReadLine($fh))
	GUICtrlSetData($mymana, FileReadLine($fh))
	GUICtrlSetData($onMissingHpAction, FileReadLine($fh))
	GUICtrlSetData($onMissingManaAction, FileReadLine($fh))
EndFunc   ;==>loadValues

Func isMissingHealth()
	Local $health = GUICtrlRead($myhealth)
	$pixel = PixelSearch(0, 0, (@DesktopWidth / 2), @DesktopHeight, "0x" & $health, 1, 1)
	If @error Then
		Return True
	EndIf
	Return False
EndFunc   ;==>isMissingHealth

Func isMissingMana()
	Local $mana = GUICtrlRead($mymana)
	$pixel = PixelSearch(0, 0, (@DesktopWidth), @DesktopHeight, "0x" & $mana, 1, 1)
	If @error Then
		Return True
	EndIf
	Return False
EndFunc   ;==>isMissingMana

Func isEnemy()
	Local $enemy = GUICtrlRead($enemyHealth)
	$pixel = PixelSearch(0, 80, (@DesktopWidth), @DesktopHeight, "0x" & $enemy, 0, 0)
	If Not @error Then
		Return $pixel
	EndIf
	;if we are hovering over an enemy with the mouse
	$pixel = PixelSearch(0, 0, @DesktopWidth, 80, "0x" & $enemy, 1, 1)
	If Not @error Then
		Return MouseGetPos()
	EndIf
	Return False
EndFunc   ;==>isEnemy

initGui()

While 1
	If WinActive("Path of Exile") Then

		$key = False
		$pix = False
		$isMissingHealth = isMissingHealth()
		$isMissingMana = isMissingMana()

		If $isMissingHealth = True And $isMissingMana = True Then
			;Loading screen check
			Sleep(1000)
			ContinueLoop
		EndIf

		If $isMissingHealth = True Then
			$key = GUICtrlRead($onMissingHpAction)
		EndIf

		If $isMissingMana = True Then
			$key = GUICtrlRead($onMissingManaAction)
		EndIf

		If Not ($key = False) Then
			Send($key)
		EndIf

		$pix = isEnemy()

		If Not ($pix = False) Then
			$btn = False

			MouseMove($pix[0], $pix[1], 0)
			$action = GUICtrlRead($onFindEnemyAction)

			If StringInStr($action, "click", 0) > 0 Then
				If StringInStr($action, "left", 0) > 0 Then
					$btn = "left"
					MouseDown("left")
				ElseIf StringInStr($action, "right", 0) > 0 Then
					$btn = "right"
				EndIf

				If Not ($btn = False) Then
					MouseDown($btn)
					Sleep(1000)
					MouseUp($btn)
				EndIf

				ContinueLoop
			Else
				Send($action)
			EndIf
		Else

		EndIf
	EndIf
	Sleep(1)
WEnd
