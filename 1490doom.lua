-- 1490 DOOM 
-- Official TTS Mod
-- (c) 2026 Buer Games, All Rights Reserved

-- DO NOT DUPLICATE

currentTurn = nil -- keep track of whose *turn* it is 
currentAction = nil -- for "interrupt" actions, this must be different
player1VP = 0
player2VP = 0 -- probably not used until end of game?
p1resourcesObtained = 0
p2resourcesObtained = 0
-- kills and high ground calculated in funcs 
currentCompanyURL = ""


function importArmyOK()
    UI.hide("importArmyPanel")
    PopulateDoomCompany(1, currentCompanyURL .. "?tts=1") 
    
    -- DEBUG 
    for w in companies[1].warriors do 
       print(dump(w))
    end

end
function change_url(a, b, c)
    --print(a, b, c)
    currentCompanyURL = b  
end
function show_url_window(a)
    UI.show("importArmyPanel")
end


-- Right now, we give a leeway of 1" in both up/down
function isSameHeight(a, b)
    if (a.z > (b.z + 1.0)) then 
        return false 
    end
    if (a.z < (b.z - 1.0)) then 
        return false 
    end 
    return true 
end
--print(isSameHeight({x=0,y=0,z=12.42}, {x=0,y=0,z=12.32}))

ResourceItems = { 
    HERBS_AND_TONIC = 1, -- +3 vit 
    FOOD = 2, -- +1 action (no repeats!)
    SCHOLARLY_SCROLL = 3, -- pass a failed skill check 
    MAP = 4, -- move all alive: 3@2", 2@3", 1@4"
    CLOAK = 5, -- may not be attacked or pushed until this models next activation
    RELIQUARY = 6 -- restore a "once-per-game" ability
}
Marks = { 
    GRAVEBORN = "Graveborn",
    -- 1per gm: hero may take 1 action immediately before perishing 
    ASHBOUND = "Ashbound", -- hearth token ***
    -- +1 combat when within 2" of hearth and level 
    DOOMED_CHOIR = "Doomed Choir", 
    -- 1 per g: start of round: 1 enemy within 2" of yours: -1 combat/skill for this round
    FOG_WALKERS = "Fog Walkers",
    -- +1 def on 1st def per round when on ground level 
    NO_MARK = "None",
    RELIC_BITTEN = "Relic Bitten",
    -- 2 dice when resource caching
    SILENT_PACT = "Silent Pact",
    -- 1per gm: 1 warrior can use 3 actions but 3rd must be standby
    TOWER_BORN = "Tower Born",
    -- roll 2 dice when falling 
    WRETCHED_SURVIVORS = "Wretched Survivors"
    -- +1 skl and def when at <2 vit 
}
Modes = { 
    STANDARD = "standard", CAMPAIGN = "campaign"
}
ClassNames = { 
    ASSASSIN = "Assassin",BEEKEEPER = "Beekeeper",BLACKSMITH = "Blacksmith",
    BRUTE = "Brute",DOOM_HUNTER = "Doom Hunter",EXECUTIONER = "Executioner",
    FIGHTER = "Fighter",KNIGHT = "Knight",SCAVENGER = "Scavenger",
    SCOUT = "Scout",REAVER = "Reaver",WARRIOR_PRIEST = "Warrior Priest",
    MAD_MULE = "Mad Mule"
}
-- Move, Attack, Vitality, Skill, Defense, Combat 
ClassStats = {  --M. A. V. S. D. C
    ASSASSIN =  { 5, 1, 5, 5, 5, 4 },BEEKEEPER = { 6, 1, 4, 4, 5, 4 },
    BLACKSMITH ={ 4, 1, 5, 3, 5, 4 },BRUTE =     { 3, 2, 7, 6, 3, 4 },
    DOOM_HUNTER={ 5, 1, 4, 4, 6, 4 },EXECUTIONER={ 4, 1, 6, 5, 5, 4 },
    FIGHTER =   { 4, 1, 6, 5, 4, 4 },HEDGE_KNIGHT={5, 1, 5, 4, 5, 4 }, -- C for HK is always 5
    KNIGHT  =   { 4, 2, 5, 6, 4, 3 },SABOTEUR =  { 5, 1, 4, 4, 5, 5 },
    SCAVENGER = { 5, 1, 6, 3, 4, 5 },SCOUT =     { 6, 1, 4, 4, 4, 5 },
    REAVER =    { 5, 2, 6, 6, 5, 4 },WARRIOR_PRIEST = { 4, 1, 5, 4, 5, 5 },
    MAD_MULE = { 6, 2, 5, 0, 4, 0 }
}
ClassAbilities = { 
    -- assassin
    NIGHT_STALKER = 1,KILLSHOT = 2,CAMOUFLAGED_CLIMBER = 3,
    -- beekeepr
    BECKON_THE_SWARM = 4,STINGING_CLOUD = 5,BUZZING_MANTLE = 6,
    -- executioner 
    EXECUTIONERS_MARK = 7,FINALITY = 8,AIM_FOR_THE_NECK = 9,
    -- blacksmith 
    PUNCTURING_PRECISION = 10,FORGE_MASTER = 11,SUNDERING_BLOW = 12,
    -- brute 
    RAGE = 13,SMASH = 14,THROW = 15,
    -- doom hunter 
    EAGLES_EYE = 16,MARKSMANS_FOCUS = 17,PINNING_SHOT = 18,
    -- fghter 
    FURY = 19,DEVASTATING_BLOW = 20,OPPORTUNISTS_CLEAVE = 21,
    -- hedge 
    GAUNT_GALLOP = 22, SQUIRE_OF_MUD_AND_ROOT = 23,THE_SHATTERED_SHIELD = 24,
    -- kn 
    SHIELD_OF_THE_REALM = 25,INSPIRING_PRESENCE = 26,DEFENDERS_PARRY = 27,
    -- saboteur 
    BOOBY_TRAP = 28,SET_TRAP = 29,IMPROVED_CANISTER = 30,
    --scavenger 
    DETERMINATION = 31,DIRTY_DAGGER = 32,empty_skill_1 = 33,
    -- scout 
    EARLY_BIRD = 34,I_CAN_SMELL_IT = 35,TAKE_THE_INITIATIVE = 36,
    -- reaver 
    BERSERKER = 37,RELENTLESS = 38,BEARING_DOWN = 39,
    -- wpriest 
    HEAL_THE_FLOCK = 40,LAST_RITES = 41,FEAR_OF_GOD = 42,
    -- mad mule 
    MAD_MULE_1 = 43,MAD_MULE_2 = 44,MAD_MULE_3 = 45
}

DoomClass={}
function DoomClass:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.name = o.name or ClassNames.ASSASSIN
    o.stats = o.stats or ClassStats.ASSASSIN
    o.abilities = o.abilities or { 1, 2, 3 }

    return o 
end

Classes = { 
    ASSASSIN = DoomClass:new(),
    BEEKEEPER = DoomClass:new({
        name = ClassNames.BEEKEEPER ,
        stats = ClassStats.BEEKEEPER ,
        abilities = { 4, 5, 6 }
    }),
    EXECUTIONER = DoomClass:new({
        name = ClassNames.EXECUTIONER,
        stats = ClassStats.EXECUTIONER , 
        abilities = { 7, 8, 9 }
    }),
    BLACKSMITH = DoomClass:new({
        name = ClassNames.BLACKSMITH ,
        stats = ClassStats.BLACKSMITH ,
        abilities = { 10, 11, 12 }
    }),
    BRUTE = DoomClass:new({
        name = ClassNames.BRUTE ,
        stats = ClassStats.BRUTE ,
        abilities = { 13, 14, 15 }
    }),
    DOOM_HUNTER = DoomClass:new({
        name = ClassNames.DOOM_HUNTER ,
        stats = ClassStats.DOOM_HUNTER ,
        abilities = { 16, 17, 18 }
    }),
    FIGHTER = DoomClass:new({
        name = ClassNames.FIGHTER ,
        stats = ClassStats.FIGHTER ,
        abilities = { 19, 20, 21 }
    }),
    HEDGE_KNIGHT = DoomClass:new({
        name = ClassNames.HEDGE_KNIGHT ,
        stats = ClassStats.HEDGE_KNIGHT ,
        abilities = { 22, 23, 24 }
    }),
    KNIGHT = DoomClass:new({
        name = ClassNames.HEDGE_KNIGHT ,
        stats = ClassStats.HEDGE_KNIGHT ,
        abilities = { 22, 23, 24 }
    }),
    SABOTEUR = DoomClass:new({
        name = ClassNames.SABOTEUR ,
        stats = ClassStats.SABOTEUR ,
        abilities = { 28, 29, 30 }
    }),
    SCAVENGER = DoomClass:new({
        name = ClassNames.SCAVENGER ,
        stats = ClassStats.SCAVENGER ,
        abilities = { 31, 32 }
    }),
    SCOUT = DoomClass:new({
        name = ClassNames.SCOUT ,
        stats = ClassStats.SCOUT ,
        abilities = { 34, 35, 36 }
    }),
    REAVER = DoomClass:new({
        name = ClassNames.REAVER ,
        stats = ClassStats.REAVER ,
        abilities = { 37, 38, 39 }
    }),
    WARRIOR_PRIEST = DoomClass:new({
        name = ClassNames.WARRIOR_PRIEST ,
        stats = ClassStats.WARRIOR_PRIEST ,
        abilities = { 40, 41, 42 }
    }),
    MAD_MULE = DoomClass:new({
        name = ClassNames.MAD_MULE,
        stats = ClassStats.MAD_MULE,
        abilities = { 43, 44, 45 }
    })
}   


Weapon={}
function Weapon:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.name = o.name or "Weapon"
    o.desc = o.desc or "No description."
    o.minRange = o.minRange or 0 -- 0 is melee 
    o.maxRange = o.maxRange or 0.5 -- lets try 0.5 for melee 
    o.damage = o.damage or 1 
    o.reload = o.reload or false 
    o.overdraw = o.overdraw or false 
    --o.light = o.light or true -- either light or heavy 
    o.twoHanded = o.twoHanded or false 
    o.oneHandedPenalty = o.oneHandedPenalty or false -- for polearms. 
    -- oneHandedPenalty also implies you MUST also have a shield.
    o.isShield = o.isShield or false -- is a shield 
    -- gives +1 to 1st atk per round; grants "guarded"
    o.onlyWeapon = o.onlyWeapon or false -- for bows etc 

    return o
end

Weapons = { 
    LIGHT_WEAPON = Weapon:new({
        name = "Light Weapon",
        desc = "One-handed. Can be paired with another light weapon or a shield."
        -- dmg and range should be ok 
        }),
    HEAVY_WEAPON = Weapon:new({
        name = "Heavy Weapon",
        damage = 2,
        twoHanded = true,
        desc = "Two-handed. Cannot equip a second weapon."
        --light = false 
    }),
    POLEARM_2H = Weapon:new({
        name = "Polearm (two-handed)", -- Polearm Two-Handed ??
        maxRange = 2,
        desc = "Two handed. Cannot equip a second weapon.",
        twoHanded = true
    }),
    POLEARM_1H = Weapon:new({
        name = "Polearm (one-handed)",
        maxRange = 2,
        desc = "Must be paired with a shield. -1 to all Combat checks.",
        oneHandedPenalty = true
    }),
    SHIELD = Weapon:new({
        name = "Shield",
        isShield = true,
        desc = "Gain +1 defense against the first attack each round. Grants the Guarded ability (once per round, this model may use their shield to prevent a PUSH action that targets them.)"
    }),
    BOW = Weapon:new(
    {
        name = "Bow",
        twoHanded = true,
        minRange = 1,
        maxRange = 5,
        overdraw = true,
        onlyWeapon = true,
        desc = "Two-handed ranged. Cannot equip a second weapon. Adds the Overdraw action (spend 1 action to double the maximum range of the next attack)."
    }),
    CROSSBOW = Weapon:new({
        name = "Crossbow",
        twoHanded = true,
        minRange = 1,
        maxRange = 5,
        onlyWeapon = true,
        reload = true,
        desc = "Two-handed ranged. Cannot equip a second weapon. Adds the Reload action (after firing, must use the Reload action before firing again)."
    })
}
ClimbingItems = { 
    LADDER = "Ladder",
    GRAPPLING_HOOK = "Grappling Hook"
}
Consumables = { 
    CANISTER = "Canister of Creeping Death",
    SERUM = "Concentrated Creeping Death Serum",
    FLASK = "Fog of War Flask"
}

DoomWarrior={}
function DoomWarrior:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.class = o.class or Classes.FIGHTER
    o.name = o.name or "No-name"
    o.isCaptain = o.isCaptain or false 
    o.weapon1 = o.weapon1 or Weapons.LIGHT_WEAPON
    o.weapon2 = o.weapon2 or nil
    o.consumable = o.consumable or nil 
    o.climbing = o.climbing or nil 
    o.ipUpgrades = o.ipUpgrades or {} -- tbd 
    o.statImprove = o.statImprove or {} -- tbd
    o.earnedIp = o.earnedIp or 0

    o.mov = o.mov or ClassStats.FIGHTER[1]
    o.atk = o.atk or ClassStats.FIGHTER[2]
    o.vit = o.vit or ClassStats.FIGHTER[3]
    o.cur_vit = o.cur_vit or ClassStats.FIGHTER[3]
    o.skl = o.skl or ClassStats.FIGHTER[4]
    o.def = o.def or ClassStats.FIGHTER[5]
    o.com = o.com or ClassStats.FIGHTER[6]

    o.dead = o.dead or false 

    o.resources = { } -- list of e.g. ResourceItems.HERBS_AND_TONIC

    return o
end

DoomCompany = {}
function DoomCompany:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.mark = o.mark or Marks.NO_MARK
    o.companyName = o.companyName or "Unnamed Company"
    o.companyMode = o.companyMode or Modes.STANDARD 
    o.ipLimit = o.ipLimit or 10 
    o.warriors = o.warriors or { DoomWarrior:new(), DoomWarrior:new(), DoomWarrior:new() }

    return o
end
        --      player1             player2
companies = { DoomCompany:new(), DoomCompany:new() }

function AssignStats(c)
    c.mov = c.class.stats[1]
    c.atk = c.class.stats[2]
    c.vit = c.class.stats[3]
    c.cur_vit = c.class.stats[3]
    c.skl = c.class.stats[4]
    c.def = c.class.stats[5]
    c.com = c.class.stats[6]
end

function PopulateDoomCompany(player, url)
    
    local dc = DoomCompany:new()
    -- Uncomment this in TTS: 
    dc_data = WebRequest.custom(url, "GET", true, "", { ["User-Agent"] = "tts-1490doom" })
    while not dc_data.is_done do 
    end 
    if dc_data.text == ""  then  
        print("Failed to obtain Doom Company data from provided URL.")
        return 
    end
    jsonData = JSON.decode(dc_data.text)
    print(dc_data.text)
    -- name 
    for i=1,3 do 

        companies[player].warriors[i].name = jsonData.warriors[i].name
    
        if jsonData.warriors[i].type == "Brute" then companies[player].warriors[i].class = Classes.BRUTE
        elseif jsonData.warriors[i].type == "Assassin" then companies[player].warriors[i].class = Classes.ASSASSIN
        elseif jsonData.warriors[i].type == "Beekeeper" then companies[player].warriors[i].class = Classes.BEEKEEPER
        elseif jsonData.warriors[i].type == "Blacksmith" then companies[player].warriors[i].class = Classes.BLACKSMITH
        elseif jsonData.warriors[i].type == "Doom Hunter" then companies[player].warriors[i].class = Classes.DOOM_HUNTER
        elseif jsonData.warriors[i].type == "Executioner" then companies[player].warriors[i].class = Classes.EXECUTIONER
        elseif jsonData.warriors[i].type == "Fighter" then companies[player].warriors[i].class = Classes.FIGHTER
        elseif jsonData.warriors[i].type == "Hedge Knight" then companies[player].warriors[i].class = Classes.HEDGE_KNIGHT
        elseif jsonData.warriors[i].type == "Knight" then companies[player].warriors[i].class = Classes.KNIGHT 
        elseif jsonData.warriors[i].type == "Saboteur" then companies[player].warriors[i].class = Classes.SABOTEUR
        elseif jsonData.warriors[i].type == "Scavenger" then companies[player].warriors[i].class = Classes.SCAVENGER
        elseif jsonData.warriors[i].type == "Scout" then companies[player].warriors[i].class = Classes.SCOUT
        elseif jsonData.warriors[i].type == "Reaver" then companies[player].warriors[i].class = Classes.REAVER
        elseif jsonData.warriors[i].type == "Warrior Priest" then companies[player].warriors[i].class = Classes.WARRIOR_PRIEST
        elseif jsonData.warriors[i].type == "Mad Mule" then companies[player].warriors[i].class = Classes.MAD_MULE
        end
    
        AssignStats(companies[player].warriors[i])
    
        if jsonData.warriors[i].isCaptain==true then companies[player].warriors[i].isCaptain = true end --end -- captain ?
        for k,v in pairs(Weapons) do     -- assign weapon1 info to the warrior based on its name given in json 
            if(jsonData.warriors[i].weapon1 == v.name) then 
                companies[player].warriors[i].weapon1 = v
            end
            if(jsonData.warriors[i].weapon2 == v.name) then 
                companies[player].warriors[i].weapon2 = v
            end
        end 
    
        for k,v in pairs(Consumables) do 
            --print(k,v,jsonData.warriors[i].consumable)
            if jsonData.warriors[i].consumable == v then 
                companies[player].warriors[i].consumable = v
            end 
        end
        for k,v in pairs(ClimbingItems) do 
            if jsonData.warriors[i].climbing == v then 
                companies[player].warriors[i].climbing = v 
            end
        end
        for u in jsonData.warriors[i].ipUpgrades do 
            if string.find(u, "stat_") then 
                table.insert(companies[player].warriors[i].statImprove, u)
            end
        end
        companies[player].warriors[i].earnedIp = jsonData.warriors[i].earnedIp

    end

end

-- TODO add descriptions 

function onLoad()
end

function onUpdate()
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
