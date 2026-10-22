-- RUIN Codex: class macros
-- Pick your class, read a macro, press Add. The macro goes into your own macro list (never over one you
-- already have) and is put on your cursor so you can drop it on an action bar.
--
-- What the game allows: macros can only be created or changed out of combat, a macro is at most 255
-- characters and a macro name at most 16. Everything here is checked against those limits first.
-- Safety: macros that run code (/run, /script ...) are never accepted; macros that send chat need a
-- confirmation; the exact text is always shown before it is added.
local ADDON, ns = ...
local R = RUIN_API
if not R or (R.apiLevel or 1) < 6 then return end
local W = R.Widgets
local C = W.COLORS

local Mac = {}
ns.Macros = Mac

local MAX_BODY, MAX_NAME = 255, 16
local TAGS = { "Combat", "Utility", "Quality of life", "Leveling", "Raid", "PvP" }
Mac.TAGS, Mac.MAX_BODY, Mac.MAX_NAME = TAGS, MAX_BODY, MAX_NAME
local TAG_ORDER = {}
for i, t in ipairs(TAGS) do TAG_ORDER[t] = i end

local M            -- the Codex module, set by Mac.Init
-- mode: "macros" (class macros) or "commands" (the macro command reference)
local ui = { class = nil, spec = "All specs", tag = "All tags", search = "", sel = nil, confirm = nil,
             mode = "macros", group = "All" }
local lastMessage = {}

local function db()
    return ns.CodexDB and ns.CodexDB() or nil
end

---------------------------------------------------------------------------
-- Checking a macro
---------------------------------------------------------------------------
-- Commands that run code or leave the game: refused everywhere.
local BLOCKED = { run = true, script = true, dump = true, console = true, logout = true, quit = true,
    exit = true, camp = true, reload = true, rl = true, eventtrace = true, etrace = true, tinspect = true,
    fstack = true, scr = true }
-- Commands that send text to other players: allowed, but the player must confirm.
local CHAT = { s = true, say = true, y = true, yell = true, sh = true, shout = true, g = true, guild = true,
    o = true, officer = true, p = true, party = true, raid = true, ra = true, rw = true, i = true, instance = true,
    bg = true, battleground = true, w = true, whisper = true, t = true, tell = true, r = true, reply = true,
    e = true, em = true, emote = true, me = true, chat = true, gen = true, general = true, trade = true,
    channel = true, join = true, invite = true, inv = true, uninvite = true, kick = true, promote = true,
    ginvite = true, gkick = true, duel = true }
for i = 1, 10 do CHAT[tostring(i)] = true end

-- Walks the macro's lines; returns the commands used.
local function commands(body)
    local out = {}
    for line in ((body or "") .. "\n"):gmatch("([^\n]*)\n") do
        local cmd = line:match("^%s*/(%w+)")
        if cmd then out[#out + 1] = cmd:lower() end
    end
    return out
end

-- rec: { n = name, body = text, c = class, tag = tag, ... }
-- Returns { ok, errors = {}, chat = bool, length = n }.
function Mac.Check(rec)
    local errors, chat = {}, false
    local name, body = rec and rec.n, rec and rec.body
    if type(name) ~= "string" or name == "" then
        errors[#errors + 1] = "it has no name"
    elseif #name > MAX_NAME then
        errors[#errors + 1] = ("the name is %d characters; the game allows %d"):format(#name, MAX_NAME)
    elseif name:find("[|%c]") then
        errors[#errors + 1] = "the name has formatting codes"
    end
    if type(body) ~= "string" or body == "" then
        errors[#errors + 1] = "it has no text"
        body = ""
    else
        if #body > MAX_BODY then errors[#errors + 1] = ("the text is %d characters; the game allows %d"):format(#body, MAX_BODY) end
        if body:find("|", 1, true) then errors[#errors + 1] = "the text has formatting codes" end
        if body:find("[%z\1-\9\11-\31]") then errors[#errors + 1] = "the text has control characters" end
        for _, cmd in ipairs(commands(body)) do
            if BLOCKED[cmd] then errors[#errors + 1] = "it uses /" .. cmd .. ", which RUIN never allows in a macro" end
            if CHAT[cmd] then chat = true end
        end
    end
    if rec and rec.tag and not TAG_ORDER[rec.tag] and rec.c ~= "CMD" then errors[#errors + 1] = "unknown tag " .. tostring(rec.tag) end
    return { ok = #errors == 0, errors = errors, chat = chat, length = #body }
end

---------------------------------------------------------------------------
-- Filling in {placeholders}: the best matching item in your bags
---------------------------------------------------------------------------
-- Best first. If none of them is in your bags the fallback name is used and the player is told.
local ITEM_SETS = {
    ["potion:heal"] = { fallback = "Healing Potion", "Major Healing Potion", "Superior Healing Potion", "Greater Healing Potion",
        "Healing Potion", "Lesser Healing Potion", "Minor Healing Potion" },
    ["potion:mana"] = { fallback = "Mana Potion", "Major Mana Potion", "Superior Mana Potion", "Greater Mana Potion",
        "Mana Potion", "Lesser Mana Potion", "Minor Mana Potion" },
    healthstone = { fallback = "Healthstone", "Major Healthstone", "Greater Healthstone", "Healthstone",
        "Lesser Healthstone", "Minor Healthstone" },
    bandage = { fallback = "Linen Bandage", "Heavy Runecloth Bandage", "Runecloth Bandage", "Heavy Mageweave Bandage",
        "Mageweave Bandage", "Heavy Silk Bandage", "Silk Bandage", "Heavy Wool Bandage", "Wool Bandage",
        "Heavy Linen Bandage", "Linen Bandage" },
    drink = { fallback = "Refreshing Spring Water", "Conjured Crystal Water", "Conjured Sparkling Water",
        "Conjured Mineral Water", "Conjured Spring Water", "Conjured Purified Water", "Conjured Fresh Water",
        "Conjured Water", "Morning Glory Dew", "Moonberry Juice", "Sweet Nectar", "Refreshing Spring Water",
        "Ice Cold Milk", "Melon Juice" },
    food = { fallback = "Tough Hunk of Bread", "Conjured Cinnamon Roll", "Conjured Sweet Roll", "Conjured Sourdough",
        "Conjured Pumpernickel", "Conjured Rye", "Conjured Bread", "Conjured Muffin", "Homemade Cherry Pie",
        "Alterac Swiss", "Darnassian Bleu", "Tough Hunk of Bread", "Shiny Red Apple" },
}
Mac.ITEM_SETS = ITEM_SETS
local ITEM_LABEL = { ["potion:heal"] = "healing potion", ["potion:mana"] = "mana potion", healthstone = "healthstone",
    bandage = "bandage", drink = "drink", food = "food" }

-- Names of everything in your bags.
local function bagNames()
    local names = {}
    local CC = C_Container
    local numSlots = (CC and CC.GetContainerNumSlots) or GetContainerNumSlots
    local itemInfo = CC and CC.GetContainerItemInfo
    if not (numSlots and itemInfo) then return names end
    for bag = 0, 5 do
        local ok, n = pcall(numSlots, bag)
        if ok and type(n) == "number" then
            for slot = 1, n do
                local ok2, info = pcall(itemInfo, bag, slot)
                if ok2 and type(info) == "table" then
                    local name = info.itemName or (type(info.hyperlink) == "string" and info.hyperlink:match("%[(.-)%]"))
                    if name then names[name] = true end
                end
            end
        end
    end
    return names
end

-- Returns the text with every placeholder replaced, and a list of the ones that found nothing in your bags.
function Mac.Resolve(body)
    local bags
    local missing = {}
    local text = body:gsub("{([%w:]+)}", function(key)
        local set = ITEM_SETS[key]
        if not set then return nil end
        bags = bags or bagNames()
        for _, name in ipairs(set) do
            if bags[name] then return name end
        end
        missing[#missing + 1] = ITEM_LABEL[key] or key
        return set.fallback
    end)
    return text, missing
end

---------------------------------------------------------------------------
-- Spells
---------------------------------------------------------------------------
function Mac.KnowsSpell(name)
    local f = (C_Spell and C_Spell.GetSpellInfo) or GetSpellInfo
    if not f then return true end   -- can't tell on this client: don't block anything
    local ok, res = pcall(f, name)
    return ok and res ~= nil
end

-- The spells this macro needs that you have not learned.
function Mac.MissingSpells(rec)
    local out = {}
    for _, spell in ipairs(rec.req or {}) do
        if not Mac.KnowsSpell(spell) then out[#out + 1] = spell end
    end
    return out
end

---------------------------------------------------------------------------
-- The library
---------------------------------------------------------------------------
local function library()
    return ns.MacroSeed or {}
end

function Mac.Get(id)
    for _, rec in ipairs(library()) do if rec.id == id then return rec end end
    for _, rec in ipairs(ns.MacroCommands or {}) do if rec.id == id then return rec end end
    return nil
end

-- The command reference, by group ("All" for every one) and search text.
function Mac.Commands(group, search)
    local out = {}
    search = (search or ""):lower()
    for _, rec in ipairs(ns.MacroCommands or {}) do
        local ok = (group == nil or group == "All" or rec.group == group)
        if ok and search ~= "" then
            ok = rec.cmd:lower():find(search, 1, true) or rec.n:lower():find(search, 1, true)
                or (rec.note or ""):lower():find(search, 1, true) or rec.body:lower():find(search, 1, true)
        end
        if ok then out[#out + 1] = rec end
    end
    return out
end

-- Macros for a class: its own, then the shared ones. class "SHARED" = shared only.
function Mac.For(class, spec, tag, search)
    local out = {}
    search = (search or ""):lower()
    for _, rec in ipairs(library()) do
        local ok = (rec.c == class) or (rec.c == "ALL")
        if class == "SHARED" then ok = rec.c == "ALL" end
        if ok and spec and spec ~= "All specs" and rec.s and rec.s ~= spec then ok = false end
        if ok and tag and tag ~= "All tags" and rec.tag ~= tag then ok = false end
        if ok and search ~= "" then
            ok = rec.n:lower():find(search, 1, true) or (rec.note or ""):lower():find(search, 1, true)
                or rec.body:lower():find(search, 1, true)
        end
        if ok then out[#out + 1] = rec end
    end
    table.sort(out, function(a, b)
        local ac, bc = (a.c == "ALL") and 1 or 0, (b.c == "ALL") and 1 or 0
        if ac ~= bc then return ac < bc end
        local at, bt = TAG_ORDER[a.tag] or 99, TAG_ORDER[b.tag] or 99
        if at ~= bt then return at < bt end
        return a.n < b.n
    end)
    return out
end

---------------------------------------------------------------------------
-- The game's macro list
---------------------------------------------------------------------------
local function limits()
    return MAX_ACCOUNT_MACROS or 120, MAX_CHARACTER_MACROS or 30
end

local function hashText(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return h
end
Mac.Hash = hashText

-- All the player's macros: { index, name, body, perChar }.
local function scan()
    local out = {}
    if not (GetNumMacros and GetMacroInfo) then return out, 0, 0 end
    local nAcc, nChar = GetNumMacros()
    nAcc, nChar = tonumber(nAcc) or 0, tonumber(nChar) or 0
    local maxAcc = limits()
    for i = 1, nAcc do
        local ok, name, _, body = pcall(GetMacroInfo, i)
        if ok and name then out[#out + 1] = { index = i, name = name, body = body or "", perChar = false } end
    end
    for i = maxAcc + 1, maxAcc + nChar do
        local ok, name, _, body = pcall(GetMacroInfo, i)
        if ok and name then out[#out + 1] = { index = i, name = name, body = body or "", perChar = true } end
    end
    return out, nAcc, nChar
end

local function findByName(list, name)
    for _, m in ipairs(list) do if m.name == name then return m end end
    return nil
end

-- Where is a macro this addon added? (Macros are sorted by name, so the number changes; look it up by name.)
local function findInstalled(id)
    local d = db()
    local inst = d and d.installed and d.installed[id]
    if not inst then return nil end
    local m = findByName(scan(), inst.name)
    if not m then
        d.installed[id] = nil   -- the player deleted it
        return nil
    end
    inst.index = m.index
    return m, inst
end

function Mac.IsInstalled(id) return findInstalled(id) ~= nil end

-- Free names: "Name", then "Name 2" ... within the 16-character limit.
local function freeName(base, list)
    if not findByName(list, base) then return base end
    for n = 2, 99 do
        local suffix = " " .. n
        local name = base:sub(1, MAX_NAME - #suffix) .. suffix
        if not findByName(list, name) then return name end
    end
    return nil
end

---------------------------------------------------------------------------
-- Adding a macro
---------------------------------------------------------------------------
-- Returns status, message[, what]. Statuses:
--   created  the macro was added and put on your cursor
--   pickup   you already had it: it is on your cursor
--   queued   in combat: it will be added when combat ends
--   confirm  needs a yes first (what = "chat", "spells", "items" or "copy")
--   copied   this client cannot create macros: the text is in a copy box
--   refused  not added (the message says why)
-- confirmed: { chat = true, spells = true, items = true, copy = true } for answers already given.
local pendingAdd
function Mac.Add(id, perChar, confirmed)
    confirmed = confirmed or {}
    local rec = Mac.Get(id)
    if not rec then return "refused", "That macro is not in the library." end
    local check = Mac.Check(rec)
    if not check.ok then return "refused", "Not added: " .. check.errors[1] .. "." end
    local body, missingItems = Mac.Resolve(rec.body)
    if #body > MAX_BODY then
        return "refused", ("Not added: with your item names filled in the text is %d characters; the game allows %d."):format(#body, MAX_BODY)
    end

    if InCombatLockdown and InCombatLockdown() then
        pendingAdd = { id = id, perChar = perChar, confirmed = confirmed }
        return "queued", "In combat. The macro will be added when combat ends."
    end

    if not (CreateMacro and GetNumMacros and GetMacroInfo) then
        R:ShowText(rec.n, "This game client can't add macros for you. Copy the text into a new macro.", body, nil, true)
        return "copied", "This client can't add macros: the text is in the copy box."
    end

    local mine = findInstalled(id)
    if mine then
        if PickupMacro then pcall(PickupMacro, mine.index) end
        return "pickup", ("You already have \"%s\". It is on your cursor."):format(mine.name)
    end

    if check.chat and not confirmed.chat then
        return "confirm", "This macro sends chat messages. Add it anyway?", "chat"
    end
    local missingSpells = Mac.MissingSpells(rec)
    if #missingSpells > 0 and not confirmed.spells then
        return "confirm", "You have not learned " .. table.concat(missingSpells, ", ") .. ". Add it anyway?", "spells"
    end
    if #missingItems > 0 and not confirmed.items then
        return "confirm", "No " .. table.concat(missingItems, " or ") .. " in your bags. The macro will use a common one. Add it anyway?", "items"
    end

    local list, nAcc, nChar = scan()
    local maxAcc, maxChar = limits()
    local name = rec.n
    local same = findByName(list, name)
    if same then
        if same.body == body then
            -- already there, same text: adopt it
            local d = db()
            if d then d.installed[id] = { index = same.index, name = same.name, rev = rec.rev or 1, hash = hashText(body), perChar = same.perChar } end
            if PickupMacro then pcall(PickupMacro, same.index) end
            return "pickup", ("You already had \"%s\". It is on your cursor."):format(same.name)
        end
        if not confirmed.copy then
            return "confirm", ("You already have a different macro called \"%s\". Add this one as a copy?"):format(name), "copy"
        end
        name = freeName(name, list)
        if not name then return "refused", "Could not find a free name for this macro." end
    end

    if perChar and nChar >= maxChar then
        return "refused", ("Your character macros are full (%d of %d). Delete one first."):format(nChar, maxChar)
    elseif not perChar and nAcc >= maxAcc then
        return "refused", ("Your account macros are full (%d of %d). Delete one first."):format(nAcc, maxAcc)
    end

    local ok, index = pcall(CreateMacro, name, rec.icon or 134400, body, perChar and true or false)
    if not ok or not index then return "refused", "The game would not create the macro." end
    local d = db()
    if d then d.installed[id] = { index = index, name = name, rev = rec.rev or 1, hash = hashText(body), perChar = perChar and true or false } end
    if PickupMacro then pcall(PickupMacro, index) end
    return "created", ("Added \"%s\" to your %s macros. It is on your cursor: drop it on an action bar."):format(name, perChar and "character" or "account")
end

-- Runs a queued add once combat ends.
local function afterCombat()
    local p = pendingAdd
    pendingAdd = nil
    if not p then return end
    local status, msg = Mac.Add(p.id, p.perChar, p.confirmed)
    lastMessage[p.id] = msg
    if M then M:Print(msg) end
end

function Mac.Pending() return pendingAdd end

function Mac.Slots()
    local _, nAcc, nChar = scan()
    local maxAcc, maxChar = limits()
    return nAcc, maxAcc, nChar, maxChar
end

---------------------------------------------------------------------------
-- Status shown in the list
---------------------------------------------------------------------------
-- "installed", "needs" (with the spell), or nil
function Mac.Status(rec)
    if Mac.IsInstalled(rec.id) then return "installed" end
    local missing = Mac.MissingSpells(rec)
    if #missing > 0 then return "needs", missing[1] end
    return nil
end

---------------------------------------------------------------------------
-- The page
---------------------------------------------------------------------------
local function helpers() return ns.CodexHelpers or {} end

local function classOptions()
    local list = {}
    for _, c in ipairs(helpers().CLASSES or {}) do list[#list + 1] = c end
    list[#list + 1] = "SHARED"
    return list
end

local function specOptions()
    local out = { "All specs" }
    for _, s in ipairs((ns.SpecOrder and ns.SpecOrder[ui.class]) or {}) do out[#out + 1] = s end
    return out
end

local refresh = function() end

local function selected()
    return ui.sel and Mac.Get(ui.sel) or nil
end

local function act(perChar, confirmed)
    local rec = selected()
    if not rec then return end
    local status, msg, what = Mac.Add(rec.id, perChar, confirmed)
    lastMessage[rec.id] = msg
    if status == "confirm" then
        ui.confirm = { id = rec.id, perChar = perChar, what = what, text = msg, answers = confirmed or {} }
    else
        ui.confirm = nil
    end
    refresh()
end

local function buildDetail(page)
    local card = W.Card(page)
    card:SetPoint("TOPLEFT", 290, -48)
    card:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -4, 30)
    ui.card = card

    ui.dName = W.Label(card, "", "GameFontNormalLarge")
    ui.dName:SetPoint("TOPLEFT", 12, -10)
    ui.dTag = W.Pill(card, 112)
    ui.dTag:SetPoint("TOPLEFT", 12, -36)
    ui.dStatus = W.Pill(card, 130)
    ui.dStatus:SetPoint("LEFT", ui.dTag, "RIGHT", 6, 0)
    ui.dNote = W.Label(card, "", "GameFontHighlightSmall")
    ui.dNote:SetPoint("TOPLEFT", 12, -60)
    ui.dNote:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    ui.dNote:SetWordWrap(true)

    ui.dBox = CreateFrame("Frame", nil, card)
    ui.dBox:SetPoint("TOPLEFT", 12, -96)
    ui.dBox:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    ui.dBox:SetHeight(104)
    W.Skin(ui.dBox, "bg", 1, "border")
    ui.dBody = W.Label(ui.dBox, "", "ChatFontNormal")
    ui.dBody:SetPoint("TOPLEFT", 8, -8)
    ui.dBody:SetPoint("RIGHT", ui.dBox, "RIGHT", -8, 0)
    ui.dBody:SetWordWrap(true)
    ui.dBody:SetJustifyV("TOP")

    ui.dCount = W.Label(card, "", "GameFontHighlightSmall")
    ui.dCount:SetPoint("TOPLEFT", ui.dBox, "BOTTOMLEFT", 2, -4)
    ui.dWarn = W.Label(card, "", "GameFontHighlightSmall")
    ui.dWarn:SetPoint("TOPLEFT", ui.dCount, "BOTTOMLEFT", 0, -6)
    ui.dWarn:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    ui.dWarn:SetWordWrap(true)

    ui.dAsk = W.Label(card, "", "GameFontNormalSmall")
    ui.dAsk:SetPoint("BOTTOMLEFT", 12, 76)
    ui.dAsk:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    ui.dAsk:SetWordWrap(true)
    ui.dYes = W.Button(card, "Yes, add it", 100, function()
        local c = ui.confirm
        if not c then return end
        local answers = c.answers
        answers[c.what] = true
        act(c.perChar, answers)
    end)
    ui.dYes:SetPoint("BOTTOMLEFT", 12, 48)
    ui.dNo = W.Button(card, "Cancel", 70, function() ui.confirm = nil; refresh() end)
    ui.dNo:SetPoint("LEFT", ui.dYes, "RIGHT", 6, 0)

    ui.dMsg = W.Label(card, "", "GameFontHighlightSmall")
    ui.dMsg:SetPoint("BOTTOMLEFT", 12, 44)
    ui.dMsg:SetPoint("RIGHT", card, "RIGHT", -12, 0)
    ui.dMsg:SetWordWrap(true)

    ui.bAcc = W.Button(card, "Add to account", 118, function() act(false) end)
    ui.bAcc:SetPoint("BOTTOMLEFT", 12, 12)
    ui.bChar = W.Button(card, "Add to character", 128, function() act(true) end)
    ui.bChar:SetPoint("LEFT", ui.bAcc, "RIGHT", 6, 0)
    ui.bCopy = W.Button(card, "Copy text", 86, function()
        local rec = selected()
        if rec then R:ShowText(rec.n, "Copy with Ctrl+C, then paste into a new macro.", (Mac.Resolve(rec.body)), nil, true) end
    end)
    ui.bCopy:SetPoint("LEFT", ui.bChar, "RIGHT", 6, 0)
end

local function refreshDetail()
    local rec = selected()
    local asking = ui.confirm and ui.confirm.id == (rec and rec.id)
    if not rec then
        ui.dName:SetText(C.dim .. "Pick a macro on the left.|r")
        ui.dTag:Hide(); ui.dStatus:Hide()
        ui.dNote:SetText(""); ui.dBody:SetText(""); ui.dCount:SetText(""); ui.dWarn:SetText("")
        ui.dAsk:SetText(""); ui.dYes:Hide(); ui.dNo:Hide(); ui.dMsg:SetText("")
        ui.bAcc:SetEnabled(false); ui.bChar:SetEnabled(false); ui.bCopy:SetEnabled(false)
        return
    end
    ui.dName:SetText(rec.cmd and (rec.cmd .. C.dim .. "   example macro: " .. rec.n .. "|r") or rec.n)
    ui.dTag:SetTag("Group", rec.group or rec.tag)
    local status, spell = Mac.Status(rec)
    if status == "installed" then
        ui.dStatus:SetTag("Verified", "Installed")
    elseif status == "needs" then
        ui.dStatus:SetTag("Unverified", "Needs " .. spell)
    else
        ui.dStatus:Hide()
    end
    ui.dNote:SetText((rec.note or "") .. (((rec.s or rec.c ~= "ALL") and rec.c ~= "CMD") and (C.dim .. "  " .. (rec.s and (rec.s .. " ") or "") .. (rec.c == "ALL" and "" or rec.c:lower()) .. "|r") or ""))
    local text, missingItems = Mac.Resolve(rec.body)
    local check = Mac.Check(rec)
    ui.dBody:SetText(text)
    local over = #text > MAX_BODY
    ui.dCount:SetText((over and C.bad or C.dim) .. ("%d / %d characters|r"):format(#text, MAX_BODY))
    local warn = {}
    if check.chat then warn[#warn + 1] = C.warn .. "Sends chat messages.|r" end
    if #missingItems > 0 then warn[#warn + 1] = C.warn .. "No " .. table.concat(missingItems, " or ") .. " in your bags; a common one is used.|r" end
    if not check.ok then warn[#warn + 1] = C.bad .. "Can't be added: " .. check.errors[1] .. ".|r" end
    ui.dWarn:SetText(table.concat(warn, "  "))
    ui.dAsk:SetText(asking and (C.gold .. ui.confirm.text .. "|r") or "")
    ui.dYes:SetShown(asking)
    ui.dNo:SetShown(asking)
    ui.dMsg:SetText((not asking) and (lastMessage[rec.id] or "") or "")
    local can = check.ok and not asking
    ui.bAcc:SetEnabled(can); ui.bChar:SetEnabled(can); ui.bCopy:SetEnabled(true)
end

local function buildFilters(page)
    -- Class macros | Commands
    ui.modeBtns = {}
    for i, m in ipairs({ { "macros", "Class macros", 106 }, { "commands", "Commands", 92 } }) do
        local b = W.Button(page, m[2], m[3], function()
            if ui.mode ~= m[1] then ui.mode = m[1]; ui.sel = nil; ui.confirm = nil; ui.search = ""; ui.searchBox:SetText("") end
            refresh()
        end)
        b:SetPoint("TOPLEFT", i == 1 and 0 or 110, 2)
        ui.modeBtns[m[1]] = b
    end
    local opts = classOptions()
    ui.clsBtn = W.Cycle(page, 116, opts, function() return ui.class end, function(v)
        ui.class = v
        ui.spec = "All specs"
        refresh()
    end)
    ui.clsBtn.format = ns.ClassLabel
    ui.clsBtn.tipTitle = "Show macros for a class (All classes = shared ones)"
    ui.clsBtn:SetPoint("TOPLEFT", 216, 2)
    ui.specBtn = W.MarkChoice(W.Button(page, "", 134, nil))
    ui.specBtn:SetPoint("LEFT", ui.clsBtn, "RIGHT", 4, 0)
    ui.specBtn:SetScript("OnClick", function(_, mouse)
        local list = specOptions()
        local idx = 1
        for i, s in ipairs(list) do if s == ui.spec then idx = i end end
        idx = (mouse == "RightButton") and ((idx - 2) % #list + 1) or (idx % #list + 1)
        ui.spec = list[idx]
        refresh()
    end)
    local tagOpts = { "All tags" }
    for _, t in ipairs(TAGS) do tagOpts[#tagOpts + 1] = t end
    ui.tagBtn = W.Cycle(page, 118, tagOpts, function() return ui.tag end, function(v) ui.tag = v; refresh() end)
    ui.tagBtn:SetPoint("LEFT", ui.specBtn, "RIGHT", 4, 0)
    ui.groupBtn = W.Dropdown(page, 150, ns.MacroCommandGroups or { "All" }, function() return ui.group end,
        function(v) ui.group = v; refresh() end, "Show: ")
    ui.groupBtn.tipTitle = "What kind of command"
    ui.groupBtn:SetPoint("TOPLEFT", 216, 2)
    ui.searchBox = W.EditBox(page, 140, function(text) ui.search = text or ""; refresh() end, "Search")
    ui.searchBox:SetPoint("TOPRIGHT", page, "TOPRIGHT", -4, 1)

    ui.info = W.Label(page, "", "GameFontHighlightSmall")
    ui.info:SetPoint("TOPLEFT", 0, -26)
    ui.info:SetPoint("RIGHT", page, "RIGHT", -6, 0)
end

local function buildList(page)
    ui.list = W.List(page, 26, function(row)
        row.name = W.Label(row, "")
        row.name:SetPoint("LEFT", 8, 0)
        row.name:SetWidth(160)
        row.name:SetWordWrap(false)
        row.stat = W.Label(row, "", "GameFontHighlightSmall")
        row.stat:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.stat:SetWidth(90)
        row.stat:SetJustifyH("RIGHT")
        row.stat:SetWordWrap(false)
        row:SetScript("OnMouseUp", function(self)
            if self.rec then ui.sel = self.rec.id; ui.confirm = nil; refresh() end
        end)
    end, function(row, rec)
        row.rec = rec
        local on = ui.sel == rec.id
        row.name:SetText((on and C.gold or C.white) .. (rec.cmd or rec.n) .. "|r")
        local status, spell = Mac.Status(rec)
        if status == "installed" then
            row.stat:SetText(W.TagText("Verified", "Installed"))
        elseif status == "needs" then
            row.stat:SetText(W.TagText("Unverified", "Needs spell"))
        else
            row.stat:SetText(C.dim .. (rec.group or rec.tag) .. "|r")
        end
        row.tip = function(tip)
            tip:AddLine(rec.cmd or rec.n, 1, 0.82, 0)
            if rec.note then tip:AddLine(rec.note, 1, 1, 1, true) end
            if status == "needs" then tip:AddLine("You have not learned " .. spell .. ".", 1, 0.5, 0.3) end
        end
    end)
    ui.list:SetEmptyText("No macros match. Try another spec or tag.")
    ui.list.frame:SetPoint("TOPLEFT", 0, -48)
    ui.list.frame:SetPoint("BOTTOMLEFT", page, "BOTTOMLEFT", 0, 30)
    ui.list.frame:SetWidth(272)
end

local function buildFooter(page)
    ui.slotText = W.Label(page, "", "GameFontHighlightSmall")
    ui.slotText:SetPoint("BOTTOMLEFT", 0, 8)
    ui.accBar = W.Progress(page, 110, 8)
    ui.accBar:SetPoint("BOTTOMLEFT", 270, 8)
    ui.charBar = W.Progress(page, 110, 8)
    ui.charBar:SetPoint("LEFT", ui.accBar, "RIGHT", 90, 0)
    ui.accLabel = W.Label(page, "", "GameFontHighlightSmall")
    ui.accLabel:SetPoint("LEFT", ui.accBar, "RIGHT", 6, 0)
    ui.charLabel = W.Label(page, "", "GameFontHighlightSmall")
    ui.charLabel:SetPoint("LEFT", ui.charBar, "RIGHT", 6, 0)
end

function Mac.Build(page, onChange)
    ui.page = page
    buildFilters(page)
    buildList(page)
    buildDetail(page)
    buildFooter(page)
    refresh = function()
        if not ui.page or not ui.page:IsVisible() then return end
        Mac.Refresh()
    end
    if onChange then ui.onChange = onChange end
end

function Mac.SetMode(mode)
    if mode == "commands" or mode == "macros" then
        if ui.mode ~= mode then ui.sel, ui.confirm = nil, nil end
        ui.mode = mode
    end
end

function Mac.Refresh()
    local h = helpers()
    local cmds = ui.mode == "commands"
    for m, b in pairs(ui.modeBtns) do if m == ui.mode then b:LockHighlight() else b:UnlockHighlight() end end
    ui.clsBtn:SetShown(not cmds); ui.specBtn:SetShown(not cmds); ui.tagBtn:SetShown(not cmds)
    ui.groupBtn:SetShown(cmds)
    ui.searchBox:SetPlaceholder(cmds and "Search commands" or "Search macros")
    ui.class = ui.class or (h.myClass and h.myClass()) or "WARRIOR"
    ui.clsBtn.Refresh()
    ui.specBtn:SetText(ui.spec)
    ui.tagBtn.Refresh()
    ui.groupBtn:Refresh()
    local items = cmds and Mac.Commands(ui.group, ui.search) or Mac.For(ui.class, ui.spec, ui.tag, ui.search)
    ui.list:SetItems(items)
    local found = false
    for _, rec in ipairs(items) do if rec.id == ui.sel then found = true end end
    if not found then
        ui.sel = items[1] and items[1].id or nil
        ui.confirm = nil
    end
    ui.info:SetText(C.dim .. (cmds and ("%d commands and conditions, each with an example. Copy the text into the game's macro window (/macro), or Add it."):format(#items)
        or ("%d macros. Pick one, read it, then Add. It goes in your own macro list; nothing you already have is changed."):format(#items)) .. "|r")
    refreshDetail()
    local nAcc, maxAcc, nChar, maxChar = Mac.Slots()
    ui.slotText:SetText(C.dim .. "Your macro slots|r")
    ui.accBar:SetValue(maxAcc > 0 and nAcc / maxAcc or 0)
    ui.charBar:SetValue(maxChar > 0 and nChar / maxChar or 0)
    ui.accBar:SetColor(nAcc >= maxAcc and "bad" or "good")
    ui.charBar:SetColor(nChar >= maxChar and "bad" or "good")
    ui.accLabel:SetText(("%sAccount %d/%d|r"):format(C.dim, nAcc, maxAcc))
    ui.charLabel:SetText(("%sCharacter %d/%d|r"):format(C.dim, nChar, maxChar))
end

-- Select a macro and show it (used by links from other pages).
function Mac.Show(id)
    local rec = Mac.Get(id)
    if not rec then return false end
    ui.class = (rec.c == "ALL") and "SHARED" or rec.c
    ui.spec, ui.tag, ui.search = "All specs", "All tags", ""
    ui.mode = rec.c == "CMD" and "commands" or "macros"
    ui.group = "All"
    ui.sel = id
    return true
end

function Mac.Init(module)
    M = module
    M:RegisterEvent("PLAYER_REGEN_ENABLED", afterCombat)
end
