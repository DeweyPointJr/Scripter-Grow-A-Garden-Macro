#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; GLOBAL VARIABLES

global TASKS := []
global OneMinuteTasks := [AutoCompressorLabel]
global FiveMinuteTasks := [SeedShopLabel, HoneySeedShopLabel, GearShopLabel, BeeEggsShopLabel]
global ThirtyMinuteTasks := [HoneyCoinsLabel, RoyalJellyLabel, EggShopLabel, AutoSellPlants]

global ERRORS := 0
lastErrors := 0

global NeedsAlignment := true
global WaitingForTasks := false

global RobloxWindow
global iniFile := A_ScriptDir "\config.ini"

global AutoAlignCamera
global UseEventLanterns
global CurrentShop := ""
global MapSide := ""

global AutoHarvest
global HarvestNow := false

global AutoCompress
global HoneyGardenActive
global UsePollenRadars
global WaitForRestocks

global FuelCampfire
global FuelNow := false

global CampfireItem1
global CampfireItem2
global CampfireItem3

global CampfireLevel := 0

global AdRewards := false

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
shopKeys["RareCosmetics"] := "RareCosmetics"
shopKeys["Safari"] := "Safari"
shopKeys["RoyalJelly"] := "RoyalJelly"
shopKeys["HoneyCoins"] := "HoneyCoins"
shopKeys["HoneySeeds"] := "HoneySeeds"
shopKeys["BeeEggs"] := "BeeEggs"
shopKeys["Pass"] := "Pass"

; === Read from INI ===
iniFile := "config.ini"

IniRead, StartHotkey, %iniFile%, Settings, StartHotkey, F1
IniRead, PauseHotkey, %iniFile%, Settings, PauseHotkey, F2
IniRead, StopHotkey, %iniFile%, Settings, StopHotkey, F3
IniRead, RecallSlot, %iniFile%, Settings, RecallSlot, 2
IniRead, LanternSlot, %iniFile%, Settings, LanternSlot, 3
IniRead, SettingsStart, %iniFile%, Settings, SettingsStart, 0

IniRead, UseEventLanterns, %iniFile%, Settings, UseEventLanterns, 0
IniRead, AutoHarvest, %iniFile%, Settings, AutoHarvest, 0
IniRead, HarvestTime, %iniFile%, Settings, HarvestTime, 30
IniRead, AutoSellPlants, %iniFile%, Settings, AutoSellPlants, 0

IniRead, AutoCompress, %iniFile%, Settings, AutoCompress, 0
IniRead, HoneyGardenActive, %iniFile%, Settings, HoneyGardenActive, 1
IniRead, UsePollenRadars, %iniFile%, Settings, UsePollenRadars, 0
IniRead, PollenRadarSlot, %iniFile%, Settings, PollenRadarSlot, 1

IniRead, FuelCampfire, %iniFile%, Campfire, FuelCampfire, 0
IniRead, FuelTime, %iniFile%, Campfire, FuelTime, 15
IniRead, CampfireItem1, %iniFile%, Campfire, CampfireItem1, "None"
IniRead, CampfireItem2, %iniFile%, Campfire, CampfireItem2, "None"
IniRead, CampfireItem3, %iniFile%, Campfire, CampfireItem3, "None"

IniRead, WaitForRestocks, %iniFile%, Settings, WaitForRestocks, 1

; === Bind Hotkeys Dynamically ===
Hotkey, %StartHotkey%, StartHotkeyLabel
Hotkey, %PauseHotkey%, PauseHotkeyLabel
Hotkey, %StopHotkey%, StopHotkeyLabel

; === Reconnect ===
global VIP_SERVER_LINK
global AutoReconnect
global JoinPublicServer
IniRead, VIP_SERVER_LINK, %iniFile%, Settings, VipServerLink, "Enter a private server link here."
INiRead, AutoReconnect, %iniFile%, Settings, AutoReconnect, 0
IniRead, JoinPublicServer, %iniFile%, Settings, JoinPublicServer, 0

; === Positiniong ===
global backpackBtnX
global backpackBtnY

IniRead, backpackBtnX, %iniFile%, Settings, backpackBtnX, 296
IniRead, backpackBtnY, %iniFile%, Settings, backpackBtnY, 53

global favoriteBtnX
global favoriteBtnY

IniRead, favoriteBtnX, %iniFile%, Settings, favoriteBtnX, 1077
IniRead, favoriteBtnY, %iniFile%, Settings, favoriteBtnY, 666


; ITEMS
global seeds := ["Carrot", "Strawberry", "Blueberry", "Buttercup", "Tomato", "Corn", "Daffodil", "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut", "Cactus"
                , "Dragon Fruit", "Mango", "Grape", "Mushroom", "Pepper", "Cacao", "Sunflower", "Beanstalk", "Ember Lily", "Sugar Apple", "Burning Bud", "Giant Pinecone"
                , "Elder Strawberry", "Romanesco", "Crimson Thorn", "Zebrazinkle", "Octobloom", "Alien Apple", "Firefly Spiral"]

global gears := ["Watering Can", "Basic Sprinkler", "Advanced Sprinkler", "Godly Sprinkler", "Master Sprinkler", "Grandmaster Sprinkler", "Trowel", "Recall Wrench", "Medium Toy", "Pet Name Reroller", "Pet Lead"
                , "Medium Treat", "Magnifying Glass", "Cleaning Spray", "Cleansing Pet Shard", "Favorite Tool", "Harvest Tool", "Friendship Pot", "Levelup Lollipop", "Trading Ticket"]

global eggs := ["Common Egg", "Uncommon Egg", "Rare Egg", "Legendary Egg", "Mythical Egg", "Bug Egg", "Jungle Egg"]

global gnomes := ["Common Gnome Crate", "Farmers Gnome Crate", "Classic Gnome Crate", "Iconic Gnome Crate", "Gnome"]

global sky := ["Night Staff", "Star Caller", "Mutation Spray Cloudtouched"]

global summer := ["Cauliflower", "Rafflesia", "Green Apple", "Avocado", "Banana", "Pineapple", "Kiwi", "Bell Pepper", "Prickly Pear", "Loquat", "Feijoa", "Pitcher Plant", "Common Summer Egg", "Rare Summer Egg", "Paradise Egg"]

global sprinklers := ["Tropical Mist Sprinkler", "Berry Blusher Sprinkler", "Spice Spritzer Sprinkler", "Sweet Soaker Sprinkler", "Flower Froster Sprinkler", "Stalk Sprout Sprinkler"]

global fall := ["Fall Seed Pack", "Kniphofia", "Maple Resin", "Fall Egg", "Chipmunk", "Space Squirrel", "Red Panda", "Bonfire", "Harvest Basket", "Super Leaf Blower", "Rake", "Leaf Crate", "Maple Crate", "Fall Fountain"]

global rareCosmetics := ["Cooking Pot", "Hot Spring", "Spell Book", "Wisp Well", "Hex Circle", "Sarcophagus"]

global safari := ["Orange Delight", "Explorer's Compass", "Safari Crate", "Zebra Whistle", "Protea", "Lush Sprinkler", "Mini Shipping Container", "Baobab", "Pet Mutation Shard Jumbo", "Savannah Crate", "Gecko", "Hyena", "Cape Buffalo", "Hippo", "Ancestral Horn", "Crocodile", "Lion"]

global royalJelly := ["Pollen Puffball", "Carpenter Bee", "Grape Droplet", "Pet Shard RoyalJelly", "Royal Jelly Fountain", "King Bee", "Pohutukawa"]

global honeyCoins := ["Honey Honey Daisy", "Honey Honey Dew", "Honey Hive Seed Pack", "Honey Ambercomb", "Pollen Radar 2026", "Honey Coneflower", "Hive Egg", "Hive Crate", "Professor Bee", "Honey Badger", "Honey Birds of Paradise", "Honey Honey Hollow"]

global honeySeeds := ["Carrot", "Strawberry", "Blueberry", "Buttercup", "Tomato", "Corn", "Daffodil", "Watermelon", "Pumpkin", "Apple", "Bamboo", "Coconut", "Cactus"
                , "Dragon Fruit", "Mango", "Grape", "Mushroom", "Pepper", "Cacao", "Sunflower", "Beanstalk", "Ember Lily", "Sugar Apple", "Burning Bud", "Giant Pinecone"
                , "Elder Strawberry", "Romanesco", "Crimson Thorn", "Zebrazinkle", "Octobloom", "Alien Apple", "Pollenvine"]

global beeEggs := ["Common", "Rare", "Mythical", "Transcendent"]

global seedCraftingOrder := ["None", "Egg Melon", "Mandrake", "Evo Apple I", "Evo Apple II", "Evo Apple III", "Evo Apple IV", "Olive", "Hollow Bamboo", "Yarrow"]

global craftingOrder := ["None", "Lightning Rod", "Tanning Mirror", "Reclaimer", "Event Lantern", "Small Toy", "Small Treat", "Pet Pouch", "Silver Ingot", "Gold Ingot", "Silver Piggy", "Golden Piggy", "Chimera Stone", "Black Spotty Egg"]

global campfireCraftingOrder := ["None", "Firepit Flower", "Cauliflower", "Campfire Crate", "Common Summer Egg", "Green Apple", "Avocado", "Super Watering Can", "Areaclaimer", "Banana", "Kiwi", "Hearth Reed" 
                                , "Rare Summer Egg", "Prickly Pear", "Feijoa", "Paradise Egg", "Energy Chew", "Pitcher Plant", "Campfire Egg"]

global pass := ["Season 5 Crate", "Hammer of Harvest", "Garden Lantern", "Season 5 Seed Pack", "Levelup Lollipop", "Grow All", "Pinkfruit Palm"]

; SHOPS
; Create global shop objects
global shops := Object()
shops["Seeds"] := seeds
shops["Gears"] := gears
shops["Eggs"] := eggs

; add merchant shops to the same map
shops["Gnomes"] := gnomes
shops["Sky"]    := sky
shops["Summer"] := summer
shops["Sprinklers"] := sprinklers
shops["Fall"]   := fall
shops["RareCosmetics"] := rareCosmetics
shops["Safari"] := safari

; add event shops
shops["Pass"] := pass
shops["RoyalJelly"] := royalJelly
shops["HoneyCoins"] := honeyCoins
shops["HoneySeeds"] := honeySeeds
shops["BeeEggs"] := beeEggs

global shopPrefixes := Object()
shopPrefixes["Seeds"] := "Seed"
shopPrefixes["Gears"] := "Gear"
shopPrefixes["Eggs"]  := "Egg"

; add merchant prefixes
shopPrefixes["Gnomes"] := "Gnome"
shopPrefixes["Sky"]    := "Sky"
shopPrefixes["Summer"] := "Summer"
shopPrefixes["Sprinklers"] := "Sprinkler"
shopPrefixes["Fall"]   := "Fall"
shopPrefixes["RareCosmetics"] := "RareCosmetics"
shopPrefixes["Safari"] := "Safari"

; add event prefixes
shopPrefixes["Pass"] := "Pass"
shopPrefixes["RoyalJelly"] := "RoyalJelly"
shopPrefixes["HoneyCoins"] := "HoneyCoins"
shopPrefixes["HoneySeeds"] := "HoneySeeds"
shopPrefixes["BeeEggs"] := "BeeEggs"

; FUNCTIONS
; --- Purchase reporting ---
global BoughtList := {}
global lastReportHour := ""

ClickRelative(relX, relY, coord := 0, noDelay := 0) {
    global RobloxWindow
    CoordMode, Window

    ; Ensure RobloxWindow is valid
    if !RobloxWindow || !WinExist("ahk_id " . RobloxWindow) {
        WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
        if !RobloxWindow {
            SetStatus("Roblox window not found!")
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

MouseMoveRelative(relX, relY, coord := 0, noDelay := 0, activate := 1) {
    global RobloxWindow

    ; Ensure RobloxWindow is valid
    if !RobloxWindow || !WinExist("ahk_id " . RobloxWindow) {
        WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
        if !RobloxWindow {
            SetStatus("Roblox window not found!")
            return
        }
    }

    ; Activate & restore window
    if (activate) {
        WinActivate, ahk_id %RobloxWindow%
        WinWaitActive, ahk_id %RobloxWindow%, , 2
        WinGet, winState, MinMax, ahk_id %RobloxWindow%
        if (winState = -1) {
            ; Window is minimized, restore it
            WinRestore, ahk_id %RobloxWindow%
        }

        WinActivate, ahk_id %RobloxWindow%
        WinWaitActive, ahk_id %RobloxWindow%, , 2
    }


    ; Get window position
    WinGetPos, X, Y, W, H, ahk_id %RobloxWindow%
    if (ErrorLevel || W = 0 || H = 0) {
        SetStatus("wingetpos failed")
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

    SendMode %oldMode%
}

RotateCamera(degrees)
{
    global RobloxWindow

    if !RobloxWindow || !WinExist("ahk_id " . RobloxWindow)
    {
        WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
        if !RobloxWindow
            return
    }

    ClickRelative(0.5, 0.5)
    WinGetPos, X, Y, W, H, ahk_id %RobloxWindow%

    ; Scale from the 1936px reference width
    dx := Round(degrees * (6.0 / 1936.0) * W)

    Loop, 25 {
        Send, {WheelUp}
        Sleep, 25
    }

    DllCall("mouse_event"
        , "UInt", 0x0001
        , "Int", dx
        , "Int", 0
        , "UInt", 0
        , "UPtr", 0)

    Sleep, 500

    Loop, 6 {
        Send, {WheelDown}
        Sleep, 25
    }
}

CheckCameraMode() {
    global RobloxWindow
    WinGetPos, X, Y, W, H, ahk_id %RobloxWindow%

    Send, {Esc}
    Sleep, 1000
    Send, {Tab}
    Sleep, 500
    if ImageDetect("Video.png", 550, 240, 755, 336, 80) {
        ClickRelative(817, 205, 1)
        Sleep, 250
    }
    MouseMoveRelative(792, 275, 1)
    Sleep, 500
    Send, {Down}

    baseDir = A_ScriptDir . Images
    CoordMode, Pixel, Window
    CoordMode, Mouse, Window

    Loop, 4 {
        imagePath := A_ScriptDir . "\Images\Camera" . A_Index . ".png"
        ImageSearch, FoundX, FoundY, (((X+557)/1936)*W), (((Y+218)/1056)*H), (((X+1376)/1936)*W), (((Y+910)/1056)*H), *80 %imagePath%
        if (ErrorLevel = 0) {
            return A_Index
        }
    }

    

    Loop, 4 {
        Send, {Right}
        Sleep, 100
    }
    Loop, 4 {
        imagePath := A_ScriptDir . "\Images\Camera" . A_Index . ".png"
        ImageSearch, FoundX, FoundY, (((X+557)/1936)*W), (((Y+218)/1056)*H), (((X+1376)/1936)*W), (((Y+910)/1056)*H), *80 %imagePath%
        if (ErrorLevel = 0) {
            return A_Index
        }
    }
    
    SetStatus("ERROR: Unable to detect camera mode")
    return 0  ; No match found
}

SetCameraMode(number) {
    if (number > 4)
        number := 4

    mode := CheckCameraMode()
    if (mode) {
        distance := mode - number
        if (distance > 0) {
            Loop, %distance% {
                ClickRelative(904, 324, 1)
                Sleep, 100
            }
        } else if (distance < 0) {
            Loop, % Abs(distance) {
                Send, {Right}
                Sleep, 100
            }
        }
        Sleep, 1000
    }
    Send, {Esc}
    Sleep, 1000
    MouseMoveRelative(0.5, 0.5)
    Return
}

CheckFavoriteMode() {
    global backpackBtnX, backpackBtnY, favoriteBtnX, favoriteBtnY

    if if PixelColorFound(0xFF0404, favoriteBtnX - 5, favoriteBtnY - 5, favoriteBtnX + 5, favoriteBtnY + 5, 10, 0) {
        SetStatus("3 detected")
        Sleep, 1000
        return 3
    } else if PixelColorFound(0xFFFFFF, favoriteBtnX, favoriteBtnY, favoriteBtnX, favoriteBtnY, 0, 0) {
        SetStatus("2 detected")
        Sleep, 1000
        return 2
    } else {
        SetStatus("1 detected")
        Sleep, 1000
        return 1
    }
    Sleep, 1000
    ClickRelative(backpackBtnX, backpackBtnY, 2)

    SetStatus("ERROR: Unable to detect favorite filter mode")
    return 0
}

SetFavoriteMode(number) {
    global backpackBtnX, backpackBtnY, favoriteBtnX, favoriteBtnY

    if (number > 3) {
        number := 3
    }

    ClickRelative(backpackBtnX, backpackBtnY, 2)

    mode := CheckFavoriteMode()
    if (mode) {
        SetStatus("Mode is " . mode)
        distance := number - mode
        if (distance > 0) {
            Loop, %distance% {
                ClickRelative(favoriteBtnX, favoriteBtnY, 2)
                Sleep, 100 
            }
        } else {
            Loop, (3 - mode + (distance*-1)) {
                ClickRelative(favoriteBtnX, favoriteBtnY, 2)
                Sleep, 100
            }
        }
    }
}

CheckRobloxStatusFunc() {

    ; Check if Roblox is not open
    if !(WinExist("Roblox")) {
        SetStatus("Roblox not open. Reconnecting...")
        ReconnectToGame()
    }
    
    ; Check if the disconnected text exists
    global RobloxWindow
    WinGetPos, X, Y, W, H, ahk_id %RobloxWindow%

    imagePath := A_ScriptDir . "\Images\Disconnected.png"
    ImageSearch, FoundX, FoundY, (((X+702)/1936)*W), (((Y+361)/1056)*H), (((X+1224)/1936)*W), (((Y+718)/1056)*H), *80 %imagePath%
    if (ErrorLevel = 0) {
        ReconnectToGame()
        return
    }
    
    ; Check for error windows
    try {
        if (WinExist("ahk_class #32770 ahk_exe RobloxPlayerBeta.exe")) {
            errorText := WinGetText, ahk_class #32770 ahk_exe RobloxPlayerBeta.exe
            if (InStr(errorText, "disconnected") || InStr(errorText, "lost connection") || InStr(errorText, "error") || InStr(errorText, "Disconnected")) {
                SetStatus("Connection error detected. Reconnecting...")
                WinClose, ahk_class #32770 ahk_exe RobloxPlayerBeta.exe
                Sleep, 1000
                ReconnectToGame()
                return
            }
        }
        
        ; Check Roblox window titles
        robloxWindows := WinGetList, ahk_exe RobloxPlayerBeta.exe
        for hwnd in robloxWindows {
            try {
                windowTitle := WinGetTitle, "ahk_id " . hwnd
                if (InStr(windowTitle, "Disconnected") || InStr(windowTitle, "Lost connection") || InStr(windowTitle, "Error")) {
                    SetStatus("Game disconnection detected. Reconnecting...")
                    ReconnectToGame()
                    return
                }
            }
        }
    }
}

ReconnectToGame() {
    global VIP_SERVER_LINK, RECONNECT_DELAY
    if (VIP_SERVER_LINK = "") || (VIP_SERVER_LINK = "Enter a private server link here.") {
        SetStatus("Cannot reconnect: No VIP Server link")
        return
    }
    
    SetStatus("Starting reconnection process...")
    
    ; Close all Roblox processes
    try {
        WinClose, Roblox
        Sleep, 1000
        WinClose, Roblox
        SetStatus("Roblox closed. Waiting...")
        Sleep, 2000
        
        ; Wait before reopening
        Sleep, %RECONNECT_DELAY%
        
        ; Open VIP Server link
        SetStatus("Opening Roblox...")
        if JoinPublicServer {
            joinLink := "roblox://placeID=126884695634066"
        } else {
            ; --- Extract the link-code part from the URL ---
            if (RegExMatch(VIP_SERVER_LINK, "i)(?<=privateServerLinkCode=)[A-Za-z0-9]+", linkCode))
            {
                ; Build the Roblox deeplink URI
                joinLink := "roblox://placeID=126884695634066&linkCode=" linkCode
            }
        }
        ; Launch via Windows Shell (same behavior as Win+R)
        try
        {
            ComObjCreate("Shell.Application").ShellExecute(joinLink)
        }
        catch e
        {
            MsgBox, 16, Error, % "Failed to launch Roblox:`n" e.Message
        }
        
        ; Wait for Roblox to open
        Loop 30 {
            global RobloxWindow
            if (WinExist("Roblox")) {
                WinMaximize, Roblox
                SetStatus("Roblox opened successfully. Loading game...")
                WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
                Sleep, 25000  ; Wait for game to load
                ; Check for connection failed
                imagePath := A_ScriptDir . "\Images\ConnectionFailed.png"
                ImageSearch, FoundX, FoundY, (((X+702)/1936)*W), (((Y+361)/1056)*H), (((X+1224)/1936)*W), (((Y+718)/1056)*H), *80 %imagePath%
                if (ErrorLevel = 0) {
                    SetStatus("Connection Failed. Retrying...")
                    Sleep, 2500
                    ReconnectToGame()
                }
                ; Connection didn't fail. Return to previous function
                SetStatus("Successfully joined game!")
                ClickRelative(0.5, 0.5)
                MapSide := ""
                CheckForAdRewards()
                break
            }
            Sleep, 1000
        }
    }
}


UINavigation(command, uialreadyopen := 0, closeUi := 1, delay := 100) {
    ; If UI is not already open, press backslash to open it
    if (!uialreadyopen) {
        Send, {sc02B}  ; sc02B is the scancode for the backslash key ("\")
        Sleep, %delay%
    }

    ; Navigate to hotbar if settings start
    if (SettingsStart) {
        UINavigation("DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD", 1, 0)
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

AddTask(task, position := 0) {
    ; prevent duplicate tasks
    for i, v in TASKS {
        if (v == task) {
            return
        }
    }
    if (position) == 0 {
        TASKS.Push(task)
    } else {
        TASKS.InsertAt(position, task)
    }
}

GoToGarden(click := false) {
    if (click) {
        ClickRelative(966, 142, 1)
    } else {
        if (AdRewards) {
            UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUURRRE", 0, 1)
        } else {
            UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUURRE", 0, 1)
        }
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
PixelColorFound(color, x1, y1, x2, y2, variation := 0, scale := 1) {
    ; Reference resolution
    refW := 1936
    refH := 1056

    ; Get Roblox window position & size
    if !RobloxWindow || !WinExist("ahk_id " . RobloxWindow) {
        WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
        if !RobloxWindow {
            SetStatus("Roblox window not found!")
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

    ; Scale coordinates to current window size
    ; Get actual window geometry (was missing causing wrong coords)
    WinGetPos, winX, winY, winW, winH, ahk_id %RobloxWindow%
    if (ErrorLevel || winW = 0 || winH = 0) {
        SetStatus("WinGetPos failed")
        return
    }

    ; Use screen coordinates since we compute absolute positions
    CoordMode, Pixel, Screen
    CoordMode, Mouse, Screen

    scaleX := winW / refW
    scaleY := winH / refH

    if (scale) {
        sx1 := winX + (x1 * scaleX)
        sx2 := winX + (x2 * scaleX)
        sy1 := winY + (y1 * scaleY)
        sy2 := winY + (y2 * scaleY)
    } else {
        sx1 := x1
        sx2 := x2
        sy1 := y1
        sy2 := y2
    }

    ; Ensure integer coordinates
    sx1 := Floor(sx1)
    sy1 := Floor(sy1)
    sx2 := Floor(sx2)
    sy2 := Floor(sy2)

    ; Search for the pixel in the selected area
    PixelSearch, foundX, foundY, %sx1%, %sy1%, %sx2%, %sy2%, %color%, %variation%, Fast RGB
    if (ErrorLevel = 0)
        return 1
    else
        return 0
}

ImageDetect(imageName, x1, y1, x2, y2, variation = 0) {
    ; === Setup ===
    baseDir := A_ScriptDir . "\Images\"
    imagePath := baseDir . imageName

    ; Reference resolution (your base)
    refW := 1936
    refH := 1056

    ; Get Roblox window position & size
    if !RobloxWindow || !WinExist("ahk_id " . RobloxWindow) {
        WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
        if !RobloxWindow {
            SetStatus("Roblox window not found!")
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

    CoordMode, Pixel, Window
    CoordMode, Mouse, Window

    ; === Try up to 4 times ===
    Loop, 4 {

        ; Scale coordinates relative to Roblox window
        x1s := X + ((x1 / refW) * W)
        y1s := Y + ((y1 / refH) * H)
        x2s := X + ((x2 / refW) * W)
        y2s := Y + ((y2 / refH) * H)

        ; Search within Roblox window
        ImageSearch, FoundX, FoundY, %x1s%, %y1s%, %x2s%, %y2s%, *%variation% %imagePath%, 

        if (ErrorLevel = 0) {
            Sleep, 500
            Tooltip
            return 1
        }
        Sleep, 1000
    }

    Sleep, 1000
    Tooltip
    return 0
}

ImageDetectTransparent(imageName, x1, y1, x2, y2, variation = 0, absolute = 0) {
    ; === Setup ===
    baseDir := A_ScriptDir . "\Images\"
    imagePath := baseDir . imageName

    ; Reference resolution (your base)
    refW := 1936
    refH := 1056

    ; Get Roblox window position & size
    if !RobloxWindow || !WinExist("ahk_id " . RobloxWindow) {
        WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
        if !RobloxWindow {
            SetStatus("Roblox window not found!")
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

    CoordMode, Pixel, Window
    CoordMode, Mouse, Window

    ; === Try up to 4 times ===
    Loop, 4 {

        ; Scale coordinates relative to Roblox window
        if (absolute) {
            x1s := X + ((x1 / refW) * W)
            y1s := Y + ((y1 / refH) * H)
            x2s := X + ((x2 / refW) * W)
            y2s := Y + ((y2 / refH) * H)
        } else {
            x1s := x1
            y1s := y1
            x2s := x2
            y2s := y2
        }

        ; Search within Roblox window
        ImageSearch, FoundX, FoundY, %x1s%, %y1s%, %x2s%, %y2s%, *%variation% *Trans0x000000 %imagePath%, 

        if (ErrorLevel = 0) {
            Sleep, 500
            Tooltip
            return 1
        }
        Sleep, 1000
    }

    Sleep, 1000
    Tooltip
    return 0
}

capitalizeFirst(text) {
    firstChar := SubStr(text, 1, 1)
    StringUpper, firstChar, firstChar, T
    return firstChar . SubStr(text, 2)
}

AddBoughtItem(item, qty) {
    global BoughtList
    if (qty <= 0)
        return
    if !IsObject(BoughtList)
        BoughtList := {}

    if (BoughtList.HasKey(item)) {
        BoughtList[item] += qty
    } else {
        BoughtList[item] := qty
    }

    ; Also append to a running purchases log immediately for reliability
    reportDir := A_ScriptDir "\Reports"
    FileCreateDir, %reportDir%
    timestamp := A_Now
    FormatTime, humanTime, %timestamp%, yyyy-MM-dd HH:mm:ss
    logLine := humanTime " - " item " x" qty "`r`n"
    FileAppend, %logLine%, %reportDir% "\purchases_current.txt"
}

HourlyReport() {
    global BoughtList
    ; Determine previous hour label (report covers the last hour)
    prev := A_Now
    EnvAdd, prev, -1, hours
    FormatTime, label, %prev%, yyyy-MM-dd_HH

    reportDir := A_ScriptDir "\Reports"
    FileCreateDir, %reportDir%
    file := reportDir "\hourly_report_" label ".txt"

    header := "Hourly report for " label "`r`n`r`n"
    FileAppend, %header%, %file%

    wrote := 0
    if IsObject(BoughtList) {
        for item, qty in BoughtList {
            line := item " x" qty "`r`n"
            FileAppend, %line%, %file%
            wrote := 1
        }
    }

    if (wrote = 0) {
        FileAppend, % "No purchases recorded.`r`n", %file%
    }

    ; Clear the list after reporting
    BoughtList := {}
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

CheckForAdRewards() {
    global AdRewards
    ;ClickRelative(486, 141, 1)
    if PixelColorFound(0x8A88F0, 430, 100, 550, 200, 10) {
        SetStatus("Ad Rewards Button Detected")
        AdRewards := true
    } else {
        SetStatus("Ad Rewards Button Not Detected")
        AdRewards := false
    }
    Return AdRewards
}

BuyFromShop(shopName) {
    global doubleScrolls, itemPositions, seeds, gears, iniFile, ahopa
    global RobloxWindow

    WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
    if !RobloxWindow {
        MsgBox, Roblox window not found!
        return
    }

    ; Navigate to the first item in the shop
    if (shopName = "Seeds") {
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLRUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURDD")
        Sleep, 100
        ClickRelative(983, 728, 1)
        Sleep, 1000
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLRUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURDEE", 0, 0)
        Sleep, 100
    } else {
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLRUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURD")
        Sleep, 100
        ClickRelative(983, 728, 1)
        Sleep, 1000
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLRUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURDEE", 0, 0)
        Sleep, 1000
    }

    ; Get shop items and prefix
    if shops.hasKey(shopName) {
        shopItems := shops[shopName]
        section := shopName
        prefix := shopPrefixes[shopName]
    } else {
        MsgBox, Shop name not found: %shopName%
        return
    }

    ; Read selected items from INI
    selectedItems := []
    for i, item in shopItems {
        IniRead, checked, %iniFile%, %section%, %prefix%%i%, 0
        if (checked = "1" || checked = 1) {
            selectedItems.Push(item)
        }
    }

    ; Build name-based lookup map
    selectedNameMap := {}
    for _, item in selectedItems {
        selectedNameMap[item] := true
    }

    ; Loop through shop items
    for index, item in shopItems {
        idx := index + 0

        ; Scroll down if not the first item
        if (idx != 1) {
            Send, {Down}
            Sleep, 500
        }

        ; Only buy if item is selected
        if selectedNameMap.HasKey(item) {
            Tooltip, Buying %item%
            noGifting := false
            if (prefix = "Gear" && idx = 7) || (prefix = "Gear" && idx = 10) || (prefix = "Gear" && idx = 11)
                || (prefix = "Gnome") || (prefix = "Sky") || (prefix = "Honey")
                || (prefix = "Summer") || (prefix = "Fall") || (prefix = "Sprinkler") || (prefix = "HoneySeeds") || (prefix = "HoneyCoins") || (prefix = "RoyalJelly") {
                noGifting := true
            }

            if (noGifting) {
                UINavigation("E|||||D", 1, 0)
            } else {
                UINavigation("E|||||DL", 1, 0)
            }
            bought := -1

            Sleep, 100
            if PixelColorFound(0x1DB31D, 598, 313, 1311, 875, 0) {
                Loop, 50 {
                    if !(PixelColorFound(0x1DB31D, 598, 313, 1311, 875, 0)) {
                        break
                    }
                    UINavigation("E|", 1, 0, 65)
                    bought += 1
                    Tooltip, Bought %item% %bought%x
                }
                ; If purchases occurred, record them to the BoughtList
                if (bought >= 0) {
                    qty := bought + 1
                    AddBoughtItem(item, qty)
                }
            }
        }

        Sleep, 150
    }

    ; Exit shop
    UINavigation("", 1, 1)
    Sleep, 1000 
    if (shopName != "HoneySeeds") && (shopName != "RoyalJelly") && (shopName != "HoneyCoins") {
        ClickRelative(1410, 164, 1)
    } else {
        ClickRelative(1320, 248, 1)
    }
    Sleep, 1000
    GoToGarden()

    ; Confirm Roblox window still exists
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

Walk(direction, duration, delay := 500) {
    Send, {%direction% down}
    Sleep, %duration%
    Send, {%direction% up}
    Sleep, %delay%
}

CloseRobuxPrompt() {
    Send, {Esc}
    Sleep, 100
    Send, {Esc}
    Sleep, 1000
}

SetStatus(status) {
    Tooltip, %status%
    SetTimer, ClearTooltip, -1500
}

CheckForUpdate() {
    currentVersion := "Campfire1.0" ; <-- Set your current version here
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
            Run, %A_ScriptDir%\"Submacros"\update.ahk
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
        FileMove, %updateCandidate%, %A_ScriptDir%\"Submacros"\update.ahk, 1
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

    global NeedsAlignment, WaitingForTasks, ERRORS, WaitForRestocks

    WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
    if (RobloxWindow) {
        WinActivate, ahk_id %RobloxWindow%

        ; Roblox is active. Start main macro actions.

        ; Check for reconnect
        global AutoReconnect
        if (AutoReconnect) {
            CheckRobloxStatusFunc()
        }

        ; Make sure camera is aligned correctly
        if (lastErrors != ERRORS) {
            lastErrors := ERRORS
            Gosub, AutoAlignCameraLabel
            NeedsAlignment := false
        }
        if (ERRORS > 3) && (AutoReconnect) {
            ReconnectToGame()
            ERRORS := 0
        }

        if NeedsAlignment {
            NeedsAlignment := false
            Gosub, AutoAlignCameraLabel
        }

        if (AutoHarvest && HarvestNow) {
            Gosub, AutoHarvestLabel
            HarvestNow := false
        }

        if (FuelCampfire && FuelNow) {
            Gosub, FuelCampfireLabel
            FuelNow := false
        }

        if (TASKS.Length()) {
            WaitingForTasks := false
            NextTask := TASKS.RemoveAt(1)
            Gosub, % NextTask
        } else {
            if WaitForRestocks {
                if !WaitingForTasks {
                    Gosub, AutoAlignCameraLabel
                    Sleep, 500
                    ClickRelative(963, 143, 1)
                    Sleep, 1000
                    Tooltip, Waiting For Restocks...
                }
                WaitingForTasks := true
            } else {
                NeedsAlignment := True
                Gosub, AddOneMinuteTasks
                Gosub, AddFiveMinuteTasks
                Gosub, AddFifteenMinuteTasks
                Gosub, AddThirtyMinuteTasks
            }
        }
        
    } else {
        if (AutoReconnect) {
            CheckRobloxStatusFunc()
        } else {
            MsgBox, Roblox window not found! Please open Roblox.
        }
        
    }

    SetTimer, MainLoop, -1000
Return

; GUI Code

MainGui:
    Gui, Destroy
    Gui, New, +Resize, Scripter Macro

    ; Title label at the top
    Gui, Add, Text, w180 h30 Center vTitleText, Scripter Grow A Garden Macro [CAMPFIRE]

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
    Gui, Add, Button, w180 h40 gCampfireGui, Campfire Event
    Gui, Add, Button, w180 h40 gEventsGui, Bizzy Bees Event
    Gui, Add, Button, w180 h40 gPassGui, Pass Shop
    Gui, Add, Button, w180 h40 gMainGui, Back

    ; Show GUI
    Gui, Show, w200 h280, Scripter Macro
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
    CurrentShop := "Seeds"
    Gosub, ShowShopGui
return

GearsGui:
    CurrentShop := "Gears"
    Gosub, ShowShopGui
return

EggsGui:
    CurrentShop := "Eggs"
    Gosub, ShowShopGui
Return

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

PassGui:
    CurrentShop := "Pass"
    Gosub, ShowShopGui
Return

RoyalJellyGui:
    CurrentShop := "RoyalJelly"
    Gosub, ShowShopGui
Return

HoneyCoinsGui:
    CurrentShop := "HoneyCoins"
    Gosub, ShowShopGui
Return

HoneySeedsGui:
    CurrentShop := "HoneySeeds"
    Gosub, ShowShopGui
Return

BeeEggsGui:
    CurrentShop := "BeeEggs"
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

CampfireGui:
    Gui, Destroy
    Gui, New, +Resize, Scripter Macro

    ; build crafting order string
    campfireOrderString := ""
    for i, item in campfireCraftingOrder {
        if (i != campfireCraftingOrder.Length()) {
            campfireOrderString .= item . "|"
        } else {
            campfireOrderString .= item
        }
    }
    

    ; Buttons stacked vertically
    Gui, Add, Text,, Fuel Campfire:

    Gui, Add, Checkbox, vFuelCampfire gSaveFuelCampfire x80 y5
    GuiControl,, FuelCampfire, %FuelCampfire%

    ; Hidden text for FuelCampfire
    Gui, Add, Text, x110 y5 Hidden vFuelEveryText1, every
    Gui, Add, Edit, x140 y3 w50 h20 Hidden vFuelTimeEdit, %FuelTime%
    Gui, Add, Text, x195 y5 Hidden vFuelEveryText2, minutes

    Gosub, SaveFuelCampfire

    Gui, Add, Text, x10 y25, Crafting Item 1:
    Gui, Add, DropDownList, x90 y23 w135 vCampfireItem1 gSaveCampfireItems, %campfireOrderString%
    GuiControl, ChooseString, CampfireItem1, %CampfireItem1%

    Gui, Add, Text, x10 y50, Crafting Item 2:
    Gui, Add, DropDownList, x90 y48 w135 vCampfireItem2 gSaveCampfireItems, %campfireOrderString%
    GuiControl, ChooseString, CampfireItem2, %CampfireItem2%

    Gui, Add, Text, x10 y75, Crafting Item 3:
    Gui, Add, DropDownList, x90 y73 w135 vCampfireItem3 gSaveCampfireItems, %campfireOrderString%
    GuiControl, ChooseString, CampfireItem3, %CampfireItem3%

    if (CampfireItem1 = "None") {
        GuiControl, Disable, CampfireItem2
        GuiControl, Disable, CampfireItem3
    } else {
        GuiControl, Enable, CampfireItem2
        if (CampfireItem2 = "None") {
            GuiControl, Disable, CampfireItem3
        } else {
            GuiControl, Enable, CampfireItem3
        }
    }

    Gui, Add, Button, x30 w180 h40 gCraftEventsGui, Back

    ; Show GUI
    Gui, Show, w240 h145, Scripter Macro
Return

SaveCampfireItems:
    Gui, Submit, NoHide

    ; Enforce dependency rules immediately after a change
    if (CampfireItem1 = "None") {
        CampfireItem2 := "None"
        CampfireItem3 := "None"
        GuiControl,, CampfireItem2, %CampfireItem2%
        GuiControl,, CampfireItem3, %CampfireItem3%
        GuiControl, Disable, CampfireItem2
        GuiControl, Disable, CampfireItem3
    } else {
        GuiControl, Enable, CampfireItem2
        if (CampfireItem2 = "None") {
            CampfireItem3 := "None"
            GuiControl,, CampfireItem3, %CampfireItem3%
            GuiControl, Disable, CampfireItem3
        } else {
            GuiControl, Enable, CampfireItem3
        }
    }

    ; Save to INI
    IniWrite, %CampfireItem1%, %iniFile%, Campfire, CampfireItem1
    IniWrite, %CampfireItem2%, %iniFile%, Campfire, CampfireItem2
    IniWrite, %CampfireItem3%, %iniFile%, Campfire, CampfireItem3
Return

SaveFuelCampfire:
    Gui, Submit, NoHide
    IniWrite, %FuelCampfire%, config.ini, Campfire, FuelCampfire
    if (FuelCampfire) {
        GuiControl, Show, FuelEveryText1
        GuiControl, Show, FuelTimeEdit
        GuiControl, Show, FuelEveryText2
    } else {
        GuiControl, Hide, FuelEveryText1
        GuiControl, Hide, FuelTimeEdit
        GuiControl, Hide, FuelEveryText2
    }
Return

CampfireCraftingGui:
Return

EventsGui:
    Gui, Destroy
    Gui, New, +Resize, Scripter Macro

    ; Buttons stacked vertically
    Gui, Add, Button, w180 h40 gHoneyCoinsGui, Honey Coins Shop
    Gui, Add, Button, w180 h40 gHoneySeedsGui, Honey Seeds Shop
    Gui, Add, Button, w180 h40 gRoyalJellyGui, Royal Jelly Shop
    Gui, Add, Button, w180 h40 gBeeEggsGui, Bee Eggs Shop
    Gui, Add, Button, w180 h40 gCraftEventsGui, Back

    Gui, Add, Text, x200 y20, Honey Garden Active:
    Gui, Add, Checkbox, vHoneyGardenActive gSaveHoneyGardenActive x310 y20
    GuiControl,, HoneyGardenActive, %HoneyGardenActive%
    
    Gui, Add, Text, x200 y40, Auto Compress:
    Gui, Add, Checkbox, vAutoCompress gSaveCompress x280 y40
    GuiControl,, AutoCompress, %AutoCompress%

    if (AutoHarvest) {
        Gui, Add, Text, x200 y60, Use Pollen Radars:
        Gui, Add, Checkbox, vUsePollenRadars gSaveUsePollenRadars x295 y60
        GuiControl,, UsePollenRadars, %UsePollenRadars%

        Gui, Add, Text, x325 y60 vPollenRadarSlotText, Slot:
        Gui, Add, DropDownList, x350 y60 w30 vPollenRadarSlot gSavePollenRadarSlot, 1|2|3|4|5|6|7|8|9|0 
        GuiControl, ChooseString, PollenRadarSlot, %PollenRadarSlot%

        Gosub, SaveUsePollenRadars
    }

    ; Show GUI
    Gui, Show, w400 h240, Scripter Macro
Return

SaveCompress:
    Gui, Submit, NoHide
    IniWrite, %AutoCompress%, config.ini, Settings, AutoCompress
Return

SaveHoneyGardenActive:
    Gui, Submit, NoHide
    IniWrite, %HoneyGardenActive%, config.ini, Settings, HoneyGardenActive
Return

SaveUsePollenRadars:
    Gui, Submit, NoHide
    IniWrite, %UsePollenRadars%, %iniFile%, Settings, UsePollenRadars
    if (UsePollenRadars) {
        GuiControl, Show, PollenRadarSlotText
        GuiControl, Show, PollenRadarSlot
    } else {
        GuiControl, Hide, PollenRadarSlotText
        GuiControl, Hide, PollenRadarSlot
    }
Return

SavePollenRadarSlot:
    Gui, Submit, NoHide
    IniWrite, %PollenRadarSlot%, %iniFile%, Settings, PollenRadarSlot
Return

SettingsGui:
    Gui, Destroy
    Gui, New, +Resize, Settings

    ; Create tab control
    Gui, Add, Tab2, x10 y10 w280 h200, General|Hotkeys|Positioning|Reconnect

    ; === General Tab ===
    Gui, Add, Text, x20 y50, Auto Align Camera:
    IniRead, AutoAlignCamera, config.ini, Settings, AutoAlignCamera, 1
    Gui, Add, Checkbox, vAutoAlignCamera x120 y50
    GuiControl,, AutoAlignCamera, %AutoAlignCamera%

    Gui, Add, Text, x20 y125, Use Event Lanterns:
    IniRead, UseEventLanterns, config.ini, Settings, UseEventLanterns, 0
    Gui, Add, Checkbox, vUseEventLanterns x120 y125
    GuiControl,, UseEventLanterns, %UseEventLanterns%

    Gui, Add, Text, x20 y75, Auto Harvest
    Gui, Add, Checkbox, vAutoHarvest gHarvestCheck x90 y75
    GuiControl,, AutoHarvest, %AutoHarvest%

    ; Hidden text for autoharvest
    Gui, Add, Text, x120 y75 Hidden vHarvestEveryText1, every
    Gui, Add, Edit, x150 y72 w50 h20 Hidden vHarvestTimeEdit, %HarvestTime%
    Gui, Add, Text, x205 y75 Hidden vHarvestEveryText2, minutes

    Gosub, HarvestCheck

    Gui, Add, Text, x20 y100, Auto Sell Plants:
    IniRead, AutoSellPlants, config.ini, Settings, AutoSellPlants, 0
    Gui, Add, Checkbox, vAutoSellPlants x120 y100
    GuiControl,, AutoSellPlants, %AutoSellPlants%

    Gui, Add, Text, x20 y150, Wait For Restocks:
    IniRead, WaitForRestocks, config.ini, Settings, WaitForRestocks, 1
    Gui, Add, Checkbox, vWaitForRestocks x120 y150
    GuiControl,, WaitForRestocks, %WaitForRestocks%

    Gui, Add, Text, x20 y175, Navigation Settings Start:
    IniRead, SettingsStart, config.ini, Settings, SettingsStart, 0
    Gui, Add, Checkbox, vSettingsStart x150 y175
    GuiControl,, SettingsStart, %SettingsStart%


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

    Gui, Add, Text, x20 y140, Recall Wrench Slot:
    Gui, Add, Edit, vRecallWrenchSlot x150 y138 w100
    GuiControl,, RecallWrenchSlot, %RecallSlot%

    Gui, Add, Text, x20 y170, Event Lantern Slot:
    Gui, Add, Edit, vEventLanternSlot x150 y168 w100
    GuiControl,, EventLanternSlot, %LanternSlot%


    ; === Positioning Tab ===
    Gui, Tab, 3
    Gui, Add, Button, x20 y50 w100 h35 gSetBackpackPos, Set Backpack Button Position

    Gui, Add, Button, x130 y50 w100 h35 gSetFavoritePos, Set Favorite Button Position

    ; === Reconnect Tab ===
    Gui, Tab, 4
    Gui, Add, Text, x20 y40 w150, VIP Server Link:
    Gui, Add, Edit, x20 y60 w200 h20 vVipLink, %VIP_SERVER_LINK%
    Gui, Add, Text, x20 y90 w120, Auto Reconnect:
    Gui, Add, Checkbox, x110 y92 vAutoReconnect
    Gui, Add, Text, x20 y115 w120, Join Public Server:
    Gui, Add, Checkbox, x110 y117 vJoinPublicServer
    GuiControl,, AutoReconnect, %AutoReconnect%
    GuiControl,, JoinPublicServer, %JoinPublicServer%
    Gui, Add, Button, gReconnectToGame x20 y145 w80 h30, Test Reconnect

    Gui, Add, Text, x20 y180, Credit to INNIE for the original reconnect script!

    ; === Save Button ===
    Gui, Tab  ; Ends tab section
    Gui, Add, Button, gSaveSettings x100 y220 w100 h30, Save

    Gui, Show, w300 h260, Settings
return

SaveSettings:
    Gui, Submit, NoHide

    ; Save general to INI
    IniWrite, %AutoAlignCamera%, config.ini, Settings, AutoAlignCamera
    IniWrite, %UseEventLanterns%, config.ini, Settings, UseEventLanterns
    IniWrite, %AutoHarvest%, config.ini, Settings, AutoHarvest
    IniWrite, %HarvestTimeEdit%, config.ini, Settings, HarvestTime
    IniWrite, %AutoSellPlants%, config.ini, Settings, AutoSellPlants
    IniWrite, %SettingsStart%, config.ini, Settings, SettingsStart


    ; Save hotkeys to INI
    IniWrite, %StartHotkeyEdit%, config.ini, Settings, StartHotkey
    IniWrite, %PauseHotkeyEdit%, config.ini, Settings, PauseHotkey
    IniWrite, %StopHotkeyEdit%, config.ini, Settings, StopHotkey
    IniWrite, %RecallWrenchSlot%, config.ini, Settings, RecallSlot
    IniWrite, %EventLanternSlot%, config.ini, Settings, LanternSlot

    ; Save Reconnect Settings
    IniWrite, %VipLink%, config.ini, Settings, VipServerLink
    IniWrite, %AutoReconnect%, config.ini, Settings, AutoReconnect
    IniWrite, %JoinPublicServer%, config.ini, Settings, JoinPublicServer

    Reload ; hotkey changes take effect
Return

HarvestCheck:
    Gui, Submit, NoHide
    if (AutoHarvest) {
        GuiControl, Show, HarvestEveryText1
        GuiControl, Show, HarvestTimeEdit
        GuiControl, Show, HarvestEveryText2
    } else {
        GuiControl, Hide, HarvestEveryText1
        GuiControl, Hide, HarvestTimeEdit
        GuiControl, Hide, HarvestEveryText2
    }
Return

; Closing GUI exits macro
GuiClose:
    ExitApp
Return

; Hotkey Labels
StartHotkeyLabel() {
    global WaitForRestocks

    Gui, Submit

    ; Ensure TASKS exists and remove any stale AutoHarvestLabel entries
    if (!IsObject(TASKS))
        TASKS := []
    i := 1
    while (i <= TASKS.Length()) {
        if (TASKS[i] = "AutoHarvestLabel")
            TASKS.RemoveAt(i)
        else
            i++
    }

    ; Start the auto-harvest timer: align with last harvest time so interval is preserved
    if (AutoHarvest) {
        ; Read last harvest wall-clock time (A_Now format)
        IniRead, lastHarvestStr, %iniFile%, Harvest, LastHarvest, 0
        desired := HarvestTime * 60000
        if (lastHarvestStr = "" || lastHarvestStr = "0") {
            ; No previous harvest recorded: start fresh
            SetTimer, AutoHarvestTimer, % desired
        } else {
            ; Compute target time = lastHarvest + HarvestTime minutes
            target := lastHarvestStr
            EnvAdd, target, %HarvestTime%, minutes

            ; If target already passed, harvest now and schedule next full interval
            if (A_Now >= target) {
                HarvestNow := true
                SetTimer, AutoHarvestTimer, % desired
            } else {
                ; Compute remaining seconds until target by stepping seconds (safe since interval is small)
                cur := A_Now
                secCount := 0
                ; guard: don't loop more than desired/1000 + 10
                maxSec := (desired // 1000) + 10
                while (cur < target) {
                    EnvAdd, cur, 1, seconds
                    secCount += 1
                    if (secCount > maxSec) {
                        break
                    }
                }
                remainingMs := secCount * 1000
                if (remainingMs <= 0) {
                    HarvestNow := true
                    SetTimer, AutoHarvestTimer, % desired
                } else {
                    SetTimer, AutoHarvestTimer, % remainingMs
                }
            }
        }
    } else {
        SetTimer, AutoHarvestTimer, Off
    }

    SetTimer, FuelCampfireTimer, % (FuelCampfire ? FuelTime * 60000 : "Off")

    ; Add tasks
    if WaitForRestocks {
        Gosub, AddOneMinuteTasks
        Gosub, AddFiveMinuteTasks
        Gosub, AddFifteenMinuteTasks
        Gosub, AddThirtyMinuteTasks
    }

    CheckForAdRewards()

    ; Start running
    global NeedsAlignment := true
    ; Initialize lastReportHour for hourly reports
    FormatTime, lastReportHour,, H
    SetTimer, CheckForNewTasks, -1000
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

SetFavoritePos:
    MsgBox, 64, Favorite Button Setup, Click where your favorite button is located.
    Gui, Hide
    ; Wait for left click
    KeyWait, LButton, D
    MouseGetPos, favoriteBtnX, favoriteBtnY
    MsgBox, 64, Favorite Button Setup, Favorite button set at X %favoriteBtnX% Y %favoriteBtnY%

    ; Save the location
    IniWrite, %favoriteBtnX%, %iniFile%, Settings, favoriteBtnX
    IniWrite, %favoriteBtnY%, %iniFile%, Settings, favoriteBtnY
    Gui, Show
Return

; Action Labels

ClearTooltip:
    Tooltip,
Return

AutoHarvestTimer:
    HarvestNow := true
Return

FuelCampfireTimer:
    FuelNow := true
Return

SeedShopLabel:
    SetStatus("Buying Seeds")
    ClickRelative(654, 138, 1)
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {e}
    Sleep, 5000
    ClickRelative(1476, 564, 1)
    Sleep, 1000
    ClickRelative(1562, 521, 1)
    Sleep, 1000
    if PixelColorFound(0x53AB3A, 468, 117, 1461, 216, 10) {
        SetStatus("Seed Shop Opened")
        Sleep, 1000
        BuyFromShop("Seeds")
        SetStatus("Seeds Completed")
        Sleep, 1000
        ClickRelative(1410, 165, 1)
        Sleep, 1000
        CloseRobuxPrompt()
    } else {
        SetStatus("ERROR: Seed Shop Not Opening")
        global ERRORS += 1
        Sleep, 1000
    }
    
Return


GearShopLabel:
    SetStatus("Buying Gears")
    Send, {%RecallSlot%}
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {e}
    Sleep, 5000
    if PixelColorFound(0x538AC2, 470, 119, 1463, 211, 10) {
        SetStatus("Gear Shop Opened")
        Sleep, 1000
        BuyFromShop("Gears")
        SetStatus("Gears Completed")
    } else {
        global ERRORS += 1
        SetStatus("ERROR: Gear Shop Not Opening")
    }
    Sleep, 1000
    ClickRelative(1410, 165, 1)
    Sleep, 1000
    CloseRobuxPrompt()
Return

EggShopLabel:
    SetStatus("Buying Eggs")
    Send, {%RecallSlot%}
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {w down}
    Sleep, 500
    Send, {w up}
    Send, {e}
    Sleep, 2000
    ClickRelative(1576, 452, 1)
    Sleep, 3000
    if PixelColorFound(0xB0AE8E, 471, 116, 1466, 220, 10) {
        ToolTip, Egg Shop Opened
        Sleep, 1000
        BuyFromShop("Eggs")
        SetStatus("Eggs Completed")
        Sleep, 1000
    } else {
        global ERRORS += 1
        SetStatus("ERROR: Egg Shop Not Opening")
    }
    Sleep, 1000
    ClickRelative(1410, 165, 1)
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
        SetCameraMode(3)

        ; Teleport to shops
        if (AdRewards) {
            UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURRERRELLERRELLERRELLERRELLERRELLERRELLERRELLERRELLERRE")
        } else {
            UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURERRELLERRELLERRELLERRELLERRELLERRELLERRELLERRELLERRE")
        }
        Sleep, 1000
        ; Chance camera back
        SetCameraMode(1)

        ; Fix angle due to compressor not being in the sell spot
        if HoneyGardenActive {
            RotateCamera(-26.75)
        }
    }

Return

SeedCraftingLabel(item) {
    global seedCraftingOrder, RecallSlot

    ; Make sure the item is not none
    if (item = "None") {
        SetStatus("Shouldn't have been run")
        Return
    }

    ; Now start the actual crafting
    SetStatus("Crafting " . %item%)
    Send, {%RecallSlot%}
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
    if PixelColorFound(0x7F4EA2, 471, 116, 1450, 220, 10) {
        SetStatus("Crafting Menu Opened")
        
        Sleep, 1000
        ; Craft the item
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUD")
        Sleep, 100
        ClickRelative(983, 728, 1)
        Sleep, 1000
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURRDEEUUUUUUUUUUURR", 0, 0)
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
        SetStatus("Seed Crafting Completed")
        Sleep, 1000
        Gosub, ClearTooltip
    } else {
        SetStatus("ERROR: Crafting Menu Not Opening")
    }
Return
}

CraftingLabel(item) {
    global craftingOrder, RecallSlot

    ; Make sure the item is not none
    if (item = "None") {
        SetStatus("Shouldn't have been run")
        Return
    }

    ; Now start the actual crafting
    SetStatus("Crafting " . %item%)
    
    Send, {%RecallSlot%}
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
    if PixelColorFound(0x7F4EA2, 471, 116, 1450, 220, 10) {
        SetStatus("Crafting Menu Opened")
        
        Sleep, 1000
        ; Craft the item
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURRD")
        Sleep, 100
        ClickRelative(983, 728, 1)
        Sleep, 1000
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURRDEEUUUUUUUUUUURR", 0, 0)
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
        SetStatus("Crafting Completed")
        Sleep, 1000
        Gosub, ClearTooltip
    } else {
        ERRORS += 1
        SetStatus("ERROR: Crafting Menu Not Opening")
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
    if (shopName = "" || !shops.HasKey(shopName)) {
        MsgBox, 48, Error, ShowShopGui called with invalid shop name: "%shopName%"
        return
    }

    capitalized := shopName
    keyPrefix := shopKeys[capitalized]
    if (keyPrefix = "") {
        MsgBox, 48, Error, No key mapping found for shop "%capitalized%"
        return
    }

    shopItems := shops[shopName]

    Gui, Destroy
    Gui, New, +Resize, %capitalized% Selection

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
        ctrlName := keyPrefix . "_" . i
        Gui, Add, Checkbox, v%ctrlName% x%xPos% y%yPos% w140 h25, %item%
        GuiControl,, %ctrlName%, %checked%
    }

    ; Calculate GUI size
    totalCols := Floor((Count - 1) / perColumn) + 1
    totalRows := (Count < perColumn) ? Count : perColumn
    buttonWidth := 100
    buttonSpacing := 20
    buttonsTotalWidth := (buttonWidth * 2) + buttonSpacing
    minWidthForButtons := buttonsTotalWidth + 40  ; extra padding
    calculatedWidth := xOffset + (totalCols * spacingX) + 20
    totalWidth := (calculatedWidth < minWidthForButtons) ? minWidthForButtons : calculatedWidth
    totalHeight := yOffset + (totalRows * spacingY) + 60

    ; Center buttons horizontally
    buttonsTotalWidth := (buttonWidth * 2) + buttonSpacing
    buttonsStartX := (totalWidth - buttonsTotalWidth) / 2
    buttonY := yOffset + (totalRows * spacingY) + 10

    ; Select All/None button
    Gui, Add, Button, x%buttonsStartX% y%buttonY% w%buttonWidth% h30 gToggleSelectAll vSelectAllButton, Select All

    ; Done button
    doneX := buttonsStartX + buttonWidth + buttonSpacing
    Gui, Add, Button, x%doneX% y%buttonY% w%buttonWidth% h30 gDynamicDone, Done

    ; Determine initial Select All/None button label
    allInitiallyChecked := true
    Loop, % Count {
        ctrlName := keyPrefix . "_" . A_Index
        GuiControlGet, state, , %ctrlName%
        if (!state) {
            allInitiallyChecked := false
            break
        }
    }
    initialLabel := allInitiallyChecked ? "Select None" : "Select All"
    GuiControl,, SelectAllButton, %initialLabel%
    
    ; Show GUI after setting correct button label
    Gui, Show, w%totalWidth% h%totalHeight%, %capitalized% Selection
Return

ToggleSelectAll:
    allChecked := true
    Loop, % Count {
        ctrlName := keyPrefix . "_" . A_Index
        GuiControlGet, state, , %ctrlName%
        if (!state) {
            allChecked := false
            break
        }
    }

    newState := allChecked ? 0 : 1
    Loop, % Count {
        ctrlName := keyPrefix . "_" . A_Index
        GuiControl,, %ctrlName%, %newState%
    }

    newLabel := allChecked ? "Select All" : "Select None"
    GuiControl,, SelectAllButton, %newLabel%
Return

MerchantLabel:
    SetStatus("Checking for Merchants")
    SetTimer, ClearTooltip, -2000
    if (AdRewards) {
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUURRE")
    } else {
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUURE")
    }
    Sleep, 1000
    Send, {s Down}
    Sleep, 1500
    Send, {s Up}
    Sleep, 250
    Send, {e}
    Sleep, 2000
    

    if PixelColorFound(0x11B3F9, 603, 236, 1338, 299, 10) {
        SetStatus("Merchant Opened. Detecting which merchant")
        if PixelColorFound(0x973434, 641, 355, 821, 535, 3) {
            SetStatus("Gnome Merchant Detected")
            if AnyItemsSelected("Gnomes") {
                BuyFromShop("Gnomes")
            }
        } else if (PixelColorFound(0x617196, 641, 355, 821, 535, 3)) {
            SetStatus("Sky Merchant Detected")
            if AnyItemsSelected("Sky") {
                BuyFromShop("Sky")
            }
        } else if (PixelColorFound(0x009CCD, 641, 355, 821, 535, 3)) {
            SetStatus("Honey Merchant Detected")
            if (AnyItemsSelected("Honey")) {
                BuyFromShop("Honey")
            }
        } else if (PixelColorFound(0x00934C, 641, 355, 821, 535, 3)) {
            SetStatus("Summer Merchant Detected")
            if (AnyItemsSelected("Summer")) {
                BuyFromShop("Summer")
            }
        } else if (PixelColorFound(0xC5C83F, 641, 355, 821, 535, 3)) {
            SetStatus("Sprinkler Merchant Detected")
            if (AnyItemsSelected("Sprinklers")) {
                BuyFromShop("Sprinklers")
            }
        } else if (PixelColorFound(0xB37B21, 641, 355, 821, 535, 3)) {
            SetStatus("Fall Merchant")
            if AnyItemsSelected("Fall") {
                BuyFromShop("Fall")
            }
        }
    } else {
        ClickRelative(0.733, 0.45)
        Sleep, 2500
        if PixelColorFound(0x11B3F9, 603, 236, 1338, 299, 10) {
            if PixelColorFound(0x973434, 641, 355, 821, 535, 3) {
            SetStatus("Gnome Merchant Detected")
            if AnyItemsSelected("Gnomes") {
                BuyFromShop("Gnomes")
            }
        } else if (PixelColorFound(0x617196, 641, 355, 821, 535, 3)) {
            SetStatus("Sky Merchant Detected")
            if AnyItemsSelected("Sky") {
                BuyFromShop("Sky")
            }
        } else if (PixelColorFound(0x009CCD, 641, 355, 821, 535, 3)) {
            SetStatus("Honey Merchant Detected")
            if (AnyItemsSelected("Honey")) {
                BuyFromShop("Honey")
            }
        } else if (PixelColorFound(0x00934C, 641, 355, 821, 535, 3)) {
            SetStatus("Summer Merchant Detected")
            if (AnyItemsSelected("Summer")) {
                BuyFromShop("Summer")
            }
        } else if (PixelColorFound(0xC5C83F, 641, 355, 821, 535, 3)) {
            SetStatus("Sprinkler Merchant Detected")
            if (AnyItemsSelected("Sprinklers")) {
                BuyFromShop("Sprinklers")
            }
        } else if (PixelColorFound(0xB37B21, 641, 355, 821, 535, 3)) {
            SetStatus("Fall Merchant")
            if AnyItemsSelected("Fall") {
                BuyFromShop("Fall")
            }
        } else {
            SetStatus("No Merchant Detected")
            SetTimer, ClearTooltip, -1000
            Sleep, 1000
        }
        }
        
    }

    
    
Return

PassShopLabel:
    SetStatus("Buying from Pass Shop")
    
    
    global doubleScrolls, itemPositions, seeds, gears, iniFile, ahopa

    global RobloxWindow
    WinGet, RobloxWindow, ID, ahk_exe RobloxPlayerBeta.exe
    if !RobloxWindow {
        MsgBox, Roblox window not found!
        return
    }

    ; First use UI navigation to get to the first item
    UINavigation("LLLLLLLLLLLLLLLLLLLLUEUUUUUUUUUUUUUUUURRRDRREDDD")
    Sleep, 100
    ClickRelative(1211, 850, 1)
    Sleep, 1000
    UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURDDUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUURDD", 0, 0)
    Sleep, 1000

    ; Accept either array directly or a string name
    shopItems := pass
    section := "Pass"
    prefix := "Pass"

    ; Find all selected items (read directly from config.ini)
    selectedItems := []
    for i, item in shopItems {
        IniRead, checked, %iniFile%, %section%, %prefix%%i%, 0
        if (checked = "1" || checked = 1) {
            selectedItems.Push(item)
        }
    }

    ; Build name-based lookup map
    selectedNameMap := {}
    for _, item in selectedItems {
        selectedNameMap[item] := true
    }

    ; Loop through shop items
    for index, item in shopItems {
        idx := index + 0

        ; Skip scrolling for the first item
        if (idx != 1) {
            UINavigation("D", 1, 0)
            Sleep, 500
        }

        ; If selected, click its position
        if selectedNameMap.HasKey(item) {
            SetStatus("Buying " . %item%)
            noGifting := false
            if (prefix = "Pass") {
                noGifting := true
            }
            if (noGifting = true) {
                UINavigation("E|||||D", 1, 0)
            } else {
                UINavigation("E|||||DL", 1, 0)
            }
            Sleep, 100
            if PixelColorFound(0x1DB31D, 778, 378, 1557, 882, 0) {
                UINavigation("EEEEEEEEEE", 1, 0)
            }
        }
        Sleep, 150
    }
    UINavigation("", 1, 1)
    Sleep, 1000
    ClickRelative(1722, 544, 1)

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

DetectMapSide:
    SetStatus("Detecting Map Side")
    GoToGarden()
    WinActivate, Roblox
    Sleep, 1000
    Walk("a", 1500)
    Send, {e}
    Sleep, 2000
    if PixelColorFound(0x279AE6, 640, 275, 1290, 860, 10) {
        SetStatus("Seeds Side Detected")
        MapSide := "Seeds"
        ClickRelative(1255, 227, 1)
    } else {
        SetStatus("Sell Side Detected")
        MapSide := "Sell"
    }
Return

Harvest() {
    global PollenRadarSlot

    if (UsePollenRadars && HoneyGardenActive) {
        Send, {%PollenRadarSlot%}
        Sleep, 100
        ClickRelative(0.5, 0.5)
        Sleep, 3000
        Send, {%PollenRadarSlot%}
    } else {
        Walk("e", 5000, 1000)
    }

    CloseRobuxPrompt()
    Sleep, 500
}

AutoHarvestLabel:
    if (MapSide = "") {
        Gosub, DetectMapSide
    }

    if (MapSide = "Sell") {
        SetCameraMode(3)
        Sleep, 1000
        if (AdRewards) {
            UINavigation("UUUUUUUUUUUUUUUUUUUUUURRERRELLERRELLERRELLERRELLE")
        } else {
            UINavigation("UUUUUUUUUUUUUUUUUUUUUURERRELLERRELLERRELLERRELLE")
        }
        Sleep, 1000
        SetCameraMode(1)
        if HoneyGardenActive {
            RotateCamera(26.75)
        }
    }

    ; Camera should be good now
    GoToGarden(1)
    Sleep, 1000

    ; Collect plants
    Loop, 50 {
        Send, {WheelDown}
        Sleep, 50
    }


    ; left side
    SetStatus("Harvesting Left Side")
    Walk("s", 270)
    Walk("a", 900)
    Harvest()
    ClickRelative(0.64824, 0.21306)
    Sleep, 500

    Walk("a", (HoneyGardenActive ? 575 : 800))
    Harvest()
    ClickRelative(0.64824, 0.21306)
    Sleep, 500
    
    Walk("a", 600)
    Walk("s", 1000)
    Harvest()

    Walk("s", (HoneyGardenActive ? 1150 : 1200))
    Harvest()

    Walk("s", 1300)
    if HoneyGardenActive {
        Walk("d", 900)
    }
    Harvest()

    if !HoneyGardenActive {
        Walk("s", 1000)
        Walk("d", 900)
        Harvest()
    }

    Walk("d", 800)
    Harvest()
    
    if !HoneyGardenActive {
        Walk("d", 600)
        Harvest()
    }

    GoToGarden()
    Sleep, 1000

    ; right side
    SetStatus("Harvesting Right Side")
    
    Walk("s", 270)
    Walk("d", 900)
    Harvest()
    ClickRelative(0.64824, 0.21306)
    Sleep, 500

    Walk("d", (HoneyGardenActive ? 575 : 800))
    Harvest()
    ClickRelative(0.64824, 0.21306)
    Sleep, 500
    
    Walk("d", 600)
    Walk("s", 1000)
    Harvest()

    Walk("s", (HoneyGardenActive ? 1150 : 1200))
    Harvest()

    Walk("s", 1300)
    if HoneyGardenActive {
        Walk("a", 900)
    }
    Harvest()

    if !HoneyGardenActive {
        Walk("s", 1000)
        Walk("a", 900)
        Harvest()
    }

    Walk("a", 800)
    Harvest()
    
    if !HoneyGardenActive {
        Walk("a", 600)
        Harvest()
    }

    GoToGarden()
    Sleep, 1000

    ; middle
    SetStatus("Harvesting Middle")

    Walk("s", 1000)
    Harvest()

    Walk("s", 1000)
    Harvest()

    Walk("s", 1175)
    Harvest()

    if !HoneyGardenActive {
        Walk("s", 1000)
        Harvest()
    }

    global NeedsAlignment := true

    ; Restart auto harvest timer
    ; Record last harvest time (wall-clock in A_Now format)
    IniWrite, %A_Now%, %iniFile%, Harvest, LastHarvest
    HarvestNow := False
    SetTimer, AutoHarvestTimer, % (AutoHarvest ? HarvestTime * 60000 : "Off")
Return

AutoSellPlantsLabel:
    if (AdRewards) {
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUURRRRE")
    } else {
        UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUURRRE")
    }
    Sleep, 2500
    Send, {E}
    Sleep, 3000
    ClickRelative(1580, 458, 1)
    Sleep, 3000
Return


HoneySeedShopLabel:
    SetStatus("Buying Honey Seeds")
    ClickRelative(654, 138, 1)
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {e}
    Sleep, 5000
    if PixelColorFound(0xFDDD67, 647, 194, 1368, 294, 10) {
        SetStatus("Honey Seed Shop Opened")
        
        Sleep, 1000
        BuyFromShop("HoneySeeds")
        SetStatus("Honey Seeds Completed")
        Sleep, 1000
        Gosub, ClearTooltip
        Sleep, 1000
        ClickRelative(1319, 248, 1)
        Sleep, 1000
        CloseRobuxPrompt()
    } else {
        global ERRORS += 1
        SetStatus("ERROR: Honey Seed Shop Not Opening")
        Sleep, 1000
    }
    
Return

HoneyCoinsLabel:
    SetStatus("Buying Honey Coin Items")
    ClickRelative(654, 138, 1)
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {e}
    Sleep, 5000
    ClickRelative(1474, 422, 1)
    Sleep, 500
    if PixelColorFound(0xFDDD67, 647, 194, 1368, 294, 10) {
        SetStatus("Honey Coin Shop Opened")
        
        Sleep, 1000
        BuyFromShop("HoneyCoins")
        SetStatus("Honey Coin Items Completed")
        Sleep, 1000
        Gosub, ClearTooltip
        Sleep, 1000
        ClickRelative(1319, 248, 1)
        Sleep, 1000
        CloseRobuxPrompt()
    } else {
        global ERRORS += 1
        SetStatus("ERROR: Honey Coin Shop Not Opening")
        Sleep, 1000
    }
    
Return

RoyalJellyLabel:
    SetStatus("Buying Royal Jelly Items")
    ClickRelative(654, 138, 1)
    Sleep, 1000
    ClickRelative(0.5, 0.5)
    Sleep, 1000
    Send, {e}
    Sleep, 5000
    ClickRelative(1478, 356, 1)
    Sleep, 500
    if PixelColorFound(0xAA4CE5, 647, 194, 1368, 294, 10) {
        SetStatus("Royal Jelly Shop Opened")
        
        Sleep, 1000
        BuyFromShop("RoyalJelly")
        SetStatus("Royal Jelly Items Completed")
        Sleep, 1000
        Gosub, ClearTooltip
        Sleep, 1000
        ClickRelative(1319, 248, 1)
        Sleep, 1000
        CloseRobuxPrompt()
    } else {
        global ERRORS += 1
        SetStatus("ERROR: Royal Jelly Shop Not Opening")
        Sleep, 1000
    }
    
Return

CompressLabel:
    SetStatus("Compressing Plants")
    ClickRelative(1279, 139, 1)
    Sleep, 1000
    Send, {e}
    Sleep, 1000
    CloseRobuxPrompt()
    Send, {s down}
    Sleep, 200
    Send, {s up}
    Sleep, 1000
    Send, {e}
    Sleep, 2000
    ClickRelative(1587, 554, 1)
    Sleep, 5000
    SetStatus("Compressing Completed")
Return

DetectBeeEggType(x1, y1, x2, y2) {
    ; Get selected eggs
    selectedEggs := {}

    for i, item in beeEggs {
        IniRead, selected, %iniFile%, BeeEggs, BeeEggs%i%

        if (selected == 1) {
            selectedEggs[item] := "Yes"
        }
    }

    if PixelColorFound(0xC7C7C7, x1, y1, x2, y2, 10) {
        ; Common Egg Detected
        if selectedEggs.HasKey("Common") {
            SetStatus("Buying Common Egg")
            Click
        }
    } else if PixelColorFound(0x0777FF, x1, y1, x2, y2, 10) {
        ; Rare Egg Detected
        if selectedEggs.HasKey("Rare") {
            SetStatus("Buying Rare Egg")
            Click
        }
    } else if PixelColorFound(0xAA55FF, x1, y1, x2, y2, 10) {
        ; Mythical Egg Detected
        if selectedEggs.HasKey("Mythical") {
            SetStatus("Buying Mythical Egg")
            Click
        }
    } else if PixelColorFound(0x55007F, x1, y1, x2, y2, 10) {
        ; Transcendent Egg Detected
        if selectedEggs.HasKey("Transcendent") {
            SetStatus("Buying Transcendent Egg")
            Click
        }
    }
}

BeeEggsShopLabel:
    SetStatus("Buying Bee Eggs")
    ClickRelative(1279, 139, 1)
    Sleep, 1000
    Walk("w", 250)
    Walk("d", 750)
    Walk("s", 1000)
    Walk("d", 250)
    RotateCamera(60)
    Sleep, 1000
    Loop, 5 {
        Send, {WheelDown}
        Sleep, 100
    }
    Sleep, 1000

    ; Detect eggs
    MouseMoveRelative(940, 280, 1)
    DetectBeeEggType(804, 220, 1076, 237)
    Sleep, 1000
    MouseMoveRelative(778, 311, 1)
    DetectBeeEggType(670, 273, 773, 289)
    Sleep, 1000
    MouseMoveRelative(1087, 314, 1)
    DetectBeeEggType(976, 272, 1192, 290)
    Sleep, 1000
    MouseMoveRelative(811, 377, 1)
    DetectBeeEggType(724, 344, 896, 360)
    Sleep, 1000
    MouseMoveRelative(937, 329, 1)
    DetectBeeEggType(1398, 542, 1587, 563)
    Sleep, 1000
    MouseMoveRelative(1062, 378, 1)
    DetectBeeEggType(975, 346, 1149, 364)
    Sleep, 1000
    SetStatus("Bee Eggs Complete")
    global NeedsAlignment := true
    Sleep, 1000
Return

CheckForNewTasks:
    FormatTime, curMin,, m
    FormatTime, curSec,, s

    ; Detect hour change for hourly reports
    FormatTime, curHour,, H
    if (lastReportHour = "") {
        lastReportHour := curHour
    } else if (curHour != lastReportHour) {
        HourlyReport()
        lastReportHour := curHour
    }

    curMin := curMin + 0
    curSec := curSec + 0

    ; Check at the start of a minute
    if (curSec = 0) {
        Gosub, AddOneMinuteTasks

        if (Mod(curMin, 5) = 0)
            Gosub, AddFiveMinuteTasks

        if (Mod(curMin, 15) = 0)
            Gosub, AddFifteenMinuteTasks

        if (Mod(curMin, 30) = 0)
            Gosub, AddThirtyMinuteTasks
    }

    SetTimer, CheckForNewTasks, -1000

Return

AddOneMinuteTasks:
    ; Check if auto compress is on
    if (AutoCompress) {
        AddTask("CompressLabel", 1)
    }
Return

AddFiveMinuteTasks:
    ; Check if any seeds are selected
    anySeedsSelected := false
    for i, item in seeds {
        IniRead, checked, %iniFile%, Seeds, Seed%i%, 0
        if (checked = "1" || checked = 1) {
            anySeedsSelected := true
            break
        }
    }
    if (anySeedsSelected) {
        AddTask("SeedShopLabel")
    }

    ; Check if any honey seeds are selected
    anyHoneySeedsSelected := false
    for i, item in honeySeeds {
        IniRead, checked, %iniFile%, HoneySeeds, HoneySeeds%i%, 0
        if (checked = "1" || checked = 1) {
            anyHoneySeedsSelected := true
            break
        }
    }
    if (anyHoneySeedsSelected) {
        AddTask("HoneySeedShopLabel")
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
        AddTask("GearShopLabel")
    }

    ; Check if any bee eggs are selected
    anyBeeEggsSelected := false
    for i, item in beeEggs {
        IniRead, checked, %iniFile%, BeeEggs, BeeEggs%i%, 0
        if (checked = "1" || checked = 1) {
            anyBeeEggsSelected := true
            break
        }
    }
    if (anyBeeEggsSelected) {
        AddTask("BeeEggsShopLabel")
    }
    ; Check if any season pass items are selected
    if (AnyItemsSelected("Pass") = 1) {
        AddTask("PassShopLabel")
    }
    
Return

AddFifteenMinuteTasks:
    AddTask("DoCrafting")
Return

AddThirtyMinuteTasks:
    ; Check if any honey coin items are selected
    anyHoneyCoinsSelected := false
    for i, item in honeyCoins {
        IniRead, checked, %iniFile%, HoneyCoins, HoneyCoins%i%, 0
        if (checked = "1" || checked = 1) {
            anyHoneyCoinsSelected := true
            break
        }
    }
    if (anyHoneyCoinsSelected) {
        AddTask("HoneyCoinsLabel")
    }

    ; Check if any royal jellyu items are selected
    anyRoyalJellySelected := false
    for i, item in royalJelly {
        IniRead, checked, %iniFile%, RoyalJelly, RoyalJelly%i%, 0
        if (checked = "1" || checked = 1) {
            anyRoyalJellySelected := true
            break
        }
    }
    if (anyRoyalJellySelected) {
        AddTask("RoyalJellyLabel")
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
        AddTask("EggShopLabel")
    }

    ; Check if any merchant items are selected
    if (AnyItemsSelected("Sky") = 1 || AnyItemsSelected("Gnomes") = 1 || AnyItemsSelected("Honey") = 1 || AnyItemsSelected("Summer") = 1 || AnyItemsSelected("Sprinklers") = 1 || AnyItemsSelected("Fall") = 1) {
        AddTask("MerchantLabel")
    }

    ; Check if auto sell plants is on
    if (AutoSellPlants) {
        AddTask("AutoSellPlantsLabel")
    }
Return

DoCrafting:
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
Return

CheckForCampfireLevel:
    global CampfireLevel

    SetTimer, CheckForCampfireLevel, -3000
Return

F6::
RotateCamera(60)
Return

F7::
    ; Dump current BoughtList to a timestamped file for debugging
    global BoughtList
    reportDir := A_ScriptDir "\Reports"
    FileCreateDir, %reportDir%
    timestamp := A_Now
    FormatTime, fileTime, %timestamp%, yyyy-MM-dd_HH-mm-ss
    dumpFile := reportDir "\purchases_dump_" fileTime ".txt"

    FileAppend, % "Dump at " fileTime "`r`n`r`n", %dumpFile%
    if IsObject(BoughtList) {
        for item, qty in BoughtList {
            FileAppend, % item " x" qty "`r`n", %dumpFile%
        }
    } else {
        FileAppend, No BoughtList object found.`r`n, %dumpFile%
    }

    Tooltip, BoughtList dumped to %dumpFile%
    SetTimer, ClearTooltip, -2500
Return

FuelCampfireLabel:
    global backpackBtnX, backpackBtnY
    
    SetStatus("Fueling Campfire")

    ; Walk to campfire
    if (UseEventLanterns) {
       Send, {EventLanternSlot}
       ClickRelative(0.5, 0.5) 
    } else {
        ClickRelative(1280, 140, 1)
        ClickRelative(0.5, 0.5)
        Sleep, 1000
        Send, {d}
        Walk("d", 6750)
        Walk("s", 500)
    }
    Sleep, 500
    ClickRelative(0.5, 0.5)
    SetFavoriteMode(3)
    Sleep, 1000
    ClickRelative(607, 780, 1)
    Sleep, 1000
    Loop, 200 {
        if PixelColorFound(0x313131, 640, 690, 710, 760, 3) {
            ClickRelative(672, 718, 1)
            Sleep, 100
            Send, {e}
            Sleep, 250
        } else {
            break
        }
    }
    SetStatus("Campfire Fueled")

    Gosub, CampfireCraftingLabel
Return

CampfireCraftingLabel:
    global CampfireItem1, CampfireItem2, CampfireItem3

    if (CampfireItem1 != "None") && (CampfireItem1 != "") {
        SetStatus("Crafting Campfire Items")

        ; Walk to crafting
        if (UseEventLanterns) {
            Send, {EventLanternSlot}
            ClickRelative(0.5, 0.5)
            Sleep, 500
            Send, {d}
            Walk("d", 1000)
            Walk("s", 1000)
        } else {
            ;ClickRelative(1280, 140, 1)
            ;ClickRelative(0.5, 0.5)
            ;Sleep, 1000
            ;Send, {d}
            ;Walk("d", 7750)
            ;Walk("s", 500)
        }
        Sleep, 500
        ClickRelative(0.5, 0.5)

        Sleep, 1000
        Send, {e}
        Sleep, 2000
        if PixelColorFound(0xCB5D31, 460, 210, 1470, 330, 10) {
            SetStatus("Campfire Workshop Opened")
            UINavigation("U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|L|LLLLLLLLRUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU", 0, 1, 30)
            ClickRelative(735, 554, 1)
            Sleep, 500
            UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLLLLLLLLLLLLLLRUUE|||E", 0, 0)
            SetStatus("Claiming Old Items")
            UINavigation("DDRE", 1, 0)
            Sleep, 1000
            CloseRobuxPrompt()
            UINavigation("RE", 1, 0)
            Sleep, 1000
            CloseRobuxPrompt()
            UINavigation("RE", 1)
            Sleep, 1000
            CloseRobuxPrompt()
            Sleep, 1000
            if (CampfireItem2 = "None") || (CampfireItem2 = "") {
                ; Craft 3 of item 1
                UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLLLLLLLLLLRUU", 0, 0)
                index := 0
                for i, listItem in campfireCraftingOrder {
                    if (listItem = CampfireItem1) {
                        SetStatus("Crafting " . listItem)
                        index := i-2
                        break
                    }
                }
                Loop, %index% {
                    Send, {Down}
                    Sleep, 30
                }
                UINavigation("E||LUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLRRE|||E|||E|||", 1)
            } else if (CampfireItem3 = "None") || (CampfireItem3 = "") {
                ; Craft 2 of item 1
                UINavigation("UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLLLLLLLLLLRUU", 0, 0)
                index := 0
                for i, listItem in campfireCraftingOrder {
                    if (listItem = CampfireItem1) {
                        SetStatus("Crafting " . listItem)
                        index := i-2
                        break
                    }
                }
                Loop, %index% {
                    Send, {Down}
                    Sleep, 30
                }
                UINavigation("E||LUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLRRE|||E|||", 1, 0)
                ; Craft 1 of item 2
                UINavigation("LUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLLLLLLLLLLRUU", 1, 0)
                index := 0
                for i, listItem in campfireCraftingOrder {
                    if (listItem = CampfireItem2) {
                        SetStatus("Crafting " . listItem)
                        index := i-2
                        break
                    }
                }
                Loop, %index% {
                    Send, {Down}
                    Sleep, 30
                }
                UINavigation("E||LUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLRRE|||", 1)
            } else if (CampfireItem3 != "None") && (CampfireItem3 != "") {
                ; Craft 1 of item 1
                UINavigation("LUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLLLLLLLLLLRUU", 0, 0)
                index := 0
                for i, listItem in campfireCraftingOrder {
                    if (listItem = CampfireItem1) {
                        SetStatus("Crafting " . listItem)
                        index := i-2
                        break
                    }
                }
                Loop, %index% {
                    Send, {Down}
                    Sleep, 30
                }
                UINavigation("E||LUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLRRE|||", 1, 0)
                ; Craft 1 of item 2
                UINavigation("LUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLLLLLLLLLLRUU", 1, 0)
                index := 0
                for i, listItem in campfireCraftingOrder {
                    if (listItem = CampfireItem2) {
                        SetStatus("Crafting " . listItem)
                        index := i-2
                        break
                    }
                }
                Loop, %index% {
                    Send, {Down}
                    Sleep, 30
                }
                UINavigation("E||LUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLRRE|||", 1, 0)
                ; Craft 1 of item 3
                UINavigation("LUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLLLLLLLLLLRUU", 1, 0)
                index := 0
                for i, listItem in campfireCraftingOrder {
                    if (listItem = CampfireItem3) {
                        SetStatus("Crafting " . listItem)
                        index := i-2
                        break
                    }
                }
                Loop, %index% {
                    Send, {Down}
                    Sleep, 30
                }
                UINavigation("E||LUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUULLLLLLLLLLRRE|||", 1)
            }
        }
        Sleep, 1000
        ClickRelative(1413, 279, 1)
        Sleep, 1000
    }
Return