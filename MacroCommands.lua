-- RUIN Codex: macro command reference
-- Less-known macro commands and conditions, each with a working example you
-- can copy into the game's macro window (or add with one click). Written for
-- RUIN; spell and item names in the examples are placeholders to swap for
-- your own. Nothing here runs code: /run, /script and /console are never used.
local ADDON, ns = ...

local list = {}
-- group, command, macro name (16 max), example text, what it does
local function c(group, cmd, name, body, note)
    list[#list + 1] = { group = group, cmd = cmd, n = name, body = body, note = note }
end

-- Targeting ---------------------------------------------------------------
c("Targeting", "/targetenemy [noharm][dead]", "Smart Tab",
    "/targetenemy [noharm][dead]",
    "Tab-targets only when you have no living enemy targeted, so it never drops a target you chose.")
c("Targeting", "/cleartarget [dead]", "Next Live Foe",
    "/cleartarget [dead]\n/targetenemy [noexists]",
    "Clears a dead target and picks the nearest enemy in one press.")
c("Targeting", "/targetexact", "Find Rare",
    "/cleartarget\n/targetexact Mirelow\n/stopmacro [noexists]\n/tm 8",
    "Targets a mob only by its exact name (here Mirelow) and puts a skull on it. Swap in any rare's name.")
c("Targeting", "/tm", "Skull Mouseover",
    "/tm [@mouseover,exists][] 8",
    "Puts a skull on your mouseover, else your target. 1-8 are star, circle, diamond, triangle, moon, square, cross, skull.")
c("Targeting", "/targetlasttarget", "Swap Back",
    "/targetlasttarget",
    "Returns to the target you had before; handy after a quick heal or a sheep.")
c("Targeting", "/targetlastenemy", "Last Enemy",
    "/targetlastenemy",
    "Re-targets the last enemy you had, even after targeting a friend.")
c("Targeting", "/assist", "Assist Mouseover",
    "/assist [@mouseover,help,exists][]",
    "Takes the target of your mouseover friend (or of your target), e.g. to hit what the tank hits.")
c("Targeting", "/targetenemyplayer", "Next Enemy Plr",
    "/targetenemyplayer",
    "Tab-targets enemy players only, skipping pets and NPCs.")
c("Targeting", "/targetparty", "Next Party Mem",
    "/targetparty",
    "Steps through your party members, for healers without unit frames handy.")

-- Casting -----------------------------------------------------------------
c("Casting", "/castsequence reset=", "Sequence",
    "#showtooltip\n/castsequence reset=target/combat Corruption, Curse of Agony, Shadow Bolt",
    "Casts the next spell each press. reset=target starts over on a new target; reset=combat after combat; reset=10 after 10 seconds idle.")
c("Casting", "/stopcasting", "Stop And Kick",
    "#showtooltip Counterspell\n/stopcasting\n/cast Counterspell",
    "Cancels whatever you're casting and interrupts at once.")
c("Casting", "/cast !Spell", "Stay Stealthed",
    "#showtooltip\n/cast !Stealth",
    "The ! never toggles the spell off: pressing again keeps you in Stealth (or a form, or an aura).")
c("Casting", "/stopmacro", "Stop If Dead",
    "#showtooltip Fireball\n/stopmacro [noexists][dead]\n/cast Fireball",
    "Ends the macro early when the conditions match, so the lines after it don't run.")
c("Casting", "/cancelaura", "Drop Buff",
    "/cancelaura Blessing of Protection",
    "Removes one of your buffs by name, e.g. Blessing of Protection so you can attack again.")
c("Casting", "/cancelform", "Leave Form",
    "/cancelform [form]",
    "Drops your shapeshift form, if you're in one.")
c("Casting", "#show", "Icon Only",
    "#show Hearthstone\n/use [nocombat] Hearthstone",
    "#show picks the icon (and cooldown) to display without the item or spell tooltip.")
c("Casting", "/startattack", "Safe Attack",
    "/startattack [harm,nodead]\n/cast [harm,nodead] Sinister Strike",
    "Starts auto attack only on a living enemy, so it never pulls by mistake.")
c("Casting", "/stopattack", "No Break CC",
    "/stopattack\n/cast Polymorph",
    "Stops auto attack first so you don't break your own crowd control.")

-- Conditions --------------------------------------------------------------
c("Conditions", "[mod:shift]", "Shift Swap",
    "#showtooltip\n/cast [mod:shift] Frost Nova; [mod:ctrl] Blink; Frostbolt",
    "Different spells with Shift, Ctrl or Alt held. mod alone means any modifier.")
c("Conditions", "[btn:2]", "Right-click Swap",
    "#showtooltip\n/cast [btn:2] Renew; Flash Heal",
    "Right-clicking the button casts something else than left-clicking.")
c("Conditions", "[@player]", "Self Cast Alt",
    "#showtooltip\n/cast [mod:alt,@player][@mouseover,help,nodead][] Renew",
    "Alt casts on yourself, otherwise on your mouseover friend, otherwise your target.")
c("Conditions", "[@targettarget]", "Heal Tank's Foe",
    "#showtooltip\n/cast [@targettarget,help,nodead] Flash Heal",
    "Target the enemy; this heals whoever it is hitting.")
c("Conditions", "[combat]", "Combat Switch",
    "#showtooltip\n/cast [combat] Shield Wall; Battle Shout",
    "One button, one spell in combat and another out of it.")
c("Conditions", "[group]", "Group Buff",
    "#showtooltip\n/cast [group] Arcane Brilliance; Arcane Intellect",
    "Uses the group version of a buff only when you're in a group. [group:raid] for raids only.")
c("Conditions", "[swimming]", "Water Form",
    "#showtooltip\n/cast [swimming] Aquatic Form; [outdoors] Travel Form; Cat Form",
    "Picks a form by where you are: water, outdoors, or inside.")
c("Conditions", "[stealth]", "Opener",
    "#showtooltip\n/cast [stealth] Cheap Shot; Sinister Strike",
    "Your opener from stealth, your normal attack otherwise.")
c("Conditions", "[channeling]", "No Clipping",
    "#showtooltip\n/cast [nochanneling] Arcane Missiles",
    "Won't restart a channel you're already casting.")
c("Conditions", "[equipped:Shields]", "Shield Check",
    "#showtooltip\n/cast [equipped:Shields] Shield Bash; Pummel",
    "Checks what you're holding: Shields, Two-Hand, Daggers, Bows and so on.")
c("Conditions", "[pet]", "Pet Or Summon",
    "#showtooltip\n/cast [nopet] Summon Imp; [@pet,dead] Summon Imp; Fire Shield",
    "Summons when the pet is missing or dead, otherwise uses the pet's ability.")
c("Conditions", "[exists]", "Mouseover Heal",
    "#showtooltip\n/cast [@mouseover,help,nodead][help,nodead][@player] Lesser Heal",
    "Mouseover first, then target, then yourself: the classic healer pattern.")

-- Items and gear ----------------------------------------------------------
c("Items & gear", "/use <slot>", "Use Gloves",
    "#showtooltip 10\n/use 10",
    "Uses the item in an equipment slot: 10 gloves, 13 and 14 trinkets, 6 belt, 15 cloak.")
c("Items & gear", "/use <bag> <slot>", "First Bag Slot",
    "/use 0 1",
    "Uses whatever is in backpack slot 1 (bag 0); bags 1-4 count from right to left.")
c("Items & gear", "/equipslot", "Shield Swap",
    "/equipslot [noequipped:Shields] 17 Worn Buckler",
    "Puts an item in a slot (17 is the off hand) unless you already hold a shield.")
c("Items & gear", "/equip", "Fishing Pole",
    "/equip [noequipped:Fishing Poles] Fishing Pole\n/cast [equipped:Fishing Poles] Fishing",
    "First press equips the pole, the next one casts.")
c("Items & gear", "/userandom", "Random Pet",
    "/userandom Cat Carrier (Siamese), Parrot Cage (Cockatiel)",
    "Uses one of the listed items at random, for pets and fun items.")
c("Items & gear", "/use [@player]", "Bandage Me",
    "#showtooltip Linen Bandage\n/use [@player] Linen Bandage",
    "Uses an item on yourself without changing your target.")

-- Pet ---------------------------------------------------------------------
c("Pet", "/petattack", "Pet Attack Mo",
    "/petattack [@mouseover,harm,nodead][]",
    "Sends the pet at your mouseover enemy, else your target.")
c("Pet", "/petfollow", "Pet Recall",
    "/petfollow\n/petpassive",
    "Calls the pet back and makes it passive, so it stops pulling.")
c("Pet", "/petdefensive", "Pet Guard",
    "/petdefensive\n/petfollow",
    "Pet back to you, defending you when you're hit.")

-- Group and raid ----------------------------------------------------------
c("Group & raid", "/readycheck", "Ready Check",
    "/readycheck",
    "Starts a ready check (leader or assistant).")
c("Group & raid", "/roll", "Roll 100",
    "/roll",
    "Rolls 1-100 for everyone in your group to see. /roll 1 6 for a die.")
c("Group & raid", "/focus", "Set Focus",
    "/focus [@mouseover,exists][]",
    "Remembers a unit as your focus (where the client supports focus); [@focus] in other macros then means that unit.")
c("Group & raid", "/follow", "Follow Friend",
    "/follow [@mouseover,help][]",
    "Follows your mouseover friend or your target.")

-- Utility -----------------------------------------------------------------
c("Utility", "/dismount", "Dismount Cast",
    "#showtooltip Shoot\n/dismount [mounted]\n/cast Shoot",
    "Gets off your mount and attacks in one press.")
c("Utility", "/click", "Accept Popup",
    "/click StaticPopup1Button1",
    "Presses the first button of the top popup: accept a summon, a resurrection or a duel without the mouse.")
c("Utility", "/sit", "Sit Down",
    "/sit",
    "Sits down, e.g. to drink without moving.")
c("Utility", "/stand", "Stand Up",
    "/stand",
    "Stands up again.")

for _, rec in ipairs(list) do
    rec.c = "CMD"
    rec.tag = "Commands"
    rec.id = ("cmd-" .. rec.n):lower():gsub("[^%w]+", "-"):gsub("%-+$", "")
    rec.rev, rec.by, rec.seed = 1, "RUIN", true
end

ns.MacroCommands = list
ns.MacroCommandGroups = { "All", "Targeting", "Casting", "Conditions", "Items & gear", "Pet", "Group & raid", "Utility" }
