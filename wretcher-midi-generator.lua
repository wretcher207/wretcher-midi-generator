-- @description Dead Pixel Drum Apparatus
-- @author David W. Russell III / Dead Pixel Design
-- @version 1.1.0
-- @changelog
--   Rebrand to Dead Pixel Drum Apparatus. Authorship and metadata updated. No functional changes.
-- @website https://www.deadpixeldesign.com
-- @about
--   Generates heavy-music drum MIDI patterns directly in REAPER. Comes with 43 grooves across 12
--   genre categories ready to go. Covers blast beats, djent, thall, death metal, black metal,
--   grindcore, metalcore, doom, sludge, progressive metal, thrash, and breakdowns. Includes 4
--   MIDI map presets with an in-script editor, power hand control, configurable time signatures,
--   humanize/push-pull timing, and auto tom fills. Requires REAPER 6.0+ and ReaImGui 0.8+.

-- DEAD PIXEL DRUM APPARATUS v1.1.0
-- THE COMPLETE BERKLEE EDITION
if not reaper.ImGui_CreateContext then
    reaper.ShowMessageBox("This script requires the ReaImGui extension.\nInstall it via ReaPack: Extensions > ReaImGui.", "Dead Pixel Drum Apparatus", 0)
    return
end
local ctx = reaper.ImGui_CreateContext('Dead Pixel Drum Apparatus v1.1.0')
reaper.atexit(function()
    if reaper.ImGui_DestroyContext then reaper.ImGui_DestroyContext(ctx) end
end)
local ImGui_SeparatorText = reaper.ImGui_SeparatorText or function(c, label)
    reaper.ImGui_Separator(c)
    reaper.ImGui_Text(c, label)
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
local M = MIDI_MAPS[current_map_idx].map
local function UpdateMap() M = MIDI_MAPS[current_map_idx].map end

local map_keys_ordered = {
    "KICK_R", "KICK_L", "SNARE", "SNARE_FLAM", "SNARE_RIM", "SNARE_GHOST",
    "TOM_1", "TOM_2", "TOM_3", "TOM_4", 
    "HH_CLOSED_TIP", "HH_CLOSED_EDGE", "HH_OPEN_1", "HH_PEDAL",
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
        category = "THALL",
        grooves = {
            { name = "The Lurch (Displaced)",    kick = "-K--K---K-K--K--", snare = "----S-------S---" },
            { name = "Stutter Stabs",            kick = "KK-K---KK-K---K-", snare = "--------S-------" },
            { name = "Half-Time Dread",          kick = "K---------------", snare = "--------S-------" },
            { name = "Foundational 4/4",         kick = "K---K---K---K---", snare = "----S-------S---" },
        }
    },
    {
        category = "DJENT",
        grooves = {
            { name = "Displaced Kick Grid",      kick = "K--K-K----K-K---", snare = "----S-------S---" },
            { name = "3-Against-4 Pattern",      kick = "K--K--K--K--K--K", snare = "----S-------S---" },
            { name = "Meshuggah Cycle",          kick = "K--K-K-K--K-K-K-", snare = "----S-------S---" },
        }
    },
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
            { name = "7/8 Grouping (2+2+3)",     kick = "K--K--K",           snare = "---S---" },
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
-- TIME SIGNATURES & SUBDIVISIONS
-- =============================================
local time_signatures = {
    { name = "4/4 (16 steps)", steps = 16 },
    { name = "3/4 (12 steps)", steps = 12 },
    { name = "7/8 (14 steps)", steps = 14 },
    { name = "5/4 (20 steps)", steps = 20 }
}

local power_hand_options = {
    { name = "HH Closed Tip",   get_note = function() return M.HH_CLOSED_TIP end, variance = function() return {M.HH_CLOSED_EDGE} end, variance_label = "Edge" },
    { name = "HH Open",         get_note = function() return M.HH_OPEN_1 end,   variance = function() return {M.HH_OPEN_2, M.HH_OPEN_3} end, variance_label = "Open Var" },
    { name = "Ride Tip",        get_note = function() return M.RIDE_TIP end,     variance = function() return {M.RIDE_BELL} end, variance_label = "Bell" },
    { name = "Crash Right",     get_note = function() return M.CRASH_R end,       variance = nil, variance_label = nil },
    { name = "China Right",     get_note = function() return M.CHINA_R end,       variance = nil, variance_label = nil },
    { name = "Stack",           get_note = function() return M.STACK end,         variance = nil, variance_label = nil }
}

local subdivision_options = {
    { name = "Quarter Notes",   steps = {0, 4, 8, 12, 16, 20} },
    { name = "8th Notes",       steps = {0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20} },
    { name = "16th Notes",      steps = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20} },
    { name = "8th Triplets",    steps = {0, 1.333, 2.667, 4, 5.333, 6.667, 8, 9.333, 10.667, 12, 13.333, 14.667, 16, 17.333, 18.667, 20} },
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
        local push = (push_pull / 100) * 0.02 
        step_offsets[key] = drift - push
    end
    return step_offsets[key]
end

local function AddNote(take, qn, beat, pitch, base_vel, humanize, push_pull, bar_idx, step_idx)
    if not pitch then return end
    local is_left = (pitch == M.KICK_L)
    local vel = GetUniqueVel(base_vel, velocity_mode, humanize, is_left)
    local offset = GetStepOffset(bar_idx, step_idx, humanize, push_pull)
    local s = reaper.TimeMap2_QNToTime(0, qn + beat)
    local sp = reaper.MIDI_GetPPQPosFromProjTime(take, s + offset)
    local ep = reaper.MIDI_GetPPQPosFromProjTime(take, reaper.TimeMap2_QNToTime(0, qn + beat + 0.12) + offset)
    reaper.MIDI_InsertNote(take, false, false, sp, ep, 0, pitch, vel, false)
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

    UpdateMap()
    step_offsets = {} 

    local start_qn = reaper.TimeMap2_timeToQN(0, reaper.GetCursorPosition())
    local num_bars = loop_lengths_vals[current_length_idx]
    local pattern = groove_library[current_cat_idx].grooves[current_groove_idx]
    local steps_in_bar = time_signatures[current_ts_idx].steps
    local bar_length_qn = steps_in_bar * 0.25

    reaper.Undo_BeginBlock()

    local item = reaper.CreateNewMIDIItemInProj(track, reaper.GetCursorPosition(),
        reaper.TimeMap2_QNToTime(0, start_qn + (bar_length_qn * num_bars) + 0.25), false)
    local take = reaper.GetActiveTake(item)
    if not take then
        reaper.Undo_EndBlock("Dead Pixel Drum Gen", -1)
        reaper.ShowMessageBox("Failed to create MIDI take.", "Dead Pixel Drum Apparatus", 0)
        return
    end
    local subdiv = subdivision_options[current_subdiv_idx]

    for bar = 0, num_bars - 1 do
        local b = start_qn + (bar * bar_length_qn)
        local limb_count = {} 
        for i=0, steps_in_bar do limb_count[i] = 0 end

        -- Fill Logic: Applies to the final bar of the loop
        local is_final_bar = (bar == num_bars - 1)
        local apply_fill = turnaround_fill_enabled and is_final_bar
        local turnaround_start = steps_in_bar - 4 
        local fill_zone = {}
        
        if apply_fill then
            for s = turnaround_start, steps_in_bar - 1 do fill_zone[s] = true end
        end

        local pat_len = #pattern.kick
        for i = 1, steps_in_bar do
            local pos = (i - 1) * 0.25
            local step_idx = i - 1
            local str_idx = ((i - 1) % pat_len) + 1

            if not fill_zone[step_idx] then
                local k = pattern.kick:sub(str_idx, str_idx)
                local s = pattern.snare:sub(str_idx, str_idx)

                if k ~= "-" then
                    local foot = (i % 2 == 0) and M.KICK_L or M.KICK_R
                    local kick_vel = (k == "K") and 127 or 110
                    AddNote(take, b, pos, foot, kick_vel, humanize_val, push_pull_val, bar, step_idx)
                    limb_count[step_idx] = limb_count[step_idx] + 1
                end

                if s ~= "-" then
                    local p, snare_vel
                    if s == "S" then
                        p = M.SNARE
                        snare_vel = 127
                    elseif s == "s" then
                        p = M.SNARE
                        snare_vel = 110
                    elseif s == "g" then
                        p = M.SNARE_GHOST or M.SNARE
                        snare_vel = math.random(25, 45)
                    elseif s == "f" then
                        p = M.SNARE_FLAM
                        snare_vel = 115
                    end
                    
                    if p then
                        AddNote(take, b, pos, p, snare_vel, humanize_val, push_pull_val, bar, step_idx)
                        limb_count[step_idx] = limb_count[step_idx] + 1
                    end
                end
            end
        end

        -- TOM FILLS
        if apply_fill then
            for step = turnaround_start, steps_in_bar - 1 do
                local pos = step * 0.25
                local tom = (step % 2 == 0) and M.TOM_1 or M.TOM_2
                AddNote(take, b, pos, tom, fill_velocity, humanize_val, push_pull_val, bar, step)
                limb_count[step] = limb_count[step] + 1
            end
            -- Big crash on the downbeat of the imaginary next measure
            AddNote(take, b, steps_in_bar * 0.25, M.CRASH_R, 127, humanize_val, push_pull_val, bar, steps_in_bar)
        end

        -- POWER HAND (CYMBALS/HATS)
        local ph = power_hand_options[current_ph_idx]
        for _, step in ipairs(subdiv.steps) do
            if step < steps_in_bar then
                local pos = step * 0.25
                local step_16th = math.floor(step)

                if not fill_zone[step_16th] and limb_count[step_16th] < 2 then
                    local pitch = ph.get_note()
                    local var_arr = ph.variance and ph.variance() or nil
                    if var_arr and #var_arr > 0 and math.random(100) < ph_variance_amount then
                        pitch = var_arr[math.random(#var_arr)]
                    end
                    AddNote(take, b, pos, pitch, ph_velocity, humanize_val, push_pull_val, bar, step_16th)
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
    local g_idx = math.random(#groove_library[cat_idx].grooves)
    current_cat_idx = cat_idx
    current_groove_idx = g_idx
end

-- =============================================
-- UI
-- =============================================
local function loop()
    reaper.ImGui_SetNextWindowSize(ctx, 440, 800, reaper.ImGui_Cond_FirstUseEver())
    local v, open = reaper.ImGui_Begin(ctx, 'Dead Pixel Drum Apparatus v1.1.0', true)
    if v then

        if reaper.ImGui_CollapsingHeader(ctx, "Map Editor (" .. MIDI_MAPS[current_map_idx].name .. ")") then
            
            -- Preset Selector Dropdown
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

        ImGui_SeparatorText(ctx, "TIME & LENGTH")
        if reaper.ImGui_BeginCombo(ctx, 'Time Signature', time_signatures[current_ts_idx].name) then
            for i, ts in ipairs(time_signatures) do
                if reaper.ImGui_Selectable(ctx, ts.name, current_ts_idx == i) then
                    current_ts_idx = i
                end
            end
            reaper.ImGui_EndCombo(ctx)
        end

        if reaper.ImGui_BeginCombo(ctx, "Pattern Length", loop_length_labels[current_length_idx]) then
            for i, label in ipairs(loop_length_labels) do
                if reaper.ImGui_Selectable(ctx, label, current_length_idx == i) then
                    current_length_idx = i
                end
            end
            reaper.ImGui_EndCombo(ctx)
        end

        ImGui_SeparatorText(ctx, "GROOVE SELECTION")
        local selected_name = groove_library[current_cat_idx].grooves[current_groove_idx].name
        if reaper.ImGui_BeginCombo(ctx, 'Select Groove', selected_name) then
            for i, cat in ipairs(groove_library) do
                ImGui_SeparatorText(ctx, cat.category)
                for j, g in ipairs(cat.grooves) do
                    local is_selected = (current_cat_idx == i and current_groove_idx == j)
                    if reaper.ImGui_Selectable(ctx, g.name, is_selected) then
                        current_cat_idx = i
                        current_groove_idx = j
                    end
                end
            end
            reaper.ImGui_EndCombo(ctx)
        end

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

        local _, pv = reaper.ImGui_SliderInt(ctx, 'Power Hand Velocity', ph_velocity, 40, 127)
        ph_velocity = pv

        ImGui_SeparatorText(ctx, "DYNAMICS & TIMING")
        local _, h = reaper.ImGui_SliderInt(ctx, 'Humanize (Slop) %', humanize_val, 0, 100)
        humanize_val = h
        local _, pp = reaper.ImGui_SliderInt(ctx, 'Push / Pull', push_pull_val, -100, 100)
        push_pull_val = pp
        
        -- The Fill Toggle
        local _, tf = reaper.ImGui_Checkbox(ctx, "Auto-Insert Tom Fill at End of Loop", turnaround_fill_enabled)
        turnaround_fill_enabled = tf

        ImGui_SeparatorText(ctx, "GENERATE")
        if reaper.ImGui_Button(ctx, 'RANDOMIZE') then GetRandomGroove() end
        reaper.ImGui_SameLine(ctx)
        if reaper.ImGui_Button(ctx, ' GENERATE GROOVE ', -1) then GenerateMIDI() end

        reaper.ImGui_End(ctx)
    end
    if open then reaper.defer(loop) end
end

reaper.defer(loop)