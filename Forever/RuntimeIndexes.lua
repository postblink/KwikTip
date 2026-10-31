-- Build Forever lookups without loading Retail/Timewalking data.
local ADDON_NAME, KwikTip = ...

local function add(index, id, entry, label)
    if id == nil then return end
    assert(type(id) == "number" and id > 0 and id % 1 == 0,
        "Unverified or invalid Forever " .. label)
    assert(index[id] == nil or index[id] == entry,
        "Duplicate Forever " .. label .. ": " .. tostring(id))
    index[id] = entry
end

function KwikTip:BuildRuntimeIndexes()
    local instances, maps, encounters, bossNPCs, trashNPCs = {}, {}, {}, {}, {}
    for _, dungeon in ipairs(self.DUNGEONS) do
        assert(dungeon.instanceID ~= nil, "Forever dungeon needs a verified instanceID")
        add(instances, dungeon.instanceID, dungeon, "instanceID")
        add(maps, dungeon.uiMapID, dungeon, "uiMapID")
        for _, id in ipairs(dungeon.altMapIDs or {}) do
            add(maps, id, dungeon, "alternate uiMapID")
        end
        for _, boss in ipairs(dungeon.bosses or {}) do
            local entry = { dungeon = dungeon, boss = boss }
            assert(boss.encounterID ~= nil, "Forever boss needs a verified encounterID")
            add(encounters, boss.encounterID, entry, "encounterID")
            for _, id in ipairs(boss.altEncounterIDs or {}) do
                add(encounters, id, entry, "alternate encounterID")
            end
            add(bossNPCs, boss.npcID, entry, "boss npcID")
            for _, id in ipairs(boss.altNpcIDs or {}) do
                add(bossNPCs, id, entry, "alternate boss npcID")
            end
        end
        for _, mob in ipairs(dungeon.trash or {}) do
            add(trashNPCs, mob.npcID, { dungeon = dungeon, mob = mob }, "trash npcID")
        end
    end
    self.DUNGEON_BY_INSTANCEID = instances
    self.DUNGEON_BY_UIMAPID = maps
    self.BOSS_BY_ENCOUNTERID = encounters
    self.BOSS_BY_NPCID = bossNPCs
    self.TRASH_BY_NPCID = trashNPCs
end

KwikTip:BuildRuntimeIndexes()
