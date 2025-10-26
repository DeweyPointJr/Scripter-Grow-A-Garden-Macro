#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.



; GLOBAL VARIABLES

global RobloxWindow
global iniFile := A_ScriptDir "\config.ini"

global AutoAlignCamera
global CurrentShop := ""

global shopKeys := Object()
shopKeys["Seeds"] := "Seed"
shopKeys["Gears"] := "Gear"
shopKeys["Eggs"] := "Egg"
shopKeys["Sky"] := "Sky"
shopKeys["Gnomes"] := "Gnome"
shopKeys["Honey"] := "Honey"
shopKeys["Summer"] := "Summer"
shopKeys["Sprinklers"] := "Sprinkler"
shopKeys["Fall"] := "Fall"

; === Read from INI ===
iniFile := "config.ini"

IniRead, StartHotkey, %iniFile%, Settings, StartHotkey, F1
IniRead, PauseHotkey, %iniFile%, Settings, PauseHotkey, F2
IniRead, StopHotkey, %iniFile%, Settings, StopHotkey, F3

; === Bind Hotkeys Dynamically ===
Hotkey, %StartHotkey%, StartHotkeyLabel
Hotkey, %PauseHotkey%, PauseHotkeyLabel
Hotkey, %StopHotkey%, StopHotkeyLabel

; === Positiniong ===
global backpackBtnX
global backpackBtnY

IniRead, backpackBtnX, %iniFile%, Settings, backpackBtnX, 204
IniRead, backpackBtnY, %iniFile%, Settings, backpackBtnY, 53


; ITEMS
global seeds := ["Carrot", "Strawberry", "Blueberry", "Orange Tulip", "Tomato", "Corn", "Daffodil", "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut", "Cactus"
                , "Dragon Fruit", "Mango", "Grape", "Mushroom", "Pepper", "Cacao", "Beanstalk", "Ember Lily", "Sugar Apple", "Burning Bud", "Giant Pinecone"
                , "Elder Strawberry", "Romanesco", "Crimson Thorn", "Great Pumpkin"]

global gears := ["Watering Can", "Trading Ticket", "Trowel", "Recall Wrench", "Basic Sprinkler", "Advanced Sprinkler", "Medium Toy", "Pet Name Reroller", "Pet Lead", "Medium Treat", "Godly Sprinkler", "Magnifying Glass"
                , "Master Sprinkler", "Cleaning Spray", "Cleansing Pet Shard", "Favorite Tool", "Harvest Tool", "Friendship Pot", "Grandmaster Sprinkler", "Levelup Lollipop"]

global eggs := ["Common Egg", "Uncommon Egg", "Rare Egg", "Legendary Egg", "Mythical Egg", "Jungle Egg", "Bug Egg"]

global gnomes := ["Common Gnome Crate", "Farmers Gnome Crate", "Classic Gnome Crate", "Iconic Gnome Crate", "Gnome"]

global sky := ["Night Staff", "Star Caller", "Mutation Spray Cloudtouched"]

global honey := ["Flower Seed Pack", "Honey Sprinkler", "Bee Egg", "Bee Crate", "Honey Crafters Crate"]

global summer := ["Cauliflower", "Rafflesia", "Green Apple", "Avocado", "Banana", "Pineapple", "Kiwi", "Bell Pepper", "Prickly Pear", "Loquat", "Feijoa", "Pitcher Plant", "Common Summer Egg", "Rare Summer Egg", "Paradise Egg"]

global sprinklers := ["Tropical Mist Sprinkler", "Berry Blusher Sprinkler", "Spice Spritzer Sprinkler", "Sweet Soaker Sprinkler", "Flower Froster Sprinkler", "Stalk Sprout Sprinkler"]

global fall := ["Fall Seed Pack", "Kniphofia", "Maple Resin", "Fall Egg", "Chipmunk", "Space Squirrel", "Red Panda", "Bonfire", "Harvest Basket", "Super Leaf Blower", "Rake", "Leaf Crate", "Maple Crate", "Fall Fountain"]

global seedCraftingOrder := ["None", "Mandrake", "Evo Apple I", "Evo Apple II", "Evo Apple III", "Evo Apple IV"]

global craftingOrder := ["None", "Lightning Rod", "Tanning Mirror", "Reclaimer", "Event Lantern", "Anti Bee Egg", "Small Toy", "Small Treat", "Pet Pouch", "Pack Bee"]

; SHOPS
; Create global shop objects
global shops := Object()
shops["Seeds"] := seeds
shops["Gears"] := gears
shops["Eggs"] := eggs

; add merchant shops to the same map
shops["Gnomes"] := gnomes
shops["Sky"]    := sky
shops["Honey"]  := honey
shops["Summer"] := summer
shops["Sprinklers"] := sprinklers
shops["Fall"]   := fall

global shopPrefixes := Object()
shopPrefixes["Seeds"] := "Seed"
shopPrefixes["Gears"] := "Gear"
shopPrefixes["Eggs"]  := "Egg"

; add merchant prefixes
shopPrefixes["Gnomes"] := "Gnome"
shopPrefixes["Sky"]    := "Sky"
shopPrefixes["Honey"]  := "Honey"
shopPrefixes["Summer"] := "Summer"
shopPrefixes["Sprinklers"] := "Sprinkler"
shopPrefixes["Fall"]   := "Fall"

; FUNCTIONS
ClickRelative(relX, relY, coord := 0, noDelay := 0) {
    global RobloxWindow

    ; Ensure RobloxWindow is valid
    if !RobloxWindow || !WinExist("ahk_id " . RobloxWindow) {
        WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
        if !RobloxWindow {
            Tooltip, Roblox window not found!
            return
        }
    }

    ; Activate & restore window
    WinActivate, ahk_id %RobloxWindow%
    WinWaitActive, ahk_id %RobloxWindow%, , 2
    WinGet, winState, MinMax, ahk_id %RobloxWindow%
    if (winState = -1) {
        ; Window is minimized, restore it
        WinRestore, ahk_id %RobloxWindow%
    }

    WinActivate, ahk_id %RobloxWindow%
    WinWaitActive, ahk_id %RobloxWindow%, , 2


    ; Get window position
    WinGetPos, X, Y, W, H, ahk_id %RobloxWindow%
    if (ErrorLevel || W = 0 || H = 0) {
        Tooltip, wingetpos failed
        return
    }

    ; Calculate click coordinates
    if (coord = 1) {
        clickX := Round(X + (relX / 1936) * W)
        clickY := Round(Y + (relY / 1056) * H)
    } else if (coord = 2) {
        clickX := relX
        clickY := relY
    } else {
        clickX := Round(X + (W * relX))
        clickY := Round(Y + (H * relY))
        clickY += 3
    }

    oldMode := A_SendMode
    

    if (noDelay = 0) {
        SendMode Event
        MouseMove, %clickX%, %clickY%, 3
    }
    Sleep, 10
    Click, %clickX%, %clickY%

    SendMode %oldMode%
}






UINavigation(command, uialreadyopen := 0, closeUi := 1, delay := 100) {
    ; If UI is not already open, press backslash to open it
    if (!uialreadyopen) {
        Send, {sc02B}  ; sc02B is the scancode for the backslash key ("\")
        Sleep, %delay%
    }

    ; Loop through each character in the command string
    Loop, Parse, command
    {
        char := A_LoopField
        if (char = "U") {
            Send, {Up}
            Sleep, %delay% 
        } else if (char = "R") {
            Send, {Right}
            Sleep, %delay%
        } else if (char = "D") {
            Send, {Down}
            Sleep, %delay%
        } else if (char = "L") {
            Send, {Left}    
            Sleep, %delay%
        } else if (char = "E") {
            Send, {Enter}
            Sleep, %delay%
        } else if (char = "|") {
            Sleep, %delay%
        }
        
    }

    ; If closeUi flag is set, press backslash again to close
    if (closeUi) {
        Sleep, %delay%
        Send, {sc02B}
    }
}

searchItem(search := "nil", crafting := 0) {
    global backpackBtnX
    global backpackBtnY

    if (search = "nil") {
        return
    }

    ClickRelative(%backpackBtnX%, %backpackBtnY%, 2)
    Sleep, 1000
    ClickRelative(1172, 678, 1)
    Sleep, 1000
    ; Delete any existing text
    Send, {Ctrl down}
    Send, {Right}
    Send, {Backspace}
    Send, {Ctrl up}
    Sleep, 1000
    Send, %search%

    if (crafting = 1) {
            ClickRelative(0.346, 0.6818)
            sleep, 250
            Send, {E}
            sleep, 250
            ClickRelative(0.346, 0.6818)
            sleep, 250
            if (search = "Common Egg") {
                ClickRelative(0.380681818182, 0.6818)
                sleep, 250
                Send, {E}
                sleep, 250
                ClickRelative(0.380681818182, 0.6818)
                sleep, 250
                ClickRelative(0.415363636, 0.6818)
                sleep, 250
                Send, {E}
                sleep, 250
                ClickRelative(0.415363636, 0.6818)
                sleep, 250
            }
            ClickRelative(0.5, 0.5)
            sleep, 250
    }
}
PixelColorFound(color, x1, y1, x2, y2, variation := 0) {
    ; Reference resolution
    refW := 1936
    refH := 1056

    ; Get the current Roblox window position and size
    global RobloxWindow
    WinGetPos, winX, winY, winW, winH, ahk_id %RobloxWindow%
    if (winW = "" || winH = "") {
        return 0 ; something went wrong
    }

    ; Scale coordinates to current window size
    scaleX := winW / refW
    scaleY := winH / refH

    sx1 := winX + (x1 * scaleX)
    sx2 := winX + (x2 * scaleX)
    sy1 := winY + (y1 * scaleY)
    sy2 := winY + (y2 * scaleY)

    ; Search for the pixel in the selected area
    PixelSearch, foundX, foundY, %sx1%, %sy1%, %sx2%, %sy2%, %color%, %variation%, Fast RGB
    if (ErrorLevel = 0)
        return 1
    else
        return 0
}

capitalizeFirst(text) {
    firstChar := SubStr(text, 1, 1)
    StringUpper, firstChar, firstChar, T
    return firstChar . SubStr(text, 2)
}


AnyItemsSelected(shopName) {
    global shops
    anyItemsSelected := false
    capitalized := capitalizeFirst(shopName)

    shop := shops[capitalized]

    ; Determine the INI key prefix from the dictionary
    keyPrefix := shopKeys[capitalized]
    if (keyPrefix = "")
    {
        MsgBox, 48, Error, No key mapping found for shop "%capitalized%"
        return false
    }
    anyItemsSelected := false

    ; Loop through the items in the given shop array (e.g., Seeds, Tools, etc.)
    for i, item in shop
    {
        IniRead, checked, %iniFile%, %capitalized%, %keyPrefix%%i%, 0
        if (checked = "1" || checked = 1)
        {
            anyItemsSelected := true
            break
        }
    }

    return anyItemsSelected
}

BuyFromShop(shopName) {
    global doubleScrolls, itemPositions, seeds, gears, iniFile, ahopa

    global RobloxWindow
    WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
    if !RobloxWindow {
        MsgBox, Roblox window not found!
        return
    }

    ; First use UI navigation to get to the first item
    UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURD")
    Sleep, 100
    ClickRelative(983, 728, 1)
    UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURD", 0, 0)

    ; Accept either array directly or a string name
    if shops.hasKey(shopName) {
        shopItems := shops[shopName]
        section := shopName
        prefix := shopPrefixes[shopName]
    }

    ; Find all selected items (read directly from config.ini)
    selectedItems := []
    for i, item in shopItems {
        IniRead, checked, %iniFile%, %section%, %prefix%%i%, 0
        if (checked = "1" || checked = 1) {
            selectedItems.Push(item)
        }
    }

    ; Build fast lookup maps
    selectedIndexMap := {}
    selectedNameMap := {}
    for k, v in selectedItems {
        selectedIndexMap[k] := true
        selectedIndexMap[v] := true
        selectedNameMap[k] := true
        selectedNameMap[v] := true
    }

    ; Loop through shop items
    for index, item in shopItems {
        idx := index + 0

        ; Skip scrolling for the first item
        if (idx != 1) {
            Send, {Down}
            Sleep, 500
        }

        ; If selected, click its position
        if (selectedIndexMap.HasKey(index) || selectedIndexMap.HasKey(idx) || selectedNameMap.HasKey(item)) {
            ToolTip, Buying %item%
            noGifting := false
            if (prefix = "Gear" && idx = 3) || (prefix = "Gnome") || (prefix = "Sky") || (prefix = "Honey") || (prefix = "Summer") || (prefix = "Fall") || (prefix = "Sprinkler") {
                noGifting := true
            }
            if (noGifting = true) {
                UINavigation("E|||||D", 1, 0)
            } else {
                UINavigation("E|||||DL", 1, 0)
            }
            Sleep, 100
            if PixelColorFound(0x1DB31D, 598, 313, 1311, 875, 0) {
                UINavigation("EEEEEEEEEE", 1, 0)
            }
        }
        Sleep, 150
    }
    UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURRRDE", 1, 0)

    global RobloxWindow
    WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
    if !RobloxWindow {
        MsgBox, Roblox window not found!
        return
    }
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Return
}

CloseRobuxPrompt() {
    Send, {Esc}
    Sleep, 100
    Send, {Esc}
    Sleep, 1000
}

CheckForUpdate() {
    currentVersion := "HalloweenPart3-1.0" ; <-- Set your current version here
    latestURL := "https://api.github.com/repos/DeweyPointJr/Scripter-Grow-A-Garden-Macro/releases/latest"

    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", latestURL, false)
    whr.Send()
    whr.WaitForResponse()
    status := whr.Status + 0

    if (status != 200) {
        MsgBox, Failed to fetch release info. Status: %status%
        return
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

            ; Run updater (it will handle the log and file moves)
            Run, %A_ScriptDir%\update.ahk
            ExitApp
        }
    } else {
        ; On startup, check if update.ahk has a pending replacement
        CheckForUpdatedUpdater()
    }
}

; --- Helper function to replace update.ahk safely ---
CheckForUpdatedUpdater() {
    updateCandidate := A_ScriptDir "\update_files\update.ahk"
    if FileExist(updateCandidate) {
        FileMove, %updateCandidate%, %A_ScriptDir%\update.ahk, 1
        FileRemoveDir, %A_ScriptDir%\update_files, 1
    }
}


CheckForUpdate()

; Show Gui
Gosub, MainGui
return

; MAIN LOOP

MainLoop:
    Gui, Destroy

    WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
    if (RobloxWindow) {
        WinActivate, ahk_id %RobloxWindow%

        ; Roblox is active. Start main macro actions.

        ; Make sure camera is aligned correctly
        Gosub, AutoAlignCameraLabel
        
        ; Check if any seeds are selected (by reading config.ini where SaveSeeds writes them)
        anySeedsSelected := false
        for i, item in seeds {
            IniRead, checked, %iniFile%, Seeds, Seed%i%, 0
            if (checked = "1" || checked = 1) {
                anySeedsSelected := true
                break
            }
        }
        if (anySeedsSelected) {
            Gosub, SeedShopLabel
        }

        ; Check if any gears are selected (by reading config.ini where SaveGears writes them)
        anyGearsSelected := false
        for i, item in gears {
            IniRead, checked, %iniFile%, Gears, Gear%i%, 0
            if (checked = "1" || checked = 1) {
                anyGearsSelected := true
                break
            }
        }
        if (anyGearsSelected) {
            Gosub, GearShopLabel
        }

        ; Check if any eggs are selected (by reading config.ini where SaveEggs writes them)
        anyEggsSelected := false
        for i, item in eggs {
            IniRead, checked, %iniFile%, Eggs, Egg%i%, 0
            if (checked = "1" || checked = 1) {
                anyEggsSelected := true
                break
            }
        }
        if (anyEggsSelected) {
            Gosub, EggShopLabel
        }

        ; Check if any seed crafting items are selected (by reading config.ini where SaveSeedCrafting writes them)
        anySeedCraftingItemsSelected := False
        selectedItem := ""
        for i, item in seedCraftingOrder {
            IniRead, checked, %iniFile%, SeedCrafting, SeedCraftingItem%i%, 0
            if (checked = "1" || checked = 1) {
                if (item = "None") {
                    anySeedCraftingItemsSelected := False
                    break
                } else {
                    selectedItem := item
                    anySeedCraftingItemsSelected := True
                    break
                }
                
            }
        }
        if (anySeedCraftingItemsSelected = 1) {
            SeedCraftingLabel(item)
        }

        ; Check if any crafting items are selected (by reading config.ini where SaveCrafting writes them)
        anyCraftingItemsSelected := False
        selectedItem := ""
        for i, item in craftingOrder {
            IniRead, checked, %iniFile%, Crafting, CraftingItem%i%, 0
            if (checked = "1" || checked = 1) {
                if (item = "None") {
                    anyCraftingItemsSelected := False
                    break
                } else {
                    selectedItem := item
                    anyCraftingItemsSelected := True
                    break
                }
                
            }
        }
        if (anyCraftingItemsSelected = 1) {
            CraftingLabel(item)
        }

        ; Check if any merchant items are selected
        if (AnyItemsSelected("Sky") = 1 || AnyItemsSelected("Gnomes") = 1 || AnyItemsSelected("Honey") = 1 || AnyItemsSelected("Summer") = 1 || AnyItemsSelected("Sprinklers") = 1 || AnyItemsSelected("Fall") = 1) {
            Gosub, MerchantLabel
        }
    } else {
        MsgBox, Roblox window not found!
    }

    SetTimer, MainLoop, -1000
Return

; GUI Code

MainGui:
    Gui, Destroy
    Gui, New, +Resize, Scripter Macro

    ; Title label at the top
    Gui, Add, Text, w180 h30 Center vTitleText, Scripter Grow A Garden Macro [HALLOWEEN]

    ; Buttons stacked vertically
    Gui, Add, Button, w180 h40 gShopsGui, Shops
    Gui, Add, Button, w180 h40 gCraftEventsGui, Events/Crafting
    Gui, Add, Button, w180 h40 gSettingsGui, Settings
    Gui, Add, Button, w180 h40 gMainLoop, Start (%StartHotkey%)

    ; Show GUI
    Gui, Show, w200 h240, Scripter Macro
return

ShopsGui:
    Gui, Destroy
    Gui, New, +Resize, Scripter Macro

    ; Buttons stacked vertically
    Gui, Add, Button, w180 h40 gSeedsGui, Seeds
    Gui, Add, Button, w180 h40 gGearsGui, Gears
    Gui, Add, Button, w180 h40 gEggsGui, Eggs
    Gui, Add, Button, w180 h40 gMerchantsGui, Merchants
    Gui, Add, Button, w180 h40 gMainGui, Back

    ; Show GUI
    Gui, Show, w200 h240, Scripter Macro
return

CraftEventsGui:
    Gui, Destroy
    Gui, New, +Resize, Scripter Macro

    ; Buttons stacked vertically
    Gui, Add, Button, w180 h40 gSeedCraftingGui,  Seed Crafting
    Gui, Add, Button, w180 h40 gCraftingGui, Crafting
    Gui, Add, Button, w180 h40 gEventsGui, Halloween Event
    Gui, Add, Button, w180 h40 gMainGui, Back

    ; Show GUI
    Gui, Show, w200 h240, Scripter Macro
Return

MerchantsGui:
    Gui, Destroy
    Gui, New, +Resize, Scripter Macro

    ; Buttons stacked vertically
    Gui, Add, Button, w180 h40 gGnomeGui, Gnome Merchant
    Gui, Add, Button, w180 h40 gSkyGui, Sky Merchant
    Gui, Add, Button, w180 h40 gHoneyGui, Honey Merchant
    Gui, Add, Button, w180 h40 gSprinklerGui, Sprinkler Merchant
    Gui, Add, Button, w180 h40 gSummerGui, Summer Merchant
    Gui, Add, Button, w180 h40 gFallGui, Fall Merchant
    Gui, Add, Button, w180 h40 gShopsGui, Back

    ; Show GUI
    Gui, Show, w200 h330, Scripter Macro
Return

SeedsGui:
    global seeds
    Gui, Destroy
    Gui, New, +Resize, Seeds Selection

    ; Layout settings
    xOffset := 10
    yOffset := 10
    spacingX := 150    ; horizontal spacing between columns
    spacingY := 30     ; vertical spacing between rows
    perColumn := 15    ; number of checkboxes per column

    seedCount := seeds.MaxIndex()
    if (seedCount = "")
        seedCount := 0

    for i, seed in seeds {
        col := Floor((i - 1) / perColumn)
        row := Mod(i - 1, perColumn)

        xPos := xOffset + (col * spacingX)
        yPos := yOffset + (row * spacingY)

        IniRead, checked, config.ini, Seeds, Seed%i%, 0
        Gui, Add, Checkbox, vSeed_%i% x%xPos% y%yPos% w140 h25, %seed%
        GuiControl,, Seed_%i%, %checked%
    }

    ; Calculate how many columns and rows we actually have
    totalCols := Floor((seedCount - 1) / perColumn) + 1
    totalRows := (seedCount < perColumn) ? seedCount : perColumn

    totalWidth := xOffset + (totalCols * spacingX) + 20
    totalHeight := yOffset + (totalRows * spacingY) + 50

    ; Center "Done" button nicely below all columns
    buttonWidth := 100
    buttonX := (totalWidth - buttonWidth) / 2
    buttonY := yOffset + (totalRows * spacingY) + 10

    Gui, Add, Button, gSaveSeeds x%buttonX% y%buttonY% w%buttonWidth% h30, Done
    Gui, Show, w%totalWidth% h%totalHeight%, Seeds Selection
return

SaveSeeds:
    global seeds
    selected := []

    ; Loop through all seeds and get checkbox state
    for i, seed in seeds {
        GuiControlGet, checked,, Seed_%i%
        IniWrite, % checked ? 1 : 0, config.ini, Seeds, Seed%i%
    }

    ; Return to Main GUI
    Gosub, MainGui
return

GearsGui:
    global gears
    Gui, Destroy
    Gui, New, +Resize, Gears Selection

    ; Layout settings
    xOffset := 10
    yOffset := 10
    spacingX := 150    ; horizontal spacing between columns
    spacingY := 30     ; vertical spacing between rows
    perColumn := 15    ; number of checkboxes per column

    gearCount := gears.MaxIndex()
    if (gearCount   = "")
        gearCount := 0

    for i, gear in gears {
        col := Floor((i - 1) / perColumn)
        row := Mod(i - 1, perColumn)

        xPos := xOffset + (col * spacingX)
        yPos := yOffset + (row * spacingY)

        IniRead, checked, config.ini, Gears, Gear%i%, 0
        Gui, Add, Checkbox, vGear_%i% x%xPos% y%yPos% w140 h25, %gear%
        GuiControl,, Gear_%i%, %checked%
    }

    ; Calculate how many columns and rows we actually have
    totalCols := Floor((gearCount - 1) / perColumn) + 1
    totalRows := (gearCount < perColumn) ? gearCount : perColumn

    totalWidth := xOffset + (totalCols * spacingX) + 20
    totalHeight := yOffset + (totalRows * spacingY) + 50

    ; Center "Done" button nicely below all columns
    buttonWidth := 100
    buttonX := (totalWidth - buttonWidth) / 2
    buttonY := yOffset + (totalRows * spacingY) + 10

    Gui, Add, Button, gSaveGears x%buttonX% y%buttonY% w%buttonWidth% h30, Done
    Gui, Show, w%totalWidth% h%totalHeight%, Gears Selection
return

SaveGears:
    global gears
    selected := []

    ; Loop through all seeds and get checkbox state
    for i, gear in gears {
        GuiControlGet, checked,, Gear_%i%
        IniWrite, % checked ? 1 : 0, config.ini, Gears, Gear%i%
    }

    ; Return to Main GUI
    Gosub, MainGui
return

EggsGui:
    global eggs
    Gui, Destroy
    Gui, New, +Resize, Eggs Selection

    ; Layout settings
    xOffset := 10
    yOffset := 10
    spacingX := 150    ; horizontal spacing between columns
    spacingY := 30     ; vertical spacing between rows
    perColumn := 15    ; number of checkboxes per column

    eggCount := eggs.MaxIndex()
    if (eggCount = "")
        eggCount := 0

    for i, egg in eggs {
        col := Floor((i - 1) / perColumn)
        row := Mod(i - 1, perColumn)

        xPos := xOffset + (col * spacingX)
        yPos := yOffset + (row * spacingY)

        IniRead, checked, config.ini, Eggs, Egg%i%, 0
        Gui, Add, Checkbox, vEgg_%i% x%xPos% y%yPos% w140 h25, %egg%
        GuiControl,, Egg_%i%, %checked%
    }

    ; Calculate how many columns and rows we actually have
    totalCols := Floor((eggCount - 1) / perColumn) + 1
    totalRows := (eggCount < perColumn) ? eggCount : perColumn

    totalWidth := xOffset + (totalCols * spacingX) + 20
    totalHeight := yOffset + (totalRows * spacingY) + 50

    ; Center "Done" button nicely below all columns
    buttonWidth := 100
    buttonX := (totalWidth - buttonWidth) / 2
    buttonY := yOffset + (totalRows * spacingY) + 10

    Gui, Add, Button, gSaveEggs x%buttonX% y%buttonY% w%buttonWidth% h30, Done
    Gui, Show, w%totalWidth% h%totalHeight%, Eggs Selection
Return

SaveEggs:
    global eggs
    selected := []

    ; Loop through all seeds and get checkbox state
    for i, egg in eggs {
        GuiControlGet, checked,, Egg_%i%
        IniWrite, % checked ? 1 : 0, config.ini, Eggs, Egg%i%
    }

    ; Return to Main GUI
    Gosub, MainGui
return

SeedCraftingGui:
    global seedCraftingOrder
    Gui, Destroy
    Gui, New, +Resize, Seed Crafting Selection

    ; Layout settings
    xOffset := 10
    yOffset := 10
    spacingX := 150    ; horizontal spacing between columns
    spacingY := 30     ; vertical spacing between rows
    perColumn := 15    ; number of checkboxes per column

    itemCount := seedCraftingOrder.MaxIndex()
    if (itemCount = "")
        itemCount := 0

    for i, item in seedCraftingOrder {
        col := Floor((i - 1) / perColumn)
        row := Mod(i - 1, perColumn)

        xPos := xOffset + (col * spacingX)
        yPos := yOffset + (row * spacingY)

        IniRead, checked, config.ini, SeedCrafting, SeedCraftingItem%i%, 0
        Gui, Add, Radio, vSeedCraftingItem_%i% x%xPos% y%yPos% w140 h25, %item%
        GuiControl,, SeedCraftingItem_%i%, %checked%
    }

    ; Calculate how many columns and rows we actually have
    totalCols := Floor((itemCount - 1) / perColumn) + 1
    totalRows := (itemCount < perColumn) ? itemCount : perColumn

    totalWidth := xOffset + (totalCols * spacingX) + 20
    totalHeight := yOffset + (totalRows * spacingY) + 50

    ; Center "Done" button nicely below all columns
    buttonWidth := 100
    buttonX := (totalWidth - buttonWidth) / 2
    buttonY := yOffset + (totalRows * spacingY) + 10

    Gui, Add, Button, gSaveSeedCrafting x%buttonX% y%buttonY% w%buttonWidth% h30, Done
    Gui, Show, w%totalWidth% h%totalHeight%, Seed Crafting Selection
Return

SaveSeedCrafting:
    global seedCraftingOrder
    selected := []

    ; Loop through all seeds and get checkbox state
    for i, item in seedCraftingOrder {
        GuiControlGet, checked,, SeedCraftingItem_%i%
        IniWrite, % checked ? 1 : 0, config.ini, SeedCrafting, SeedCraftingItem%i%
    }

    ; Return to Main GUI
    Gosub, MainGui
return

CraftingGui:
    global craftingOrder
    Gui, Destroy
    Gui, New, +Resize, Crafting Selection

    ; Layout settings
    xOffset := 10
    yOffset := 10
    spacingX := 150    ; horizontal spacing between columns
    spacingY := 30     ; vertical spacing between rows
    perColumn := 15    ; number of checkboxes per column

    itemCount := craftingOrder.MaxIndex()
    if (itemCount = "")
        itemCount := 0

    for i, item in craftingOrder {
        col := Floor((i - 1) / perColumn)
        row := Mod(i - 1, perColumn)

        xPos := xOffset + (col * spacingX)
        yPos := yOffset + (row * spacingY)

        IniRead, checked, config.ini, Crafting, CraftingItem%i%, 0
        Gui, Add, Radio, vCraftingItem_%i% x%xPos% y%yPos% w140 h25, %item%
        GuiControl,, CraftingItem_%i%, %checked%
    }

    ; Calculate how many columns and rows we actually have
    totalCols := Floor((itemCount - 1) / perColumn) + 1
    totalRows := (itemCount < perColumn) ? itemCount : perColumn

    totalWidth := xOffset + (totalCols * spacingX) + 20
    totalHeight := yOffset + (totalRows * spacingY) + 50

    ; Center "Done" button nicely below all columns
    buttonWidth := 100
    buttonX := (totalWidth - buttonWidth) / 2
    buttonY := yOffset + (totalRows * spacingY) + 10

    Gui, Add, Button, gSaveCrafting x%buttonX% y%buttonY% w%buttonWidth% h30, Done
    Gui, Show, w%totalWidth% h%totalHeight%, Crafting Selection
Return

GnomeGui:
    CurrentShop := "Gnomes"
    Gosub, ShowShopGui
Return

SkyGui:
    CurrentShop := "Sky"
    Gosub, ShowShopGui
Return

HoneyGui:
    CurrentShop := "Honey"
    Gosub, ShowShopGui
Return

SummerGui:
    CurrentShop := "Summer"
    Gosub, ShowShopGui
Return

SprinklerGui:
    CurrentShop := "Sprinklers"
    Gosub, ShowShopGui
Return

FallGui:
    CurrentShop := "Fall"
    Gosub, ShowShopGui
Return

SaveCrafting:
    global craftingOrder
    selected := []

    ; Loop through all seeds and get checkbox state
    for i, item in craftingOrder {
        GuiControlGet, checked,, CraftingItem_%i%
        IniWrite, % checked ? 1 : 0, config.ini, Crafting, CraftingItem%i%
    }

    ; Return to Main GUI
    Gosub, MainGui
return

EventsGui:
    MsgBox, Events are temporarily unavailable! Sorry! I will add merchants/events back after the Hallowen event is over.
Return

SettingsGui:
    Gui, Destroy
    Gui, New, +Resize, Settings

    ; Create tab control
    Gui, Add, Tab2, x10 y10 w280 h200, General|Hotkeys|Positioning

    ; === General Tab ===
    Gui, Add, Text, x20 y50, Auto Align Camera:
    IniRead, AutoAlignCamera, config.ini, Settings, AutoAlignCamera, 0
    Gui, Add, Checkbox, vAutoAlignCamera x120 y50
    GuiControl,, AutoAlignCamera, %AutoAlignCamera%


    ; === Hotkeys Tab ===
    Gui, Tab, 2
    Gui, Add, Text, x20 y50, Start Hotkey:
    Gui, Add, Edit, vStartHotkeyEdit x150 y48 w100
    GuiControl,, StartHotkeyEdit, %StartHotkey%

    Gui, Add, Text, x20 y80, Pause Hotkey:
    Gui, Add, Edit, vPauseHotkeyEdit x150 y78 w100
    GuiControl,, PauseHotkeyEdit, %PauseHotkey%

    Gui, Add, Text, x20 y110, Stop Hotkey:
    Gui, Add, Edit, vStopHotkeyEdit x150 y108 w100
    GuiControl,, StopHotkeyEdit, %StopHotkey%


    ; === Positioning Tab ===
    Gui, Tab, 3
    Gui, Add, Button, x20 y50 w100 h35 gSetBackpackPos, Set Backpack Button Position

    ; === Save Button ===
    Gui, Tab  ; Ends tab section
    Gui, Add, Button, gSaveSettings x100 y220 w100 h30, Save

    Gui, Show, w300 h260, Settings
return

SaveSettings:
    Gui, Submit, NoHide

    ; Save general to INI
    IniWrite, %AutoCollectMoney%, config.ini, Settings, AutoCollectMoney
    IniWrite, %AutoAlignCamera%, config.ini, Settings, AutoAlignCamera
    IniWrite, %AutoHitList%, config.ini, Settings, AutoHitList

    ; Save hotkeys to INI
    IniWrite, %StartHotkeyEdit%, config.ini, Settings, StartHotkey
    IniWrite, %PauseHotkeyEdit%, config.ini, Settings, PauseHotkey
    IniWrite, %StopHotkeyEdit%, config.ini, Settings, StopHotkey

    Reload ; hotkey changes take effect
Return

; Closing GUI exits macro
GuiClose:
    ExitApp
Return

; Hotkey Labels
StartHotkeyLabel() {
    Gui, Hide
    Gosub, MainLoop
}

PauseHotkeyLabel() {
    Pause
}

StopHotkeyLabel() {
    Reload
}

; Positioning Labels
SetBackpackPos:
    MsgBox, 64, Backpack Setup, Click where your backpack button is located.
    Gui, Hide
    ; Wait for left click
    KeyWait, LButton, D
    MouseGetPos, backpackBtnX, backpackBtnY
    MsgBox, 64, Backpack Setup, Backpack button set at X %backpackBtnX% Y %backpackBtnY%

    ; Save the location
    IniWrite, %backpackBtnX%, %iniFile%, Settings, backpackBtnX
    IniWrite, %backpackBtnY%, %iniFile%, Settings, backpackBtnY
    Gui, Show
Return

; Action Labels

ClearTooltip:
    Tooltip,
Return

SeedShopLabel:
    Tooltip, Buying Seeds
    ClickRelative(679, 133, 1)
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {e}
    Sleep, 5000
    if PixelColorFound(0x53AB3A, 603, 236, 1338, 299, 10) {
        ToolTip, Seed Shop Opened
        SetTimer, ClearTooltip, -1500
        Sleep, 1000
        BuyFromShop("Seeds")
        Tooltip, Seeds Completed
        Sleep, 1000
        Gosub, ClearTooltip
        Sleep, 1000
        ClickRelative(1298, 264, 1)
        Sleep, 1000
        CloseRobuxPrompt()
    } else {
        Tooltip, ERROR: Seed Shop Not Opening
    }
    
Return

GearShopLabel:
    Tooltip, Buying Gears
    Send, {2}
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {e}
    Sleep, 5000
    if PixelColorFound(0xD06839, 603, 236, 1338, 299, 10) {
        ToolTip, Gear Shop Opened
        SetTimer, ClearTooltip, -1500
        Sleep, 1000
        BuyFromShop("Gears")
        Tooltip, Gears Completed
        Sleep, 1000
        Gosub, ClearTooltip
    } else {
        Tooltip, ERROR: Gear Shop Not Opening
    }
    Sleep, 1000
    ClickRelative(1298, 264, 1)
    Sleep, 1000
    CloseRobuxPrompt()
Return

EggShopLabel:
    Tooltip, Buying Eggs
    Send, {2}
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {w down}
    Sleep, 500
    Send, {w up}
    Send, {e}
    Sleep, 2000
    ClickRelative(1576, 390, 1)
    Sleep, 3000
    if PixelColorFound(0xFD942E, 603, 236, 1338, 299, 10) {
        ToolTip, Egg Shop Opened
        SetTimer, ClearTooltip, -1500
        Sleep, 1000
        BuyFromShop("Eggs")
        Tooltip, Eggs Completed
        Sleep, 1000
        Gosub, ClearTooltip
    } else {
        Tooltip, ERROR: Egg Shop Not Opening
    }
    Sleep, 1000
    ClickRelative(1298, 264, 1)
    Sleep, 1000
    CloseRobuxPrompt()
Return

AutoAlignCameraLabel:
    ; First zoom alignment
    Loop, 25 {
        Send, {WheelUp}
        Sleep, 30
    }
    Sleep, 1000
    Loop, 6 {
        Send, {WheelDown}
        Sleep, 30
    }
    Sleep, 1000

    ; Next, put the camera into a top-down view
    ClickRelative(0.5, .4)
    Sleep, 500
    Click, Right, Down
    Sleep, 250
    ClickRelative(0.5, 0.8)
    Sleep, 250
    Click, Right, Up
    Sleep, 1000

    ; Last align the camera through the shops
    IniRead, AutoAlignCamera, config.ini, Settings, AutoAlignCamera
    if (AutoAlignCamera) {
        Send, {Esc}
        Sleep, 1000
        Send, {Tab}
        Sleep, 1000
        Send, {Down}
        Sleep, 100
        Send, {Right}
        Sleep, 100
        Send, {Right}
        Sleep, 1000
        Send, {Esc}
        Sleep, 1000

        ; Teleport to shops
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURERRELLERRELLERRELLERRELLERRELLERRELLERRELLERRELLERRE")
        Sleep, 1000
        ; Chance camera back
        Send, {Esc}
        Sleep, 1000
        Send, {Tab}
        Sleep, 1000
        Send, {Down}
        Sleep, 100
        Send, {Right}
        Sleep, 100
        Send, {Right}
        Sleep, 1000
        Send, {Esc}
        Sleep, 1000
    }

Return

SeedCraftingLabel(item) {
    global seedCraftingOrder

    ; Make sure the item is not none
    if (item = "None") {
        Tooltip, Shouldn't have been run
        Return
    }

    ; Now start the actual crafting
    Tooltip, Crafting %item%
    SetTimer, ClearTooltip, -1500
    Send, {2}
    Sleep, 1000
    ClickRelative(0.5, 0.5, 0)
    Sleep, 1000
    Send, {s down}
    Sleep, 850
    Send, {s up}
    Sleep, 1000
    Send, {c}
    Sleep, 1000
    Loop, 5 {
        Send, {e}
        Sleep, 100
    }
    Sleep, 2500
    ; Make sure the crafting menu opened
    if PixelColorFound(0x4D01A1, 603, 236, 1338, 299, 10) {
        ToolTip, Crafting Menu Opened
        SetTimer, ClearTooltip, -1500
        Sleep, 1000
        ; Craft the item
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURD")
        Sleep, 100
        ClickRelative(983, 728, 1)
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURDEEUUUUUUUUUUUR", 0, 0)
        Sleep, 1000
        ; Find the index of the item in the crafting seed order
        index := 0
        for i, listItem in seedCraftingOrder {
            if (listItem = item) {
                index := i-1
                break
            }
        }
        Loop, %index% {
            Send, {down}
            Sleep, 30
        }
        UINavigation("E||||DE", 1)
        Sleep, 1000
        Send, {F}
        Sleep, 1000
        Send, {e}
        Sleep, 1000
        Tooltip, Seed Crafting Completed
        Sleep, 1000
        Gosub, ClearTooltip
    } else {
        Tooltip, ERROR: Crafting Menu Not Opening
    }
Return
}

CraftingLabel(item) {
    global craftingOrder

    ; Make sure the item is not none
    if (item = "None") {
        Tooltip, Shouldn't have been run
        Return
    }

    ; Now start the actual crafting
    Tooltip, Crafting %item%
    SetTimer, ClearTooltip, -1500
    Send, {2}
    Sleep, 1000
    ClickRelative(0.5, 0.5, 0)
    Sleep, 1000
    Send, {s down}
    Sleep, 1250
    Send, {s up}
    Sleep, 1000
    Send, {c}
    Sleep, 1000
    Loop, 5 {
        Send, {e}
        Sleep, 100
    }
    Sleep, 2500
    ; Make sure the crafting menu opened
    if PixelColorFound(0x4D01A1, 603, 236, 1338, 299, 10) {
        ToolTip, Crafting Menu Opened
        SetTimer, ClearTooltip, -1500
        Sleep, 1000
        ; Craft the item
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURD")
        Sleep, 100
        ClickRelative(983, 728, 1)
        Sleep, 1000
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURDEEUUUUUUUUUUUR", 0, 0)
        Sleep, 1000
        ; Find the index of the item in the crafting seed order
        index := 0
        for i, listItem in craftingOrder {
            if (listItem = item) {
                index := i-1
                break
            }
        }
        Loop, %index% {
            Send, {down}
            Sleep, 30
        }
        UINavigation("E||||DE", 1)
        Sleep, 1000
        Send, {F}
        Sleep, 1000
        Send, {e}
        Sleep, 1000
        Tooltip, Crafting Completed
        Sleep, 1000
        Gosub, ClearTooltip
    } else {
        Tooltip, ERROR: Crafting Menu Not Opening
    }
Return
}

DynamicDone:
    global CurrentShop, shops, shopKeys, iniFile

    if (CurrentShop = "" || !shops.HasKey(CurrentShop)) {
        MsgBox, 48, Warning, No shop is currently open or invalid!
        return
    }

    shopItems := shops[CurrentShop]       ; array of items
    keyPrefix := shopKeys[CurrentShop]    ; prefix for INI keys

    ; Loop through items and save checkbox states
    for i, item in shopItems {
        controlVar := keyPrefix . "_" . i    ; must match vVariable of the checkbox
        
        GuiControlGet, checked, , %controlVar%
        if (checked = "")                  ; ensure unchecked boxes are saved as 0
            checked := 0

        iniKey := keyPrefix . i            ; desired INI key format: Egg1, Egg2, etc.
        IniWrite, %checked%, %iniFile%, %CurrentShop%, %iniKey%
    }

    CurrentShop := ""                      ; reset after saving
    Gosub, MainGui                         ; return to main GUI
Return


ShowShopGui:
    global shopKeys, shopPrefixes, shops, CurrentShop, iniFile

    shopName := CurrentShop

    ; Safety check: don't proceed if shopName is empty
    if (shopName = "" || !shops.HasKey(shopName)) {
        MsgBox, 48, Error, ShowShopGui called with invalid shop name: "%shopName%"
        return
    }

    capitalized := shopName  ; your shopKeys already use capitalized names
    keyPrefix := shopKeys[capitalized]
    if (keyPrefix = "") {
        MsgBox, 48, Error, No key mapping found for shop "%capitalized%"
        return
    }

    shopItems := shops[shopName]

    Gui, Destroy
    Gui, New, +Resize, %capitalized% Selection

    ; Layout settings
    xOffset := 10
    yOffset := 10
    spacingX := 150
    spacingY := 30
    perColumn := 15

    Count := shopItems.MaxIndex()
    if (Count = "")
        Count := 0

    ; Add checkboxes dynamically
    for i, item in shopItems {
        col := Floor((i - 1) / perColumn)
        row := Mod(i - 1, perColumn)
        xPos := xOffset + (col * spacingX)
        yPos := yOffset + (row * spacingY)

        IniRead, checked, %iniFile%, %capitalized%, %keyPrefix%%i%, 0
        global ctrlName
        ctrlName := keyPrefix . "_" . i
        Gui, Add, Checkbox, v%ctrlName% x%xPos% y%yPos% w140 h25, %item%
        GuiControl,, %ctrlName%, %checked%
    }

    ; Calculate GUI size
    totalCols := Floor((Count - 1) / perColumn) + 1
    totalRows := (Count < perColumn) ? Count : perColumn
    totalWidth := xOffset + (totalCols * spacingX) + 20
    totalHeight := yOffset + (totalRows * spacingY) + 50

    ; Done button
    buttonWidth := 100
    buttonX := (totalWidth - buttonWidth) / 2
    buttonY := yOffset + (totalRows * spacingY) + 10
    Gui, Add, Button, x%buttonX% y%buttonY% w%buttonWidth% h30 gDynamicDone, Done

    Gui, Show, w%totalWidth% h%totalHeight%, %capitalized% Selection
Return

MerchantLabel:
    Tooltip, Checking for Merchants
    SetTimer, ClearTooltip, -2000
    UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUURE")
    Sleep, 1000
    Send, {s Down}
    Sleep, 1500
    Send, {s Up}
    Sleep, 250
    Send, {e}
    Sleep, 2000
    ClickRelative(0.733, 0.45)
    Sleep, 2500

    if PixelColorFound(0x973434, 641, 355, 821, 535, 3) {
        Tooltip, Gnome Merchant Detected
        if AnyItemsSelected("Gnomes") {
            BuyFromShop("Gnomes")
        }
    } else if (PixelColorFound(0x617196, 641, 355, 821, 535, 3)) {
        Tooltip, Sky Merchant Detected
        if AnyItemsSelected("Sky") {
            BuyFromShop("Sky")
        }
    } else if (PixelColorFound(0x009CCD, 641, 355, 821, 535, 3)) {
        Tooltip, Honey Merchant Detected
        if (AnyItemsSelected("Honey")) {
            BuyFromShop("Honey")
        }
    } else if (PixelColorFound(0x00934C, 641, 355, 821, 535, 3)) {
        Tooltip, Summer Merchant Detected
        if (AnyItemsSelected("Summer")) {
            BuyFromShop("Summer")
        }
    } else if (PixelColorFound(0xC5C83F, 641, 355, 821, 535, 3)) {
        Tooltip, Sprinkler Merchant Detected
        if (AnyItemsSelected("Sprinklers")) {
            BuyFromShop("Sprinklers")
        }
    } else if (PixelColorFound(0xB67933, 641, 355, 821, 535, 3)) {
        Tooltip, Fall Merchant 
        if AnyItemsSelected("Fall") {
            BuyFromShop("Fall")
        }
    } else {
        Tooltip, No Merchant Detected
        SetTimer, ClearTooltip, -1000
        Sleep, 1000
    }
Return