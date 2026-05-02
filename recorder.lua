local sheltersByCell = require("Rain Sheltering.shelter_locations")
local config = require("Rain Sheltering.config")

local M = {}

--- @class mwseLogger
--- @field name string modName

--- @param log mwseLogger
function M.register(log)
	local function notify(message)
		tes3.messageBox("[%s] %s", log.name, message)
	end

	local function isExteriorCell(cell)
		return cell and cell.isOrBehavesAsExterior == true
	end

	local function getCellKey(cell)
		if not cell or not cell.id then
			return nil
		end
		return cell.id
	end

	local function addShelterAtPlayerPosition()
		local player = tes3.player
		if not player then return end

		local cell = player.cell
		if not isExteriorCell(cell) then
			notify("Only in exterior-cells")
			return
		end

		local key = getCellKey(cell)
		if not key then return end

		local points = sheltersByCell[key] or {}
		local position = player.position
		local point = {
			name = string.format("%s_%02d", key:gsub("%s+", "_"), #points + 1),
			x = math.floor(position.x + 0.5),
			y = math.floor(position.y + 0.5),
			z = math.floor(position.z + 0.5),
		}

		sheltersByCell[key] = points
		table.insert(points, point)

		log:info(
			"Added shelter point for cell '%s': { name = '%s', x = %d, y = %d, z = %d }",
			key,
			point.name,
			point.x,
			point.y,
			point.z
		)
		notify(string.format("Added point '%s' â '%s'", point.name, key))
	end

	local function onKeyDown(e)
		if e.isRepeat then return end
		if tes3ui.menuMode() then return end
		if e.keyCode ~= config.recordHotkey then return end

		addShelterAtPlayerPosition()
	end

	event.register(tes3.event.keyDown, onKeyDown)
end

return M