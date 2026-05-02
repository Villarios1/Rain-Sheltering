local config = require("Rain Sheltering.config")
local log = require("Rain Sheltering.log")

local function isClassExcluded(npc)
    if config.excludedClasses[npc.object.class.id] then
        log:debug("class is excluded: %s", config.excludedClasses[npc.object.class.id])
    end
    return config.excludedClasses[npc.object.class.id]
end

local function isIdNpcExcluded(npc)
    log:debug("isIdNpcExcluded: %s, %s", npc.baseObject.id, config.excludedObjectIdNpc[npc.baseObject.id])
    return config.excludedObjectIdNpc[npc.baseObject.id]
end

local function hasQuestBlock(npc)
    local requirements = config.questRequirements[npc.baseObject.id]
    -- Если у NPC нет квестов, из-за которого он не должен передвигаться
    if not requirements then return false end

    for _, requirement in ipairs(requirements) do
        local currentQuestStage = tes3.getJournalIndex({id = requirement.journal})
        if currentQuestStage < requirement.stageComplete then
            log:debug("Quest %s not finished: %s < %s", requirement.journal, currentQuestStage, requirement.stageComplete)
            return true
        end
    end

    return false
end

-- Состояние NPC, при котором его нужно выписать из укрытия
---@param reference tes3reference
---@return boolean
return function(reference)
    if not reference or reference.deleted then
        log:debug("Bug in isValidNpc. NPC has no reference: %s", reference.id)
        return false
    end
    if not reference.mobile then
        log:debug("Bug in isValidNpc. NPC has no mobile: %s", reference.id)
        return false
    end
    if reference.mobile.objectType ~= tes3.objectType.mobileNPC then
        log:debug("Bug in isValidNpc. NPC is not mobile: %s", reference.mobile.objectType)
        return false
    end
    if reference.disabled then
        return false
    end
    if reference.mobile.isDead then
        log:debug("NPC is dead: %s", reference.id)
        return false
    end

    -- if escort/follow/activate
    local package = tes3.getCurrentAIPackageId({ reference = reference })
    if package ~= tes3.aiPackage.wander
        and package ~= tes3.aiPackage.travel
        and package ~= tes3.aiPackage.none then -- если NPC находится за activeCells - ему ставится none ?
        log:debug("NPC is invalid due to package: %s, %s", reference.id, tes3.getCurrentAIPackageId({ reference = reference }))
        return false
    end

    if isClassExcluded(reference) then
        return false
    end

    if isIdNpcExcluded(reference) then
        return false
    end

    if hasQuestBlock(reference) then
        return false
    end

    return true
end