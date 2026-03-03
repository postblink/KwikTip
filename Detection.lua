-- KwikTip: Dungeon detection and HUD content engine
local ADDON_NAME, KwikTip = ...

-- ============================================================
-- Content formatting
-- ============================================================

local GOLD  = "|cffffcc00"
local WHITE = "|cffffffff"
local GRAY  = "|cff999999"
local RESET = "|r"

-- Build the string shown inside the HUD for a known dungeon.
local function FormatDungeonContent(dungeon)
    local lines = {}

    -- Header: dungeon name in gold
    lines[#lines + 1] = GOLD .. dungeon.name .. RESET

    -- Boss list
    for i, boss in ipairs(dungeon.bosses) do
        local entry
        if boss.tip and boss.tip ~= "" then
            entry = string.format("%s%d. %s%s  " .. GRAY .. "%s" .. RESET,
                WHITE, i, boss.name, RESET, boss.tip)
        else
            entry = string.format("%s%d. %s%s", WHITE, i, boss.name, RESET)
        end
        lines[#lines + 1] = entry
    end

    return table.concat(lines, "\n")
end

-- ============================================================
-- Detection
-- ============================================================

-- Identify the current dungeon and push content to the HUD.
-- Called on zone transitions and login.
function KwikTip:UpdateContent()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or (instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario") then
        self:SetContent("")
        return
    end

    local mapID  = C_Map.GetBestMapForUnit("player")
    local dungeon = mapID and KwikTip.DUNGEON_BY_UIMAPID[mapID]

    if dungeon then
        self:SetContent(FormatDungeonContent(dungeon))
    else
        -- Inside an instance we don't have data for yet.
        self:SetContent(GRAY .. "No data for this instance." .. RESET)
    end
end
