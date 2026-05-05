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
companies = {}
lastLoadFailed = false 

function import_company(btn, _b, _c)
    UI.show("importArmyPanel")
end

function SpawnDoomer(c, _pos)
    local show_empty_equipment = true
    local has_shield = false
    local d = ""
    local sta = c.GetStats()
    d = d .. c.class.name .. '\n'
    d = d .. "[ff2020]Mov.  Atk.  Vit.  Skl.  Def.  Com.[-]\n"
    d = d .. "  " .. sta[1] .. "       " .. sta[2] .. "       " .. sta[3] .. "     " 
    d = d .. sta[4] .. "+     " .. sta[5] .. "+     " .. sta[6] .. "+\n\n[ff2020]Equipment[-]\n"
    d = d .. c.weapon1.name .. " [c0c020](" .. c.weapon1.damage .. " Dmg, "
    if c.weapon1.minRange == 0 then 
        if c.weapon1.maxRange > 0.5 then
            d = d .. c.weapon1.maxRange .. "\")\n"
        else
            d = d.."Base)\n" 
        end 
    else 
        d = d .. c.weapon1.minRange .. "-" .. c.weapon1.maxRange .. "\")\n"
    end
    d = d .. "[-]"
    if c.weapon2 then 
        if c.weapon2 == Weapons.SHIELD then 
            d = d .. "Shield\n"
            has_shield = true
        else 
            d = d .. c.weapon2.name .. "[c0c020](" .. c.weapon2.damage .. " Dmg, "
            if c.weapon2.minRange == 0 then 
                if c.weapon2.maxRange > 0.5 then
                    d = d .. c.weapon2.maxRange .. "\")\n"
                else
                    d = d.."Base)\n" 
                end 
            else 
                d = d .. c.weapon2.minRange .. "-" .. c.weapon2.maxRange .. "\")\n"
            end
        end
    end
    d = d .. "[-]"
    if c.climbing then 
        d = d .. c.climbing .. "\n"
    end 
    if c.consumable then 
        d = d .. c.consumable .. "\n"
    end
    d = d .. "\n[ff2020]Abilities[-]\n"
    for i=1,#c.class.abilities do 
       d = d .. c.class.abilities[i].name .. "\n"
    end
    if has_shield then d = d .. "Guarded\n" end 
    
    -- testing spawn
    local o = spawnObject({
        type = "PlayerPawn",
        position = _pos 
    })
    o.setDescription(d)
    local nm = c.name 
    if nm == nil then nm = c.class.name end 
    nm = nm .. "    [ [a0ffa0]" .. c.cur_vit .. " [-]/ [a0ffa0]" .. c.vit .. " [-]]"
    o.setName(nm)
    o.measure_movement = true 

    local _sc = getObjectFromGUID("2cf58e").getLuaScript()
    o.setLuaScript(_sc)
    o.reload()

    --return d
end

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

ClassAbility = {}
function ClassAbility:new(o)
    o = o or { }
    setmetatable(o, self)
    self.__index = self

    o.name = o.name or ClassAbilityNames[1]
    o.desc = o.desc or AbilitiesDesc[1]

    return o
end
ClassAbilityNames = {
    "Night Stalker", "Killshot", "Camouflaged Climber",
    "Beckon the Swarm", "Stinging Cloud", "Buzzing Mantle",
    "Executioner's Mark", "Finality", "Aim for the Neck",
    "Puncturing Precision", "Forge Master", "Sundering Blow",
    "Rage", "Smash", "Throw", "Eagle's Eye", "Marksman's Focus", "Pinning Shot",
    "Fury", "Devastating Blow", "Opportunist's Cleave", "Gaunt Gallop", 
    "Squire of Mud and Root", "The Shattered Shield", "Shield of the Realm",
    "Inspiring Presence", "Defender's Parry", "Booby Trap", "Set Trap", 
    "Improved Canister", "Determination", "Dirty Dagger", "",
    "Early Bird", "I Can Smell It", "Take the Initiative", "Berserker",
    "Relentless", "Bearing Down", "Heal the Flock", "Last Rites", "Fear of God",
    "","","",
    "Overdraw (Bow)", "Reload (Crossbow)", "Shielded (Shield)",
    "Captain Re-Roll"
}
AbilitiesDesc = { 
    "NIGHT STALKER - The Assassin cannot be attacked until after they ATTACK, PUSH, or Round 4 begins. Until NIGHT STALKER has been expended, enemy models may move over the Assassin as long as they do not land on top of them, and may SCALE climbing items the Assassin occupies.",
    "KILLSHOT - Once per game after a successful COMBAT Check, the Assassin may perform a KILL SHOT that does 4 damage. The Assassin may only use KILL SHOT on a model that has not activated this round and is within 3 inches. This attack ignores DEFENSE rolls.",
    "CAMOUFLAGED CLIMBER - An Assassin only requires a 3+ on SKILL Checks while using the CLIMB action.",
    "BECKON THE SWARM - Once per activation, the Beekeeper may spend an action to BECKON THE SWARM onto an enemy model within 3 inches and within light of sight. That model must roll a DEFENSE Check. If they pass, nothing happens. If they fail, that model becomes Hindered.",
    "STINGING CLOUD - Whenever an enemy model within 2 inches of the Beekeeper causes the Beekeeper to lose VITALITY, that enemy model must pass a SKILL Check or lose 1 VITALITY.",
    "BUZZING MANTLE - Enemy models within 1 inch of the Beekeeper suffer -1 to all COMBAT Checks.",
    "EXECUTIONER'S MARK - Whenever an Executioner declares an ATTACK action targeting an opponent with 2 or less VITALITY, they have +1 COMBAT. In addition, if a COMBAT check succeeds in this manner, the enemy model loses 1 VITALITY bypassing DEFENSE before resolving the rest of the ATTACK.",
    "FINALITY - Any time an Executioner resolves an ATTACK that reduces a model to 0 VITALITY, the Executioner immediately moves up to 2 inches and restores 1 VITALITY.",
    "AIM FOR THE NECK - Any time the Executioner attacks an enemy at full VITALITY, they land a Piercing Blow on both 5s and 6s.",
    "PUNCTURING PRECISION - Once per game, after a successful COMBAT Check, the Blacksmith may use PUNCTURING PRECISION. When they do, the enemy model becomes Breached.",
    "FORGE MASTER - Once per game, the Blacksmith can spend one action to remove the Breached or Sundered status from a friendly model in base contact (including itself).",
    "SUNDERING BLOW - Once per game, after a successful COMBAT Check, the Blacksmith may forgo dealing damage and instead that enemy's weapon becomes Sundered.",
    "RAGE - Once per game a Brute may move up to twice their Movement value and ATTACK with an additional die. This ability requires all of the Brute's actions this turn.",
    "SMASH - Once per game a Brute may SMASH a door, a ladder, an improvised bridge, or a resource cache that they are in base contact with. Remove that item from play. Any models scaling or standing on that item fall.",
    "THROW - Once per game after any successful COMBAT Check, instead of resolving any of their ATTACKS that turn, a Brute may instead pick up and THROW an opposing model they are in base contact with 2 inches in any direction (ignoring Barriers). The opponent becomes Stunned after thrown. Roll for falling damage as normal. THROW may not be used in the same turn as RAGE.",
    "EAGLE'S EYE - The Doom Hunter adds +1 to their Combat stat when targeting models further than 4 inches away.",
    "MARKSMAN'S FOCUS - Once per activation, a Doom Hunter may use MARKSMAN'S FOCUS to ATTACK with an additional die. This ability requires all of the Doom Hunter's actions this turn.",
    "PINNING SHOT - Once per game, after a successful COMBAT Check, the Doom Hunter may forgo dealing damage and instead the enemy model becomes Immobilized until the end of their next activation.",
    "FURY - If the Fighter is in melee range with multiple enemy models, they may spend one action to make a full ATTACK on each of them. This counts as one action regardless of how many enemies are struck. A fighter with multiple attacks from dual wielded light weapons get their bonus attack on each enemy.",
    "DEVASTATING BLOW - Once per game, after a successful COMBAT Check, you may use DEVASTATING BLOW. This attack does 2 additional damage and ignores DEFENSE rolls.",
    "OPPORTUNIST'S CLEAVE - The Fighter gains a bonus ATTACK die when targeting an opponent that has not yet activated. This ability does not stack with other bonus ATTACK die (such as the bonus gained from Concentrated Creeping Death Serum).",
    "GAUNT GALLOP - Anytime the Hedge Knight has performed the DASH Action that brings them in CONTACT with an opposing model, that model makes a SKILL Check. If they fail, they lose 1 VITALITY. If they succeed, the Hedge Knight becomes Hindered.",
    "SQUIRE OF MUD AND ROOT - The Hedge Knight cannot be Immobilized. In addition, anytime the Hedge Knight successfully inspects a resource cache, they only find Food.",
    "THE SHATTERED SHIELD - Once per game, the Hedge Knight can block all damage from one standard ATTACK. This ability must be declared after a successful COMBAT check, but before damage is dealt. This ability can block a Piercing Blow, but cannot block any other special abilities. After using this ability, the Hedge Knight's Shield is destroyed, and wields their Polearm with two hands for the rest of the game.",
    "SHIELD OF THE REALM - Once per game, the Knight can block all damage from one standard ATTACK directed at either them or an ally within 3 inches. This ability must be declared after a successful COMBAT check, but before damage is dealt. It cannot block damage from Special Abilities.",
    "INSPIRING PRESENCE - Any friendly models within 4 inches of the Knight gain +1 to COMBAT checks while in line of sight of the Knight.",
    "DEFENDER'S PARRY - Once per game, when an enemy model fails all COMBAT checks against the Knight during an ATTACK, this Knight may counter them. The enemy model takes 2 damage and becomes Hindered. This ability bypasses DEFENSE.",
    "BOOBY TRAP - The first time an enemy model rolls a 1 or 2 while trying to open a Resource Cache, the Cache explodes dealing 2 damage to that model (this ability is active even after the Saboteur has perished).",
    "SET TRAP - Twice per game, a Saboteur can set a TRAP within 2 inches of them and at least 2 inches from any other model. The TRAP has a 2-inch diameter. Any model that uses MOVE, DASH, or ends an action within that area (even partially) loses 1 VITALITY without a DEFENSE Check, becomes Hindered, and immediately ends the action. Remove the TRAP from play. The Saboteur is immune to their own traps and may use HANDOFF to retrieve them.",
    "IMPROVED CANISTER - Once per game, the Saboteur's IMPROVED CANISTER can be thrown a number of inches equal to their current VITALITY +2. When thrown, the gas canister releases a toxic cloud that covers a 2-inch diameter on one level. All models (enemy or friendly) within the cloud must roll a SKILL Check. If failed, they take 2 damage and are immobilized until the end of their next activation.",
    "DETERMINATION - Once per round, when a Scavenger fails a SKILL Check, they may choose to re-roll that check. They must take the next result.",
    "DIRTY DAGGER - Once per game, the Scavenger may spend an action to use DIRTY DAGGER on an opponent in contact. They take 1 damage and are Stunned. This ability ignores DEFENSE Check.",
    "EARLY BIRD - The Scout may deploy up to 4 inches from the edge of the board on Ground Level. They cannot deploy on a STRUCTURE.",
    "I CAN SMELL IT - After deployment of all Doom Companies, the Scout may deploy an additional resource cache anywhere within 6 inches from the center of the board on a STRUCTURE. The Reliquary cache consumable may not restore this ability.",
    "TAKE THE INITIATIVE - Once per game a player with a living Scout may claim initiative after losing the initiative roll. In addition, if there is ever a tie, initiative always goes to the player with a living Scout. If each player has a Scout, resolve normally.",
    "BERSERKER - If the Reaver begins their activation at 2 or less VITALITY, they get +1 to MOVEMENT and to ATTACKS.",
    "RELENTLESS - If the Reaver uses both MOVE and DASH during their activation and ends in contact with an enemy, they may ATTACK, but with only a single die.",
    "BEARING DOWN - Once per game, after a successful COMBAT Check, the Reaver may forgo dealing damage with that Attack. Instead, the target becomes Immobilized.",
    "HEAL THE FLOCK - Once per round, a Warrior Priest may spend one action to heal a friendly model in base to base contact for 2 VITALITY, or heal itself for 1 VITALITY.",
    "LAST RITES - Once per game, a Warrior Priest may perform LAST RITES within 6 inches of where a friendly model Perished after the Warrior Priest's last activation. That Perished model is revived with 1 VITALITY. Place them exactly where they Perished. This does not cost an action. (Until your Warrior Priest has used LAST RITES, mark where friendly models have Perished until the Warrior Priest finishes their next activation.)",
    "FEAR OF GOD - Once per game, a Warrior Priest may intimidate an enemy within 1 inch instilling the FEAR OF GOD. Push that model 2 inches directly away from the Warrior Priest ignoring Barriers. If that model comes in contact with an edge they fall. They may not make a SKILL Check to prevent themselves from falling. This ability cannot be prevented by a shield.",
        "MM1",
        "MM2",
        "MM3",
    "OVERDRAW (Bow) - Spend 1 action. Doubles the maximum range for your next ranged attack this round.",
    "RELOAD (Crossbow) - After firing, must use the Reload action before firing again.",
    "GUARDED (Shield) - Once per round, the model may use their shield to prevent a PUSH action that targets them.",
    "CAPTAIN REROLL - Once per game, the Captain may re-roll a single die."
}

ClassAbilities = { 
    -- assassin
    NIGHT_STALKER = ClassAbility:new({name=ClassAbilityNames[1],desc=AbilitiesDesc[1]}), KILLSHOT = ClassAbility:new({name=ClassAbilityNames[2],desc=AbilitiesDesc[2]}),CAMOUFLAGED_CLIMBER = ClassAbility:new({name=ClassAbilityNames[3],desc=AbilitiesDesc[3]}),
    -- beekeepr
    BECKON_THE_SWARM = ClassAbility:new({name=ClassAbilityNames[4],desc=AbilitiesDesc[4]}),STINGING_CLOUD = ClassAbility:new({name=ClassAbilityNames[5],desc=AbilitiesDesc[5]}),BUZZING_MANTLE = ClassAbility:new({name=ClassAbilityNames[6],desc=AbilitiesDesc[6]}),
    -- executioner 
    EXECUTIONERS_MARK = ClassAbility:new({name=ClassAbilityNames[7],desc=AbilitiesDesc[7]}),FINALITY = ClassAbility:new({name=ClassAbilityNames[8],desc=AbilitiesDesc[8]}),AIM_FOR_THE_NECK = ClassAbility:new({name=ClassAbilityNames[9],desc=AbilitiesDesc[9]}),
    -- blacksmith 
    PUNCTURING_PRECISION = ClassAbility:new({name=ClassAbilityNames[10],desc=AbilitiesDesc[10]}),FORGE_MASTER = ClassAbility:new({name=ClassAbilityNames[11],desc=AbilitiesDesc[11]}),SUNDERING_BLOW = ClassAbility:new({name=ClassAbilityNames[12],desc=AbilitiesDesc[12]}),
    -- brute 
    RAGE = ClassAbility:new({name=ClassAbilityNames[13],desc=AbilitiesDesc[13]}),SMASH = ClassAbility:new({name=ClassAbilityNames[14],desc=AbilitiesDesc[14]}),THROW = ClassAbility:new({name=ClassAbilityNames[15],desc=AbilitiesDesc[15]}),
    -- doom hunter 
    EAGLES_EYE = ClassAbility:new({name=ClassAbilityNames[16],desc=AbilitiesDesc[16]}),MARKSMANS_FOCUS = ClassAbility:new({name=ClassAbilityNames[17],desc=AbilitiesDesc[17]}),PINNING_SHOT = ClassAbility:new({name=ClassAbilityNames[18],desc=AbilitiesDesc[18]}),
    -- fghter 
    FURY = ClassAbility:new({name=ClassAbilityNames[19],desc=AbilitiesDesc[19]}),DEVASTATING_BLOW = ClassAbility:new({name=ClassAbilityNames[20],desc=AbilitiesDesc[20]}),OPPORTUNISTS_CLEAVE = ClassAbility:new({name=ClassAbilityNames[21],desc=AbilitiesDesc[21]}),
    -- hedge 
    GAUNT_GALLOP = ClassAbility:new({name=ClassAbilityNames[22],desc=AbilitiesDesc[22]}), SQUIRE_OF_MUD_AND_ROOT = ClassAbility:new({name=ClassAbilityNames[23],desc=AbilitiesDesc[23]}),THE_SHATTERED_SHIELD = ClassAbility:new({name=ClassAbilityNames[24],desc=AbilitiesDesc[24]}),
    -- kn 
    SHIELD_OF_THE_REALM = ClassAbility:new({name=ClassAbilityNames[25],desc=AbilitiesDesc[25]}),INSPIRING_PRESENCE = ClassAbility:new({name=ClassAbilityNames[26],desc=AbilitiesDesc[26]}),DEFENDERS_PARRY = ClassAbility:new({name=ClassAbilityNames[27],desc=AbilitiesDesc[27]}),
    -- saboteur 
    BOOBY_TRAP = ClassAbility:new({name=ClassAbilityNames[28],desc=AbilitiesDesc[28]}),SET_TRAP = ClassAbility:new({name=ClassAbilityNames[29],desc=AbilitiesDesc[29]}),IMPROVED_CANISTER = ClassAbility:new({name=ClassAbilityNames[30],desc=AbilitiesDesc[30]}),
    --scavenger 
    DETERMINATION = ClassAbility:new({name=ClassAbilityNames[31],desc=AbilitiesDesc[31]}),DIRTY_DAGGER = ClassAbility:new({name=ClassAbilityNames[32],desc=AbilitiesDesc[32]}),empty_skill_1 = ClassAbility:new({name=ClassAbilityNames[33],desc=AbilitiesDesc[33]}),
    -- scout 
    EARLY_BIRD = ClassAbility:new({name=ClassAbilityNames[34],desc=AbilitiesDesc[34]}),I_CAN_SMELL_IT = ClassAbility:new({name=ClassAbilityNames[35],desc=AbilitiesDesc[35]}),TAKE_THE_INITIATIVE = ClassAbility:new({name=ClassAbilityNames[36],desc=AbilitiesDesc[36]}),
    -- reaver 
    BERSERKER = ClassAbility:new({name=ClassAbilityNames[37],desc=AbilitiesDesc[37]}),RELENTLESS = ClassAbility:new({name=ClassAbilityNames[38],desc=AbilitiesDesc[38]}),BEARING_DOWN = ClassAbility:new({name=ClassAbilityNames[39],desc=AbilitiesDesc[39]}),
    -- wpriest 
    HEAL_THE_FLOCK = ClassAbility:new({name=ClassAbilityNames[40],desc=AbilitiesDesc[40]}),LAST_RITES = ClassAbility:new({name=ClassAbilityNames[41],desc=AbilitiesDesc[41]}),FEAR_OF_GOD = ClassAbility:new({name=ClassAbilityNames[42],desc=AbilitiesDesc[42]}),
    -- mad mule 
    MAD_MULE_1 = ClassAbility:new({name=ClassAbilityNames[43],desc=AbilitiesDesc[43]}),MAD_MULE_2 = ClassAbility:new({name=ClassAbilityNames[44],desc=AbilitiesDesc[44]}),MAD_MULE_3 = ClassAbility:new({name=ClassAbilityNames[45],desc=AbilitiesDesc[45]}),
    -- item abilities 
    BOW_OVERDRAW = ClassAbility:new({name=ClassAbilityNames[46],desc=AbilitiesDesc[46]}), CROSSBOW_RELOAD = ClassAbility:new({name=ClassAbilityNames[47],desc=AbilitiesDesc[47]}), SHIELD_GUARDED = ClassAbility:new({name=ClassAbilityNames[48],desc=AbilitiesDesc[48]}),
    -- etc 
    CAPTAIN_REROLL = ClassAbility:new({name=ClassAbilityNames[49],desc=AbilitiesDesc[49]})
}

DoomClass={}
function DoomClass:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    o.name = o.name or ClassNames.ASSASSIN
    o.stats = o.stats or ClassStats.ASSASSIN
    o.abilities = o.abilities or { ClassAbilities.NIGHT_STALKER, ClassAbilities.KILLSHOT, ClassAbilities.CAMOUFLAGED_CLIMBER }
    o.restrictions = o.restrictions or {}
    
    return o 
end

Classes = { 
    ASSASSIN = DoomClass:new({
        --restrictions = { Weapons.HEAVY_WEAPON, Weapons.POLEARM_1H, Weapons.POLEARM_2H }
    }),
    BEEKEEPER = DoomClass:new({
        name = ClassNames.BEEKEEPER ,
        stats = ClassStats.BEEKEEPER ,
        abilities = { ClassAbilities.BECKON_THE_SWARM, ClassAbilities.STINGING_CLOUD, ClassAbilities.BUZZING_MANTLE }
    }),
    EXECUTIONER = DoomClass:new({
        name = ClassNames.EXECUTIONER,
        stats = ClassStats.EXECUTIONER , 
        abilities = { ClassAbilities.EXECUTIONERS_MARK, ClassAbilities.FINALITY, ClassAbilities.AIM_FOR_THE_NECK }
    }),
    BLACKSMITH = DoomClass:new({
        name = ClassNames.BLACKSMITH ,
        stats = ClassStats.BLACKSMITH ,
        abilities = { ClassAbilities.PUNCTURING_PRECISION, ClassAbilities.FORGE_MASTER, ClassAbilities.SUNDERING_BLOW }
    }),
    BRUTE = DoomClass:new({
        name = ClassNames.BRUTE ,
        stats = ClassStats.BRUTE ,
        abilities = { ClassAbilities.RAGE, ClassAbilities.SMASH, ClassAbilities.THROW }
    }),
    DOOM_HUNTER = DoomClass:new({
        name = ClassNames.DOOM_HUNTER ,
        stats = ClassStats.DOOM_HUNTER ,
        abilities = { ClassAbilities.EAGLES_EYE, ClassAbilities.MARKSMANS_FOCUS, ClassAbilities.PINNING_SHOT }
    }),
    FIGHTER = DoomClass:new({
        name = ClassNames.FIGHTER ,
        stats = ClassStats.FIGHTER ,
        abilities = { ClassAbilities.FURY, ClassAbilities.DEVASTATING_BLOW, ClassAbilities.OPPORTUNISTS_CLEAVE }
    }),
    HEDGE_KNIGHT = DoomClass:new({
        name = ClassNames.HEDGE_KNIGHT ,
        stats = ClassStats.HEDGE_KNIGHT ,
        abilities = { ClassAbilities.GAUNT_GALLOP, ClassAbilities.SQUIRE_OF_MUD_AND_ROOT, ClassAbilities.THE_SHATTERED_SHIELD }
    }),
    KNIGHT = DoomClass:new({
        name = ClassNames.HEDGE_KNIGHT ,
        stats = ClassStats.HEDGE_KNIGHT ,
        abilities = { ClassAbilities.SHIELD_OF_THE_REALM, ClassAbilities.INSPIRING_PRESENCE, ClassAbilities.DEFENDERS_PARRY }
    }),
    SABOTEUR = DoomClass:new({
        name = ClassNames.SABOTEUR ,
        stats = ClassStats.SABOTEUR ,
        abilities = { ClassAbilities.BOOBY_TRAP, ClassAbilities.SET_TRAP, ClassAbilities.IMPROVED_CANISTER }
    }),
    SCAVENGER = DoomClass:new({
        name = ClassNames.SCAVENGER ,
        stats = ClassStats.SCAVENGER ,
        abilities = { ClassAbilities.DETERMINATION, ClassAbilities.DIRTY_DAGGER }
    }),
    SCOUT = DoomClass:new({
        name = ClassNames.SCOUT ,
        stats = ClassStats.SCOUT ,
        abilities = { ClassAbilities.EARLY_BIRD, ClassAbilities.I_CAN_SMELL_IT, ClassAbilities.TAKE_THE_INITIATIVE }
    }),
    REAVER = DoomClass:new({
        name = ClassNames.REAVER ,
        stats = ClassStats.REAVER ,
        abilities = { ClassAbilities.BERSERKER, ClassAbilities.RELENTLESS, ClassAbilities.BEARING_DOWN }
    }),
    WARRIOR_PRIEST = DoomClass:new({
        name = ClassNames.WARRIOR_PRIEST ,
        stats = ClassStats.WARRIOR_PRIEST ,
        abilities = { ClassAbilities.HEAL_THE_FLOCK, ClassAbilities.LAST_RITES, ClassAbilities.FEAR_OF_GOD }
    }),
    MAD_MULE = DoomClass:new({
        name = ClassNames.MAD_MULE,
        stats = ClassStats.MAD_MULE,
        abilities = {  }
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
    o.name = o.name or nil
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
    
    o.GetStats = function()
        local sta = { o.mov, o.atk, o.vit, o.skl, o.def, o.com }
        for i=1,#o.statImprove do 
            if string.find(o.statImprove[i], "MOV") then 
                sta[1] = sta[1] + 1
            elseif string.find(o.statImprove[i], "VIT") then 
                sta[3] = sta[3] + 1
            elseif string.find(o.statImprove[i], "SKL") then 
                sta[4] = sta[4] + 1
            elseif string.find(o.statImprove[i], "DEF") then 
                sta[5] = sta[5] + 1
            elseif string.find(o.statImprove[i], "COM") then 
                sta[6] = sta[6] + 1
            end
        end
        return sta
    end

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

function importArmyOK()
    companies = { DoomCompany:new(), DoomCompany:new() }
    UI.hide("importArmyPanel")
    PopulateDoomCompany(1, currentCompanyURL .. "?tts=1") 
    
    if lastLoadFailed == false then 
        SpawnDoomer(companies[1].warriors[1], {-23, 1, -2})
        SpawnDoomer(companies[1].warriors[2], {-22, 1, -1})
        SpawnDoomer(companies[1].warriors[3], {-24, 1, -1})
    end

    currentCompanyURL = ""
    UI.setAttribute("urlinput", "Text", "")
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

        --      player1             player2

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
    lastLoadFailed = false
    local dc = DoomCompany:new()
    -- Uncomment this in TTS: 
    dc_data = WebRequest.custom(url, "GET", true, "", { ["User-Agent"] = "tts-1490doom" })
    while not dc_data.is_done do 
    end 
    if dc_data.text == ""  then  
        print("Failed to obtain Doom Company data from provided URL.")
        lastLoadFailed = true 
        return 
    end
    jsonData = JSON.decode(dc_data.text)
    if type(jsonData)~=type({}) then 
        print("Failed to obtain Doom Company data from provided URL.")
        lastLoadFailed = true 
        return
    end
    --print(dc_data.text)
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
            else 
                table.insert(companies[player].warriors[i].ipUpgrades, u)
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
