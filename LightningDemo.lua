-- LightningDemo.lua
-- Procedural multi-termination lightning demo
-- Classic Era (11509) concept for WoW Forever (16001)

local addonName = "LightningDemo"
local frame = CreateFrame("Frame", "LightningDemoFrame", UIParent)
frame:SetAllPoints(UIParent)
frame:SetMovable(false)
frame:EnableMouse(false)
frame:SetFrameStrata("TOOLTIP")
frame:SetFrameLevel(1000)
frame:Hide()

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0.02, 0.02, 0.06, 0.25)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -20)
title:SetText("Lightning Demo - /lightning config for options")

local info = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
info:SetPoint("BOTTOM", 0, 20)
info:SetText("Fast flash + flicker | color variation | branching falloff | /lightning config")

-- Line drawing
local linePool = {}
local function GetLine()
    local line = table.remove(linePool)
    if not line then
        line = frame:CreateTexture(nil, "OVERLAY")
        line:SetTexture("Interface\\Buttons\\WHITE8X8")
        line:SetBlendMode("ADD")
    end
    line:Show()
    return line
end

local function ReleaseLine(line)
    line:Hide()
    table.insert(linePool, line)
end

local activeLines = {}

local function ClearLines()
    for _, line in ipairs(activeLines) do
        ReleaseLine(line)
    end
    wipe(activeLines)
end

local function DrawSegment(x1, y1, x2, y2, r, g, b, thickness, withGlow)
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx*dx + dy*dy)
    if length < 1 then length = 1 end
    local angle = math.atan2(dy, dx)
    local midX, midY = (x1 + x2) / 2, (y1 + y2) / 2

    if withGlow ~= false then
        local glowPad = math.max(4, thickness * 1.8)
        local glow = GetLine()
        glow:ClearAllPoints()
        glow:SetSize(length, thickness + glowPad)
        glow:SetPoint("CENTER", frame, "CENTER", midX, midY)
        glow:SetRotation(angle)
        glow:SetVertexColor(1, 0.95, 0.6, 0.4)
        table.insert(activeLines, glow)

        local glow2 = GetLine()
        glow2:ClearAllPoints()
        glow2:SetSize(length, thickness + glowPad * 0.5)
        glow2:SetPoint("CENTER", frame, "CENTER", midX, midY)
        glow2:SetRotation(angle)
        glow2:SetVertexColor(r or 1, g or 1, b or 1, 0.6)
        table.insert(activeLines, glow2)
    end

    local line = GetLine()
    line:ClearAllPoints()
    line:SetSize(length, thickness or 3)
    line:SetPoint("CENTER", frame, "CENTER", midX, midY)
    line:SetRotation(angle)
    line:SetVertexColor(r or 1, g or 1, b or 1, 1)
    table.insert(activeLines, line)
end

local markerPool = {}
local activeMarkers = {}
local function ClearMarkers()
    for _, m in ipairs(activeMarkers) do
        m:Hide()
        table.insert(markerPool, m)
    end
    wipe(activeMarkers)
end

local function DrawMarker(x, y, r, g, b)
    return
end

-- Visible messages on a custom chat channel via C_ChatInfo.SendChatMessage
local CHANNEL_NAME = "LightningDemo"
local channelID = nil

local function RefreshChannelID()
    local id = GetChannelName(CHANNEL_NAME)
    if id and id > 0 then
        channelID = id
        return id
    end
    return nil
end

local function LPrint(text)
    local id = GetChannelName(CHANNEL_NAME)
    if not id or id <= 0 then
        print("|cFF88AAFF[Lightning]|r " .. text)
        return
    end
    channelID = id
    local clean = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("[^%w%s%p]", ""):sub(1, 255)
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(clean, "CHANNEL", nil, id)
    else
        SendChatMessage(clean, "CHANNEL", nil, id)
    end
end

local function AttachChannel()
    local id = RefreshChannelID()
    if not id then return end
    if ChatFrame_AddChannel and ChatFrame1 then
        pcall(ChatFrame_AddChannel, ChatFrame1, CHANNEL_NAME)
    end
end

local function JoinLightning()
    if RefreshChannelID() then
        return true
    end
    JoinChannelByName(CHANNEL_NAME)
    return false
end

local function EnsureJoined()
    if RefreshChannelID() then
        AttachChannel()
        return
    end
    JoinChannelByName(CHANNEL_NAME)
    local tries = 0
    local function Retry()
        tries = tries + 1
        if RefreshChannelID() then
            print("|cFF88AAFF[LightningDemo]|r Joined " .. CHANNEL_NAME .. " (ID " .. channelID .. ").")
            AttachChannel()
            return
        end
        if tries >= 6 then return end
        JoinChannelByName(CHANNEL_NAME)
        C_Timer.After(1.0, Retry)
    end
    C_Timer.After(1.0, Retry)
end

local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:RegisterEvent("PLAYER_ENTERING_WORLD")
init:SetScript("OnEvent", function(self, event)
    C_Timer.After(0.5, EnsureJoined)
end)





-- Config
local config = {
    minGround = 5,
    maxGround = 12,
    animDelay = 0.018,
    holdTime = 1.8,
    minWait = 10,
    maxWait = 40,
    flicker = true,
    worldMode = false,
}

-- Node generation
local animTimer
local flickerTimer
local function GenerateStrike()
    ClearLines()
    ClearMarkers()
    if animTimer then animTimer:Cancel() end
    if flickerTimer then flickerTimer:Cancel() end

    local scale = config.worldMode and 7.5 or 9.5
    local groundStrikes = math.random(config.minGround, config.maxGround)
    local segments = {}

    -- Distance first so horizontal node spacing can shrink with distance
    local fakeDistanceYards = math.random(200, 2200)
    local thunderDelay = fakeDistanceYards / 375
    local minDist, maxDist = 200, 2200
    local d = math.max(minDist, math.min(maxDist, fakeDistanceYards))
    local refDist = 300
    local sizeScale = math.max(0.28, math.min(1.4, refDist / d))
    -- Extra compression on sideways steps so far strikes look tighter
    local hSpacing = sizeScale * 0.85

    local function QueueSegment(x1, y1, x2, y2, r, g, b, thick, heightFactor)
        table.insert(segments, {x1, y1, x2, y2, r, g, b, thick, heightFactor or 1})
    end

    local cloudPath = {}
    local cx, cy = math.random(-120, 120) * hSpacing, 380
    table.insert(cloudPath, {x = cx, y = cy})
    DrawMarker(cx, cy, 0.7, 0.85, 1)

    local upperSteps = math.random(4, 7)
    for i = 1, upperSteps do
        local prev = cloudPath[#cloudPath]
        cx = prev.x + math.random(-50, 50) * scale * 0.16 * hSpacing
        cy = prev.y - math.random(28, 50) * scale * 0.2
        cx = math.max(-450, math.min(450, cx))
        table.insert(cloudPath, {x = cx, y = cy})
        DrawMarker(cx, cy, 0.8, 0.9, 1)
    end

    for i = 1, #cloudPath - 1 do
        local a, b = cloudPath[i], cloudPath[i+1]
        local h = (a.y + 400) / 800
        QueueSegment(a.x, a.y, b.x, b.y, 1, 1, 1, 4.5, h)
        QueueSegment(a.x + 1, a.y, b.x - 1, b.y, 0.85, 0.9, 1, 2.5, h)
    end

    local branchPoints = {}
    for i = 1, groundStrikes do
        local idx = math.random(math.max(2, #cloudPath - 4), #cloudPath - 1)
        table.insert(branchPoints, cloudPath[idx])
    end

    for g = 1, groundStrikes do
        local start = branchPoints[g] or cloudPath[#cloudPath]
        local path = {{x = start.x, y = start.y}}
        local px, py = start.x, start.y
        local dirBias = (g - (groundStrikes + 1) / 2) * 70 * hSpacing

        local heightBias = math.max(0.6, (start.y + 200) / 600)
        local steps = math.floor(math.random(5, 10) * heightBias)

        for s = 1, steps do
            local progress = s / steps
            local down = math.random(20, 40) * scale * 0.3 * (1.1 - progress * 0.3)
            local side = (math.random(-40, 40) * scale * 0.22 + dirBias * 0.18) * hSpacing
            if math.random() < (0.15 + progress * 0.25) and s > 2 then
                local bx = px + math.random(-40, 40) * hSpacing
                local by = py - math.random(10, 25)
                QueueSegment(px, py, bx, by, 0.7, 0.8, 1, 1.5, (py + 400) / 800)
            end
            px = px + side
            py = py - down
            px = math.max(-520, math.min(520, px))
            py = math.max(-380, py)
            table.insert(path, {x = px, y = py})
            DrawMarker(px, py, 0.9, 0.95, 1)
        end

        local thick = (g == 1) and 3.8 or 2.4
        for i = 1, #path - 1 do
            local a, b = path[i], path[i+1]
            local h = (a.y + 400) / 800
            QueueSegment(a.x, a.y, b.x, b.y, 0.95, 0.97, 1, thick, h)
        end

        local endNode = path[#path]
        for f = 1, math.random(1, 3) do
            local fx = endNode.x + math.random(-45, 45) * hSpacing
            local fy = endNode.y + math.random(-6, 10)
            QueueSegment(endNode.x, endNode.y, fx, fy, 0.8, 0.85, 1, 1.6, 0.2)
            DrawMarker(fx, fy, 1, 0.7, 0.3)
        end
    end

    local STRIKE_SOUND = 30
    local LEADUP_SOUND = 31
    -- fakeDistanceYards, thunderDelay, sizeScale already computed above
    local horizonY = 40
    local closeBaseY = -360
    local baseY = horizonY + (closeBaseY - horizonY) * (sizeScale / 1.4)
    local topY = 440

    local function ScalePoint(x, y)
        local normY = (y + 380) / 760
        local scaledY = baseY + normY * (topY - baseY)
        local scaledX = x * sizeScale
        return scaledX, scaledY
    end

    local scaledSegments = {}
    for _, s in ipairs(segments) do
        local x1, y1 = ScalePoint(s[1], s[2])
        local x2, y2 = ScalePoint(s[3], s[4])
        local scaledThick = math.max(1.2, s[8] * sizeScale * 1.6)
        table.insert(scaledSegments, {x1, y1, x2, y2, s[5], s[6], s[7], scaledThick, s[9]})
    end
    segments = scaledSegments

    local function PlayStrikeSound()
        -- Simulate distance volume by briefly adjusting SFX volume (Classic has no per-call volume)
        local oldVol = GetCVar("Sound_SFXVolume") or "1"
        local vol = math.max(0.15, math.min(1.0, 1.0 - (fakeDistanceYards / 2500)))
        SetCVar("Sound_SFXVolume", tostring(vol))
        PlaySound(STRIKE_SOUND, "SFX")
        C_Timer.After(1.5, function()
            SetCVar("Sound_SFXVolume", oldVol)
        end)
        LPrint("|cFF88AAFFStrike!|r ~" .. math.floor(fakeDistanceYards) .. " yd (" .. string.format("%.1f", thunderDelay) .. "s) — scale " .. string.format("%.2f", sizeScale) .. " — vol " .. string.format("%.0f", vol * 100) .. "%.")
    end

    local idx = #segments
    local function Flicker()
        if not config.flicker then return end
        for _, line in ipairs(activeLines) do
            if line:IsShown() then
                line:SetAlpha(0.6 + math.random() * 0.4)
            end
        end
        flickerTimer = C_Timer.After(0.04, Flicker)
    end

    local function ScheduleNext()
        local wait = math.random(config.minWait, config.maxWait)
        LPrint("|cFFAAAAAANext strike in " .. wait .. "s.|r")
        local leadUpTime = math.max(1.5, wait - 2.5)
        C_Timer.After(leadUpTime, function()
            if frame:IsShown() then
                PlaySound(LEADUP_SOUND, "SFX")
                LPrint("|cFFAAAAAALead-up (sound 31)...|r")
            end
        end)
        animTimer = C_Timer.After(wait, function()
            if frame:IsShown() then GenerateStrike() end
        end)
    end

    local function NextSegment()
        if idx < 1 then
            C_Timer.After(thunderDelay, PlayStrikeSound)
            if config.flicker then Flicker() end
            animTimer = C_Timer.After(config.holdTime, function()
                if flickerTimer then flickerTimer:Cancel() end
                ClearLines()
                ClearMarkers()
                ScheduleNext()
            end)
            return
        end
        local s = segments[idx]
        local yellowBias = math.max(0, 0.4 - s[9] * 0.5)
        DrawSegment(s[1], s[2], s[3], s[4], s[5], s[6] + yellowBias * 0.15, s[7], s[8], true)
        idx = idx - 1
        animTimer = C_Timer.After(config.animDelay, NextSegment)
    end

    NextSegment()

    LPrint("|cFF88AAFFLightning Demo:|r " .. groundStrikes .. " ground points" .. (config.worldMode and " (world-sim)" or "") .. ".")
    LPrint("|cFFAAAAAAStrike sound in ~" .. string.format("%.1f", thunderDelay) .. "s.|r")
end

SLASH_LIGHTNINGDEMO1 = "/lightning"
SLASH_LIGHTNINGDEMO2 = "/ldemo"
SlashCmdList["LIGHTNINGDEMO"] = function(msg)
    msg = (msg or ""):lower():trim()
    if msg == "hide" then
        frame:Hide()
        if animTimer then animTimer:Cancel() end
        if flickerTimer then flickerTimer:Cancel() end
        LPrint("Hidden. Cycle stopped.")
    elseif msg == "join" or msg == "chat" then
        JoinLightning()
        print("|cFF88AAFFChannel:|r " .. CHANNEL_NAME .. " ID " .. tostring(channelID or "none"))
    elseif msg == "flicker" then
    elseif msg == "flicker" then
        config.flicker = not config.flicker
        LPrint("|cFF88AAFFFlicker:|r " .. (config.flicker and "on" or "off"))
    elseif msg == "world" then
        config.worldMode = not config.worldMode
        LPrint("|cFF88AAFFWorld projection mode:|r " .. (config.worldMode and "on (simulated)" or "off"))
        LPrint("|cFFAAAAAATrue camera projection is engine-side. This only adjusts scale/spread.|r")
    elseif msg:find("^min ") then
        config.minGround = tonumber(msg:match("%d+")) or config.minGround
        LPrint("|cFF88AAFFMin ground strikes:|r " .. config.minGround)
    elseif msg:find("^max ") then
        config.maxGround = tonumber(msg:match("%d+")) or config.maxGround
        LPrint("|cFF88AAFFMax ground strikes:|r " .. config.maxGround)
    elseif msg == "config" or msg == "help" then
        LPrint("|cFF88AAFFLightningDemo commands:|r")
        LPrint("  /lightning          — regenerate now")
        LPrint("  /lightning hide     — hide + stop cycle")
        LPrint("  /lightning show     — show + generate")
        LPrint("  /lightning flicker  — toggle flicker")
        LPrint("  /lightning world    — toggle world-sim mode")
        LPrint("  /lightning min N    — set min ground strikes")
        LPrint("  /lightning max N    — set max ground strikes")
        LPrint("  /lightning chat     — show/hide message window")
        LPrint("  Channel: /join LightningDemo")
        LPrint("  /lightning config   — this help")
    else
        frame:Show()
        GenerateStrike()
    end
end

frame:Show()
GenerateStrike()

print("|cFF88AAFFLightningDemo r42 loaded.|r MD synced. /lightning")
print("|cFFAAAAAAEnable the LightningDemo channel in a chat window to see messages.|r")
