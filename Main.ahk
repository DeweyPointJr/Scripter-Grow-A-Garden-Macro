; Scripter GAG Macro

#SingleInstance, Force
#NoEnv
SetWorkingDir %A_ScriptDir%
#WinActivateForce
SetMouseDelay, -1 
SetWinDelay, -1
SetControlDelay, -1
SetBatchLines, -1   

; globals

global webhookURL
global privateServerLink
global discordUserID
global PingSelected
global reconnectingProcess

global windowIDS := []
global currentWindow := ""
global firstWindow := ""
global instanceNumber
global idDisplay := ""
global started := 0

global cycleCount := 0
global cycleFinished := 0
global toolTipText := ""

global currentItem := ""
global currentArray := ""
global currentSelectedArray := ""
global indexItem := ""
global indexArray := []

global currentHour
global currentMinute
global currentSecond

global midX
global midY

global msgBoxCooldown := 0

global gearAutoActive := 0
global seedAutoActive := 0
global merchantAutoActive := 0
global eggAutoActive  := 0
global cosmeticAutoActive := 0
global honeyShopAutoActive := 0
global craftingSeedAutoActive := 0
global craftingAutoActive := 0
global collectPlantsAutoActive := 0

global mapSide = ""
global NavigationMode

global selectedCookingItem
global SelectedCookingRarity

global SavedSpeed
global AutoAlign


IniRead, AutoAlign, %settingsFile%, Main, AutoAlign
if (ErrorLevel || AutoAlign = "" || AutoAlign = "ERROR")
    AutoAlign := 1  ; or whatever your preferred fallback is
IniRead, SavedSpeed, %settingsFile%, Main, MacroSpeed
if (ErrorLevel || SavedSpeed = "" || SavedSpeed = "ERROR")
    SavedSpeed := "Stable"  ; or whatever your preferred fallback is

IniRead, mapSide, %settingsFile%, Main, MapSide

global GAME_PASS_ID  := 1244038348
global VERIFIED_KEY  := "VerifiedUser"

global actionQueue := []

settingsFile := A_ScriptDir "\settings.ini"

; unused

global currentShop := ""

global selectedResolution

global scrollCounts_1080p, scrollCounts_1440p_100, scrollCounts_1440p_125
scrollCounts_1080p :=       [2, 4, 6, 8, 9, 11, 13, 14, 16, 18, 20, 21, 23, 25, 26, 28, 29, 31]
scrollCounts_1440p_100 :=   [3, 5, 8, 10, 13, 15, 17, 20, 22, 24, 27, 30, 31, 34, 36, 38, 40, 42]
scrollCounts_1440p_125 :=   [3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 25, 27, 29, 30, 31, 32]

global gearScroll_1080p, toolScroll_1440p_100, toolScroll_1440p_125
gearScroll_1080p     := [1, 2, 4, 6, 8, 9, 11, 13]
gearScroll_1440p_100 := [2, 3, 6, 8, 10, 13, 15, 17]
gearScroll_1440p_125 := [1, 3, 4, 6, 8, 9, 12, 12]

CheckForUpdate() { 
    currentVersion := "Beanstalk0.5" ; <-- Set your current version here 
    latestURL := "https://api.github.com/repos/DeweyPointJr/Scripter-Grow-A-Garden-Macro/releases/latest" 
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1") 
    whr.Open("GET", latestURL, false) 
    whr.Send() 
    whr.WaitForResponse() 
    status := whr.Status + 0 
    if (status != 200) { 
        MsgBox, Failed to fetch release info. Status: %status% return 
    } 
    json := whr.ResponseText 
    RegExMatch(json, """tag_name"":\s*""([^""]+)""", m) 
    latestVersion := m1
    if (latestVersion = "") {
        MsgBox, Could not find latest version in response.
        return
    }

    if (latestVersion != currentVersion) {
        MsgBox, 4, Update Available, New version %latestVersion% found! Download and install?
        IfMsgBox, Yes
        {
            RegExMatch(json, """zipball_url"":\s*""([^""]+)""", d)
            downloadURL := d1
            if (downloadURL = "") {
                MsgBox, Could not find zipball_url in release JSON.
                return
            }
            whr2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            whr2.Open("GET", downloadURL, false)
            whr2.Send()
            whr2.WaitForResponse()
            status2 := whr2.Status + 0
            if (status2 != 200) {
                MsgBox, Failed to download update file. Status: %status2%
                return
            }
            stream := ComObjCreate("ADODB.Stream")
            stream.Type := 1 ; binary
            stream.Open()
            stream.Write(whr2.ResponseBody)
            stream.SaveToFile(A_ScriptDir "\update.zip", 2)
            stream.Close()
            ; Extract the update
            RunWait, %ComSpec% /c powershell -Command "Expand-Archive -Force '%A_ScriptDir%\update.zip' '%A_ScriptDir%'",, Hide
            ; Run updater and exit
            Run, %A_ScriptDir%\update.ahk
            ExitApp
        }
    }
}

CheckForUpdate()


; http functions

SendDiscordMessage(webhookURL, message) {

    FormatTime, messageTime, , hh:mm:ss tt
    fullMessage := "[" . messageTime . "] " . message

    json := "{""content"": """ . fullMessage . """}"
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")

    try {
        whr.Open("POST", webhookURL, false)
        whr.SetRequestHeader("Content-Type", "application/json")
        whr.Send(json)
        whr.WaitForResponse()
        status := whr.Status

        if (status != 200 && status != 204) {
            return
        }
    } catch {
        return
    }

}

checkValidity(url, msg := 0, mode := "nil") {

    global webhookURL
    global privateServerLink
    global settingsFile

    isValid := 0

    if (mode = "webhook" && (url = "" || !(InStr(url, "discord.com/api") || InStr(url, "discordapp.com/api")))) {
        isValid := 0
        if (msg) {
            MsgBox, 0, Message, Invalid Webhook
            IniRead, savedWebhook, %settingsFile%, Main, UserWebhook,
            GuiControl,, webhookURL, %savedWebhook%
        }
        return false
    }

    if (mode = "privateserver" && (url = "" || !InStr(url, "roblox.com/share"))) {
        isValid := 0
        if (msg) {
            MsgBox, 0, Message, Invalid Private Server Link
            IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink,
            GuiControl,, privateServerLink, %savedServerLink%
        }
        return false
    }

    try {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", url, false)
        whr.Send()
        whr.WaitForResponse()
        status := whr.Status

        if (mode = "webhook" && (status = 200 || status = 204)) {
            isValid := 1
        } else if (mode = "privateserver" && (status >= 200 && status < 400)) {
            isValid := 1
        }
    } catch {
        isValid := 0
    }

    if (msg) {
        if (mode = "webhook") {
            if (isValid && webhookURL != "") {
                IniWrite, %webhookURL%, %settingsFile%, Main, UserWebhook
                MsgBox, 0, Message, Webhook Saved Successfully
            }
            else if (!isValid && webhookURL != "") {
                MsgBox, 0, Message, Invalid Webhook
                IniRead, savedWebhook, %settingsFile%, Main, UserWebhook,
                GuiControl,, webhookURL, %savedWebhook%
            }
        } else if (mode = "privateserver") {
            if (isValid && privateServerLink != "") {
                IniWrite, %privateServerLink%, %settingsFile%, Main, PrivateServerLink
                MsgBox, 0, Message, Private Server Link Saved Successfully
            }
            else if (!isValid && privateServerLink != "") {
                MsgBox, 0, Message, Invalid Private Server Link
                IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink,
                GuiControl,, privateServerLink, %savedServerLink%
            }
        }
    }

    return isValid

}


showPopupMessage(msgText := "nil", duration := 2000) {

    static popupID := 99

    ; get main GUI position and size
    WinGetPos, guiX, guiY, guiW, guiH, A

    innerX := 20
    innerY := 35
    innerW := 200
    innerH := 50
    winW := 200
    winH := 50
    x := guiX + (guiW - winW) // 2 - 40
    y := guiY + (guiH - winH) // 2

    if (!msgBoxCooldown) {
        msgBoxCooldown = 1
        Gui, %popupID%:Destroy
        Gui, %popupID%:+AlwaysOnTop -Caption +ToolWindow +Border
        Gui, %popupID%:Color, FFFFFF
        Gui, %popupID%:Font, s10 cBlack, Segoe UI
        Gui, %popupID%:Add, Text, x%innerX% y%innerY% w%innerW% h%innerH% BackgroundWhite Center cBlack, %msgText%
        Gui, %popupID%:Show, x%x% y%y% NoActivate
        SetTimer, HidePopupMessage, -%duration%
        Sleep, 2200
        msgBoxCooldown = 0
    }

}

DonateResponder(ctrlName) {

    MsgBox, 1, Disclaimer, 
    (
    Your browser will open with a link to a roblox gamepass once you press OK.
    - Feel free to check the code, there are no malicious links.
    )

    IfMsgBox, OK
        if (ctrlName = "Donate100")
            Run, https://www.roblox.com/game-pass/1197306369/100-Donation
        else if (ctrlName = "Donate500")
            Run, https://www.roblox.com/game-pass/1222540123/500-Donation
        else if (ctrlName = "Donate1000")
            Run, https://www.roblox.com/game-pass/1222262383/1000-Donation
        else if (ctrlName = "Donate2500")
            Run, https://www.roblox.com/game-pass/1222306189/2500-Donation
        else if (ctrlName = "Donate10000")
            Run, https://www.roblox.com/game-pass/1220930414/10-000-Donation
        else
            return

}

; mouse functions

SafeMoveRelative(xRatio, yRatio) {

    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        moveX := winX + Round(xRatio * winW)
        moveY := winY + Round(yRatio * winH)
        MouseMove, %moveX%, %moveY%
    }

}

SafeClickRelative(xRatio, yRatio, clickdown:= "") {

    if WinExist("ahk_exe RobloxPlayerBeta.exe") {
        WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        clickX := winX + Round(xRatio * winW)
        clickY := winY + Round(yRatio * winH)
        Click, %clickX%, %clickY%, clickdown
    }

}

getMouseCoord(axis) {

    WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe
        CoordMode, Mouse, Screen
        MouseGetPos, mouseX, mouseY

        relX := (mouseX - winX) / winW
        relY := (mouseY - winY) / winH

        if (axis = "x")
            return relX
        else if (axis = "y")
            return relY

    return ""  ; error

}

; directional sequence encoder/executor
; if you're going to modify the calls to this make sure you know what you're doing (ui navigation has some odd behaviours)

uiUniversal(order := 0, exitUi := 1, continuous := 0, spam := 0, spamCount := 30, delayTime := 50, mode := "universal", index := 0, dir := "nil", itemType := "nil") {

    global SavedSpeed
    global SavedKeybind

    global indexItem
    global currentArray

    If (!order && mode = "universal") {
        return
    }

    if (!continuous) {
        sendKeybind(SavedKeybind)
        Sleep, 50
    }  

    ; right = 1, left = 2, up = 3, down = 4, enter = 0, manual delay = 5
    if (mode = "universal") {

        Loop, Parse, order 
        {
            if (A_LoopField = "1") {
                repeatKey("Right", 1)
            }
            else if (A_LoopField = "2") {
                repeatKey("Left", 1)
            }
            else if (A_LoopField = "3") {
                repeatKey("Up", 1)
            }        
            else if (A_LoopField = "4") {
                repeatKey("Down", 1)
            }  
            else if (A_LoopField = "0") {
                repeatKey("Enter", spam ? spamCount : 1, spam ? 10 : 0)
            }       
            else if (A_LoopField = "5") {
                Sleep, 100
            } 
            if (SavedSpeed = "Stable" && A_LoopField != "5") {
                Sleep, %delayTime%
            }
        }

    }
    else if (mode = "calculate") {

        previousIndex := findIndex(currentArray, indexItem)
        sendCount := index - previousIndex

        if (dir = "up") {
            repeatKey(dir)
            repeatKey("Enter")
            repeatKey(dir, sendCount)
        }
        else if (dir = "down") {
            if ((currentArray.Name = "zenItems") && (previousIndex = 0 || previousIndex = 1 || previousIndex = 7 || previousIndex = 11)) {
            }
            ; --- ZenItems skip logic ---
            if (currentArray.Name = "zenItems" and NavigationMode = "Settings") {
                ; Check if passing over index 6 or 9 and they're not selected
                for skipIdx, skipVal in [1, 2, 8, 12] {
                    if (previousIndex < skipVal && index >= skipVal) {
                        found := false
                        for _, sel in selectedZenItems {
                            if (zenItems[skipVal] = sel) {
                                found := true
                                break
                            }
                        }
                        if (!found) {
                            sendCount++
                        }
                    }
                }
            }
            if (curentArray.Name = "eggItems" and NavigationMode = "Settings") {
                sendCount ++
            }

            repeatKey(dir, sendCount)
            repeatKey("Enter")
            repeatKey(dir)
            if (currentArray.Name = "seedItems" or currentArray.Name = "gearItems") {
                if (NavigationMode = "Hotbar") {
                    if !(currentArray.Name = "gearItems" && index = 3) {
                        Send, {Left}
                    }
                }
            }
            if ((currentArray.Name = "zenItems" and NavigationMode = "Settings") && (index = 1 || index = 2 || index = 8 || index = 12)) {
                repeatKey(dir)
            }
            if ((currentArray.Name = "honeyMerchantItems" and NavigationMode = "Settings") && (index = 1 || index = 3 || index = 4 || index = 5)) {
                repeatKey(dir)
            }
            if (currentArray.Name = "eggItems" and NavigationMode = "Settings") {
                repeatKey(dir)
            }
        }

    }
    else if (mode = "close") {

        if (dir = "up") {
            if (currentArray.Name = "eggItems") {
                repeatKey(dir)
                repeatKey("Enter")
                repeatKey(dir, (index+.5)*2)
            } else if (currentArray.Name = "zenItems") {
                repeatKey(dir)
                repeatKey("Enter")
                repeatKey(dir, (index+4))
            } else {
                repeatKey(dir)
                repeatKey("Enter")
                repeatKey(dir, index)
            }
        }
        else if (dir = "down") {
            repeatKey(dir, index)
            repeatKey("Enter")
            repeatKey(dir)
        }

    }

    if (exitUi) {
        Sleep, 50
        sendKeybind(SavedKeybind)
    }

    return

}

; universal shop buyer

buyUniversal(itemType) {

    global currentArray
    global currentSelectedArray
    global indexItem := ""
    global indexArray := []

    indexArray := []
    lastIndex := 0
    
    ; name array
    arrayName := itemType . "Items"
    currentArray := %arrayName%
    currentArray.Name := arrayName

    ; get arrays
    StringUpper, itemType, itemType, T

    selectedArrayName := "selected" . itemtype . "Items"
    currentSelectedArray := %selectedArrayName%

    ; get item indexes
    for i, selectedItem in currentSelectedArray {
        indexArray.Push(findIndex(currentArray, selectedItem))
    }

    ; buy items
    for i, index in indexArray {
        currentItem := currentSelectedArray[i]
        Sleep, 50
        uiUniversal(, 0, 1, , , , "calculate", index, "down", itemType)
        indexItem := currentSelectedArray[i]
        sleepAmount(100, 200)
        quickDetect(0x26EE26, 0x1DB31D, 5, 0.4262, 0.2903, 0.6918, 0.8508)
        Sleep, 50
        lastIndex := index - 1
    }

    ; end
    Sleep, 100
    uiUniversal(, 0, 1,,,, "close", lastIndex, "up", itemType)
    Sleep, 100

}

; helper functions

repeatKey(key := "nil", count := 1, delay := 30) {

    global SavedSpeed

    if (key = "nil") {
        return
    }

    Loop, %count% {
        Send {%key%}
        Sleep, % (SavedSpeed = "Ultra" ? (delay - 25) : SavedSpeed = "Max" ? (delay - 30) : delay)
    }

}

sendKeybind(keybind) {
    if (keybind = "\") {
        Send, \
    } else {
        Send, {%keybind%} 
    }
}


sleepAmount(fastTime, slowTime) {

    global SavedSpeed

    Sleep, % (SavedSpeed != "Stable") ? fastTime : slowTime

}

findIndex(array := "", value := "", returnValue := "int") {

    for index, item in array {
        if (value = item) {
            if (returnValue = "int") {
                return index
            }
            else if (returnValue = "bool") {
                return true
            }
        }
    }

    if (returnValue = "int") {
        return 1
    }
    else if (returnValue = "bool") {
        return false
    }

}

searchItem(search := "nil", crafting := 0, type := "None") {

    if(search = "nil") {
        Return
    }

        SendInput, ``
        sleepAmount(100, 1000)
        SafeClickRelative(0.655991736, 0.63446969697)
        sleepAmount(100, 1000)
        SafeClickRelative(0.6095, 0.6439)
        Sleep, 50
        SendInput, {Ctrl down}{A}{Right}{Ctrl up}  
        if !(search = "food")  { 
            typeString(search)
        }
        Sleep, 50

        

        if (search = "recall") {
            uiUniversal("22211550554155055", 1, 1)
        }
        else if (search = "tranquil") {
            SafeClickRelative(0.3099, 0.767)
            sleep, 250
            SafeClickRelative(0.346, 0.6818)
            sleep, 250
            SendInput, ``
        }
        else if (search = "corrupt") {
            SafeClickRelative(0.3099, 0.767)
            sleep, 250
            SafeClickRelative(0.346, 0.6818)
            sleep, 250
            SendInput, ``
        }
        else if (search = "radar") {
            uiUniversal("4433055411550", 1, 1)
        }
        else if (search = "food") {
            SafeClickRelative(0.3125, 0.890151515)
            sleep, 500
            SafeClickRelative(0.346, 0.6818)
            sleep, 500
            SafeClickRelative(0.5, 0.5)
        }

        if (type = "fruit") {
            SafeClickRelative(0.31353, 0.73863)
            sleep, 500
        }

        if (crafting = 1) {
            SafeClickRelative(0.346, 0.6818)
            sleep, 250
            Send, {E}
            sleep, 250
            SafeClickRelative(0.346, 0.6818)
            sleep, 250
            if (search = "Common Egg") {
                SafeClickRelative(0.380681818182, 0.6818)
                sleep, 250
                Send, {E}
                sleep, 250
                SafeClickRelative(0.380681818182, 0.6818)
                sleep, 250
                SafeClickRelative(0.415363636, 0.6818)
                sleep, 250
                Send, {E}
                sleep, 250
                SafeClickRelative(0.415363636, 0.6818)
                sleep, 250
            }
            SendInput, ``
            sleep, 250
        }
        if (crafting = 2) {
            SafeClickRelative(0.346, 0.6818)
            sleep, 750
            Send, {e}
            sleep, 750
            SafeClickRelative(0.5, 0.5)
            sleep, 750
        }

}

typeString(string, enter := 1, clean := 1) {

    if (string = "") {
        Return
    }

    if (clean) {
        repeatKey("right", 50)
        Send {BackSpace 50}
        Sleep, 100
    }

    Loop, Parse, string
    {
        if (A_LoopField = " ") {
            Send, {Space}
        } else {
            Send, {%A_LoopField%}
        }
        Sleep, 100
    }

    if (enter) {
        Send, {Enter}
    }

    Return

}

dialogueClick(shop) {

    

    Sleep, 500

    if (shop = "gear") {
        SafeClickRelative(midX + 0.4, midY)
    }
    else if (shop = "honey") {
        SafeClickRelative(midX + 0.4, midY)
    }

    Sleep, 500

   

    SafeClickRelative(midX, midY)

}

hotbarController(select := 0, unselect := 0, key := "nil") {

    if ((select = 1 && unselect = 1) || (select = 0 && unselect = 0) || key = "nil") {
        Return
    }

    if (unselect) {
        Send, {%key%}
        Sleep, 200
        Send, {%key%}
    }
    else if (select) {
        Send, {%key%}
    }

}

closeRobuxPrompt() {

    Loop, 4 {
        Send {Escape}
        Sleep, 100
    }

}

getWindowIDS(returnIndex := 0) {

    global windowIDS
    global idDisplay
    global firstWindow

    windowIDS := []
    idDisplay := ""
    firstWindow := ""

    WinGet, robloxWindows, List, ahk_exe RobloxPlayerBeta.exe

    Loop, %robloxWindows% {
        windowIDS.Push(robloxWindows%A_Index%)
        idDisplay .= windowIDS[A_Index] . ", "
    }

    firstWindow := % windowIDS[1]

    StringTrimRight, idDisplay, idDisplay, 2

    if (returnIndex) {
        Return windowIDS[returnIndex]
    }
    
}

closeShop(shop, success) {

    StringUpper, shop, shop, T

    if (success) {

        Sleep, 500
        if (shop = "Egg" or shop = "Zen") {
        uiUniversal("33410320", 1, 1)
        }
        else {
            uiUniversal("4330320", 1, 1)
        }

    }
    else {

        ToolTip, % "Error In Detecting " . shop
        SafeClickRelative(0.66838, 0.25284)
        Sleep, 100
        SetTimer, HideTooltip, -1500
        SendDiscordMessage(webhookURL, "Failed To Detect " . shop . " Shop Opening [Error]" . (PingSelected ? " <@" . discordUserID . ">" : ""))
        ; failsafe
        SafeClickRelative(0.5, 0.127)

    }

}

walkDistance(order := 0, multiplier := 1) {

    ; later

}

sendMessages() {

    ; later

}

; color detectors

quickDetectEgg(buyColor, variation := 10, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0) {

    global selectedEggItems
    global currentItem

    eggsCompleted := 0
    isSelected := 0

    eggColorMap := Object()
    eggColorMap["Common Egg"]    := "0xFFFFFF"
    eggColorMap["Uncommon Egg"]  := "0x81A7D3"
    eggColorMap["Rare Egg"]      := "0xBB5421"
    eggColorMap["Legendary Egg"] := "0x2D78A3"
    eggColorMap["Mythical Egg"]  := "0x00CCFF"
    eggColorMap["Bug Egg"]       := "0x86FFD5"
    eggColorMap["Common Summer Egg"]  := "0x00FFFF"
    eggColorMap["Rare Summer Egg"]  := "0xFBFCA8"
    eggColorMap["Paradise Egg"]  := "0x32CDFF"
    eggColorMap["Bee Egg"]  := "0x00ACFF"

    Loop, 5 {
        for rarity, color in eggColorMap {
            currentItem := rarity
            isSelected := 0

            for i, selected in selectedEggItems {
                if (selected = rarity) {
                    isSelected := 1
                    break
                }
            }

            ; check for the egg on screen, if its selected it gets bought
            if (simpleDetect(color, variation, 0.41, 0.32, 0.54, 0.38)) {
                if (isSelected) {
                    quickDetect(buyColor, 0, 5, 0.4, 0.60, 0.65, 0.70, 0, 1)
                    eggsCompleted = 1
                    break
                } else {
                    if (simpleDetect(buyColor, variation, 0.40, 0.60, 0.65, 0.70)) {
                        ToolTip, % currentItem . "`nIn Stock, Not Selected"
                        SetTimer, HideTooltip, -1500
                        SendDiscordMessage(webhookURL, currentItem . " In Stock, Not Selected")
                    }
                    else {
                        ToolTip, % currentItem . "`nNot In Stock, Not Selected"
                        SetTimer, HideTooltip, -1500
                        SendDiscordMessage(webhookURL, currentItem . " Not In Stock, Not Selected")
                    }
                    uiUniversal(1105, 1, 1)
                    eggsCompleted = 1
                    break
                }
            }    
        }
        ; failsafe
        if (eggsCompleted) {
            return
        }
        Sleep, 1500
    }
    
    if (!eggsCompleted) {
        uiUniversal(5, 1, 1)
        ToolTip, Error In Detection
        SetTimer, HideTooltip, -1500
        SendDiscordMessage(webhookURL, "Failed To Detect Any Egg [Error]" . (PingSelected ? " <@" . discordUserID . ">" : ""))
    }

}

simpleDetect(colorInBGR, variation, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0) {

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    ; limit search to specified area
	WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe

    x1 := winX + Round(x1Ratio * winW)
    y1 := winY + Round(y1Ratio * winH)
    x2 := winX + Round(x2Ratio * winW)
    y2 := winY + Round(y2Ratio * winH)

    PixelSearch, FoundX, FoundY, x1, y1, x2, y2, colorInBGR, variation, Fast
    if (ErrorLevel = 0) {
        return true
    }

}

quickDetect(color1, color2, variation := 10, x1Ratio := 0.0, y1Ratio := 0.0, x2Ratio := 1.0, y2Ratio := 1.0, item := 1, egg := 0) {

    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    stock := 0
    eggDetected := 0

    global currentItem
    
    ; change to whatever you want to be pinged for
    pingItems := ["Bamboo Seed", "Coconut Seed", "Cactus Seed", "Dragon Fruit Seed", "Mango Seed", "Grape Seed", "Mushroom Seed", "Pepper Seed"
                , "Cacao Seed", "Beanstalk Seed"
                , "Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler", "Lightning Rod", "Master Sprinkler"
                , "Rare Egg", "Legendary Egg", "Mythical Egg", "Bug Egg"
                , "Flower Seed Pack", "Nectarine Seed", "Hive Fruit Seed", "Honey Sprinkler"
                , "Bee Egg", "Bee Crate", "Honey Comb", "Bee Chair", "Honey Torch", "Honey Walkway"]

	ping := false

    if (PingSelected) {
        for i, pingitem in pingItems {
            if (pingitem = currentItem) {
                ping := true
                break
            }
        }
    }

    ; limit search to specified area
	WinGetPos, winX, winY, winW, winH, ahk_exe RobloxPlayerBeta.exe

    x1 := winX + Round(x1Ratio * winW)
    y1 := winY + Round(y1Ratio * winH)
    x2 := winX + Round(x2Ratio * winW)
    y2 := winY + Round(y2Ratio * winH)

    ; for seeds/gears checks if either color is there (buy button)
    if (item) {
        for index, color in [color1, color2] {
            PixelSearch, FoundX, FoundY, x1, y1, x2, y2, %color%, variation, Fast RGB
            if (ErrorLevel = 0) {
                stock := 1
                ToolTip, %currentItem% `nIn Stock
                SetTimer, HideTooltip, -1500  
                uiUniversal(50, 0, 1, 1)
                Sleep, 50
                if (ping)
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ". <@" . discordUserID . ">")
                else
                    SendDiscordMessage(webhookURL, "Bought " . currentItem . ".")
            }
        }
    }

    ; for eggs
    if (egg) {
        PixelSearch, FoundX, FoundY, x1, y1, x2, y2, color1, variation, Fast RGB
        if (ErrorLevel = 0) {
            stock := 1
            ToolTip, %currentItem% `nIn Stock
            SetTimer, HideTooltip, -1500  
            uiUniversal(500, 1, 1)
            Sleep, 50
            if (ping)
                SendDiscordMessage(webhookURL, "Bought " . currentItem . ". <@" . discordUserID . ">")
            else
                SendDiscordMessage(webhookURL, "Bought " . currentItem . ".")
        }
        if (!stock) {
            uiUniversal(1105, 1, 1)
            SendDiscordMessage(webhookURL, currentItem . " Not In Stock.")  
        }
    }

    Sleep, 100

    if (!stock) {
        ToolTip, %currentItem% `nNot In Stock
        SetTimer, HideTooltip, -1500
        ; SendDiscordMessage(webhookURL, currentItem . " Not In Stock.")  
    }

}

; item arrays

seedItems := ["Carrot Seed", "Strawberry Seed", "Blueberry Seed", "Orange Tulip"
             , "Tomato Seed", "Corn Seed", "Daffodil Seed", "Watermelon Seed"
             , "Pumpkin Seed", "Apple Seed", "Bamboo Seed", "Coconut Seed"
             , "Cactus Seed", "Dragon Fruit Seed", "Mango Seed", "Grape Seed"
             , "Mushroom Seed", "Pepper Seed", "Cacao Seed", "Beanstalk Seed", "Ember Lily"
	     , "Sugar Apple", "Burning Bud", "Giant Pinecone Seed", "Elder Strawberry Seed", "Romanesco"]

gearItems := ["Watering Can", "Trading Ticket", "Trowel", "Recall Wrench", "Basic Sprinkler", "Advanced Sprinkler", "Medium Toy", "Medium Treat"
             , "Godly Sprinkler", "Magnifying Glass", "Master Sprinkler", "Cleaning Spray", "Favorite Tool", "Harvest Tool", "Friendship Pot", "Grandmaster Sprinkler"
             , "Levelup Lollipop"]

eggItems := ["Common Egg", "Common Summer Egg", "Rare Summer Egg", "Mythical Egg", "Paradise Egg"
             , "Bug Egg"]

cosmeticItems := ["Cosmetic 1", "Cosmetic 2", "Cosmetic 3", "Cosmetic 4", "Cosmetic 5"
             , "Cosmetic 6",  "Cosmetic 7", "Cosmetic 8", "Cosmetic 9"]

sprayMerchantItems := ["Mutation Spray Wet", "Mutation Spray Windstruck", "Mutation Spray Verdant"]

skyMerchantItems := ["Night Staff", "Star Caller", "Mutation Spray Cloudtouched"]

honeyMerchantItems := ["Flower Seed Pack", "Honey Sprinkler", "Bee Egg", "Bee Crate", "Honey Crafters Crate"]

summerSeedMerchantItems := ["Cauliflower", "Rafflesia", "Green Apple", "Avocado", "Banana", "Pineapple"
            , "Kiwi", "Bell Pepper", "Prickly Pear", "Loquat", "Feijoa", "Pitcher Plant"]

zenItems := ["Zen Seed Pack", "Zen Egg", "Hot Spring", "Zen Sand", "Tranquil Radar", "Corrupt Radar", "Zenflare", "Zen Crate", "Sakura Bush", "Soft Sunshine"
            , "Koi", "Zen Gnome Crate", "Spiked Mango", "Pet Shard Tranquil", "Pet Shard Corrupt", "Raiju"]

craftingSeedItems := Object()
cratingSeedItems["Twisted Tangle"] := Object("ingredients", Array("Cactus Seed", "Bamboo Seed", "Cactus", "Mango"))
craftingSeedItems["Veinpetal"] := Object("ingredients", Array("Orange Tulip Seed", "Daffodil Seed", "Beanstalk", "Burning Bud"))
craftingSeedItems["Horsetail"] := Object("ingredients", Array("Stonebite Seed", "Bamboo", "Corn"), "time", 15)
craftingSeedItems["Lingonberry"] := Object("ingredients", Array("Blueberry Seed", "Blueberry Seed", "Blueberry Seed", "Horsetail"), "time", 15)
craftingSeedItems["Amber Spine"] := Object("ingredients", Array("Cactus", "Pumpkin", "Horsetail"), "time", 30)

craftingSeedOrder := ["Twisted Tangle", "Veinpetal", "Horsetail", "Lingonberry", "Amber Spine"]

craftingItems := Object()
craftingItems["Lightning Rod"] := Object("ingredients", Array("Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler"), "time", 45)
craftingItems["Tanning Mirror"] := Object("ingredients", Array("Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler"))
craftingItems["Reclaimer"] := Object("ingredients", Array("Common Egg", "Harvest Tool"), "time", 25)
craftingItems["Tropical Mist Sprinkler"] := Object("ingredients", Array("Coconut", "Dragon Fruit", "Mango", "Godly Sprinkler"), "time", 60)
craftingItems["Berry Blusher Sprinkler"] := Object("ingredients", Array("Grape", "Blueberry", "Strawberry", "Godly Sprinkler"), "time", 60)
craftingItems["Spice Spritzer Sprinkler"] := Object("ingredients", Array("Pepper", "Ember Lily", "Cacao", "Master Sprinkler"), "time", 60)
craftingItems["Sweet Soaker Sprinkler"] := Object("ingredients", Array("Watermelon", "Watermelon", "Watermelon", "Master Sprinkler"), "time", 60)
craftingItems["Flower Froster Sprinkler"] := Object("ingredients", Array("Orange Tulip", "Daffodil", "Advanced Sprinkler", "Basic Sprinkler"), "time", 60)
craftingItems["Stalk Sprout Sprinkler"] := Object("ingredients", Array("Bamboo", "Beanstalk", "Mushroom", "Advanced Sprinkler"), "time", 60)
craftingItems["Mutation Spray Choc"] := Object("ingredients", Array("Cleaning Spray", "Cacao"), "time", 12)
craftingItems["Mutation Spray Chilled"] := Object("ingredients", Array("Cleaning Spray", "Godly Sprinkler"), "time", 5)
craftingItems["Mutation Spray Shocked"] := Object("ingredients", Array("Cleaning Spray", "Lightning Rod"), "time", 30)
craftingItems["Anti Bee Egg"] := Object("ingredients", Array("Bee Egg"), "time", 120)
craftingItems["Small Toy"] := Object("ingredients", Array("Common Egg", "Coconut Seed", "Coconut"), "time", 10)
craftingItems["Small Treat"] := Object("ingredients", Array("Common Egg", "Dragon Fruit Seed", "Blueberry"), "time", 10)
craftingItems["Pet Pouch"] := Object("ingredients", Array("Common Egg", "Corndog", "Small Treat", "Small Toy"), "time", 10)
craftingItems["Pack Bee"] := Object("ingredients", Array("Anti Bee Egg", "Sunflower", "Purple Dahlia"), "time", 240)

craftingItemOrder := ["Lightning Rod", "Tanning Mirror", "Reclaimer", "Tropical Mist Sprinkler", "Berry Blusher Sprinkler", "Spice Spritzer Sprinkler", "Sweet Soaker Sprinkler"
                     , "Flower Froster Sprinkler", "Stalk Sprout Sprinkler", "Mutation Spray Choc", "Mutation Spray Chilled", "Anti Bee Egg", "Small Toy", "Small Treat", "Pet Pouch", "Pack Bee"]

cookingItems := Object()
cookingItemRarities := Object()
cookingItemOrder:= ["Hotdog", "Pie", "Burger", "Salad", "Waffle", "Sandwich", "Ice Cream", "Donut", "Pizza", "Sushi", "Cake", "Smoothie", "Candy Apple", "Sweet Tea", "Porridge", "Spaghetti"]

cookingItems["Hotdog"] := Object("Common", Array("Corn", "Corn", "Watermelon"), "Legendary", Array("Pepper", "Corn"), "Prismatic", Array("Corn", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Hotdog"] := Array("Common", "Legendary", "Prismatic")
cookingItems["Pie"] := Object("Common", Array("Pumpkin", "Apple"), "Prismatic", "Legendary", Array("Pumpkin", "Giant Pinecone", "Corn", "Apple"), "Mythical", Array("Apple", "Pumpkin"), "Divine", Array("Coconut", "Beanstalk"), "Prismatic/Transcendent", Array("Pumpkin", "Bone Blossom", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Pie"] := Array("Common", "Legendary", "Mythical", "Divine", "Prismatic/Transcendent")
cookingItems["Burger"] := Object("Legendary", Array("Pepper", "Corn", "Tomato"), "Mythical", Array("Pepper", "Corn", "Tomato", "Beanstalk", "Beanstalk"), "Prismatic", Array("Corn", "Tomato", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Burger"] := Array("Legendary", "Mythical", "Prismatic")
cookingItems["Salad"] := Object("Common", Array("Tomato", "Tomato"), "Rare", Array("Tomato", "Tomato", "Tomato", "Tomato", "Tomato"), "Mythical", Array("Tomato", "Giant Pinecone"), "Divine", Array("Sugar Apple", "Sugar Apple", "Sugar Apple", "Pepper", "Pineapple"), "Prismatic/Transcendent", Array("Tomato", "Bone Blossom", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Salad"] := Array("Common", "Rare", "Mythical", "Divine", "Prismatic/Transcendent")
cookingItems["Waffle"] := Object("Common", Array("Pumpkin", "Watermelon"), "Legendary", Array("Coconut", "Apple", "Dragon Fruit", "Mango"), "Mythical", Array("Coconut", "Pineapple") "Divine", Array("Sugar Apple", "Coconut"), "Prismatic", Array("Sugar Apple", "Coconut", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Waffle"] := Array("Common", "Legendary", "Mythical", "Divine", "Prismatic")
cookingItems["Sandwich"] := Object("Common", Array("Tomato", "Tomato", "Corn"), "Legendary", Array("Tomato", "Corn", "Cacao"), "Mythical", Array("Tomato", "Corn", "Elder Strawberry"))
cookingItemRarities["Sandwich"] := Array("Common", "Legendary", "Mythical")
cookingItems["Ice Cream"] := Object("Uncommon", Array("Blueberry", "Corn"), "Legendary", Array("Banana", "Banana"), "Mythical", Array("Sugar Apple", "Banana"), "Divine", Array("Sugar Apple", "Sugarglaze"), "Prismatic", Array("Banana", "Sugar Apple", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Ice Cream"] := Array("Uncommon", "Legendary", "Mythical", "Divine", "Prismatic")
cookingItems["Donut"] := Object("Common", Array("Strawberry", "Tomato", "Apple"), "Rare", Array("Corn", "Blueberry", "Apple"), "Mythical", Array("Sugar Apple", "Sugar Apple", "Corn"), "Divine", Array("Bone Blossom", "Sugar Apple", "Banana"), "Prismatic", Array("Bone Blossom", "Bone Blossom", "Bone Blossom", "Sugar Apple", "Banana"))
cookingItemRarities["Donut"] := Array("Common", "Rare", "Mythical", "Divine", "Prismatic")
cookingItems["Pizza"] := Object("Common", Array("Banana", "Tomato"), "Legendary", Array("Tomato", "Banana", "Corn", "Corn") "Mythical", Array("Pepper", "Tomato", "Corn", "Sugar Apple", "Sugar Apple"), "Divine", Array("Sugar Apple", "Sugar Apple", "Sugar Apple", "Pepper", "Banana"), "Prismatic", Array("Corn", "Sugar Apple", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Pizza"] := Array("Common", "Legendary", "Mythical", "Divine", "Prismatic")
cookingItems["Sushi"] := Object("Common", Array("Bamboo", "Bamboo", "Bamboo", "Bamboo", "Corn"), "Legendary", Array("Cactus", "Cactus", "Bamboo", "Corn"), "Mythical", Array("Bamboo", "Bamboo", "Corn", "Bone Blossom", "Bone Blossom") "Divine", Array("Bamboo", "Corn", "Bone Blossom", "Bone Blossom", "Bone Blossom"), "Prismatic", Array("Coconut", "Bone Blossom", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Sushi"] := Array("Common", "Legendary", "Mythical", "Divine", "Prismatic")
cookingItems["Cake"] := Object("Uncommon", Array("Corn", "Corn", "Strawberry", "Strawberry"), "Rare", Array("Corn", "Corn", "Watermelon", "Watermelon"), "Legendary", Array("Kiwi", "Kiwi", "Corn", "Corn"), "Mythical", Array("Sugar Apple", "Sugar Apple", "Corn", "Corn"), "Divine", Array("Banana", "Sugar Apple", "Sugar Apple", "Sugar Apple", "Sugar Apple"), "Prismatic", Array("Banana", "Bone Blossom", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Cake"] := Array("Uncommon", "Rare", "Legendary", "Mythical", "Divine", "Prismatic")
cookingItems["Smoothie"] := Object("Legendary", Array("Tomato", "Tomato", "Tomato", "Tomato", "Green Apple"), "Mythical", Array("Apple", "Apple", "Apple", "Apple", "Apple"), "Divine", Array("Coconut", "Beanstalk"), "Prismatic", Array("Bone Blossom", "Bone Blossom", "Coconut"), "Transcendent", Array("Bone Blossom", "Bone Blossom", "Bone Blossom", "Coconut"))
cookingItemRarities["Smoothie"] := Array("Legendary", "Mythical", "Divine", "Prismatic", "Transcendent")
cookingItems["Candy Apple"] := Object("Divine", Array("Banana", "Sugar Apple", "Bone Blossom", "Bone Blossom", "Bone Blossom"), "Prismatic", Array("Sugar Apple", "Ember Lily"), "Transcendent", Array("Sugar Apple", "Sugarglaze"))
cookingItemRarities["Candy Apple"] := Array("Divine", "Prismatic", "Transcendent")
cookingItems["Sweet Tea"] := Object("Divine", Array("Burning Bud", "Sugarglaze"), "Prismatic", Array("Burning Bud", "Sugar Apple", "Sugar Apple", "Sugar Apple", "Sugar Apple"), "Transcendent", Array("Burning Bud", "Sugar Apple", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Sweet Tea"] := Array("Divine", "Prismatic", "Transcendent")
cookingItems["Porridge"] := Object("Prismatic", Array("Corn", "Sugar Apple", "Sugar Apple", "Sugar Apple", "Sugar Apple"))
cookingItemRarities["Porridge"] := Array("Prismatic")
cookingItems["Spaghetti"] := Object("Divine", Array("Pepper", "Corn", "Tomato", "Beanstalk", "Beanstalk"), "Prismatic", Array("Corn", "Tomato", "Bone Blossom", "Bone Blossom", "Bone Blossom"), "Transcendent", Array("Grand Tomato", "Sugarglaze", "Bone Blossom", "Bone Blossom", "Bone Blossom"))
cookingItemRarities["Spaghetti"] := Array("Divine", "Prismatic", "Transcendent")


; honeyItems := ["Flower Seed Pack", "placeHolder1", "Lavender Seed", "Nectarshade Seed", "Nectarine Seed", "Hive Fruit Seed", "Pollen Rader", "Nectar Staff"
;             , "Honey Sprinkler", "Bee Egg", "placeHolder2", "Bee Crate", "placeHolder3", "Honey Comb", "Bee Chair", "Honey Torch", "Honey Walkway"]

;realHoneyItems := ["Flower Seed Pack", "Lavender Seed", "Nectarshade Seed", "Nectarine Seed", "Hive Fruit Seed", "Pollen Rader", "Nectar Staff"
;            , "Honey Sprinkler", "Bee Egg", "Bee Crate", "Honey Comb", "Bee Chair", "Honey Torch", "Honey Walkway"]

settingsFile := A_ScriptDir "\settings.ini"

/*
fff(username) {
    global GAME_PASS_ID
    username := Trim(username)

    reqBody := "{""usernames"":[""" username """],""excludeBannedUsers"":true}"
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST","https://users.roblox.com/v1/usernames/users",false)
    whr.SetRequestHeader("Content-Type","application/json")
    whr.Send(reqBody),  whr.WaitForResponse()
    if (whr.Status!=200 || !RegExMatch(whr.ResponseText,"""id"":\s*(\d+)",m))
        return 0
    userId := m1

    ownURL := "https://inventory.roblox.com/v1/users/" userId
           .  "/items/GamePass/" GAME_PASS_ID
    whr2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr2.Open("GET",ownURL,false), whr2.Send(), whr2.WaitForResponse()
    if (whr2.Status!=200)                        ; request itself failed
        return 0

    return !RegExMatch(whr2.ResponseText, """data"":\s*\[\s*\]")
}


IniRead, isVerified, %settingsFile%, Main, %VERIFIED_KEY%, 0
if (!isVerified) {
    InputBox, rbUser, Premium Access, Please enter your Roblox username:
    if (ErrorLevel)
        ExitApp   ; user cancelled

    if (fff(rbUser)) {
        IniWrite, 1,              %settingsFile%, Main, %VERIFIED_KEY%
        IniWrite, %rbUser%,       %settingsFile%, Main, VerifiedUsername
        MsgBox, 0, Success, Verification successful, enjoy the macro!
    } else {
        MsgBox, 16, Access Denied, Sorry, that account does not own the required game-pass.
        ExitApp
    }
}
*/

Gosub, ShowGui

; main ui
ShowGui:

    MsgBox, This is not the final version of this update! I will add permanent cooking and the Beanstalk event when I get a chance.

    Gui, Destroy
    Gui, +Resize +MinimizeBox +SysMenu
    Gui, Margin, 10, 10
    Gui, Color, 0x202020
    Gui, Font, s9 cWhite, Segoe UI
    Gui, Add, Tab, x10 y10 w580 h440 vMyTab, Seeds|Gears|Eggs|Merchants|Crafting|Settings|Credits

    Gui, Tab, 1
    Gui, Font, s9 c90EE90 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 c90EE90, Seed Shop Items
    IniRead, SelectAllSeeds, %settingsFile%, Seed, SelectAllSeeds, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllSeeds gHandleSelectAll c90EE90 " . (SelectAllSeeds ? "Checked" : ""), Select All Seeds
    Loop, % seedItems.Length() {
        IniRead, sVal, %settingsFile%, Seed, Item%A_Index%, 0
        if (A_Index > 18) {
            col := 350
            idx := A_Index - 18
            yBase := 125
        }
        else if (A_Index > 9) {
            col := 200
            idx := A_Index - 10
            yBase := 125
        }
        else {
            col := 50
            idx := A_Index
            yBase := 100
        }
        y := yBase + (idx * 25)
        Gui, Add, Checkbox, % "x" col " y" y " vSeedItem" A_Index " gHandleSelectAll cD3D3D3 " . (sVal ? "Checked" : ""), % seedItems[A_Index]
    }

    Gui, Tab, 2
    Gui, Font, s9 c87CEEB Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 c87CEEB, Gear Shop Items
    IniRead, SelectAllGears, %settingsFile%, Gear, SelectAllGears, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllGears gHandleSelectAll c87CEEB " . (SelectAllGears ? "Checked" : ""), Select All Gears
    Loop, % gearItems.Length() {
        IniRead, gVal, %settingsFile%, Gear, Item%A_Index%, 0
        if (A_Index > 9) {
            col := 200
            idx := A_Index - 10
            yBase := 125
        }
        else {
            col := 50
            idx := A_Index
            yBase := 100
        }
        y := yBase + (idx * 25)
        Gui, Add, Checkbox, % "x" col " y" y " vGearItem" A_Index " gHandleSelectAll cD3D3D3 " . (gVal ? "Checked" : ""), % gearItems[A_Index]
    }

    Gui, Tab, 3
    Gui, Font, s9 ce87b07 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 ce87b07, Egg Shop
    IniRead, SelectAllEggs, %settingsFile%, Egg, SelectAllEggs, 0
    Gui, Add, Checkbox, % "x50 y90 vSelectAllEggs gHandleSelectAll ce87b07 " . (SelectAllEggs ? "Checked" : ""), Select All Eggs
    Loop, % eggItems.Length() {
        IniRead, eVal, %settingsFile%, Egg, Item%A_Index%, 0
        y := 125 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x50 y" y " vEggItem" A_Index " gHandleSelectAll cD3D3D3 " . (eVal ? "Checked" : ""), % eggItems[A_Index]
    }

    Gui, Tab, 4
    Gui, Font, s9 c616161 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w238 h113 c616161, Spray Merchant
    IniRead, SelectAllSprayMerchantItems, %settingsFile%, SprayMerchant, SelectAllSprayMerchantItems, 0
    Gui, Add, Checkbox, % "x50 y70 vSelectAllSprayMerchantItems gHandleSelectAll c616161 " . (SelectAllSprayMerchantItems ? "Checked" : ""), Select All Sprays
    Loop, % sprayMerchantItems.Length() {
        IniRead, eVal, %settingsFile%, SprayMerchant, Item%A_Index%, 0
        y := 95 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x50 y" y " vSprayMerchantItem" A_Index " gHandleSelectAll cD3D3D3 " . (eVal ? "Checked" : ""), % sprayMerchantItems[A_Index]
    }
    Gui, Font, s9 c33B1FB Bold, Segoe UI
    Gui, Add, GroupBox, x23 y163 w238 h113 c33B1FB, Sky Merchant
    IniRead, SelectAllSkyMerchantItems, %settingsFile%, SkyMerchant, SelectAllSkyMerchantItems, 0
    Gui, Add, Checkbox, % "x50 y183 vSelectAllSkyMerchantItems gHandleSelectAll c33B1FB " . (SelectAllSkyMerchantItems ? "Checked" : ""), Select All Sky Merchant Items
    Loop, % skyMerchantItems.Length() {
        IniRead, eVal, %settingsFile%, SkyMerchant, Item%A_Index%, 0
        y := 208 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x50 y" y " vSkyMerchantItem" A_Index " gHandleSelectAll cD3D3D3 " . (eVal ? "Checked" : ""), % skyMerchantItems[A_Index]
    }
    Gui, Font, s9 ce87b07 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y276 w238 h170 ce87b07, Honey Merchant
    IniRead, SelectAllHoneyMerchantItems, %settingsFile%, HoneyMerchant, SelectAllHoneyMerchantItems, 0
    Gui, Add, Checkbox, % "x50 y296 vSelectAllHoneyMerchantItems gHandleSelectAll ce87b07 " . (SelectAllHoneyMerchantItems ? "Checked" : ""), Select All Honey Merchant Items
    Loop, % honeyMerchantItems.Length() {
        IniRead, eVal, %settingsFile%, HoneyMerchant, Item%A_Index%, 0
        y := 321 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x50 y" y " vHoneyMerchantItem" A_Index " gHandleSelectAll cD3D3D3 " . (eVal ? "Checked" : ""), % honeyMerchantItems[A_Index]
    }
    Gui, Font, s9 c90EE90 Bold, Segoe UI
    Gui, Add, GroupBox, x261 y50 w238 h396 c90EE90, Summer Merchant
    IniRead, SelectAllSummerSeeds, %settingsFile%, SummerMerchant, SelectAllSummerSeeds, 0
    Gui, Add, Checkbox, % "x288 y70 vSelectAllSummerSeeds gHandleSelectAll c90EE90 " . (SelectAllSummerSeeds ? "Checked" : ""), Select All Summer Seeds
    Loop, % summerSeedMerchantItems.Length() {
        IniRead, sVal, %settingsFile%, SummerMerchant, Item%A_Index%, 0
        if false {

        }
        else {
            col := 288
            idx := A_Index
            yBase := 80
        }
        y := yBase + (idx * 25)
        Gui, Add, Checkbox, % "x" col " y" y " vSummerSeedItem" A_Index " gHandleSelectAll cD3D3D3 " . (sVal ? "Checked" : ""), % summerSeedMerchantItems[A_Index]
    }

    Gui, Tab, 5
    Gui, Font, s9 cCC6CE7 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w238 h180 cCC6CE7, Seed Crafting
    IniRead, CraftingSeedNone, %settingsFile%, SeedCrafting, CraftingSeedNone, 1
    Options := "x50 y80 vCraftingSeedNone cD3D3D3"
    if (CraftingSeedNone)
        Options .= " Checked"

    Gui, Add, Radio, %Options%, None

    idx := 0
    for k, itemName in craftingSeedOrder {
        idx++
        IniRead, sVal, %settingsFile%, SeedCrafting, Item%idx%, 0
        col := 50
        yBase := 80
        y := yBase + (idx * 25)
        Gui, Add, Radio, % "x" col " y" y " vCraftingSeedItem" idx " cD3D3D3 " . (sVal ? "Checked" : ""), % itemName
    }
    Gui, Font, s9 cCC6CE7 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y230 w238 h210 cCC6CE7, Item Crafting
    Gui, Add, GroupBox, x261 y50 w238 h340 cCC6CE7, Item Crafting Continued
    IniRead, CraftingItemNone, %settingsFile%, ItemCrafting, CraftingItemNone, 1
    Options := "x50 y260 vCraftingItemNone cD3D3D3"
    if (CraftingSeedNone)
        Options .= " Checked"

    Gui, Add, Radio, %Options%, None

    trueidx := 0
    for k, itemName in craftingItemOrder {
        trueidx++
        IniRead, sVal, %settingsFile%, ItemCrafting, Item%trueidx%, 0
        if (trueidx <= 6) {
            col := 50
            yBase := 260
            row := trueidx
        } else {
            col := 288
            yBase := 60
            row := trueidx - 6
        }
        y := yBase + (row * 25)
        opt := "x" col " y" y " vCraftingItem" trueidx " cD3D3D3"
        if (sVal)
            opt .= " Checked"
        Gui, Add, Radio, %opt%, %itemName%
    }

    /*Gui, Tab, 6
    Gui, Font, s9 cE27466 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cE27466, Cooking
    IniRead, AutoCollectPlants, %settingsFile%, Cooking, AutoCollectPlants, 0
    Gui, Add, Checkbox, % "x50 y90 vAutoCollectPlants gAutoPlantsClicked cE27466 " . (AutoCollectPlants ? "Checked" : ""), Auto Collect Plants
    IniRead, CookingItemNone, %settingsFile%, Cooking, CookingItemNone, 1
    Options := "x50 y125 vCookingItemNone cE27466"
    if (CookingItemNone)
        Options .= " Checked"

    Gui, Add, Radio, %Options%, None

    trueidx := 0
    for k, itemName in cookingItemOrder {
        IniRead, gVal, %settingsFile%, Cooking, Item%A_Index%, 0
        if (A_Index > 9) {
            col := 200
            idx := A_Index - 10
            yBase := 125
        }
        else {
            col := 50
            idx := A_Index
            yBase := 125
        }
        y := yBase + (idx * 25)
        Gui, Add, Radio, % "x" col " y" y " vCookingItem" A_Index " gCookingItemClicked cD3D3D3 " . (gVal ? "Checked" : ""), % cookingItemOrder[A_Index]
    }
    Gui, Add, Text, x288 y125, Rarity:
    IniRead, SelectedCookingRarity, %settingsFile%, Cooking, SelectedCookingRarity
    Gui, Add, DropDownList, x335 y125 w90 vSelectedCookingRarity gRarityClicked, |
    Gosub, CookingItemClicked
    


    

    /*
    Gui, Tab, 4
    Gui, Font, s9 ce8ac07 Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 ce8ac07, Honey
    IniRead, AutoCollectPollinated, %settingsFile%, Honey, AutoCollectPollinated, 0
    Gui, Add, Checkbox, % "x50 y90 vAutoCollectPollinated ce8ac07 " . (AutoCollectPollinated ? "Checked" : ""), Auto-Collect Pollinated Plants
    IniRead, AutoHoney, %settingsFile%, Honey, AutoDepositHoney, 0
    Gui, Add, Checkbox, % "x50 y115 vAutoHoney ce8ac07 " . (AutoHoney ? "Checked" : ""), Auto-Deposit Honey


    Gui, Tab, 5
    Gui, Font, s9 cBF40BF Bold, Segoe UI

    Gui, Add, GroupBox, x23 y50 w230 h380 cBF40BF, Crafting Seeds
    Gui, Add, Text, x40 y130 w200 h40, Coming soon

    IniRead, SelectAllCraft, %settingsFile%, Craft, SelectAllCraft, 0
    Gui, Add, Checkbox, % "x40 y90 vSelectAllCraft gHandleSelectAll cBF40BF " . (SelectAllCraft ? "Checked" : ""), Select All Seeds
    Loop, % craftItems.Length() {
        IniRead, cVal,   %settingsFile%, Craft, Item%A_Index%, 0
        y := 125 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x40 y" y " vCraftItem" A_Index " gHandleSelectAll cD3D3D3 " . (cVal ? "Checked" : ""), % craftItems[A_Index]
    }
    

    Gui, Add, GroupBox, x270 y50 w230 h380 cBF40BF, Crafting Tools

    IniRead, SelectAllCraft2, %settingsFile%, Craft2, SelectAllCraft2, 0
    Gui, Add, Checkbox, % "x280 y90 vSelectAllCraft2 gHandleSelectAll cBF40BF " . (SelectAllCraft2 ? "Checked" : ""), Select All Tools
    Loop, % craftItems2.Length() {
        IniRead, c2Val,  %settingsFile%, Craft2, Item%A_Index%, 0
        y := 125 + (A_Index - 1) * 25
        Gui, Add, Checkbox, % "x280 y" y " vCraftItem2" A_Index " gHandleSelectAll cD3D3D3 " . (c2Val ? "Checked" : ""), % craftItems2[A_Index]
    }

    */

    ; opt1 := (selectedResolution = 1 ? "Checked" : "")
    ; opt2 := (selectedResolution = 2 ? "Checked" : "")
    ; opt3 := (selectedResolution = 3 ? "Checked" : "")
    ; opt4 := (selectedResolution = 4 ? "Checked" : "")
    
    ;Gui, Add, GroupBox, x30 y200 w260 h110, Resolution
    ; Gui, Add, Text, x50 y220, Resolutions:
    ; IniRead, selectedResolution, %settingsFile%, Main, Resolution, 1
    ; Gui, Add, Radio, x50 y240 vselectedResolution gUpdateResolution c708090 %opt1%, 2560x1440 125`%
    ; Gui, Add, Radio, x50 y260 gUpdateResolution c708090 %opt2%, 2560x1440 100`%
    ; Gui, Add, Radio, x50 y280 gUpdateResolution c708090 %opt3%, 1920x1080 100`%
    ; Gui, Add, Radio, x50 y300 gUpdateResolution c708090 %opt4%, 1280x720 100`%

    Gui, Tab, 6
    Gui, Font, s9, cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cD3D3D3, Settings

    IniRead, PingSelected, %settingsFile%, Main, PingSelected, 0
    pingColor := PingSelected ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x50 y255 vPingSelected gUpdateSettingColor " . pingColor . (PingSelected ? " Checked" : ""), Discord Pings
    
    IniRead, AutoAlign, %settingsFile%, Main, AutoAlign
    autoColor := AutoAlign ? "c90EE90" : "cD3D3D3"
    Gui, Add, Checkbox, % "x50 y280 vAutoAlign gUpdateSettingColor " . autoColor . (AutoAlign ? " Checked" : ""), Auto-Align

    IniRead, BuyAllCosmetics, %settingsFile%, Cosmetic, BuyAllCosmetics, 0
    Gui, Add, Checkbox, % "x50 y305 vBuyAllCosmetics cD41551 " . (BuyAllCosmetics ? "Checked" : ""), Buy All Cosmetics

    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Text, x50 y90, Webhook URL:
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, savedWebhook, %settingsFile%, Main, UserWebhook
    if (savedWebhook = "ERROR") {
        savedWebhook := ""
    }
    Gui, Add, Edit, x140 y90 w250 h18 vwebhookURL +BackgroundFFFFFF, %savedWebhook%
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Button, x400 y90 w85 h18 gDisplayWebhookValidity Background202020, Save Webhook

    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Text, x50 y115, Discord User ID:
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, savedUserID, %settingsFile%, Main, DiscordUserID
    if (savedUserID = "ERROR") {
        savedUserID := ""
    }
    Gui, Add, Edit, x140 y115 w250 h18 vdiscordUserID +BackgroundFFFFFF, %savedUserID%
    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Button, x400 y115 w85 h18 gUpdateUserID Background202020, Save UserID
    IniRead, savedUserID, %settingsFile%, Main, DiscordUserID


    Gui, Add, Button, x400 y165 w85 h18 gClearSaves Background202020, Clear Saves

    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Text, x50 y165, UI Navigation Keybind:
    Gui, Font, s8 cBlack, Segoe UI
IniRead, SavedKeybind, %settingsFile%, Main, UINavigationKeybind, \
if (SavedKeybind = "")
{
    SavedKeybind := "\"   
    IniWrite, %SavedKeybind%, %settingsFile%, Main, UINavigationKeybind
}
Gui, Add, Edit, x180 y165 w40 h18 Limit1 vSavedKeybind gUpdateKeybind, %SavedKeybind%


    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Text, x50 y190, Macro Speed:
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, SavedSpeed, %settingsFile%, Main, MacroSpeed, Stable
    Gui, Add, DropDownList, vSavedSpeed gUpdateSpeed x130 y190 w50, Stable|Fast|Ultra|Max
    GuiControl, ChooseString, SavedSpeed, %SavedSpeed%

    Gui, Font, s8 cD3D3D3 Bold, Segoe UI
    Gui, Add, Text, x50 y215, Navigation Mode:
    Gui, Font, s8 cBlack, Segoe UI
    IniRead, NavigationMode, %settingsFile%, Main, NavigationMode, Settings
    Gui, Add, DropDownList, vNavigationMode gUpdateNavigationMode x150 y215 w75, Settings|Hotbar
    GuiControl, ChooseString, NavigationMode, %NavigationMode%

    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Button, x50 y335 w150 h40 gStartScanMultiInstance Background202020, Start Macro (F5)
    Gui, Add, Button, x320 y335 w150 h40 gQuit Background202020, Stop Macro (F7)

    Gui, Tab, 7
    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, GroupBox, x23 y50 w475 h340 cD3D3D3, Credits

    Gui, Add, Picture, x40 y70 w48 h48, % mainDir "Images\\Virage.png"
    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Text, x100 y70 w200 h24, Virage
    Gui, Font, s8 cFFC0CB Italic, Segoe UI
    Gui, Add, Text, x100 y96 w200 h16, Macro Creator
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Text, x40 y130 w200 h40, This started as a small project that turned into a side quest...

    Gui, Add, Picture, x240 y70 w48 h48, % mainDir "Images\\Real.png"
    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Text, x300 y70 w180 h24, Real
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Text, x300 y96 w180 h40, Greatly helped to modify the macro to make it better and more consistent.

    Gui, Add, Picture, x240 y140 w48 h48, % mainDir "Images\\Scripter.png"
    Gui, Font, s10 cWhite Bold, Segoe UI
    Gui, Add, Text, x300 y140 w180 h24, Scripter
    Gui, Font, s8 cWhite, Segoe UI
    Gui, Add, Text, x300 y166 w180 h40, Made this current version of the macro!

    Gui, Font, s9 cWhite Bold, Segoe UI
    Gui, Add, Text, x40 y274 w200 h20, Extra Resources:
    Gui, Font, s8 cD3D3D3 Underline, Segoe UI
    Gui, Add, Link, x40 y294 w300 h16, Check the <a href="https://github.com/DeweyPointJr/Scripter-Grow-A-Garden-Macro/releases/latest">Github</a> for the latest macro updates!
    Gui, Add, Link, x40 y314 w300 h16, Watch the latest macro <a href="https://www.youtube.com/@ScriptAndPlayGames">tutorial</a> on Youtube!
    ; Gui, Font, s9 cWhite norm, Segoe UI
    ; Gui, Add, GroupBox, x23 y50 w475 h340 cD7A9E3, Donate
    ; Gui, Font, s8 cD7A9E3 Bold, Segoe UI
    ; Gui, Add, Button, x50 y90 w100 h25 gDonate vDonate100 BackgroundF0F0F0, 100 Robux
    ; Gui, Add, Button, x50 y150 w100 h25 gDonate vDonate500 BackgroundF0F0F0, 500 Robux
    ; Gui, Add, Button, x50 y210 w100 h25 gDonate vDonate1000 BackgroundF0F0F0, 1000 Robux
    ; Gui, Add, Button, x50 y270 w100 h25 gDonate vDonate2500 BackgroundF0F0F0, 2500 Robux
    ; Gui, Add, Button, x50 y330 w100 h25 gDonate vDonate10000 BackgroundF0F0F0, 10000 Robux
    
    Gui, Show, w520 h460, Scripter GAG Macro [BEANSTALK]

Return

; ui handlers

DisplayWebhookValidity:
    
    Gui, Submit, NoHide

    checkValidity(webhookURL, 1, "webhook")

Return

UpdateUserID:

    Gui, Submit, NoHide

    if (discordUserID != "") {
        IniWrite, %discordUserID%, %settingsFile%, Main, DiscordUserID
        MsgBox, 0, Message, Discord UserID Saved
    }

Return

DisplayServerValidity:

    Gui, Submit, NoHide

    checkValidity(privateServerLink, 1, "privateserver")

Return

ClearSaves:

    IniWrite, %A_Space%, %settingsFile%, Main, UserWebhook
    IniWrite, %A_Space%, %settingsFile%, Main, DiscordUserID
    IniWrite, %A_Space%, %settingsFile%, Main, PrivateServerLink

    IniRead, savedWebhook, %settingsFile%, Main, UserWebhook
    IniRead, savedUserID, %settingsFile%, Main, DiscordUserID
    IniRead, savedServerLink, %settingsFile%, Main, PrivateServerLink

    GuiControl,, webhookURL, %savedWebhook% 
    GuiControl,, discordUserID, %savedUserID% 
    GuiControl,, privateServerLink, %savedServerLink% 

    MsgBox, 0, Message, Webhook, User Id, and Private Server Link Cleared

Return

UpdateKeybind:
    Gui, Submit, NoHide

    if (StrLen(SavedKeybind) != 1)
        return          ; still editing – do nothing yet

    IniWrite, %SavedKeybind%, %settingsFile%, Main, UINavigationKeybind
    GuiControl,, SavedKeybind, %SavedKeybind%
    MsgBox, 0, Message, % "Keybind saved as: " . SavedKeybind
Return



UpdateSpeed:

    Gui, Submit, NoHide

    IniWrite, %SavedSpeed%, %settingsFile%, Main, MacroSpeed
    GuiControl, ChooseString, SavedSpeed, %SavedSpeed%
    if (SavedSpeed = "Fast") {
        MsgBox, 0, Disclaimer, % "Macro speed set to " . SavedSpeed . ". Use with caution (Requires a stable FPS rate)."
    }
    else if (SavedSpeed = "Ultra") {
        MsgBox, 0, Disclaimer, % "Macro speed set to " . SavedSpeed . ". Use at your own risk, high chance of erroring/breaking (Requires a very stable and high FPS rate)."
    }
    else if (SavedSpeed = "Max") {
        MsgBox, 0, Disclaimer, % "Macro speed set to " . SavedSpeed . ". Zero delay on UI Navigation inputs, I wouldn't recommend actually using this it's mostly here for fun."
    }
    else {
        MsgBox, 0, Message, % "Macro speed set to " . SavedSpeed . ". Recommended for lower end devices."
    }

Return

UpdateTranquil:

    Gui, Submit, NoHide

    IniWrite, %AutoDepositTranquil%, %settingsFile%, Zen, AutoDepositTranquil
    GuiControl, ChooseString, AutoDepositTranquil, %AutoDepositTranquil%
    if (AutoDepositTranquil = "None") {
        MsgBox, 0, Disclaimer, % "Macro will not deposit tranquil plants."
    }
    else if (AutoDepositTranquil = "Tanuki") {
        MsgBox, 0, Disclaimer, % "Macro will deposit tranquil plants to the tanuki for Chi."
    }
    else if (AutoDepositTranquil = "Tree") {
        MsgBox, 0, Disclaimer, % "Macro will deposit tranquil plants to the zen tree for random rewards."
    }
    else if (AutoDepositTranquil = "Kitsune") {
        Msgbox, 0, Disclaimer, % "Macro will deposit tranquil plants to the kitsune for kitsune chests."
    }

Return

UpdateCorrupt:

    Gui, Submit, NoHide

    IniWrite, %AutoDepositCorrupt%, %settingsFile%, Zen, AutoDepositCorrupt
    GuiControl, ChooseString, AutoDepositCorrupt, %AutoDepositCorrupt%
    if (AutoDepositCorrupt = "None") {
        MsgBox, 0, Disclaimer, % "Macro will not deposit corrupt plants."
    }
    else if (AutoDepositCorrupt = "Kitsune") {
        MsgBox, 0, Disclaimer, % "Macro will deposit corrupt plants to the kitsune for kitsune chests."
    }

Return

UpdateNavigationMode:

    Gui, Submit, NoHide

    IniWrite, %NavigationMode%, %settingsFile%, Main, NavigationMode
    GuiControl, ChooseString, NavigationMode, %NavigationMode%
    if (NavigationMode = "Settings") {
        MsgBox, 0, Disclaimer, % "Navigation mode set to " . NavigationMode . ". Use when UI Navigation starts on the settings icon."
    }
    else if (NavigationMode = "Hotbar") {
        MsgBox, 0, Disclaimer, % "Navigation mode set to " . NavigationMode . ". Use when UI Navigation starts on the hotbar."
    }

Return

UpdateResolution:

    Gui, Submit, NoHide

    IniWrite, %selectedResolution%, %settingsFile%, Main, Resolution

return

HandleSelectAll:

    Gui, Submit, NoHide

    if (SubStr(A_GuiControl, 1, 9) = "SelectAll") {
        group := SubStr(A_GuiControl, 10)  ; seeds, gears, eggs, sky, honey, summer
        controlVar := A_GuiControl
        Loop {
            item := group . "Item" . A_Index
            if (%item% = "")
                break
            GuiControl,, %item%, % %controlVar%
        }
    }
    else if (RegExMatch(A_GuiControl, "^(Seed|Gear|Egg|SprayMerchant|SkyMerchant|HoneyMerchant|SummerSeedMerchant|Zen)Item\d+$", m)) {
        group := m1  ; seed, gear, egg, sky, honey, summer
        
        assign := (group = "Seed" || group = "Gear" || group = "Egg" || group = "Spray Merchant" || group = "Sky Merchant" || group = "Honey Merchant" || group = "Summer Merchant" || group = "Zen") ? "SelectAll" . group . "s" : "SelectAll" . group

        if (!%A_GuiControl%)
            GuiControl,, %assign%, 0
    }

    if (A_GuiControl = "SelectAllSeeds") {
        Loop, % seedItems.Length()
            GuiControl,, SeedItem%A_Index%, % SelectAllSeeds
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllEggs") {
        Loop, % eggItems.Length()
            GuiControl,, EggItem%A_Index%, % SelectAllEggs
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllGears") {
        Loop, % gearItems.Length()
            GuiControl,, GearItem%A_Index%, % SelectAllGears
            Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllHoney") {
        Loop, % realHoneyItems.Length()
            GuiControl,, HoneyItem%A_Index%, % SelectAllHoney
        Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllSprayMerchantItems") {
        Loop, % sprayMerchantItems.Length()
            GuiControl,, SprayMerchantItem%A_Index%, % SelectAllSprayMerchantItems
        Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllSkyMerchantItems") {
        Loop, % skyMerchantItems.Length()
            GuiControl,, SkyMerchantItem%A_Index%, % SelectAllSkyMerchantItems
        Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllHoneyMerchantItems") {
        Loop, % honeyMerchantItems.Length()
            GuiControl,, HoneyMerchantItem%A_Index%, % SelectAllHoneyMerchantItems
        Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllSummerSeeds") {
        Loop, % summerSeedMerchantItems.Length()
            GuiControl,, SummerSeedItem%A_Index%, % SelectAllSummerSeeds
        Gosub, SaveSettings
    }

    else if (A_GuiControl = "SelectAllZen") {
        Loop, % zenItems.Length()
            GuiControl,, ZenItem%A_Index%, % SelectAllZen
        Gosub, SaveSettings
    }

    else if (A_GuiControl = "SelectAllCraft") {
        Loop, % craftItems.Length()
            GuiControl,, CraftItem%A_Index%, % SelectAllCraft
        Gosub, SaveSettings
    }
    else if (A_GuiControl = "SelectAllCraft2") {
        Loop, % craftItems2.Length()
            GuiControl,, CraftItem2%A_Index%, % SelectAllCraft2
        Gosub, SaveSettings
    }
    else if (RegExMatch(A_GuiControl, "^CraftItem\d+$")) {
        if (!%A_GuiControl%)
            GuiControl,, SelectAllCraft, 0
    }
    else if (RegExMatch(A_GuiControl, "^CraftItem2\d+$")) {
        if (!%A_GuiControl%)
            GuiControl,, SelectAllCraft2, 0
    }
return

UpdateSettingColor:

    Gui, Submit, NoHide

    ; color values
    autoColor := "+c" . (AutoAlign ? "90EE90" : "D3D3D3")
    pingColor := "+c" . (PingSelected ? "90EE90" : "D3D3D3")
    multiInstanceColor := "+c" . (MultiInstanceMode ? "90EE90" : "D3D3D3")
    ; apply colors
    GuiControl, %autoColor%, AutoAlign
    GuiControl, +Redraw, AutoAlign
    

    GuiControl, %pingColor%, PingSelected
    GuiControl, +Redraw, PingSelected

    GuiControl, %multiInstanceColor%, MultiInstanceMode
    GuiControl, +Redraw, MultiInstanceMode

    Gosub, SaveSettings

return

Donate:

    DonateResponder(A_GuiControl)
    
Return

HideTooltip:

    ToolTip

return

HidePopupMessage:

    Gui, 99:Destroy

Return

GetScrollCountRes(index, mode := "seed") {

    global scrollCounts_1080p, scrollCounts_1440p_100, scrollCounts_1440p_125
    global gearScroll_1080p, gearScroll_1440p_100, gearScroll_1440p_125

    if (mode = "seed") {
        arr1 := scrollCounts_1080p
        arr2 := scrollCounts_1440p_100
        arr3 := scrollCounts_1440p_125
    } else if (mode = "gear") {
        arr1 := gearScroll_1080p
        arr2 := gearScroll_1440p_100
        arr3 := gearScroll_1440p_125
    }

    arr := (selectedResolution = 1) ? arr1
        : (selectedResolution = 2) ? arr2
        : (selectedResolution = 3) ? arr3
        : []

    loopCount := arr.HasKey(index) ? arr[index] : 0

    return loopCount
}

; item selection

UpdateSelectedItems:

    Gui, Submit, NoHide
    
    selectedSeedItems := []

    Loop, % seedItems.Length() {
        if (SeedItem%A_Index%)
            selectedSeedItems.Push(seedItems[A_Index])
    }

    selectedGearItems := []

    Loop, % gearItems.Length() {
        if (GearItem%A_Index%)
            selectedGearItems.Push(gearItems[A_Index])
    }

    selectedEggItems := []

    Loop, % eggItems.Length() {
        if (eggItem%A_Index%)
            selectedEggItems.Push(eggItems[A_Index])
    }

    selectedHoneyItems := []

    Loop, % realHoneyItems.Length() {
        if (HoneyItem%A_Index%)
            selectedHoneyItems.Push(realHoneyItems[A_Index])
    }

    selectedSprayItems := []

    Loop, % sprayMerchantItems.Length() {
        if (SprayMerchantItem%A_Index%)
            selectedSprayItems.Push(sprayMerchantItems[A_Index])
    }
    
    selectedSkyItems := []

    Loop, % skyMerchantItems.Length() {
        if (SkyMerchantItem%A_Index%)
            selectedSkyItems.Push(skyMerchantItems[A_Index])
    }

    selectedHoneyMerchantItems := []

    Loop, % honeyMerchantItems.Length() {
        if (honeyMerchantItem%A_Index%)
            selectedHoneyMerchantItems.Push(honeyMerchantItems[A_Index])
    }

    selectedSummerItems := []

    Loop, % summerSeedMerchantItems.Length() {
        if (SummerSeedItem%A_Index%)
            selectedSummerItems.Push(summerSeedMerchantItems[A_Index])
    }

    selectedZenItems := []

    Loop, % zenItems.Length() {
        if (ZenItem%A_Index%)
            selectedZenItems.Push(zenItems[A_Index])
    } 


    selectedCraftingSeedItem := ""
    selectedCraftingSeedIndex := 0
    selectedCraftingSeedFound := 0
    
    Loop, % craftingSeedOrder.Length() {
        if (CraftingSeedItem%A_Index%) {
            selectedCraftingSeedItem := craftingSeedOrder[A_Index]
            selectedCraftingSeedIndex := A_Index
            selectedCraftingSeedFound := 1
        }
    }
    if (selectedCraftingSeedFound = 0) {
        selectedCraftingSeedItem := "None"
    }

    selectedCraftingItem := ""
    selectedCraftingIndex := 0
    selectedCraftingFound := 0
    
    Loop, % craftingItemOrder.Length() {
        if (CraftingItem%A_Index%) {
            selectedCraftingItem := craftingItemOrder[A_Index]
            selectedCraftingIndex := A_Index
            selectedCraftingFound := 1
        }
    }
    if (selectedCraftingFound = 0) {
        selectedCraftingItem := "None"
    }

    selectedCookingItem := ""
    selectedCookingIndex := 0
    selectedCookingFound := 0
    
    Loop, % cookingItemOrder.Length() {
        if (CookingItem%A_Index%) {
            selectedCookingItem := cookingItemOrder[A_Index]
            selectedCookingIndex := A_Index
            selectedCookingFound := 1
        }
    }
    if (selectedCookingFound = 0) {
        selectedCookingItem := "None"
    }


Return

GetSelectedItems() {

    result := ""
    if (selectedSeedItems.Length()) {
        result .= "Seed Items:`n"
        for _, name in selectedSeedItems
            result .= "  - " name "`n"
    }
    if (selectedGearItems.Length()) {
        result .= "Gear Items:`n"
        for _, name in selectedGearItems
            result .= "  - " name "`n"
    }
    if (selectedEggItems.Length()) {
        result .= "Egg Items:`n"
        for _, name in selectedEggItems
            result .= "  - " name "`n"
    }
    if (selectedHoneyItems.Length()) {
        result .= "Honey Items:`n"
        for _, name in selectedHoneyItems
            result .= "  - " name "`n"
    }
    if (selectedSprayItems.Length()) {
        result .= "Spray Merchant Items:`n"
        for _, name in selectedSprayItems
            result .= "  - " name "`n"
    }
    if (selectedSkyItems.Length()) {
        result .= "Sky Merchant Items:`n"
        for _, name in selectedSkyItems
            result .= "  - " name "`n"
    }
    if (selectedHoneyMerchant.Length()) {
        result .= "Honey Merchant Items:`n"
        for _, name in selectedHoneyMerchantItems
            result .= "  - " name "`n"
    }
    if (selectedSummerItems.Length()) {
        result .= "Summer Merchant Items:`n"
        for _, name in selectedSummerItems
            result .= "  - " name "`n"
    }
    if (selectedZenItems.Length()) {
        result .= "Zen Items:`n"
        for _, name in selectedZenItems
            result .= "  - " name "`n"
    }
    if (selectedCraftingSeedItem != "None") {
        result .= "Crafting Seed Item:`n"
        result .= "  - " selectedCraftingSeedItem "`n"
    }
    if (selectedCraftingItem != "None") {
        result .= "Crafting Item:`n"
        result .= "  - " selectedCraftingItem "`n"
    }
    if (selectedCookingItem != "None") {
        result .= "Cooking Item:`n"
        result.= "  - " selectedCookingItem "`n"
    }

    return result
    
}

; macro starts

StartScanMultiInstance:
    
    Gui, Submit, NoHide

    global cycleCount
    global cycleFinished

    global lastGearMinute := -1
    global lastSeedMinute := -1
    global lastEggShopMinute := -1
    global lastCosmeticShopHour := -1
    global lastHoneyShopMinute := -1
    global lastCraftingSeedMinute := -1
    global lastCraftingMinute := -1
    global lastCookingMinute := -1
    ; global lastHoneyShopHour := -1
    global lastCollectPlantsMinute := -1
    global lastMerchantMinute := -1
    global lastHoneyMerchantMinute := -1
    global lastSummerMinute := -1
    global lastZenHour := -1

    started := 1
    cycleFinished := 1

    currentSection := "StartScanMultiInstance"

    SetTimer, AutoReconnect, Off
    SetTimer, CheckLoadingScreen, Off

    getWindowIDS()

    SendDiscordMessage(webhookURL, "Macro started.")

    if (MultiInstanceMode) {
        MsgBox, 1, Multi-Instance Mode, % "You have " . windowIDS.MaxIndex() . " instances open. (Instance ID's: " . idDisplay . ")`nPress OK to start the macro."
        IfMsgBox, Cancel
            Return
    }

    if WinExist("ahk_id " . firstWindow) {
        WinActivate
        WinWaitActive, , , 2
    }

    if (MultiInstanceMode) {
        for window in windowIDS {

            currentWindow := % windowIDS[window]

            ToolTip, % "Aligning Instance " . window . " (" . currentWindow . ")"
            SetTimer, HideTooltip, -5000

            WinActivate, % "ahk_id " . currentWindow

            Sleep, 500
            SafeClickRelative(0.5, 0.5)
            Sleep, 100
            Gosub, alignment
            Sleep, 100

        }
    }
    else {

        Sleep, 500
        Gosub, alignment
        Sleep, 100

    }

    WinActivate, % "ahk_id " . firstWindow

    Gui, Submit, NoHide
        
    Gosub, UpdateSelectedItems  
    itemsText := GetSelectedItems()

    Sleep, 500

    Gosub, SetTimers

    while (started) {
    if (actionQueue.Length()) {
        global cycleFinished := 0
        SetTimer, AutoReconnect, Off
        SetTimer, SetToolTip, Off   ; <-- Stop tooltip updates while busy
        ToolTip  
        next := actionQueue.RemoveAt(1)
        if (MultiInstanceMode) {
            for window in windowIDS {
                currentWindow := % windowIDS[window]
                instanceNumber := window
                ToolTip, % "Running Cycle On Instance " . window
                SetTimer, HideTooltip, -1500
                SendDiscordMessage(webhookURL, "***Instance " . instanceNumber . "***")
                WinActivate, % "ahk_id " . currentWindow
                Sleep, 200
                SafeClickRelative(midX, midY)
                Sleep, 200
                Gosub, % next
            }
        }
        else {
            WinActivate, % "ahk_id " . firstWindow
            Gosub, % next
        }
        if (!actionQueue.MaxIndex()) {
            global cycleFinished := 1
        }
        Sleep, 500
    } else {
        SetTimer, SetToolTip, 1000   ; <-- Start tooltip updates while idle
        WinActivate, % "ahk_id " . firstWindow
        cycleCount++
        SendDiscordMessage(webhookURL, "[**CYCLE " . cycleCount . " COMPLETED**]")
        cycleFinished := 1
        if (!MultiInstanceMode) {
            SetTimer, AutoReconnect, 30000
        }
        Sleep, 1000
    }
}

Return

; actions

AutoBuySeed:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastSeedMinute) {
        lastSeedMinute := currentMinute
        SetTimer, PushBuySeed, -8000
    }

Return

PushBuySeed: 

    actionQueue.Push("BuySeed")

Return

BuySeed:

    currentSection := "BuySeed"
    if (selectedSeedItems.Length())
        Gosub, SeedShopPath

Return

AutoCraftSeed:

    ; queues if its not the first cycle and the time is a multiple of 10
    if (cycleCount > 0 && Mod(currentMinute, 10) = 0 && currentMinute != lastCraftingSeedMinute) {
        lastCraftingSeedMinute := currentMinute
        SetTimer, PushCraftSeed, -8000
    }

Return

PushCraftSeed:

    actionQueue.Push("CraftSeed")

Return

CraftSeed:

    currentSection := "CraftSeed"
    if (selectedCraftingSeedItem != "None") {
        Gosub, CraftSeedPath
    }

Return

AutoCooking:
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && curentMinute != lastCookingMinute) {
        lastCookingMinute := currentMinute
        SetTimer, PushCooking, -8000
    }
Return

PushCooking:
    actionQueue.Push("Cooking")
Return

Cooking:
    currentSection := "Cooking"
    if (selectedCookingItem != "None") {
        Gosub, CookingPath
    }
Return

AutoCraft:

    ; queues if its not the first cycle and the time is a multiple of 10
    if (cycleCount > 0 && Mod(currentMinute, 10) = 0 && currentMinute != lastCraftingMinute) {
        lastCraftingSeedMinute := currentMinute
        SetTimer, PushCraft, -8000
    }

Return

PushCraft:

    actionQueue.Push("Craft")

Return

Craft:

    currentSection := "Craft"
    if (selectedCraftingItem != "None") {
        Gosub, CraftPath
    }

Return



AutoBuyMerchant:

    ; queues if its not the first cycle and the time is a multiple of 30
    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastMerchantMinute) {
        lastMerchantMinute := currentMinute
        SetTimer, PushBuyMerchant, -8000
    }

Return

PushBuyMerchant: 

    actionQueue.Push("BuyMerchant")

Return

BuyMerchant:

    currentSection := "BuyMerchant"
    if (selectedSprayMerchantItems.Length() or selectedSkyItems.Length() or selectedHoneyMerchantItems.Length() or selectedSummerItems.Length())
        Gosub, MerchantPath

Return

/*
AutoBuyHoneyMerchant:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastHoneyMerchantMinute) {
        lastHoneyMerchantMinute := currentMinute
        SetTimer, PushBuyHoneyMerchant, -8000
    }

Return

PushBuyHoneyMerchant: 

    actionQueue.Push("BuyHoneyMerchant")

Return

BuyHoneyMerchant:

    currentSection := "BuyHoneyMerchant"
    if (selectedHoneyMerchantItems.Length())
        Gosub, HoneyMerchantPath

Return

AutoBuySummer:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastSummerMinute) {
        lastSummerMinute := currentMinute
        SetTimer, PushBuySummer, -8000
    }

Return

PushBuySummer: 

    actionQueue.Push("BuySummer")

Return

BuySummer:

    currentSection := "BuySummer"
    if (selectedSummerItems.Length())
        Gosub, SummerShopPath

Return
*/

FindInArray(array, find) {
    for k,v in array {
        if (v = find) {
            return true
        }
    }
    return false
}

AutoPlantsClicked:
    Gui, Submit, NoHide ; Submit the GUI (gets current state of controls)
    if (AutoCollectPlants) ; If the checkbox is checked
    {
        ; Create custom popup with two buttons (Left and Right)
        Gosub, SaveSettings
        Gui, Destroy
        Gui, Add, Text, , Which side of the map are you on? (Seeds / Sell)
        Gui, Add, Button, gLeftClicked, Seeds
        Gui, Add, Button, gRightClicked, Sell
        Gui, Show, , Scripter GAG Macro [COOKING]
    } else {
        Gosub, SaveSettings
    }
Return

CookingItemClicked:
    Gosub, SaveSettings
    options := ""

    ; Assume you have a numeric range to check CookingItem1 through CookingItemN
    Loop, % cookingItemOrder.Length() {
        idx := A_Index
        if (CookingItem%idx%) {
            selectedCookingItem := cookingItemOrder[idx]
            for each, rarity in cookingItemRarities[selectedCookingItem] {
                options .= rarity . "|"
            }
        }
    }

    GuiControl,, SelectedCookingRarity, |
    GuiControl,, SelectedCookingRarity, %options%
Return

RarityClicked:
    Gosub, SaveSettings
    ingredientsNeeded := []
    for each, ingredient in cookingItems[selectedCookingItem][selectedCookingRarity] {
        ingredientFound := FindInArray(ingredientsNeeded, ingredient)
        if (!ingredientFound) {
            ingredientsNeeded.Push(ingredient)
        }
    }
    if (AutoCollectPlants) {
        ingredientString := "Make sure to plant lots of "
        ingredientStringFinal := "in your garden!"
    } else {
        ingredientString := "Make sure you have lots of "
        ingredientStringFinal := "in your inventory!"
    }
    for each, ingredient in ingredientsNeeded {
        ingredientString .= ingredient . ", "
    }
    MsgBox, %ingredientString%%ingredientStringFinal%
Return

AutoCorruptClicked:
    Gui, Submit, NoHide ; Submit the GUI (gets current state of controls)
    if (AutoCollectCorrupt) ; If the checkbox is checked
    {
        ; Create custom popup with two buttons (Left and Right)
        Gosub, SaveSettings
        Gui, Destroy
        Gui, Add, Text, , Which side of the map are you on? (Seeds / Sell)
        Gui, Add, Button, gLeftClicked, Seeds
        Gui, Add, Button, gRightClicked, Sell
        Gui, Show, , Custom Popup
    } else {
        Gosub, SaveSettings
        Gosub, ShowGui
    }
Return

LeftClicked:
    global mapSide := "Seeds"
    IniWrite, % mapSide, %settingsFile%, Main, mapSide
    Gui, Destroy
    MsgBox, 0, Disclaimer, This will not always collect all your plants!! The macro will only be able to collect plants with the perimeter of the garden. If there are plants you don't want to be collected, please favorite them!
    Gosub, ShowGui
Return

RightClicked:
    global mapSide := "Sell"
    IniWrite, % mapSide, %settingsFile%, Main, mapSide
    Gui, Destroy
    MsgBox, 0, Disclaimer, This will not always collect all your plants!! The macro will only be able to collect plants with the perimeter of the garden. If there are plants you don't want to be collected, please favorite them!
    Gosub, ShowGui
Return

AutoBuyGear:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastGearMinute) {
        lastGearMinute := currentMinute
        SetTimer, PushBuyGear, -8000
    }

Return

PushBuyGear: 

    actionQueue.Push("BuyGear")

Return

BuyGear:

    currentSection := "BuyGear"
    if (selectedGearItems.Length())
        Gosub, GearShopPath

Return

AutomaticCollectPlants:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastCollectPlantsMinute) {
        lastCollectPlantsMinute := currentMinute
        SetTimer, PushCollectPlants, -8000
    }

Return

PushCollectPlants:

    actionQueue.Push("CollectPlants")

Return

CollectPlants:

    currentSection := "CollectPlants"
    if (AutoCollectPlants) {
        Gosub, CollectPlantsPath
    }

AutoBuyEggShop:

    ; queues if its not the first cycle and the time is a multiple of 30
    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastEggShopMinute) {
        lastEggShopMinute := currentMinute
        SetTimer, PushBuyEggShop, -8000
    }

Return

PushBuyEggShop: 

    actionQueue.Push("BuyEggShop")

Return

BuyEggShop:

    currentSection := "BuyEggShop"
    if (selectedEggItems.Length()) {
        Gosub, EggShopPath
    } 

Return

AutoBuyCosmeticShop:

    ; queues if its not the first cycle, the minute is 0, and the current hour is an even number (every 2 hours)
    if (cycleCount > 0 && currentMinute = 0 && Mod(currentHour, 2) = 0 && currentHour != lastCosmeticShopHour) {
        lastCosmeticShopHour := currentHour
        SetTimer, PushBuyCosmeticShop, -8000
    }

Return

PushBuyCosmeticShop: 

    actionQueue.Push("BuyCosmeticShop")

Return

BuyCosmeticShop:

    currentSection := "BuyCosmeticShop"
    if (BuyAllCosmetics) {
        Gosub, CosmeticShopPath
    } 

Return

AutoBuyHoneyShop:

    ; queues if its not the first cycle and the time is a multiple of 30
    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastHoneyShopMinute) {
        lastHoneyShopMinute := currentMinute
        SetTimer, PushBuyHoneyShop, -8000
    }

Return

PushBuyHoneyShop:

    actionQueue.Push("BuyHoneyShop")

Return

BuyHoneyShop:

    currentSection := "BuyHoneyShop"
    if (selectedHoneyItems.Length()) {
        
    }

Return

AutoBuyZen:

    ; queues if its not the first cycle and the time is a multiple of 30
    if (cycleCount > 0 && Mod(currentMinute, 30) = 0 && currentMinute != lastZenHour) {
        lastZenHour := currentMinute
        SetTimer, PushBuyZen, -8000
    }

Return

PushBuyZen:

    actionQueue.Push("BuyZen")

Return

BuyZen:

    currentSection := "BuyZen"
    if (selectedZenItems.Length()) {
        Gosub, ZenPath
    }

Return

AutomaticDepositTranquil:

    ; queues if its not the first cycle and the time is a multiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastDepositTranquilMinute) {
        lastDepositTranquilMinute := currentMinute
        SetTimer, PushDepositTranquil, -8000
    }

Return

PushDepositTranquil:

    actionQueue.Push("DepositTranquil")

Return

PushDepositCorrupt:

    actionQueue.Push("DepositCorrupt")

Return

DepositTranquil:

    currentSection := "DepositTranquil"
    if (AutoDepositTranquil != "None") {
        Gosub, DepositTranquilPath
    }

Return

DepositCorrupt:

    currentSection := "DepositCorrupt"
    if (AutoDepositCorrupt != "None") {
        Gosub, DepositCorruptPath
    }

AutomaticDepositCorrupt:

    ; queues if its not the first cycle and the time is amultiple of 5
    if (cycleCount > 0 && Mod(currentMinute, 5) = 0 && currentMinute != lastDepositCorruptMinute) {
        lastDepositCorruptMinute := currentMinute
        SetTimer, PushDepositCorrupt, -8000
    }

; helper labels

SetToolTip:

    if (cycleFinished) {
        mod5 := Mod(currentMinute, 5)
        rem5min := (mod5 = 0) ? 5 : 5 - mod5
        rem5sec := rem5min * 60 - currentSecond
        if (rem5sec < 0)
            rem5sec := 0
        seedMin := rem5sec // 60
        seedSec := Mod(rem5sec, 60)
        seedText := (seedSec < 10) ? seedMin . ":0" . seedSec : seedMin . ":" . seedSec
        gearMin := rem5sec // 60
        gearSec := Mod(rem5sec, 60)
        gearText := (gearSec < 10) ? gearMin . ":0" . gearSec : gearMin . ":" . gearSec
        depositTranquilMin := rem5sec // 60
        depositTranquilSec := Mod(rem5sec, 60)
        depositTranquilText := (depositTranquilSec < 10) ? depositTranquilMin . ":0" . depositTranquilSec : depositTranquilMin . ":" . depositTranquilSec
        depositCorruptMin := rem5sec // 60
        depositCorruptSec := Mod(rem5sec, 60)
        depositCorruptText := (depositCorruptSec < 10) ? depositCorruptMin . ":0" . depositCorruptSec : depositCorruptMin . ":" . depositCorruptSec
        collectPlantsMin := rem5sec // 60
        collectPlantsSec := Mod(rem5sec, 60)
        collectPlantsText := (collectPlantsSec < 10) ? collectPlantsMin . ":0" . collectPlantsSec : collectPlantsMin . ":" . collectPlantsSec

        craftingSeedMin := rem5sec // 60
        craftingSeedSec := Mod(rem5sec, 60)
        craftingSeedText := (craftingSeedSec < 10) ? craftingSeedMin . ":0" . craftingSeedSec : craftingSeedMin . ":" . craftingSeedSec
        craftingText := craftingSeedText

        cookingMin := rem5sec // 60
        cookingSec := Mod(rem5sec, 60)
        cookingText := (cookingSec < 10) ? cookingMin . ":0" . cookingSec : cookingMin . ":" . cookingSec

        mod30 := Mod(currentMinute, 30)
        rem30min := (mod30 = 0) ? 30 : 30 - mod30
        rem30sec := rem30min * 60 - currentSecond
        if (rem30sec < 0)
            rem30sec := 0
        eggMin := rem30sec // 60
        eggSec := Mod(rem30sec, 60)
        eggText := (eggSec < 10) ? eggMin . ":0" . eggSec : eggMin . ":" . eggSec
        zenMin := rem30sec // 60
        zenSec := Mod(rem30sec, 60)
        zenText := (zenSec < 10) ? zenMin . ":0" . zenSec : zenMin . ":" . zenSec

        skyMin := rem30sec // 60
        skySec := Mod(rem30sec, 60)
        merchantText := (skySec < 10) ? skyMin . ":0" . skySec : skyMin . ":" . skySec

        honeyMerchantMin := rem30sec // 60
        honeyMerchantSec := Mod(rem30sec, 60)
        honeyMerchantText := (honeyMerchantSec < 10) ? honeyMerchantMin . ":0" . honeyMerchantSec : honeyMerchantMin . ":" . honeyMerchantSec

        summerMin := rem30sec // 60
        summerSec := Mod(rem30sec, 60)
        summerText := (summerSec < 10) ? summerMin . ":0" . summerSec : summerMin . ":" . summerSec

        totalSecNow := currentHour * 3600 + currentMinute * 60 + currentSecond
        nextCosHour := (Floor(currentHour/2) + 1) * 2
        nextCosTotal := nextCosHour * 3600
        remCossec := nextCosTotal - totalSecNow
        if (remCossec < 0)
            remCossec := 0
        cosH := remCossec // 3600
        cosM := (remCossec - cosH*3600) // 60
        cosS := Mod(remCossec, 60)
        if (cosH > 0)
            cosText := cosH . ":" . (cosM < 10 ? "0" . cosM : cosM) . ":" . (cosS < 10 ? "0" . cosS : cosS)
        else
            cosText := cosM . ":" . (cosS < 10 ? "0" . cosS : cosS)

        if (currentMinute = 0 && currentSecond = 0) {
            remHoneySec := 0
        } else {
            remHoneySec := 3600 - (currentMinute * 60 + currentSecond)
        }

        tooltipText := ""
        if (selectedSeedItems.Length()) {
            tooltipText .= "Seed Shop: " . seedText . "`n"
        }
        if (selectedGearItems.Length()) {
            tooltipText .= "Gear Shop: " . gearText . "`n"
        }
        if (selectedEggItems.Length()) {
            tooltipText .= "Egg Shop : " . eggText . "`n"
        }
        if (BuyAllCosmetics) {
            tooltipText .= "Cosmetic Shop: " . cosText . "`n"
        }
        if (selectedHoneyItems.Length()) {
            tooltipText .= "Honey Shop: " . honeyText . "`n"
        }
        if (AutoCollectPlants) {
            tooltipText .= "Collect Plants: " . collectPlantsText . "`n"
        }
        if (selectedSprayItems.Length() or selectedSkyItems.Length() or selectedHoneyMerchantItems.Length() or selectedSummerItems.Length()) {
            tooltipText .= "Merchant: " . merchantText . "`n"

        }
        if (selectedZenItems.Length()) {
            tooltipText .= "Zen Shop: " . zenText . "`n"
        }
        if (selectedCraftingSeedItem != "None" or selectedCraftingItem != "None") {
            tooltipText .= "Crafting: " . craftingSeedText . "`n"
        }
        if (selectedCookingItem != "None") {
            tooltipText .= "Cooking: " . cookingText . "`n"
        }

        if (tooltipText != "") {
            CoordMode, Mouse, Screen
            MouseGetPos, mX, mY
            offsetX := 10
            offsetY := 10
            ToolTip, % tooltipText, % (mX + offsetX), % (mY + offsetY)
        } else {
            ToolTip  ; clears any existing tooltip
        }
    }
    

Return

SetTimers:

    SetTimer, UpdateTime, 1000

    if (selectedSeedItems.Length()) {
        actionQueue.Push("BuySeed")
    }
    seedAutoActive := 1
    SetTimer, AutoBuySeed, 1000 ; checks every second if it should queue

    if (selectedGearItems.Length()) {
        actionQueue.Push("BuyGear")
    }
    gearAutoActive := 1
    SetTimer, AutoBuyGear, 1000 ; checks every second if it should queue

    if (selectedEggItems.Length()) {
        actionQueue.Push("BuyEggShop")
    }
    eggAutoActive := 1
    SetTimer, AutoBuyEggShop, 1000 ; checks every second if it should queue

    if (BuyAllCosmetics) {
        actionQueue.Push("BuyCosmeticShop")
    }
    cosmeticAutoActive := 1
    SetTimer, AutoBuyCosmeticShop, 1000 ; checks every second if it should queue

    if (selectedHoneyItems.Length()) {
        actionQueue.Push("BuyHoneyShop")
    }
    honeyShopAutoActive := 1
    SetTimer, AutoBuyHoneyShop, 1000 ; checks every second if it should queue

    if (selectedCraftingSeedItem != "None") {
        actionQueue.Push("CraftSeed")
    }
    craftingSeedAutoActive := 1
    SetTimer, AutoCraftSeed, 1000

    if (selectedCraftingItem != "None") {
        actionQueue.Push("Craft")
    }
    craftingAutoActive := 1
    SetTimer, AutoCraft, 1000

    if (cookingItem != "None") {
        actionQueue.Push("Cooking")
    }
    cookingAutoActive := 1
    SetTimer, AutoCooking, 1000

    if (AutoCollectPlants) {
        actionQueue.Push("CollectPlants")
    }
    collectPlantsAutoActive := 1
    SetTimer, AutomaticCollectPlants, 1000

    

    if (selectedSprayItems.Length() or selectedSkyItems.Length() or selectedHoneyMerchantItems.Length() or selectedSummerItems.Length()) {
        actionQueue.Push("BuyMerchant")
    }
    merchantAutoActive := 1
    SetTimer, AutoBuyMerchant, 1000 ; checks every second if it should queue

    if (selectedZenItems.Length()) {
        actionQueue.Push("BuyZen")
    }
    zenAutoActive := 1
    SetTimer, AutoBuyZen, 1000

Return

/*
VerifyUser(username) {
    global GAME_PASS_ID
    username := Trim(username)

    reqBody := "{""usernames"":[""" username """],""excludeBannedUsers"":true}"
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST","https://users.roblox.com/v1/usernames/users",false)
    whr.SetRequestHeader("Content-Type","application/json")
    whr.Send(reqBody),  whr.WaitForResponse()
    if (whr.Status!=200 || !RegExMatch(whr.ResponseText,"""id"":\s*(\d+)",m))
        return 1
    userId := m1

    ownURL := "https://inventory.roblox.com/v1/users/" userId
           .  "/items/GamePass/" GAME_PASS_ID
    whr2 := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr2.Open("GET",ownURL,false), whr2.Send(), whr2.WaitForResponse()
    if (whr2.Status!=200)                        ; request itself failed
        return 1

    return !RegExMatch(whr2.ResponseText, """data"":\s*\[\s*\]")
}


IniRead, isVerified, %settingsFile%, Main, %VERIFIED_KEY%, 0
if (!isVerified) {
    InputBox, rbUser, Premium Access, Please enter your Roblox username:
    if (ErrorLevel)
        ExitApp   ; user cancelled

    if (VerifyUser(rbUser)) {
        IniWrite, 1,              %settingsFile%, Main, %VERIFIED_KEY%
        IniWrite, %rbUser%,       %settingsFile%, Main, VerifiedUsername
        MsgBox, 0, Success, Verification successful, enjoy the macro!
    } else {
        MsgBox, 16, Access Denied, Sorry, that account does not own the required game-pass.
        ExitApp
    }
}
*/


UpdateTime:

    FormatTime, currentHour,, hh
    FormatTime, currentMinute,, mm
    FormatTime, currentSecond,, ss

    currentHour := currentHour + 0
    currentMinute := currentMinute + 0
    currentSecond := currentSecond + 0

Return

AutoReconnect:

    global actionQueue

     

    if (simpleDetect(0x302927, 0, 0.3988, 0.3548, 0.6047, 0.6674) && simpleDetect(0xFFFFFF, 0, 0.3988, 0.3548, 0.6047, 0.6674)) {
        closeRobuxPrompt()
        Sleep, 500
        if (simpleDetect(0x302927, 0, 0.3988, 0.3548, 0.6047, 0.6674) && simpleDetect(0xFFFFFF, 0, 0.3988, 0.3548, 0.6047, 0.6674)) {
            started := 0
            actionQueue := []
            SetTimer, AutoReconnect, Off
            Sleep, 500
            WinClose, % "ahk_id" . firstWindow
            Sleep, 1000
            WinClose, % "ahk_id" . firstWindow
            Sleep, 500
            SafeClickRelative(0.5165, 0.5823)
            ToolTip, Attempting To Reconnect
            SetTimer, HideTooltip, -5000
            SendDiscordMessage(webhookURL, "Lost connection or macro errored, attempting to reconnect..." . (PingSelected ? " <@" . discordUserID . ">" : ""))
            sleepAmount(15000, 30000)
            SetTimer, CheckLoadingScreen, 5000
        }    
    }

Return

CheckLoadingScreen:

    ToolTip, Detecting Rejoin

    getWindowIDS()

    WinActivate, % "ahk_id" . firstWindow

    if (simpleDetect(0x000000, 0, 0.75, 0.75, 0.9, 0.9)) {
        SafeClickRelative(midX, midY)
    }
    else {
        ToolTip, Rejoined Successfully
        sleepAmount(5000, 10000)
        SendDiscordMessage(webhookURL, "Successfully reconnected to server." . (PingSelected ? " <@" . discordUserID . ">" : ""))
        Sleep, 200
        Gosub, StartScanMultiInstance
    }

Return

; set up labels

alignment:

    ToolTip, Beginning Alignment
    SetTimer, HideTooltip, -5000

    SafeClickRelative(0.5, 0.5)
    Sleep, 100

    Sleep, 200

    if (AutoAlign) {
        GoSub, cameraChange
        Sleep, 100
        Gosub, zoomAlignment
        Sleep, 100
        GoSub, cameraAlignment
        Sleep, 100
        Gosub, characterAlignment
        Sleep, 100
        Gosub, cameraChange
        Sleep, 100
        }
    else {
        Gosub, zoomAlignment
        Sleep, 100
    }

    Sleep, 1000
    SafeClickRelative(0.5, 0.127)
    Sleep, 100

    ToolTip, Alignment Complete
    SetTimer, HideTooltip, -1000

Return

cameraChange:

    ; changes camera mode to follow and can be called again to reverse it (0123, 0->3, 3->0)
    Send, {Escape}
    Sleep, 500
    Send, {Tab}
    Sleep, 400
    Send {Down}
    Sleep, 100
    repeatKey("Right", 2, (SavedSpeed = "Ultra") ? 55 : (SavedSpeed = "Max") ? 60 : 30)
    Sleep, 100
    Send {Escape}

Return

cameraAlignment:

    ; puts character in overhead view
    Click, Right, Down
    Sleep, 200
    SafeMoveRelative(0.5, 0.5)
    Sleep, 200
    MouseMove, 0, 800, R
    Sleep, 200
    Click, Right, Up

Return

zoomAlignment:

    ; sets correct player zoom
    SafeMoveRelative(0.5, 0.5)
    Sleep, 100

    Loop, 40 {
        Send, {WheelUp}
        Sleep, 20
    }

    Sleep, 200

    Loop, 6 {
        Send, {WheelDown}
        Sleep, 20
    }

    midX := getMouseCoord("x")
    midY := getMouseCoord("y")

Return

characterAlignment:

    ; aligns character through spam tping and using the follow camera mode

    

    
    Loop, % ((SavedSpeed = "Ultra") ? 12 : (SavedSpeed = "Max") ? 18 : 8) {
    SafeClickRelative(0.35, 0.127)
    Sleep, 125
    SafeClickRelative(0.65, 0.127)
    Sleep, 125
    }
    Sleep, 10
    

Return

closeRobuxShopOdds:

    ; checks to see if the robux shop is open

    if simpleDetect(1313A4, 10, 0.58161, 0.23011, 0.60278, 0.27367) {
        SafeClickRelative(0.58987, 0.24431)
        Sleep, 500
        SafeClickRelative(0.0475, 0.5)
        Sleep, 500
    }
    SafeClickRelative(0.73657, 0.35321)
    Sleep, 500
    SafeClickRelative(0.67252, 0.24905)
    Sleep, 500
    SafeClickRelative(0.71074, 0.76893)
    Sleep, 500
    SafeClickRelative(0.60588, 0.28977)
    Sleep, 250
    SafeClickRelative(0.96797, 0.29356)
    Sleep, 250

Return

; buying paths

EggShopPath:

    Sleep, 100
    SafeClickRelative(0.5, 0.127)
    Sleep, 100
    hotbarController(1, 0, "2")
    sleepAmount(100, 1000)
    SafeClickRelative(midX, midY)
    SendDiscordMessage(webhookURL, "**[Egg Cycle]**")
    Sleep, 800

    Send, {w Down}
    Sleep, 500
    Send, {w Up}

    Send, e
    Sleep, sleepAmount(1500, 5000)

    SafeClickRelative(0.75, 0.36174)
    sleepAmount(2500, 5000)
    ;checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x2E92FC, 10, 0.54, 0.2, 0.65, 0.325)) {
            ToolTip, Egg Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Egg Shop Opened.")
            Sleep, 200
            if (NavigationMode == "Settings") {
                uiUniversal("33311443333114405550555", 0)
            } else if (NavigationMode == "Hotbar") {
                uiUniversal("3333333333333333333333333333333333333333333231114", 0)
            }
            Sleep, 100
            buyUniversal("egg")
            SendDiscordMessage(webhookURL, "Egg Shop Closed")
            eggsCompleted = 1
        }
        if (eggsCompleted) {
            break
        }
        Sleep, 2000
    }

    Send, {\}
    SafeClickRelative(0.66838, 0.25284)
    Sleep, 500

    closeRobuxPrompt()
    Gosub, closeRobuxShopOdds
    sleepAmount(1250, 2500)
    SendDiscordMessage(webhookURL, "**[Eggs Completed]**")

Return

SeedShopPath:

    Gosub, alignment

    seedsCompleted := 0

    SafeClickRelative(0.35, 0.127)
    Sleep, 100
    SafeClickRelative(0.5, 0.5)
    Sleep, 100
    Click, right, down
    Sleep, 100
    SafeMoveRelative(0.75, 0.5)
    Sleep, 100
    Click, right, up
    sleepAmount(100, 1000)
    Send, {e}
    SendDiscordMessage(webhookURL, "**[Seed Cycle]**")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Seed Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Seed Shop Opened.")
            Sleep, 200
            if (NavigationMode == "Settings") {
                uiUniversal("33311443333114405550555", 0)
            } else if (NavigationMode == "Hotbar") {
                uiUniversal("33333333333333333333333333333333333333333333333333222221114", 0, 0)
            }
            Sleep, 100
            buyUniversal("seed")
            SendDiscordMessage(webhookURL, "Seed Shop Closed.")
            seedsCompleted = 1
        }
        if (seedsCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("seed", seedsCompleted)
    closeRobuxPrompt()
    Gosub, closeRobuxShopOdds

    Sleep, 200
    Gosub, alignment
    Sleep, 200

    SendDiscordMessage(webhookURL, "**[Seeds Completed]**")

Return

CraftSeedPath:

    seedCraftCompleted := 0

    Tooltip, Crafting %selectedCraftingSeedItem%
    SetTimer, HideTooltip, -1500

    hotbarController(1, 0, "2")
    sleepamount(100, 1000)
    SafeClickRelative(0.5, 0.5)
    sleepamount(100, 1000)

    Send, {s down}
    sleep, 850
    Send, {s up}
    sleepAmount(100, 1000)

    SendDiscordMessage(webhookURL, "**[Seed Crafting Cycle]**")

    Send, {c}
    sleep, 250
    repeatKey("e", 2)
    sleepAmount(100, 1000)
    closeRobuxPrompt()
    sleepAmount(100, 1000)

    if (simpleDetect(0xA2014D, 10, 0.54, 0.2, 0.65, 0.325)) {
        Tooltip, Seed Crafting Opened
        SetTimer, HideTooltip, -1500
        SendDiscordMessage(webhookURL, "Seed Crafting Opened")
        Sleep, 200
        if (NavigationMode = "Settings") {
            uiUniversal("33311443333114405550555", 0)
        } else if (NavigationMode = "Hotbar") {
            uiUniversal("3333333333333333333333333333333333322222111405550553", 0)
            sleep, 300
            Tooltip, %selectedCraftingSeedIndex%
            repeatKey("down", selectedCraftingSeedIndex)
            sleep, 300
            Send, {Enter}
            sleep, 100
            Send, {down}
            sleep, 100
            Send, {Enter}
            sleepAmount(100, 1000)
            Send, {%SavedKeybind%}
            sleep, 500
            
        }
        Tooltip, Adding Ingredients
        SetTimer, HideTooltip, -1500
        ingredients := craftingSeedItems[selectedCraftingSeedItem]["ingredients"]
        for index, ingredient in ingredients {
            searchItem(ingredient, 1)
            Sleep, 200
        }
        Send, E
        sleepAmount(100, 1000)
    }

    closeRobuxPrompt()
    Gosub, closeRobuxShopOdds
    SafeClickRelative(0.5, 0.127)

Return

CraftPath:
    CraftCompleted := 0

    Tooltip, Crafting %selectedCraftingItem%
    SetTimer, HideTooltip, -1500

    hotbarController(1, 0, "2")
    sleepamount(100, 1000)
    SafeClickRelative(0.5, 0.5)
    sleepamount(100, 1000)

    Send, {s down}
    sleep, 1250
    Send, {s up}
    sleepAmount(100, 1000)

    SendDiscordMessage(webhookURL, "**[Crafting Cycle]**")

    Send, {c}
    sleep, 250
    repeatKey("e", 2)
    sleepAmount(100, 1000)
    closeRobuxPrompt()
    sleepAmount(100, 1000)

    if (simpleDetect(0xA2014D, 10, 0.54, 0.2, 0.65, 0.325)) {
        Tooltip, Crafting Opened
        SetTimer, HideTooltip, -1500
        SendDiscordMessage(webhookURL, "Crafting Opened")
        Sleep, 200
        if (NavigationMode = "Settings") {
            uiUniversal("33311443333114405550555", 0)
        } else if (NavigationMode = "Hotbar") {
            uiUniversal("3333333333333333333333333333333333322222111405550553", 0)
            sleep, 300
            Tooltip, %selectedCraftingIndex%
            repeatKey("down", selectedCraftingIndex)
            sleep, 300
            Send, {Enter}
            sleep, 100
            Send, {down}
            sleep, 100
            Send, {Enter}
            sleepAmount(100, 1000)
            Send, {%SavedKeybind%}
            sleep, 500
            
        }
        Tooltip, Adding Ingredients
        SetTimer, HideTooltip, -1500
        ingredients := craftingItems[selectedCraftingItem]["ingredients"]
        for index, ingredient in ingredients {
            searchItem(ingredient, 1)
            Sleep, 200
        }
        Send, E
        sleepAmount(100, 1000)
    }

    closeRobuxPrompt()
    Gosub, closeRobuxShopOdds
    SafeClickRelative(0.5, 0.127)
Return

CookingPath:
    ToolTip, Cooking %selectedCookingRarity% %selectedCookingItem%
    SetTimer, HideTooltip, -1500
    
    cookingCompleted := 0

    Gosub, cameraChange
    Loop, % ((SavedSpeed = "Ultra") ? 12 : (SavedSpeed = "Max") ? 18 : 8) {
        SafeClickRelative(0.35, 0.127)
        Sleep, 125
        SafeClickRelative(0.65, 0.127)
        Sleep, 125
    }
    SafeClickRelative(0.35, 0.127)
    Sleep, 500
    Gosub, cameraChange
    Sleep, 500

    SafeClickRelative(0.66, 0.127)
    sleepAmount(100, 1000)
    SafeClickRelative(0.5, 0.5)
    sleepAmount(100, 500)
    Send, {s down}
    sleep, 500
    Send, {s up}
    sleep, 500
    Send, {a down}
    Sleep, 9650
    Send, {a up}
    sleep, 500
    Send, {w down}
    sleep, 1050
    Send, {w up}

    repeatKey("e", 2)
    sleepAmount(100,1000)

    ingredients := cookingItems[selectedCookingItem][selectedCookingRarity]
    for index, ingredient in ingredients {
        searchItem(ingredient, 2, "fruit")
        sleep, 200
        sleepAmount(100,1000)
    }
    closeRobuxPrompt()
    SafeClickRelative(0.595041322314, 0.392992424242)
    sleep, 500
    SafeClickRelative(0.387396694, 0.366477272727)
    sleep, 500
    SafeClickRelative(0.521694214876, 0.27272727272727)

    SafeClickRelative(0.5, 0.127)

    Gosub, alignment


Return


MerchantPath:

    merchantCompleted := 0

    SafeClickRelative(0.35, 0.127)
    sleepAmount(100, 1000)
    Send, {s Down}
    Sleep, 1500
    Send, {s Up}
    Sleep, 250
    Send, {e}
    SendDiscordMessage(webhookURL, "**[Merchant Cycle]**")
    sleepAmount(2000, 2500)
    SafeClickRelative(0.733, 0.45)
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
  Loop, 5 {
        if (simpleDetect(0xFFFB48, 10, 0.35, 0.43, 0.37, 0.45)) {
            ToolTip, Merchant Opened
            repeatKey("\", 2, 50) ; scroll up before detecting so it sees the first item
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Merchant Opened.")
            Sleep, 200
            if (simpleDetect(0x, 10, 0.357, 0.285, 0.359, 0.287)) {
                ToolTip, Spray Merchant Detected
                SetTimer, HideTooltip, -1500
                SendDiscordMessage(webhookURL, "Spray Merchant Detected.")
                Sleep, 200
                uiUniversal("3331144333311405550555", 0)
                Sleep, 100
                buyUniversal("spray")
                SendDiscordMessage(webhookURL, "Merchant Closed.")
                merchantCompleted = 1
            } else if (simpleDetect(0x896253, 10, 0.372, 0.436, 0.374, 0.438)) {
                ToolTip, Sky Merchant Detected
                SetTimer, HideTooltip, -1500
                SendDiscordMessage(webhookURL, "Sky Merchant Detected.")
                Sleep, 200
                if (NavigationMode == "Settings") {
                    uiUniversal("33311443333114405550555", 0)
                } else if (NavigationMode == "Hotbar") {
                    repeatKey("up", 50)
                    uiUniversal("332233311443333114405550555", 0)
                }
                Sleep, 100
                buyUniversal("sky")
                SendDiscordMessage(webhookURL, "Merchant Closed.")
                merchantCompleted = 1
            } else if (simpleDetect(0xD5A208, 10, 0.376, 0.396, 0.378, 0.398)) {
                ToolTip, Honey Merchant Opened
                SetTimer, HideTooltip, -1500
                SendDiscordMessage(webhookURL, "Honey Shop Opened.")
                Sleep, 200
                if (NavigationMode == "Settings") {
                    uiUniversal("33311443333114405550555", 0)
                } else if (NavigationMode == "Hotbar") {
                    repeatKey("up", 50)
                    uiUniversal("332233311443333114405550555", 0)
                }
                Sleep, 100
                buyUniversal("honeyMerchant")
                SendDiscordMessage(webhookURL, "Honey Merchant Closed.")
                merchantCompleted = 1
            } else if (simpleDetect(0xBCCFD3, 10, 0.37, 0.422, 0.372, 0.424)) {
                ToolTip, Summer Shop Opened
                SetTimer, HideTooltip, -1500
                SendDiscordMessage(webhookURL, "Summer Shop Opened.")
                Sleep, 200
                if (NavigationMode == "Settings") {
                    uiUniversal("33311443333114405550555", 0)
                } else if (NavigationMode == "Hotbar") {
                    repeatKey("up", 50)
                    uiUniversal("332233311443333114405550555", 0)
                }
                Sleep, 100
                buyUniversal("summer")
                SendDiscordMessage(webhookURL, "Summer Shop Closed.")
                merchantCompleted = 1
            }
            if (merchantCompleted) {
                break
            }
            Sleep, 1000

        } else {
            ToolTip, No Merchant Detected
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "No Merchant Detected.")
            Sleep, 200
            merchantCompleted = 1
        }
    }

    SafeClickRelative(0.66838, 0.25284)
    closeRobuxPrompt()
    Gosub, closeRobuxShopOdds

    Sleep, 400
    SendDiscordMessage(webhookURL, "**[Merchant Completed]**")

Return

/*
SkyShopPath:

    skyCompleted := 0

    uiUniversal("1111020")
    sleepAmount(100, 1000)
    Send, {s Down}
    Sleep, 1500
    Send, {s Up}
    Sleep, 100
    Send, {e}
    Sleep, 500
    SafeClickRelative(0.733, 0.45)
    SendDiscordMessage(webhookURL, "**[Sky Cycle]**")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00003A, 10, 0.357, 0.285, 0.359, 0.287)) {
            ToolTip, Sky Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Sky Shop Opened.")
            Sleep, 200
            ; right = 1, left = 2, up = 3, down = 4, enter = 0, manual delay = 5
            uiUniversal("3331144333311405550555", 0)
            Sleep, 100
            buyUniversal("sky")
            SendDiscordMessage(webhookURL, "Sky Shop Closed.")
            skyCompleted = 1
        }
        if (skyCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("sky", skyCompleted)


    SendDiscordMessage(webhookURL, "**[Sky Completed]**")

Return


HoneyMerchantPath:

    honeyMerchantCompleted := 0

    uiUniversal("1111020")
    sleepAmount(100, 1000)
    Send, {s Down}
    Sleep, 1500
    Send, {s Up}
    Sleep, 100
    Send, {e}
    Sleep, 500
    SafeClickRelative(0.733, 0.45)
    SendDiscordMessage(webhookURL, "**[Honey Merchant Cycle]**")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00003A, 10, 0.390, 0.282, 0.392, 0.284)) {
            ToolTip, Honey Merchant Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Honey Shop Opened.")
            Sleep, 200
            uiUniversal("33311443333114405550555", 0)
            Sleep, 100
            buyUniversal("honeyMerchant")
            SendDiscordMessage(webhookURL, "Honey Merchant Closed.")
            honeyMerchantCompleted = 1
        }
        if (honeyMerchantCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("honeyMerchant", honeyMerchantCompleted)


    SendDiscordMessage(webhookURL, "**[Honey Merchant Completed]**")

Return

SummerShopPath:

    summerCompleted := 0

    uiUniversal("1111020")
    sleepAmount(100, 1000)
    Send, {s Down}
    Sleep, 1500
    Send, {s Up}
    Sleep, 100
    Send, {e}
    SendDiscordMessage(webhookURL, "**[Summmer Cycle]**")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x2A2737, 10, 0.42407, 0.26041, 0.42407, 0.26041)) {
            ToolTip, Summer Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Summer Shop Opened.")
            Sleep, 200
            uiUniversal("33311443333114405550555", 0)
            Sleep, 100
            buyUniversal("summer")
            SendDiscordMessage(webhookURL, "Summer Shop Closed.")
            summerCompleted = 1
        }
        if (summerCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("summer", summerCompleted)


    SendDiscordMessage(webhookURL, "**[Summer Completed]**")

Return

*/

GearShopPath:

    gearsCompleted := 0

    hotbarController(0, 1, "0")
    SafeClickRelative(0.5, 0.127)
    sleepAmount(100, 500)
    hotbarController(1, 0, "2")
    sleepAmount(100, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(1200, 2500)
    Send, {e}
    sleepAmount(1500, 5000)
    dialogueClick("gear")
    SendDiscordMessage(webhookURL, "**[Gear Cycle]**")
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Gear Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Gear Shop Opened.")
            Sleep, 200
            if (NavigationMode == "Settings") {
                uiUniversal("33311443333114405550555", 0)
            } else if (NavigationMode == "Hotbar") {
                 uiUniversal("33333333333333333333333333333333333333333333333333333222221114", 0, 0)
            }
            Sleep, 100
            buyUniversal("gear")
            SendDiscordMessage(webhookURL, "Gear Shop Closed.")
            gearsCompleted = 1
        }
        if (gearsCompleted) {
            break
        }
        Sleep, 2000
    }

    closeShop("gear", gearsCompleted)
    closeRobuxPrompt()
    Gosub, closeRobuxShopOdds

    hotbarController(0, 1, "0")
    SendDiscordMessage(webhookURL, "**[Gears Completed]**")

Return

CosmeticShopPath:

    cosmeticsCompleted := 0

    hotbarController(0, 1, "0")
    SafeClickRelative(0.5, .127)
    sleepAmount(100, 500)
    hotbarController(1, 0, "2")
    sleepAmount(100, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(800, 1000)
    Send, {s Down}
    Sleep, 550
    Send, {s Up}
    sleepAmount(100, 1000)
    Send, {e}
    sleepAmount(2500, 5000)
    SendDiscordMessage(webhookURL, "**[Cosmetic Cycle]**")
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0x00CCFF, 10, 0.61, 0.182, 0.764, 0.259)) {
            ToolTip, Cosmetic Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Cosmetic Shop Opened.")
            Sleep, 200
            for index, item in cosmeticItems {
                label := StrReplace(item, " ", "")
                currentItem := cosmeticItems[A_Index]
                Gosub, %label%
                SendDiscordMessage(webhookURL, "Bought " . currentItem . (PingSelected ? " <@" . discordUserID . ">" : ""))
                Sleep, 100
            }
            SendDiscordMessage(webhookURL, "Cosmetic Shop Closed.")
            cosmeticsCompleted = 1
        }
        if (cosmeticsCompleted) {
            break
        }
        Sleep, 2000
    }

    if (cosmeticsCompleted) {
        Sleep, 500
        uiUniversal("111114150320")
    }
    else {
        SendDiscordMessage(webhookURL, "Failed To Detect Cosmetic Shop Opening [Error]" . (PingSelected ? " <@" . discordUserID . ">" : ""))
        ; failsafe
        uiUniversal("11114111350")
        Sleep, 50
        uiUniversal("11110")
    }

    hotbarController(0, 1, "0")
    Gosub, closeRobuxShopOdds
    SendDiscordMessage(webhookURL, "**[Cosmetics Completed]**")

Return

CollectPlantsPath:

    SendDiscordMessage(webhookURL, "**[Plant Collection Cycle]**")
    if (mapSide = "Sell") {
        Gosub, cameraChange
        Loop, % ((SavedSpeed = "Ultra") ? 12 : (SavedSpeed = "Max") ? 18 : 8) {
            SafeClickRelative(0.35, 0.127)
            Sleep, 125
            SafeClickRelative(0.65, 0.127)
            Sleep, 125
        }
        SafeClickRelative(0.35, 0.127)
        Sleep, 500
        Gosub, cameraChange
        Sleep, 500
        
    }

    SafeClickRelative(0.5, 0.127)
    sleepAmount(1000, 2000)
    Send, {o down}
    Sleep, 5000
    Send, {o up}
    sleepAmount(100, 1000)


    ; left side
    SendDiscordMessage(webhookURL, "**[Collecting Left Side...]**")
    Send, {s down}
    Sleep, 270
    Send, {s up}
    sleepAmount(200, 500)
    Send, {a down}
    Sleep, 900
    Send, {a up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Sleep, 500
    SafeClickRelative(0.64824, 0.21306)
    Sleep, 500
    Send, {a down}
    Sleep, 800
    Send, {a up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Sleep, 500
    SafeClickRelative(0.64824, 0.21306)
    Sleep, 500
    Send, {a down}
    Sleep, 600
    Send, {a up}
    sleepAmount(200, 500)

    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {s down}
    Sleep, 1200
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {s down}
    Sleep, 1300
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)

    Send, {d down}
    Sleep, 900
    Send, {d up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {d down}
    Sleep, 800
    Send, {d up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {d down}
    Sleep, 600
    Send, {d up}
    sleepAmount(200, 500)

    SafeClickRelative(0.5, 0.127)

    ; right side
    SendDiscordMessage(webhookURL, "**[Collecting Right Side...]**")
    Send, {s down}
    Sleep, 270
    Send, {s up}
    sleepAmount(200, 500)
    Send, {d down}
    Sleep, 800
    Send, {d up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {d down}
    Sleep, 800
    Send, {d up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {d down}
    Sleep, 600
    Send, {d up}
    sleepAmount(200, 500)

    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {s down}
    Sleep, 1200
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {s down}
    Sleep, 1300
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)

    Send, {a down}
    Sleep, 900
    Send, {a up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {a down}
    Sleep, 800
    Send, {a up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {a down}
    Sleep, 600
    Send, {a up}
    sleepAmount(200, 500)

    SafeClickRelative(0.5, 0.127)

    ; middle
    SendDiscordMessage(webhookURL, "**[Collecting Middle Area...]**")
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {s down}
    Sleep, 1200
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {s down}
    Sleep, 1300
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    Send, {e down}
    sleepAmount(8000, 10000)
    Send, {e up}

    hotbarController(0, 1, "0")
    SafeClickRelative(0.5, 0.127)

    SendDiscordMessage(webhookURL, "**[Plant Collection Completed]**")

    Sleep, 500
    Gosub, alignment

Return

CollectCorruptPath:

    SendDiscordMessage(webhookURL, "**[Corrupt Plant Collection Cycle]**")
    if (mapSide = "Sell") {
        Gosub, cameraChange
        Loop, % ((SavedSpeed = "Ultra") ? 12 : (SavedSpeed = "Max") ? 18 : 8) {
            SafeClickRelative(0.35, 0.127)
            Sleep, 125
            SafeClickRelative(0.65, 0.127)
            Sleep, 125
        }
        SafeClickRelative(0.35, 0.127)
        Sleep, 500
        Gosub, cameraChange
        Sleep, 500
        SafeClickRelative(0.5, 0.127)
        sleepAmount(1000, 2000)
    }

    SafeClickRelative(0.5, 0.127)
    sleepAmount(1000, 2000)

    hotbarController(1, 0, "4")

    ; left side
    SendDiscordMessage(webhookURL, "**[Collecting Left Side...]**")
    Send, {s down}
    Sleep, 270
    Send, {s up}
    sleepAmount(200, 500)
    Send, {a down}
    Sleep, 900
    Send, {a up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {a down}
    Sleep, 800
    Send, {a up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {a down}
    Sleep, 600
    Send, {a up}
    sleepAmount(200, 500)

    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1200
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1300
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)

    Send, {d down}
    Sleep, 900
    Send, {d up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {d down}
    Sleep, 800
    Send, {d up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {d down}
    Sleep, 600
    Send, {d up}
    sleepAmount(200, 500)

    SafeClickRelative(0.5, 0.127)

    ; right side
    SendDiscordMessage(webhookURL, "**[Collecting Right Side...]**")
    Send, {s down}
    Sleep, 270
    Send, {s up}
    sleepAmount(200, 500)
    Send, {d down}
    Sleep, 800
    Send, {d up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {d down}
    Sleep, 800
    Send, {d up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {d down}
    Sleep, 600
    Send, {d up}
    sleepAmount(200, 500)

    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1200
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1300
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)

    Send, {a down}
    Sleep, 900
    Send, {a up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {a down}
    Sleep, 800
    Send, {a up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {a down}
    Sleep, 600
    Send, {a up}
    sleepAmount(200, 500)

    SafeClickRelative(0.5, 0.127)

    ; middle
    SendDiscordMessage(webhookURL, "**[Collecting Middle Area...]**")
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1200
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1300
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)
    Send, {s down}
    Sleep, 1000
    Send, {s up}
    sleepAmount(200, 500)
    SafeClickRelative(midX, midY)
    sleepAmount(8000, 10000)

    hotbarController(0, 1, "0")
    SafeClickRelative(0.5, 0.127)

    SendDiscordMessage(webhookURL, "**[Corrupt Plant Collection Completed]**")

    Sleep, 500
    Gosub, alignment

Return

DepositTranquilPath:
    Tooltip, Depositing Tranquil to %AutoDepositTranquil%
    SetTimer, HideTooltip, -1500

    SendDiscordMessage(webhookURL, "**[Tranquil Deposit Cycle]**")    

    SafeClickRelative(0.65, 0.127)
    sleepAmount(1000, 2000)
    
    if (AutoDepositTranquil = "Tanuki") {
        Send, {s down}
        Sleep, 80
        Send, {s up}
        sleepAmount(100, 1000)
        Send, {d down}
        Sleep, 8050
        Send, {d up}
        sleepAmount(100, 1000)
        Send, {s down}
        Sleep, 1750
        Send, {s up}
        sleepAmount(100, 1000)
        Send, {d down}
        Sleep, 500
        Send, {d up}
        sleepAmount(500, 1500)
        Send, {e}
        sleepAmount(500, 2000)
        SafeClickRelative(0.8, 0.6)
        Sleep, 2000
    } else if (AutoDepositTranquil = "Tree") {
        Send, {s down}
        Sleep, 80
        Send, {s up}
        sleepAmount(100, 1000)
        Send, {d down}
        Sleep, 8050
        Send, {d up}
        sleepAmount(100, 1000)
        Send, {s down}
        Sleep, 800
        Send, {s up}
        sleepAmount(100, 1000)
        Send, {d down}
        Sleep, 400
        Send, {d up}
        sleepAmount(500, 1500)
        Send, {e}
        sleepAmount(500, 2000)
        SafeClickRelative(0.8, 0.568)
        Sleep, 5000

    } else if (AutoDepositTranquil = "Kitsune") {
        Send, {w down}
        Sleep, 500
        Send, {w up}
        sleepAmount(100, 1000)
        Send, {d down}
        Sleep, 9500
        Send, {d up}
        sleepAmount(100, 1000)
        Send, {s down}
        Sleep, 1400
        Send, {s up}
        sleepAmount(100, 1000)
        Loop, 5 {
            searchItem("tranquil")
            sleepAmount(100, 500)
            Send, {E}
            sleepamount(100, 1000)
            SafeClickRelative(0.7644, 0.492)
            sleepamount(100, 1000)
        }

    }

    SafeClickRelative(0.5, 0.127)
    Gosub, closeRobuxShopOdds
    SendDiscordMessage(webhookURL, "**[Tranquil Deposit Completed]**")

Return

ZenPath:

    zenCompleted := 0

    Tooltip, Traveling to Zen Shop
    SetTimer, HideTooltip, -1500

    SendDiscordMessage(webhookURL, "**[Zen Shop Cycle]**")
    SafeClickRelative(0.65, 0.127)
    sleepAmount(1000, 2000)
    Send, {s down}
    Sleep, 80
    Send, {s up}
    sleepAmount(100, 1000)
    Send, {d down}
    Sleep, 8050
    Send, {d up}
    sleepAmount(100, 1000)
    Send, {s down}
    Sleep, 1750
    Send, {s up}
    sleepAmount(100, 1000)
    Send, {d down}
    Sleep, 500
    Send, {d up}
    sleepAmount(500, 1500)
    Send, {e}
    sleepAmount(500, 2000)
    SafeClickRelative(0.8, .397)
    sleepAmount(2500, 5000)
    ; checks for the shop opening up to 5 times to ensure it doesn't fail
    Loop, 5 {
        if (simpleDetect(0xDDAEC1, 10, 0.54, 0.20, 0.65, 0.325)) {
            ToolTip, Zen Shop Opened
            SetTimer, HideTooltip, -1500
            SendDiscordMessage(webhookURL, "Zen Shop Opened.")
            Sleep, 200
            if (NavigationMode == "Settings") {
                uiUniversal("33331144433333114405550555", 0)
            } else if (NavigatonMode == "Hotbar") {
                uiUniversal("33333333333333333333333333333333333333333333333231114", 0, 0)
            }
            
            Sleep, 100
            buyUniversal("zen")
            SendDiscordMessage(webhookURL, "Zen Shop Closed.")
            zenCompleted = 1
        }
        if (zenCompleted) {
            break
        }
        Sleep, 2000
    }

    SafeClickRelative(0.66838, 0.25284)
    Gosub, closeRobuxShopOdds

    hotbarController(0, 1, "0")
    SendDiscordMessage(webhookURL, "**[Zen Shop Completed]**")

Return

DepositCorruptPath:

    Tooltip, Depositing Corrupt to %AutoDepositCorrupt%
    SetTimer, HideTooltip, -1500

    SendDiscordMessage(webhookURL, "**[Corrupt Deposit Cycle]**")    

    SafeClickRelative(0.65, 0.127)
    sleepAmount(1000, 2000)
    
   if (AutoDepositCorrupt = "Kitsune") {
    Send, {w down}
    Sleep, 500
    Send, {w up}
    sleepAmount(100, 1000)
    Send, {d down}
    Sleep, 9500
    Send, {d up}
    sleepAmount(100, 1000)
    Send, {s down}
    Sleep, 1400
    Send, {s up}
    sleepAmount(100, 1000)
    Loop, 5 {
        searchItem("corrupt")
        sleepAmount(100, 500)
        Send, {E}
        sleepamount(100, 1000)
        SafeClickRelative(0.7644, 0.492)
        sleepamount(100, 1000)
    }

    }

    SafeClickRelative(0.5, 0.127)
    Gosub, closeRobuxShopOdds
    SendDiscordMessage(webhookURL, "**[Corrupt Deposit Completed]**")

Return

; cosmetic labels

Cosmetic1:

    Sleep, 50
    Loop, 5 {
        uiUniversal("111114450")
        sleepAmount(50, 200)
    }

Return

Cosmetic2:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111442250")
        sleepAmount(50, 200)
    }

Return

Cosmetic3:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1111144222250")
        sleepAmount(50, 200)
    }

Return

Cosmetic4:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111442222450")
        sleepAmount(50, 200)
    }

Return

Cosmetic5:

    Sleep, 50
    Loop, 5 {
        uiUniversal("111114422224150")
        sleepAmount(50, 200)
    }

Return

Cosmetic6:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1111144222241150")
        sleepAmount(50, 200)
    }

Return

Cosmetic7:

    Sleep, 50
    Loop, 5 {
        uiUniversal("11111442222411150")
        sleepAmount(50, 200)
    }

Return

Cosmetic8:

    Sleep, 50
    Loop, 5 {
        uiUniversal("111114422224111150")
        sleepAmount(50, 200)
    }

Return

Cosmetic9:

    Sleep, 50
    Loop, 5 {
        uiUniversal("1111144222241111150")
        sleepAmount(50, 200)
    }

Return

; save settings and start/exit

SaveSettings:
    Gui, Submit, NoHide

    ; — Egg section —
    Loop, % eggItems.Length()
        IniWrite, % (EggItem%A_Index%    ? 1 : 0), %settingsFile%, Egg, Item%A_Index%
    IniWrite, % SelectAllEggs,         %settingsFile%, Egg, SelectAllEggs

    ; — Gear section —
    Loop, % gearItems.Length()
        IniWrite, % (GearItem%A_Index%   ? 1 : 0), %settingsFile%, Gear, Item%A_Index%
    IniWrite, % SelectAllGears,        %settingsFile%, Gear, SelectAllGears

    ; — Seed section —
    Loop, % seedItems.Length()
        IniWrite, % (SeedItem%A_Index%   ? 1 : 0), %settingsFile%, Seed, Item%A_Index%
    IniWrite, % SelectAllSeeds,        %settingsFile%, Seed, SelectAllSeeds

    ; — Sky section —
    Loop, % skyMerchantItems.Length()
        IniWrite, % (SkyMerchantItem%A_Index%   ? 1 : 0), %settingsFile%, SkyMerchant, Item%A_Index%
    IniWrite, % SelectAllSkyMerchantItems,        %settingsFile%, SkyMerchant, SelectAllSkyMerchantItems

    ; — Honey Merchant section —
    Loop, % honeyMerchantItems.Length()
        IniWrite, % (HoneyMerchantItem%A_Index%   ? 1 : 0), %settingsFile%, HoneyMerchant, Item%A_Index%
    IniWrite, % SelectAllHoneyMerchantItems,        %settingsFile%, HoneyMerchant, SelectAllHoneyMerchantItems

    ; - Spray Merchant section -
    Loop, % sprayMerchantItems.Length()
        IniWrite, % (SprayMerchantItem%A_Index%   ? 1 : 0), %settingsFile%, SprayMerchant, Item%A_Index%
    IniWrite, % SelectAllSprayMerchantItems,        %settingsFile%, SprayMerchant, SelectAllSprayMerchantItems

    ; — Summer section —
    Loop, % summerSeedMerchantItems.Length()
        IniWrite, % (SummerSeedItem%A_Index%   ? 1 : 0), %settingsFile%, SummerMerchant, Item%A_Index%
    IniWrite, % SelectAllSummerSeeds,        %settingsFile%, SummerMerchant, SelectAllSummerSeeds

    ; — Zen section —
    Loop, % zenItems.Length()
        IniWrite, % (ZenItem%A_Index%   ? 1 : 0), %settingsFile%, Zen, Item%A_Index%
    IniWrite, % SelectAllZen,        %settingsFile%, Zen, SelectAllZen

    ; - Crafting Section - 
    Loop, % craftingSeedOrder.Length()
        IniWrite, % (CraftingSeedItem%A_Index%  ? 1 : 0), %settingsFile%, SeedCrafting, Item%A_Index%
    IniWrite, % CraftingSeedNone,        %settingsFile%, SeedCrafting, CraftingSeedNone

    Loop, % craftingItemOrder.Length()
        IniWrite, % (CraftingItem%A_Index%  ? 1 : 0), %settingsFile%, ItemCrafting, Item%A_Index%
    IniWrite, % CraftingItemNone,        %settingsFile%, ItemCrafting, CraftingItemNone

    ; — Honey section —
    ; first the “place” items 1–10
    Loop, 10
        IniWrite, % (HoneyItem%A_Index%  ? 1 : 0), %settingsFile%, Honey, Item%A_Index%
    IniWrite, % SelectAllHoney,        %settingsFile%, Honey, SelectAllHoney
    IniWrite, % AutoDepositTranquil, %settingsFile%, Zen, AutoDepositTranquil
    ; then 11–14
    Loop, % realHoneyItems.Length()
        if (A_Index > 10 && A_Index <= 14)
            IniWrite, % (HoneyItem%A_Index% ? 1 : 0), %settingsFile%, Honey, Item%A_Index%
    IniWrite, % AutoCollectTranquil, %settingsFile%, Zen, AutoCollectTranquil
    IniWrite, % AutoCollectCorrupt, %settingsFile%, Zen, AutoCollectCorrupt

    ; — Main section —
    IniWrite, %AutoAlign%,      %settingsFile%, Main, AutoAlign
    IniWrite, % PingSelected,          %settingsFile%, Main, PingSelected
    IniWrite, % MultiInstanceMode,     %settingsFile%, Main, MultiInstanceMode
    IniWrite, % SavedSpeed,            %settingsFile%, Main, MacroSpeed
    IniWrite, % privateServerLink,     %settingsFile%, Main, PrivateServerLink
    IniWrite, % discordUserID,         %settingsFile%, Main, DiscordUserID
    IniWrite, % SavedKeybind,          %settingsFile%, Main, UINavigationKeybind
    IniWrite, % webhookURL,            %settingsFile%, Main, UserWebhook

    ; — Cosmetic section —
    IniWrite, % BuyAllCosmetics,       %settingsFile%, Cosmetic, BuyAllCosmetics

    ; - Cooking section -
    IniWrite, % AutoCollectPlants,      %settingsFile%, Cooking, AutoCollectPlants
    IniWrite, % CookingItemNone,       %settingsFile%, Cooking, CookingItemNone
    Loop, % cookingItemOrder.Length()
        IniWrite, % (CookingItem%A_Index%  ? 1 : 0), %settingsFile%, Cooking, Item%A_Index%
    IniWrite, % CookingItemRarity,      %settingsFile%, Cooking, CookingItemRarity

Return

StopMacro(terminate := 1) {

    Gui, Submit, NoHide
    Sleep, 50
    started := 0
    Gosub, SaveSettings
    Gui, Destroy
    if (terminate)
        ExitApp

}

PauseMacro(terminate := 1) {

    Gui, Submit, NoHide
    Sleep, 50
    started := 0
    Gosub, SaveSettings

}

; pressing x on window closes macro 
GuiClose:

    StopMacro(1)

Return

; pressing f7 button reloads
Quit:

    PauseMacro(1)
    SendDiscordMessage(webhookURL, "Macro reloaded.")
    Reload ; ahk built in reload

Return

; f7 reloads
F7::

    PauseMacro(1)
    SendDiscordMessage(webhookURL, "Macro reloaded.")
    Reload ; ahk built in reload

Return

; f5 starts scan
F5:: 

Gosub, StartScanMultiInstance

Return

#MaxThreadsPerHotkey, 2
