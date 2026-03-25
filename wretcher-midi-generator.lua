-- @description Dead Pixel Drum Apparatus
-- @author David W. Russell III / Dead Pixel Design
-- @version 1.7.0
-- @changelog
--   v1.7.0: Capture engine now records all kit pieces (hi-hats, rides, toms, crashes, cymbals). Captured grooves play back exactly as recorded, bypassing the power hand.
--   v1.6.0: Added Diagnostic Pitch Scanner to alert users of exact timeline pitch mismatches.
--   v1.5.2: Overhauled timeline capture to support layered MIDI overdubs and early humanized notes.
--   v1.5.0: Fixed custom groove playback speed limitations. Capture engine calculates exact grid timing.
-- @website https://www.deadpixeldesign.com

if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox("This script requires the ReaImGui extension.\nInstall it via ReaPack: Extensions > ReaImGui.", "Dead Pixel Drum Apparatus", 0)
    return
end
local ctx = reaper.ImGui_CreateContext('Dead Pixel Drum Apparatus v1.7.0')
reaper.atexit(function()
    if reaper.ImGui_DestroyContext then reaper.ImGui_DestroyContext(ctx) end
end)
local ImGui_SeparatorText = reaper.ImGui_SeparatorText or function(c, label)
    reaper.ImGui_Separator(c)
    reaper.ImGui_Text(c, label)
end

-- =============================================
-- UTILITIES
-- =============================================
local function DeepCopy(orig)
    if type(orig) ~= 'table' then return orig end
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = type(v) == 'table' and DeepCopy(v) or v
    end
    return copy
end

-- =============================================
-- VST MIDI MAPS
-- =============================================
local MIDI_MAPS = {
    {
        name = "Odeholm Default (Wretcher Fix)",
        map = {
            KICK_R = 36, KICK_L = 35, SNARE = 38, SNARE_FLAM = 39, SNARE_RIM = 40, SNARE_GHOST = 38,
            TOM_1 = 47, TOM_2 = 45, TOM_3 = 43, TOM_4 = 41,
            HH_OPEN_1 = 50, HH_OPEN_2 = 49, HH_OPEN_3 = 48,
            HH_CLOSED_TIP = 51, HH_CLOSED_EDGE = 52, HH_PEDAL = 53,
            RIDE_TIP = 58, RIDE_BELL = 59, RIDE_CRASH = 60,
            CRASH_L = 54, CRASH_R = 56, BIG_CRASH = 61,
            CHINA_L = 63, CHINA_R = 65, STACK = 67,
            SPLASH_L = 68, SPLASH_R = 70, BELL = 72
        }
    },
    {
        name = "RS Monarch",
        map = {
            KICK_R = 24, KICK_L = 24, SNARE = 26, SNARE_FLAM = 27, SNARE_RIM = 28, SNARE_GHOST = 30,
            TOM_1 = 38, TOM_2 = 37, TOM_3 = 36, TOM_4 = 35,
            HH_OPEN_1 = 45, HH_OPEN_2 = 46, HH_OPEN_3 = 47,
            HH_CLOSED_TIP = 41, HH_CLOSED_EDGE = 42, HH_PEDAL = 40,
            RIDE_TIP = 62, RIDE_BELL = 63, RIDE_CRASH = 61,
            CRASH_L = 49, CRASH_R = 54, BIG_CRASH = 58,
            CHINA_L = 56, CHINA_R = 56, STACK = 60,
            SPLASH_L = 51, SPLASH_R = 51, BELL = 53
        }
    },
    {
        name = "Ultimate Heavy Drums (MDL Tone)",
        map = {
            KICK_R = 36, KICK_L = 35, SNARE = 38, SNARE_FLAM = 38, SNARE_RIM = 38, SNARE_GHOST = 38,
            TOM_1 = 48, TOM_2 = 47, TOM_3 = 45, TOM_4 = 43,
            HH_OPEN_1 = 59, HH_OPEN_2 = 60, HH_OPEN_3 = 60,
            HH_CLOSED_TIP = 62, HH_CLOSED_EDGE = 61, HH_PEDAL = 44,
            RIDE_TIP = 51, RIDE_BELL = 53, RIDE_CRASH = 51,
            CRASH_L = 49, CRASH_R = 57, BIG_CRASH = 66,
            CHINA_L = 71, CHINA_R = 52, STACK = 71,
            SPLASH_L = 55, SPLASH_R = 69, BELL = 53
        }
    },
    {
        name = "Sleep Token II by MixWave",
        map = {
            KICK_R = 36, KICK_L = 35, SNARE = 38, SNARE_FLAM = 37, SNARE_RIM = 40, SNARE_GHOST = 25,
            TOM_1 = 50, TOM_2 = 47, TOM_3 = 43, TOM_4 = 41,
            HH_OPEN_1 = 77, HH_OPEN_2 = 78, HH_OPEN_3 = 64,
            HH_CLOSED_TIP = 75, HH_CLOSED_EDGE = 76, HH_PEDAL = 44,
            RIDE_TIP = 49, RIDE_BELL = 60, RIDE_CRASH = 59,
            CRASH_L = 49, CRASH_R = 57, BIG_CRASH = 54,
            CHINA_L = 95, CHINA_R = 95, STACK = 54,
            SPLASH_L = 55, SPLASH_R = 55, BELL = 53
        }
    }
}

local current_map_idx = 1
local M = DeepCopy(MIDI_MAPS[current_map_idx].map)

local function UpdateMap() M = DeepCopy(MIDI_MAPS[current_map_idx].map) end

local map_keys_ordered = {
    "KICK_R", "KICK_L", "SNARE", "SNARE_FLAM", "SNARE_RIM", "SNARE_GHOST",
    "TOM_1", "TOM_2", "TOM_3", "TOM_4",
    "HH_CLOSED_TIP", "HH_CLOSED_EDGE", "HH_OPEN_1", "HH_OPEN_2", "HH_OPEN_3", "HH_PEDAL",
    "RIDE_TIP", "RIDE_BELL", "RIDE_CRASH",
    "CRASH_L", "CRASH_R", "BIG_CRASH",
    "CHINA_L", "CHINA_R", "STACK",
    "SPLASH_L", "SPLASH_R", "BELL"
}

-- =============================================
-- MASTER GROOVE LIBRARY
-- =============================================
local groove_library = {
    {
        category = "DEATH METAL",
        grooves = {
            { name = "Standard 16th Stream",     kick = "KKKKKKKKKKKKKKKK", snare = "----S-------S---" },
            { name = "The Gallop",               kick = "K-kkK-kkK-kkK-kk", snare = "----S-------S---" },
            { name = "Tech Death Pulse",         kick = "K-K-K-K-KKKKKKKK", snare = "----S-------S---" },
            { name = "Hammer Blast",             kick = "KKKKKKKKKKKKKKKK", snare = "S-S-S-S-S-S-S-S-" },
        }
    },
    {
        category = "SLAM DEATH",
        grooves = {
            { name = "Slam Breakdown (Lurch)",   kick = "K-k-K--k-K-k-K--", snare = "--------S-------" },
            { name = "Bomb Blast",               kick = "KKKKKKKKKKKKKKKK", snare = "S---S---S---S---" },
            { name = "Stuttered Double Kick",    kick = "KK-K---KK-K---K-", snare = "----S-------S---" },
            { name = "Half-Time Crushing",       kick = "K---K-K-----K---", snare = "--------S-------" },
        }
    },
    {
        category = "BLACK METAL",
        grooves = {
            { name = "Traditional Blast",        kick = "KKKKKKKKKKKKKKKK", snare = "S-S-S-S-S-S-S-S-" },
            { name = "Norsecore (Primitive)",    kick = "K-------K-------", snare = "----S-------S---" },
            { name = "D-Beat (Black 'n' Roll)",  kick = "K---K-K---K-K---", snare = "----S-------S---" },
        }
    },
    {
        category = "GRINDCORE",
        grooves = {
            { name = "Traditional Blast",        kick = "KKKKKKKKKKKKKKKK", snare = "S-S-S-S-S-S-S-S-" },
            { name = "Hammer Blast (Unison)",    kick = "KKKKKKKKKKKKKKKK", snare = "SSSSSSSSSSSSSSSS" },
            { name = "Push Blast (Fotball)",     kick = "KKKKKKKKKKKKKKKK", snare = "-S-S-S-S-S-S-S-S" },
            { name = "Slam Grind Breakdown",     kick = "K-K-k-K---K-k---", snare = "--------S-------" },
        }
    },
    {
        category = "METALCORE",
        grooves = {
            { name = "Metalcore Verse",          kick = "K-K---K-K---K-K-", snare = "----S-------S---" },
            { name = "D-Beat (Hardcore)",        kick = "K---K-K---K-K---", snare = "----S-------S---" },
            { name = "Half-Time Breakdown",      kick = "K-------K-K-----", snare = "--------S-------" },
            { name = "Gallop Kick Transition",   kick = "K-kkK---K-kkK---", snare = "----S-------S---" },
        }
    },
    {
        category = "DOOM & SLUDGE",
        grooves = {
            { name = "Standard Half-Time",       kick = "K-------K-------", snare = "--------S-------" },
            { name = "Funeral Crawl",            kick = "K---------------", snare = "----------------" },
            { name = "Sludge Pound",             kick = "K---K-K-----K---", snare = "----S-------S---" },
        }
    },
    {
        category = "PROGRESSIVE METAL",
        grooves = {
            { name = "Prog Half-Time",           kick = "K-------K-k-----", snare = "--------S-------" },
            { name = "Linear Precision",         kick = "K---k---S---k---", snare = "----------------" },
            { name = "7/8 Grouping (2+2+3)",     kick = "K--K--K",          snare = "---S---" },
            { name = "5/4 Shift",                kick = "K---K---K---K---K---", snare = "----S-------S-------" },
        }
    },
    {
        category = "ROCK",
        grooves = {
            { name = "Basic Rock Beat",          kick = "K-------K-------", snare = "----S-------S---" },
            { name = "Kick Syncopation",         kick = "K--K----K-------", snare = "----S-------S---" },
            { name = "16th Note Kick",           kick = "K--KK---K--K----", snare = "----S-------S---" },
        }
    },
    {
        category = "THRASH METAL",
        grooves = {
            { name = "Skank Beat (Polka)",       kick = "K---K---K---K---", snare = "--S---S---S---S-" },
            { name = "Thrash Gallop",            kick = "K-kkK-kkK-kkK-kk", snare = "----S-------S---" },
            { name = "D-Beat Driving",           kick = "K--kK-k-K--kK-k-", snare = "----S-------S---" },
        }
    },
    {
        category = "BREAKDOWNS",
        grooves = {
            { name = "The Pit Opener",           kick = "K-------K-------", snare = "--------S-------" },
            { name = "Wall of Groove",           kick = "K---k---K---k---", snare = "--------S-------" },
            { name = "Stutter Breakdown",        kick = "K-K---K-K-K---K-", snare = "--------S-------" },
            { name = "The Silence Drop",         kick = "----------------", snare = "----------------" },
        }
    }
}

-- =============================================
-- TIME SIGNATURES & SUBDIVISIONS (DECOUPLED)
-- =============================================
local time_signatures = {
    { name = "4/4", qn = 4.0 },
    { name = "3/4", qn = 3.0 },
    { name = "7/8", qn = 3.5 },
    { name = "5/4", qn = 5.0 },
    { name = "6/8", qn = 3.0 }
}

local power_hand_options = {
    { name = "HH Closed Tip",   get_note = function() return M.HH_CLOSED_TIP end, variance = function() return {M.HH_CLOSED_EDGE} end, variance_label = "Edge" },
    { name = "HH Open",         get_note = function() return M.HH_OPEN_1 end,     variance = function() return {M.HH_OPEN_2, M.HH_OPEN_3} end, variance_label = "Open Var" },
    { name = "Ride Tip",        get_note = function() return M.RIDE_TIP end,       variance = function() return {M.RIDE_BELL} end, variance_label = "Bell" },
    { name = "Crash Right",     get_note = function() return M.CRASH_R end,        variance = nil, variance_label = nil },
    { name = "China Right",     get_note = function() return M.CHINA_R end,        variance = nil, variance_label = nil },
    { name = "Stack",           get_note = function() return M.STACK end,          variance = nil, variance_label = nil }
}

local subdivision_options = {
    { name = "Quarter Notes",   spacing_qn = 1.0 },
    { name = "8th Notes",       spacing_qn = 0.5 },
    { name = "16th Notes",      spacing_qn = 0.25 },
    { name = "8th Triplets",    spacing_qn = 1.0 / 3.0 }
}

-- =============================================
-- STATE
-- =============================================
local left_foot_strength = 92
local humanize_val = 45
local push_pull_val = 0
local velocity_mode = 1
local loop_lengths_vals = {1, 2, 4, 8}
local loop_length_labels = {"1 Bar", "2 Bars", "4 Bars", "8 Bars"}
local current_length_idx = 3
local current_cat_idx = 1
local current_groove_idx = 1
local current_ts_idx = 1
local current_ph_idx = 2
local current_subdiv_idx = 2
local ph_velocity = 90
local ph_variance_amount = 40
local turnaround_fill_enabled = true
local fill_velocity = 115

-- =============================================
-- FILE-BASED CUSTOM GROOVE SYSTEM
-- =============================================
local USER_GROOVES_FILE = reaper.GetResourcePath() .. "/Scripts/DeadPixelDrums_UserGrooves.txt"
local user_custom_grooves = {}
local cg_input_name    = ""
local cg_capture_steps = 16
local cg_target_cat_idx = 1
local cg_capture_grid_qn = 0.25 

local function SaveUserGrooves()
    local f = io.open(USER_GROOVES_FILE, "w")
    if not f then return end
    for _, ug in ipairs(user_custom_grooves) do
        local safe_name = ug.name:gsub("|", "_")
        f:write(ug.category .. "|" .. safe_name .. "|" .. ug.kick .. "|" .. (ug.snare or "")
            .. "|" .. tostring(ug.grid_qn or 0.25)
            .. "|" .. (ug.hh or "") .. "|" .. (ug.ride or "") .. "|" .. (ug.toms or "") .. "|" .. (ug.crash or "")
            .. "\n")
    end
    f:close()
end

local function LoadUserGrooves()
    user_custom_grooves = {}
    local f = io.open(USER_GROOVES_FILE, "r")
    if not f then return end
    for line in f:lines() do
        local parts = {}
        for part in (line .. "|"):gmatch("([^|]*)|") do table.insert(parts, part) end
        local cat, name, kick, snare = parts[1], parts[2], parts[3], parts[4]
        if cat and name and kick then
            local grid_qn = tonumber(parts[5]) or 0.25
            local hh    = (parts[6] and parts[6] ~= "") and parts[6] or nil
            local ride  = (parts[7] and parts[7] ~= "") and parts[7] or nil
            local toms  = (parts[8] and parts[8] ~= "") and parts[8] or nil
            local crash = (parts[9] and parts[9] ~= "") and parts[9] or nil
            table.insert(user_custom_grooves, {
                category=cat, name=name, kick=kick, snare=snare, grid_qn=grid_qn,
                hh=hh, ride=ride, toms=toms, crash=crash
            })
        end
    end
    f:close()

    for _, ug in ipairs(user_custom_grooves) do
        for _, lib_cat in ipairs(groove_library) do
            if lib_cat.category == ug.category then
                table.insert(lib_cat.grooves, {
                    name = ug.name, kick = ug.kick, snare = ug.snare, grid_qn = ug.grid_qn,
                    hh = ug.hh, ride = ug.ride, toms = ug.toms, crash = ug.crash, is_user = true
                })
                break
            end
        end
    end
end

local function CommitCustomGroove(cat_name, name, kick, snare, grid_qn, hh, ride, toms, crash)
    table.insert(user_custom_grooves, {
        category=cat_name, name=name, kick=kick, snare=snare, grid_qn=grid_qn,
        hh=hh, ride=ride, toms=toms, crash=crash
    })
    SaveUserGrooves()
    for i, lib_cat in ipairs(groove_library) do
        if lib_cat.category == cat_name then
            table.insert(lib_cat.grooves, {
                name = name, kick = kick, snare = snare, grid_qn = grid_qn,
                hh = hh, ride = ride, toms = toms, crash = crash, is_user = true
            })
            current_cat_idx = i
            current_groove_idx = #lib_cat.grooves
            break
        end
    end
end

local function DeleteCustomGroove(user_idx)
    local ug = user_custom_grooves[user_idx]
    if not ug then return end
    for i, lib_cat in ipairs(groove_library) do
        if lib_cat.category == ug.category then
            for j, g in ipairs(lib_cat.grooves) do
                if g.name == ug.name and g.kick == ug.kick and g.is_user then
                    table.remove(lib_cat.grooves, j)
                    if current_cat_idx == i and current_groove_idx == j then
                        current_groove_idx = math.max(1, j - 1)
                    end
                    break
                end
            end
            break
        end
    end
    table.remove(user_custom_grooves, user_idx)
    SaveUserGrooves()
end

-- =============================================
-- TIMELINE CAPTURE ENGINE
-- =============================================
local function BuildPitchRoleMap()
    local pm = {}
    -- Kick & Snare (velocity-dependent character chosen at capture time)
    if M.KICK_R then pm[M.KICK_R] = {role="kick"} end
    if M.KICK_L then pm[M.KICK_L] = {role="kick"} end
    if M.SNARE then pm[M.SNARE] = {role="snare"} end
    if M.SNARE_RIM then pm[M.SNARE_RIM] = {role="snare"} end
    if M.SNARE_GHOST and M.SNARE_GHOST ~= M.SNARE then pm[M.SNARE_GHOST] = {role="snare_ghost"} end
    if M.SNARE_FLAM and M.SNARE_FLAM ~= M.SNARE then pm[M.SNARE_FLAM] = {role="snare_flam"} end
    -- Hi-Hat (first-write-wins: won't overwrite kick/snare if pitches collide)
    if M.HH_CLOSED_TIP and not pm[M.HH_CLOSED_TIP] then pm[M.HH_CLOSED_TIP] = {role="hh", char="T"} end
    if M.HH_CLOSED_EDGE and not pm[M.HH_CLOSED_EDGE] then pm[M.HH_CLOSED_EDGE] = {role="hh", char="E"} end
    if M.HH_OPEN_1 and not pm[M.HH_OPEN_1] then pm[M.HH_OPEN_1] = {role="hh", char="O"} end
    if M.HH_OPEN_2 and not pm[M.HH_OPEN_2] then pm[M.HH_OPEN_2] = {role="hh", char="O"} end
    if M.HH_OPEN_3 and not pm[M.HH_OPEN_3] then pm[M.HH_OPEN_3] = {role="hh", char="O"} end
    if M.HH_PEDAL and not pm[M.HH_PEDAL] then pm[M.HH_PEDAL] = {role="hh", char="P"} end
    -- Ride
    if M.RIDE_TIP and not pm[M.RIDE_TIP] then pm[M.RIDE_TIP] = {role="ride", char="R"} end
    if M.RIDE_BELL and not pm[M.RIDE_BELL] then pm[M.RIDE_BELL] = {role="ride", char="B"} end
    if M.RIDE_CRASH and not pm[M.RIDE_CRASH] then pm[M.RIDE_CRASH] = {role="ride", char="C"} end
    -- Toms
    if M.TOM_1 and not pm[M.TOM_1] then pm[M.TOM_1] = {role="toms", char="1"} end
    if M.TOM_2 and not pm[M.TOM_2] then pm[M.TOM_2] = {role="toms", char="2"} end
    if M.TOM_3 and not pm[M.TOM_3] then pm[M.TOM_3] = {role="toms", char="3"} end
    if M.TOM_4 and not pm[M.TOM_4] then pm[M.TOM_4] = {role="toms", char="4"} end
    -- Crashes & Cymbals
    if M.CRASH_L and not pm[M.CRASH_L] then pm[M.CRASH_L] = {role="crash", char="L"} end
    if M.CRASH_R and not pm[M.CRASH_R] then pm[M.CRASH_R] = {role="crash", char="R"} end
    if M.BIG_CRASH and not pm[M.BIG_CRASH] then pm[M.BIG_CRASH] = {role="crash", char="B"} end
    if M.CHINA_L and not pm[M.CHINA_L] then pm[M.CHINA_L] = {role="crash", char="N"} end
    if M.CHINA_R and not pm[M.CHINA_R] then pm[M.CHINA_R] = {role="crash", char="n"} end
    if M.STACK and not pm[M.STACK] then pm[M.STACK] = {role="crash", char="T"} end
    if M.SPLASH_L and not pm[M.SPLASH_L] then pm[M.SPLASH_L] = {role="crash", char="P"} end
    if M.SPLASH_R and not pm[M.SPLASH_R] then pm[M.SPLASH_R] = {role="crash", char="p"} end
    if M.BELL and not pm[M.BELL] then pm[M.BELL] = {role="crash", char="E"} end
    return pm
end

local function QNToStepIndex(note_qn, region_qn, step_qn, num_steps)
    local offset = note_qn - region_qn
    if offset < -(step_qn / 2) then return nil end
    local idx = math.floor((offset / step_qn) + 0.5)
    if idx < 0 or idx >= num_steps then return nil end
    return idx
end

local function CaptureFromTimeline(num_steps)
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then return nil, nil, nil, nil, nil, nil, nil, "Select the drum track first." end

    local sel_start, sel_end = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if sel_end <= sel_start then return nil, nil, nil, nil, nil, nil, nil, "Set a time selection on the timeline that covers the pattern you want to capture." end

    local valid_takes = {}
    for i = 0, reaper.CountTrackMediaItems(track) - 1 do
        local item = reaper.GetTrackMediaItem(track, i)
        local item_start = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local item_end   = item_start + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        if item_start < sel_end and item_end > sel_start then
            local t = reaper.GetActiveTake(item)
            if t and reaper.TakeIsMIDI(t) then table.insert(valid_takes, t) end
        end
    end

    if #valid_takes == 0 then return nil, nil, nil, nil, nil, nil, nil, "No MIDI item found on the selected track within the time selection." end

    local region_qn = reaper.TimeMap2_timeToQN(0, sel_start)
    local end_qn = reaper.TimeMap2_timeToQN(0, sel_end)
    local region_len_qn = end_qn - region_qn
    local capture_step_qn = region_len_qn / num_steps

    local pitch_role = BuildPitchRoleMap()
    local kick_steps, snare_steps = {}, {}
    local hh_steps, ride_steps, toms_steps, crash_steps = {}, {}, {}, {}
    for i = 0, num_steps - 1 do
        kick_steps[i], snare_steps[i] = "-", "-"
        hh_steps[i], ride_steps[i], toms_steps[i], crash_steps[i] = "-", "-", "-", "-"
    end

    local snare_priority = { S=4, f=3, s=2, g=1, ["-"]=0 }
    local found_raw_pitches = {}
    local total_notes_found = 0

    for _, take in ipairs(valid_takes) do
        local i = 0
        while true do
            local retval, selected, muted, startppq, endppq, chan, pitch, vel = reaper.MIDI_GetNote(take, i)
            if not retval then break end

            if not muted then
                found_raw_pitches[pitch] = true
                total_notes_found = total_notes_found + 1

                local note_time = reaper.MIDI_GetProjTimeFromPPQPos(take, startppq)
                local note_qn   = reaper.TimeMap2_timeToQN(0, note_time)
                local step_idx  = QNToStepIndex(note_qn, region_qn, capture_step_qn, num_steps)

                if step_idx then
                    local info = pitch_role[pitch]
                    if info then
                        local role = info.role
                        if role == "kick" then
                            local ch = (vel >= 100) and "K" or "k"
                            if kick_steps[step_idx] == "-" or (ch == "K" and kick_steps[step_idx] == "k") then kick_steps[step_idx] = ch end
                        elseif role == "snare" then
                            local ch
                            if vel < 60 then ch = "g" elseif vel < 100 then ch = "s" else ch = "S" end
                            if (snare_priority[ch] or 0) > (snare_priority[snare_steps[step_idx]] or 0) then snare_steps[step_idx] = ch end
                        elseif role == "snare_ghost" then
                            if (snare_priority["g"]) > (snare_priority[snare_steps[step_idx]] or 0) then snare_steps[step_idx] = "g" end
                        elseif role == "snare_flam" then
                            if (snare_priority["f"]) > (snare_priority[snare_steps[step_idx]] or 0) then snare_steps[step_idx] = "f" end
                        elseif role == "hh" then
                            if hh_steps[step_idx] == "-" then hh_steps[step_idx] = info.char end
                        elseif role == "ride" then
                            if ride_steps[step_idx] == "-" then ride_steps[step_idx] = info.char end
                        elseif role == "toms" then
                            if toms_steps[step_idx] == "-" then toms_steps[step_idx] = info.char end
                        elseif role == "crash" then
                            if crash_steps[step_idx] == "-" then crash_steps[step_idx] = info.char end
                        end
                    end
                end
            end
            i = i + 1
        end
    end

    if total_notes_found == 0 then
        return nil, nil, nil, nil, nil, nil, nil, "No unmuted notes found in the time selection."
    end

    local kick_str, snare_str = "", ""
    local hh_str, ride_str, toms_str, crash_str = "", "", "", ""
    local has_data = false
    for idx = 0, num_steps - 1 do
        kick_str  = kick_str  .. kick_steps[idx]
        snare_str = snare_str .. snare_steps[idx]
        hh_str    = hh_str    .. hh_steps[idx]
        ride_str  = ride_str  .. ride_steps[idx]
        toms_str  = toms_str  .. toms_steps[idx]
        crash_str = crash_str .. crash_steps[idx]
        if kick_steps[idx] ~= "-" or snare_steps[idx] ~= "-"
            or hh_steps[idx] ~= "-" or ride_steps[idx] ~= "-"
            or toms_steps[idx] ~= "-" or crash_steps[idx] ~= "-" then
            has_data = true
        end
    end

    -- Collapse all-dash strings to nil so they don't clutter the save file
    if hh_str:match("^%-+$") then hh_str = nil end
    if ride_str:match("^%-+$") then ride_str = nil end
    if toms_str:match("^%-+$") then toms_str = nil end
    if crash_str:match("^%-+$") then crash_str = nil end

    -- DIAGNOSTIC PITCH SCANNER
    if not has_data then
        local p_list = {}
        for p, _ in pairs(found_raw_pitches) do table.insert(p_list, tostring(p)) end
        table.sort(p_list, function(a,b) return tonumber(a) < tonumber(b) end)

        local msg = "CAPTURE FAILED: PITCH MISMATCH\n\n"
        msg = msg .. "The script scanned your selection and found " .. total_notes_found .. " physical notes, but NONE of them matched any pitches defined in the Map Editor.\n\n"
        msg = msg .. "RAW PITCHES FOUND ON TIMELINE:\n[ " .. table.concat(p_list, ", ") .. " ]\n\n"
        msg = msg .. "WHAT THE MAP EDITOR IS CURRENTLY LOOKING FOR:\n"
        msg = msg .. "Kick: " .. (M.KICK_R or "?") .. " / " .. (M.KICK_L or "?") .. "\n"
        msg = msg .. "Snare: " .. (M.SNARE or "?") .. " / " .. (M.SNARE_RIM or "?") .. "\n"
        msg = msg .. "HH Closed: " .. (M.HH_CLOSED_TIP or "?") .. "  HH Open: " .. (M.HH_OPEN_1 or "?") .. "\n"
        msg = msg .. "Ride: " .. (M.RIDE_TIP or "?") .. "  Toms: " .. (M.TOM_1 or "?") .. "-" .. (M.TOM_4 or "?") .. "\n\n"
        msg = msg .. "ACTION: Look at the raw pitches found above, type those exact numbers into the Map Editor UI, and hit capture again."
        return nil, nil, nil, nil, nil, nil, nil, msg
    end

    return kick_str, snare_str, capture_step_qn, hh_str, ride_str, toms_str, crash_str, nil
end

LoadUserGrooves()

-- =============================================
-- VELOCITY & TIMING ENGINE
-- =============================================
local function GetUniqueVel(base_vel, mode, humanize, is_left_foot)
    local final_vel = base_vel
    if mode == 0 then final_vel = base_vel * 0.85
    elseif mode == 2 then final_vel = base_vel * 1.1 end
    if is_left_foot then final_vel = final_vel * (left_foot_strength / 100) end
    local var = math.floor(20 * (humanize / 100))
    final_vel = final_vel + math.random(-var, var)
    return math.max(1, math.min(127, math.floor(final_vel)))
end

local step_offsets = {}
local function GetStepOffset(bar, step, humanize, push_pull)
    local key = bar .. "_" .. step
    if not step_offsets[key] then
        local drift = ((math.random() - 0.5) * (humanize / 100) * 0.025)
        local push  = (push_pull / 100) * 0.02
        step_offsets[key] = drift - push
    end
    return step_offsets[key]
end

local function AddNote(take, qn, beat, pitch, base_vel, humanize, push_pull, bar_idx, step_idx)
    if not pitch then return end
    local is_left = (pitch == M.KICK_L)
    local vel    = GetUniqueVel(base_vel, velocity_mode, humanize, is_left)
    local offset = GetStepOffset(bar_idx, step_idx, humanize, push_pull)
    local s  = reaper.TimeMap2_QNToTime(0, qn + beat)
    local sp = reaper.MIDI_GetPPQPosFromProjTime(take, s + offset)
    local ep = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.TimeMap2_QNToTime(0, qn + beat + 0.12) + offset)
    reaper.MIDI_InsertNote(take, false, false, sp, ep, 0, pitch, vel, false)
end

-- =============================================
-- CAPTURED PATTERN PLAYBACK MAPS
-- =============================================
local function GetHHPitch(ch)
    if ch == "T" then return M.HH_CLOSED_TIP
    elseif ch == "E" then return M.HH_CLOSED_EDGE
    elseif ch == "O" then return M.HH_OPEN_1
    elseif ch == "P" then return M.HH_PEDAL end
end

local function GetRidePitch(ch)
    if ch == "R" then return M.RIDE_TIP
    elseif ch == "B" then return M.RIDE_BELL
    elseif ch == "C" then return M.RIDE_CRASH end
end

local function GetTomPitch(ch)
    if ch == "1" then return M.TOM_1
    elseif ch == "2" then return M.TOM_2
    elseif ch == "3" then return M.TOM_3
    elseif ch == "4" then return M.TOM_4 end
end

local function GetCrashPitch(ch)
    if ch == "L" then return M.CRASH_L
    elseif ch == "R" then return M.CRASH_R
    elseif ch == "B" then return M.BIG_CRASH
    elseif ch == "N" then return M.CHINA_L
    elseif ch == "n" then return M.CHINA_R
    elseif ch == "T" then return M.STACK
    elseif ch == "P" then return M.SPLASH_L
    elseif ch == "p" then return M.SPLASH_R
    elseif ch == "E" then return M.BELL end
end

-- =============================================
-- MAIN MIDI GENERATOR
-- =============================================
local function GenerateMIDI()
    local track = reaper.GetSelectedTrack(0, 0)
    if not track then
        reaper.ShowMessageBox("Select a track first.", "Dead Pixel Drum Apparatus", 0)
        return
    end

    step_offsets = {}

    local start_qn      = reaper.TimeMap2_timeToQN(0, reaper.GetCursorPosition())
    local num_bars      = loop_lengths_vals[current_length_idx]
    local pattern       = groove_library[current_cat_idx].grooves[current_groove_idx]
    
    local step_qn       = pattern.grid_qn or 0.25
    local bar_length_qn = time_signatures[current_ts_idx].qn
    
    local steps_in_bar  = math.floor((bar_length_qn / step_qn) + 0.5)

    reaper.Undo_BeginBlock()

    local item = reaper.CreateNewMIDIItemInProj(track, reaper.GetCursorPosition(),
        reaper.TimeMap2_QNToTime(0, start_qn + (bar_length_qn * num_bars) + 0.25), false)
    local take = reaper.GetActiveTake(item)
    if not take then
        reaper.Undo_EndBlock("Dead Pixel Drum Gen", -1)
        reaper.ShowMessageBox("Failed to create MIDI take.", "Dead Pixel Drum Apparatus", 0)
        return
    end

    local has_captured_cymbals = (pattern.hh or pattern.ride or pattern.toms or pattern.crash)

    for bar = 0, num_bars - 1 do
        local b = start_qn + (bar * bar_length_qn)
        local limb_count = {}
        for i = 0, steps_in_bar do limb_count[i] = 0 end

        local is_final_bar     = (bar == num_bars - 1)
        local apply_fill       = turnaround_fill_enabled and is_final_bar and not has_captured_cymbals

        local steps_per_beat   = math.floor((1.0 / step_qn) + 0.5)
        local turnaround_start = steps_in_bar - steps_per_beat
        local fill_zone = {}
        if apply_fill then
            for s = turnaround_start, steps_in_bar - 1 do fill_zone[s] = true end
        end

        local pat_len = #pattern.kick
        for i = 1, steps_in_bar do
            local pos      = (i - 1) * step_qn
            local step_idx = i - 1
            local str_idx  = ((i - 1) % pat_len) + 1

            if not fill_zone[step_idx] then
                local k = pattern.kick:sub(str_idx, str_idx)
                local s = pattern.snare:sub(str_idx, str_idx)

                if k ~= "-" then
                    local foot     = (i % 2 == 0) and M.KICK_L or M.KICK_R
                    local kick_vel = (k == "K") and 127 or 110
                    AddNote(take, b, pos, foot, kick_vel, humanize_val, push_pull_val, bar, step_idx)
                    limb_count[step_idx] = limb_count[step_idx] + 1
                end

                if s ~= "-" then
                    local p, snare_vel
                    if s == "S" then p = M.SNARE; snare_vel = 127
                    elseif s == "s" then p = M.SNARE; snare_vel = 110
                    elseif s == "g" then p = M.SNARE_GHOST or M.SNARE; snare_vel = math.random(25, 45)
                    elseif s == "f" then p = M.SNARE_FLAM; snare_vel = 115
                    end
                    if p then
                        AddNote(take, b, pos, p, snare_vel, humanize_val, push_pull_val, bar, step_idx)
                        limb_count[step_idx] = limb_count[step_idx] + 1
                    end
                end
            end
        end

        -- Captured pattern playback: hh, ride, toms, crash
        if has_captured_cymbals then
            for i = 1, steps_in_bar do
                local pos      = (i - 1) * step_qn
                local step_idx = i - 1
                local str_idx  = ((i - 1) % pat_len) + 1

                if pattern.hh then
                    local ch = pattern.hh:sub(str_idx, str_idx)
                    local p = (ch ~= "-") and GetHHPitch(ch) or nil
                    if p then AddNote(take, b, pos, p, ph_velocity, humanize_val, push_pull_val, bar, step_idx) end
                end
                if pattern.ride then
                    local ch = pattern.ride:sub(str_idx, str_idx)
                    local p = (ch ~= "-") and GetRidePitch(ch) or nil
                    if p then AddNote(take, b, pos, p, ph_velocity, humanize_val, push_pull_val, bar, step_idx) end
                end
                if pattern.toms then
                    local ch = pattern.toms:sub(str_idx, str_idx)
                    local p = (ch ~= "-") and GetTomPitch(ch) or nil
                    if p then AddNote(take, b, pos, p, 115, humanize_val, push_pull_val, bar, step_idx) end
                end
                if pattern.crash then
                    local ch = pattern.crash:sub(str_idx, str_idx)
                    local p = (ch ~= "-") and GetCrashPitch(ch) or nil
                    if p then AddNote(take, b, pos, p, 127, humanize_val, push_pull_val, bar, step_idx) end
                end
            end
        end

        if apply_fill then
            for step = turnaround_start, steps_in_bar - 1 do
                local pos = step * step_qn
                local tom = (step % 2 == 0) and M.TOM_1 or M.TOM_2
                AddNote(take, b, pos, tom, fill_velocity, humanize_val, push_pull_val, bar, step)
                limb_count[step] = limb_count[step] + 1
            end
            AddNote(take, b, steps_in_bar * step_qn, M.CRASH_R, 127, humanize_val, push_pull_val, bar, steps_in_bar)
        end

        if not has_captured_cymbals then
            local ph = power_hand_options[current_ph_idx]
            local subdiv_qn = subdivision_options[current_subdiv_idx].spacing_qn
            local ph_steps = math.floor((bar_length_qn / subdiv_qn) + 0.5)

            for i = 0, ph_steps - 1 do
                local pos = i * subdiv_qn
                local nearest_drum_step = math.floor((pos / step_qn) + 0.5)

                if not fill_zone[nearest_drum_step] and (limb_count[nearest_drum_step] or 0) < 2 then
                    local pitch   = ph.get_note()
                    local var_arr = ph.variance and ph.variance() or nil
                    if var_arr and #var_arr > 0 and math.random(100) < ph_variance_amount then
                        pitch = var_arr[math.random(#var_arr)]
                    end
                    AddNote(take, b, pos, pitch, ph_velocity, humanize_val, push_pull_val, bar, 0)
                end
            end
        end
    end

    reaper.MIDI_Sort(take)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Dead Pixel Drum Gen", -1)
end

local function GetRandomGroove()
    local cat_idx = math.random(#groove_library)
    local g_idx   = math.random(#groove_library[cat_idx].grooves)
    current_cat_idx    = cat_idx
    current_groove_idx = g_idx
end

-- =============================================
-- UI
-- =============================================
local preview_kick  = nil
local preview_snare = nil
local preview_hh    = nil
local preview_ride  = nil
local preview_toms  = nil
local preview_crash = nil
local preview_valid = false

local function loop()
    reaper.ImGui_SetNextWindowSize(ctx, 460, 860, reaper.ImGui_Cond_FirstUseEver())
    local v, open = reaper.ImGui_Begin(ctx, 'Dead Pixel Drum Apparatus v1.7.0', true)
    if v then

        -- MAP EDITOR
        if reaper.ImGui_CollapsingHeader(ctx, "Map Editor (" .. MIDI_MAPS[current_map_idx].name .. ")") then
            if reaper.ImGui_BeginCombo(ctx, 'Preset MIDI Map', MIDI_MAPS[current_map_idx].name) then
                for i, map_preset in ipairs(MIDI_MAPS) do
                    if reaper.ImGui_Selectable(ctx, map_preset.name, current_map_idx == i) then
                        current_map_idx = i
                        UpdateMap()
                    end
                end
                reaper.ImGui_EndCombo(ctx)
            end
            reaper.ImGui_Spacing(ctx)
            if reaper.ImGui_BeginTable(ctx, "map_table", 2) then
                for i, key in ipairs(map_keys_ordered) do
                    reaper.ImGui_TableNextColumn(ctx)
                    reaper.ImGui_PushItemWidth(ctx, 60)
                    local rv, new_val = reaper.ImGui_InputInt(ctx, key, M[key], 0, 0)
                    if rv then M[key] = new_val end
                    reaper.ImGui_PopItemWidth(ctx)
                end
                reaper.ImGui_EndTable(ctx)
            end
            reaper.ImGui_Spacing(ctx)
        end

        -- TIME & LENGTH
        ImGui_SeparatorText(ctx, "TIME & LENGTH")
        if reaper.ImGui_BeginCombo(ctx, 'Time Signature', time_signatures[current_ts_idx].name) then
            for i, ts in ipairs(time_signatures) do
                if reaper.ImGui_Selectable(ctx, ts.name, current_ts_idx == i) then current_ts_idx = i end
            end
            reaper.ImGui_EndCombo(ctx)
        end
        if reaper.ImGui_BeginCombo(ctx, "Pattern Length", loop_length_labels[current_length_idx]) then
            for i, label in ipairs(loop_length_labels) do
                if reaper.ImGui_Selectable(ctx, label, current_length_idx == i) then current_length_idx = i end
            end
            reaper.ImGui_EndCombo(ctx)
        end

        -- GROOVE SELECTION
        ImGui_SeparatorText(ctx, "GROOVE SELECTION")
        local selected_name = groove_library[current_cat_idx].grooves[current_groove_idx].name
        if reaper.ImGui_BeginCombo(ctx, 'Select Groove', selected_name) then
            for i, cat in ipairs(groove_library) do
                ImGui_SeparatorText(ctx, cat.category)
                for j, g in ipairs(cat.grooves) do
                    local is_selected = (current_cat_idx == i and current_groove_idx == j)
                    if reaper.ImGui_Selectable(ctx, g.name .. (g.is_user and " [User]" or ""), is_selected) then
                        current_cat_idx    = i
                        current_groove_idx = j
                    end
                end
            end
            reaper.ImGui_EndCombo(ctx)
        end

        -- CAPTURE SYSTEM
        if reaper.ImGui_CollapsingHeader(ctx, "Capture Custom Groove") then
            reaper.ImGui_Spacing(ctx)
            reaper.ImGui_Text(ctx, "1. Select drum track & make a time selection over the pattern.")
            reaper.ImGui_Text(ctx, "2. Set step count & target category, then hit Capture.")
            reaper.ImGui_Spacing(ctx)

            reaper.ImGui_Text(ctx, "Groove Name")
            reaper.ImGui_PushItemWidth(ctx, -1)
            local rv_name, new_name = reaper.ImGui_InputText(ctx, "##cg_name", cg_input_name)
            if rv_name then cg_input_name = new_name; preview_valid = false end
            reaper.ImGui_PopItemWidth(ctx)
            reaper.ImGui_Spacing(ctx)

            if reaper.ImGui_BeginCombo(ctx, 'Save to Category', groove_library[cg_target_cat_idx].category) then
                for i, cat in ipairs(groove_library) do
                    if reaper.ImGui_Selectable(ctx, cat.category, cg_target_cat_idx == i) then cg_target_cat_idx = i end
                end
                reaper.ImGui_EndCombo(ctx)
            end
            reaper.ImGui_Spacing(ctx)

            reaper.ImGui_Text(ctx, "Steps to Capture")
            reaper.ImGui_PushItemWidth(ctx, 120)
            local rv_steps, new_steps = reaper.ImGui_InputInt(ctx, "##cg_steps", cg_capture_steps, 1, 4)
            if rv_steps then cg_capture_steps = math.max(1, math.min(128, new_steps)); preview_valid = false end
            reaper.ImGui_PopItemWidth(ctx)
            reaper.ImGui_Spacing(ctx)

            if reaper.ImGui_Button(ctx, "CAPTURE FROM TIMELINE", -1) then
                local name = cg_input_name:match("^%s*(.-)%s*$")
                if name == "" then
                    reaper.ShowMessageBox("Enter a groove name before capturing.", "Dead Pixel Drum Apparatus", 0)
                else
                    local kick_str, snare_str, calc_grid_qn, hh_str, ride_str, toms_str, crash_str, err = CaptureFromTimeline(cg_capture_steps)
                    if err then
                        reaper.ShowMessageBox(err, "Dead Pixel Drum Apparatus", 0)
                        preview_valid = false
                    else
                        preview_kick  = kick_str
                        preview_snare = snare_str
                        preview_hh    = hh_str
                        preview_ride  = ride_str
                        preview_toms  = toms_str
                        preview_crash = crash_str
                        cg_capture_grid_qn = calc_grid_qn
                        preview_valid = true
                    end
                end
            end

            if preview_valid then
                reaper.ImGui_Spacing(ctx)
                reaper.ImGui_Separator(ctx)
                reaper.ImGui_Text(ctx, "Preview:")
                reaper.ImGui_Text(ctx, "Kick:  " .. (preview_kick  or ""))
                reaper.ImGui_Text(ctx, "Snare: " .. (preview_snare or ""))
                if preview_hh    then reaper.ImGui_Text(ctx, "HiHat: " .. preview_hh) end
                if preview_ride  then reaper.ImGui_Text(ctx, "Ride:  " .. preview_ride) end
                if preview_toms  then reaper.ImGui_Text(ctx, "Toms:  " .. preview_toms) end
                if preview_crash then reaper.ImGui_Text(ctx, "Crash: " .. preview_crash) end
                reaper.ImGui_Spacing(ctx)
                if reaper.ImGui_Button(ctx, "SAVE GROOVE", -1) then
                    local name = cg_input_name:match("^%s*(.-)%s*$")
                    CommitCustomGroove(groove_library[cg_target_cat_idx].category, name,
                        preview_kick, preview_snare, cg_capture_grid_qn,
                        preview_hh, preview_ride, preview_toms, preview_crash)
                    cg_input_name = ""
                    preview_kick  = nil
                    preview_snare = nil
                    preview_hh    = nil
                    preview_ride  = nil
                    preview_toms  = nil
                    preview_crash = nil
                    preview_valid = false
                end
            end

            if #user_custom_grooves > 0 then
                reaper.ImGui_Spacing(ctx)
                reaper.ImGui_Separator(ctx)
                reaper.ImGui_Text(ctx, "Manage Saved Grooves:")
                reaper.ImGui_Spacing(ctx)
                local to_delete = nil
                for i, g in ipairs(user_custom_grooves) do
                    if reaper.ImGui_Button(ctx, "X##cgdel_" .. i) then to_delete = i end
                    reaper.ImGui_SameLine(ctx)
                    reaper.ImGui_Text(ctx, "[" .. g.category .. "] " .. g.name)
                end
                if to_delete then DeleteCustomGroove(to_delete) end
            end
            reaper.ImGui_Spacing(ctx)
        end

        -- POWER HAND
        ImGui_SeparatorText(ctx, "POWER HAND (CYMBALS)")
        local ph = power_hand_options[current_ph_idx]
        if reaper.ImGui_BeginCombo(ctx, 'Kit Piece', ph.name) then
            for i, opt in ipairs(power_hand_options) do
                if reaper.ImGui_Selectable(ctx, opt.name, current_ph_idx == i) then current_ph_idx = i end
            end
            reaper.ImGui_EndCombo(ctx)
        end

        local subdiv = subdivision_options[current_subdiv_idx]
        if reaper.ImGui_BeginCombo(ctx, 'Subdivision', subdiv.name) then
            for i, s in ipairs(subdivision_options) do
                if reaper.ImGui_Selectable(ctx, s.name, current_subdiv_idx == i) then current_subdiv_idx = i end
            end
            reaper.ImGui_EndCombo(ctx)
        end

        local rv_pv, pv = reaper.ImGui_SliderInt(ctx, 'Power Hand Velocity', ph_velocity, 40, 127)
        if rv_pv then ph_velocity = pv end

        -- DYNAMICS & TIMING
        ImGui_SeparatorText(ctx, "DYNAMICS & TIMING")
        local rv_h, h = reaper.ImGui_SliderInt(ctx, 'Humanize (Slop) %', humanize_val, 0, 100)
        if rv_h then humanize_val = h end
        
        local rv_pp, pp = reaper.ImGui_SliderInt(ctx, 'Push / Pull', push_pull_val, -100, 100)
        if rv_pp then push_pull_val = pp end
        
        local rv_tf, tf = reaper.ImGui_Checkbox(ctx, "Auto-Insert Tom Fill at End of Loop", turnaround_fill_enabled)
        if rv_tf then turnaround_fill_enabled = tf end

        -- GENERATE
        ImGui_SeparatorText(ctx, "GENERATE")
        if reaper.ImGui_Button(ctx, 'RANDOMIZE') then GetRandomGroove() end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, ' GENERATE GROOVE ', -1) then GenerateMIDI() end

        reaper.ImGui_End(ctx)
    end
    if open then reaper.defer(loop) end
end

reaper.defer(loop)