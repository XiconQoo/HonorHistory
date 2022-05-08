local ADDON_NAME, H = ...
H.modules = {}

local date, time = date, time
local str_find = string.find
local tonumber = tonumber
local CreateFrame = CreateFrame
local PVPHonor = _G["PVPHonor"]

local HonorHistory = CreateFrame("Frame", "HonorHistory", UIParent)
H.HonorHistory = HonorHistory

function HonorHistory:Initialize()
    -- add lines
    PVPHonor.honorLabel = PVPHonor:CreateFontString("PVPHonorHonorLabel", "BACKGROUND", "GameFontDisableSmall")
    PVPHonor.honorLabel:SetPoint("TOPRIGHT", PVPHonorKillsLabel, "BOTTOMRIGHT")
    PVPHonor.honorLabel:SetJustifyH("RIGHT")
    PVPHonor.honorLabel:SetText(HONOR)
    PVPHonor.todayHonor = PVPHonor:CreateFontString("PVPHonorTodayHonor", "BACKGROUND", "GameFontHighlightSmall")
    PVPHonor.todayHonor:SetPoint("TOP", PVPHonorTodayKills, "BOTTOM")
    PVPHonor.yesterdayHonor = PVPHonor:CreateFontString("PVPHonorYesterdayHonor", "BACKGROUND", "GameFontHighlightSmall")
    PVPHonor.yesterdayHonor:SetPoint("TOP", PVPHonorYesterdayKills, "BOTTOM")

    self:Call("Initialize")
end

----------------------
-- EVENTS
----------------------

HonorHistory:RegisterEvent("ADDON_LOADED")
HonorHistory:RegisterEvent("PLAYER_LOGOUT")
HonorHistory:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
HonorHistory:SetScript("OnEvent", function(self, event, msg)
    self[event](self, msg)
end)

local updateInterval, lastUpdate = 20, 0
HonorHistory:SetScript("OnUpdate", function(self, elapsed)
    lastUpdate = lastUpdate + elapsed
    if lastUpdate > updateInterval then
        self:UpdateSavedVariables()
        lastUpdate = 0;
    end
end)

function HonorHistory:ADDON_LOADED(msg)
    if msg ~= ADDON_NAME then
        return
    end
    H.db = HonorHistorySV
    if H.db == nil then
        H.db = { today = { date = date("%m/%d/%y"), honor = 0},
                 yesterday = { date = date("%m/%d/%y", time()-24*60*60), honor = 0}
        }
    end
    self:Initialize()
    self:UpdateSavedVariables()
    self:UpdateHonor()
end

function HonorHistory:PLAYER_LOGOUT()
    HonorHistorySV = H.db
end

function HonorHistory:CHAT_MSG_COMBAT_HONOR_GAIN(msg)
    local honor = HonorHistory:FindHonor(msg)
    if honor then
        H.db["today"].honor = H.db["today"].honor + honor -- add honor here
        self:UpdateHonor(honor)
        self:Call("UpdateHonor", honor)
    end
end

----------------------
-- HELPER
----------------------

function HonorHistory:Call(func, ...)
    for _, module in pairs(H.modules) do
        module[func](module, ...)
    end
end

function HonorHistory:UpdateHonor()
    PVPHonor.todayHonor:SetText(H.db["today"] and H.db["today"].honor or 0)
    PVPHonor.yesterdayHonor:SetText(H.db["yesterday"] and H.db["yesterday"].honor or 0)
end

function HonorHistory:UpdateSavedVariables()
    local dateToday = date("%m/%d/%y")
    local dateYesterday = date("%m/%d/%y", time()-24*60*60)
    if H.db["today"] and H.db["today"].date ~= dateToday then
        H.db["yesterday"] = {
            date = H.db["today"].date,
            honor = H.db["today"].honor
        }
        H.db["today"] = { date = dateToday, honor = 0}
    end
    if H.db["yesterday"] and H.db["yesterday"].date ~= dateYesterday then
        H.db["yesterday"] = {
            date = dateYesterday,
            honor = 0
        }
    end
    self:Call("UpdateSavedVariables", dateToday, dateYesterday)
end

----------------------
-- PATTERN + MATCHER
----------------------

local function createPattern(str)
    return str:gsub("(%()", "%%(")
              :gsub("(%))", "%%)")
              :gsub("(%%s)", ".+")
              :gsub("(%%d)", "(.+)")
end

local COMBATLOG_HONORGAIN_pattern = createPattern(COMBATLOG_HONORGAIN)
local COMBATLOG_HONORGAIN_NO_RANK_pattern = createPattern(COMBATLOG_HONORGAIN_NO_RANK)
local COMBATLOG_HONORGAIN_EXHAUSTION1_pattern = createPattern(COMBATLOG_HONORGAIN_EXHAUSTION1)
local COMBATLOG_HONORGAIN_NO_RANK_EXHAUSTION1_pattern = createPattern(COMBATLOG_HONORGAIN_NO_RANK_EXHAUSTION1)
local COMBATLOG_HONORAWARD_pattern = COMBATLOG_HONORAWARD:gsub("(%%d)", "(%%d+)")

function HonorHistory:Extract(str, pattern)
    if not pattern or not str then
        return nil
    end
    local find = str_find(str, pattern) and {str_find(str, pattern)} or nil
    return find and find[3] and tonumber(find[3]) or nil
end

function HonorHistory:FindHonor(msg)
    if not msg then
        return nil
    end
    if HonorHistory:Extract(msg, COMBATLOG_HONORGAIN_pattern) then
        return HonorHistory:Extract(msg, COMBATLOG_HONORGAIN_pattern)
    end
    if HonorHistory:Extract(msg, COMBATLOG_HONORAWARD_pattern) then
        return HonorHistory:Extract(msg, COMBATLOG_HONORAWARD_pattern)
    end
    if HonorHistory:Extract(msg, COMBATLOG_HONORGAIN_EXHAUSTION1_pattern) then
        return HonorHistory:Extract(msg, COMBATLOG_HONORGAIN_EXHAUSTION1_pattern)
    end
    if HonorHistory:Extract(msg, COMBATLOG_HONORGAIN_NO_RANK_EXHAUSTION1_pattern) then
        return HonorHistory:Extract(msg, COMBATLOG_HONORGAIN_NO_RANK_EXHAUSTION1_pattern)
    end
    if HonorHistory:Extract(msg, COMBATLOG_HONORGAIN_NO_RANK_pattern) then
        return HonorHistory:Extract(msg, COMBATLOG_HONORGAIN_NO_RANK_pattern)
    end
end



