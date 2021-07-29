--[[
Minetest Mod Storage Drawers - A Mod adding storage drawers

Copyright (C) 2017-2020 Linus Jahn <lnj@kaidan.im>

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- Load support for intllib.
local MP = core.get_modpath(core.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

-- these are used for multiple other loaded lua files
pipeworks_loaded = core.get_modpath("pipeworks") and pipeworks
tubelib_loaded = nil
default_loaded = core.get_modpath("default") and default
mcl_loaded = core.get_modpath("mcl_core") and mcl_core

if core.get_modpath("tubelib") then
	if tubelib.version >= 2.1 then
		tubelib_loaded = true
	else
		core.log("Warning", "Tubelib version must be at least v2.1 to work with drawers")
	end
end

drawers = {}
drawers.drawer_visuals = {}

drawers.WOOD_ITEMSTRING = "group:wood"
if default_loaded then
	drawers.WOOD_SOUNDS = default.node_sound_wood_defaults()
	drawers.CHEST_ITEMSTRING = "default:chest"
elseif mcl_loaded then -- MineClone 2
	drawers.CHEST_ITEMSTRING = "mcl_chests:chest"
	if core.get_modpath("mcl_sounds") and mcl_sounds then
		drawers.WOOD_SOUNDS = mcl_sounds.node_sound_wood_defaults()
	end
else
	drawers.CHEST_ITEMSTRING = "chest"
end


drawers.enable_1x1 = not core.settings:get_bool("drawers_disable_1x1")
drawers.enable_1x2 = not core.settings:get_bool("drawers_disable_1x2")
drawers.enable_2x2 = not core.settings:get_bool("drawers_disable_2x2")

drawers.CONTROLLER_RANGE = 14

--
-- GUI
--

drawers.gui_bg = "bgcolor[#080808BB;true]"
drawers.gui_slots = "listcolors[#00000069;#5A5A5A;#141318;#30434C;#FFF]"
if mcl_loaded then-- MCL2
	drawers.gui_bg_img = "background[5,5;1,1;crafting_creative_bg.png;true]"
else
	drawers.gui_bg_img = "background[5,5;1,1;gui_formbg.png;true]"
end

--
-- Load API
--

dofile(MP .. "/lua/helpers.lua")
dofile(MP .. "/lua/visual.lua")
dofile(MP .. "/lua/api.lua")
dofile(MP .. "/lua/controller.lua")


--
-- Register drawers
--


if mcl_loaded then
	-- {node name, Description, texture ID, recipe ingredient
	for _,v in ipairs({
		{"oakwood", "Oak Wood", "oak_wood", drawers.WOOD_ITEMSTRING},
		{"acaciawood", "Acacia Wood", "acacia_wood_mcl", "mcl_core:acaciawood"},
		{"birchwood", "Birch Wood", "birch_wood", "mcl_core:birchwood"},
		{"darkwood", "Dark Oak Wood", "dark_oak_wood", "mcl_core:darkwood"},
		{"junglewood", "Junglewood", "junglewood_mcl", "mcl_core:junglewood"},
		{"sprucewood", "Spruce Wood", "spruce_wood", "mcl_core:sprucewood"}
	}) do
		drawers.register_drawer("drawers:" .. v[1], {
			description = S(v[2]),
			tilestring = v[3],
			groups = {handy = 1, axey = 1, flammable = 3, wood = 1, building_block = 1, material_wood = 1},
			sounds = drawers.WOOD_SOUNDS,
			drawer_stack_max_factor = 36,
			material = v[4],
			_mcl_blast_resistance = 15,
			_mcl_hardness = 2
		})
	end

	-- backwards compatibility
	core.register_alias("drawers:wood1", "drawers:oakwood1")
	core.register_alias("drawers:wood2", "drawers:oakwood2")
	core.register_alias("drawers:wood4", "drawers:oakwood4")

	for _,v in ipairs({
		-- { node suffix, description, multiplier, ingredient }
		{"iron", "Iron Drawer Upgrade (x2)", 100, "iron_ingot"},
		{"gold", "Gold Drawer Upgrade (x3)", 200, "gold_ingot"},
		{"obsidian","Obsidian Drawer Upgrade (x4)",300, "obsidian"},
		{"diamond","Diamond Drawer Upgrade (x8)",700, "diamond"},
		{"emerald","Emerald Drawer Upgrade (x13)",1200, "emerald"}
	}) do
		drawers.register_drawer_upgrade("drawers:upgrade_" .. v[1], {
			description = S(v[2]),
			inventory_image = "drawers_upgrade_" .. v[1] .. ".png",
			groups = {drawer_upgrade = v[3]},
			recipe_item = "mcl_core:" .. v[4]
		})
	end

	core.register_node("drawers:trim", {
		description = S("Wooden Trim"),
		tiles = {"drawers_trim.png"},
		groups = {drawer_connector = 1, handy = 1, axey = 1, flammable = 3, wood = 1, building_block = 1, material_wood = 1},
		_mcl_blast_resistance = 15,
		_mcl_hardness = 2,
	})

else
	if default_loaded then
		-- This loop didn't need node name separate from texture ID
		-- { Description, node name/texture ID, ingrediet }
		for _,v in ipairs({
			{"Acacia Wood", "acacia", "acacia_wood"},
			{"Aspen Wood", "aspen", "aspen_wood"},
			{"Junglewood", "jungle","junglewood"},
			{"Pine Wood", "pine", "pine_wood"}
		}) do
			drawers.register_drawer("drawers:" .. v[3], {
				description = S(v[1]),
				tilestring = v[3],
				groups = {choppy = 3, oddly_breakable_by_hand = 2},
				sounds = drawers.WOOD_SOUNDS,
				drawer_stack_max_factor = 32,
				material = "default:" .. v[3]
			})
		end

		for _,v in ipairs({
		-- { material, description, multiplier, ingredient }
			{"steel", "Steel Drawer Upgrade (x2)", 100, "steel_ingot"},
			{"gold", "Gold Drawer Upgrade (x3)", 200, "gold_ingot"},
			{"obsidian","Obsidian Drawer Upgrade (x4)",300, "obsidian"},
			{"diamond","Diamond Drawer Upgrade (x8)",700, "diamond"}
		}) do
			drawers.register_drawer_upgrade("drawers:upgrade_" .. v[1], {
				description = S(v[2]),
				inventory_image = "drawers_upgrade_" .. v[1] .. ".png",
				groups = {drawer_upgrade = v[3]},
				recipe_item = "mcl_core:" .. v[4]
			})
		end

		core.register_node("drawers:trim", {
			description = S("Wooden Trim"),
			tiles = {"drawers_trim.png"},
			groups = {drawer_connector = 1, choppy = 3, oddly_breakable_by_hand = 2},
		})
	end

	drawers.register_drawer("drawers:wood", {
		description = S("Wooden"),
		tilestring = "wood",
		groups = {choppy = 3, oddly_breakable_by_hand = 2},
		sounds = drawers.WOOD_SOUNDS,
		drawer_stack_max_factor = 32, -- 4 * 8 normal chest size
		material = drawers.WOOD_ITEMSTRING
	})
end

if core.get_modpath("moreores") then
	drawers.register_drawer_upgrade("drawers:upgrade_mithril", {
		description = S("Mithril Drawer Upgrade (x13)"),
		inventory_image = "drawers_upgrade_mithril.png",
		groups = {drawer_upgrade = 1200},
		recipe_item = "moreores:mithril_ingot"
	})
end

core.register_craft({
	output = "drawers:trim 6",
	recipe = {
		{"group:stick", "group:wood", "group:stick"},
		{"group:wood",  "group:wood",  "group:wood"},
		{"group:stick", "group:wood", "group:stick"}
	}
})

--
-- Register drawer upgrade template
--

core.register_craftitem("drawers:upgrade_template", {
	description = S("Drawer Upgrade Template"),
	inventory_image = "drawers_upgrade_template.png"
})

core.register_craft({
	output = "drawers:upgrade_template 4",
	recipe = {
		{"group:stick", "group:stick", "group:stick"},
		{"group:stick", "group:drawer", "group:stick"},
		{"group:stick", "group:stick", "group:stick"}
	}
})

--
-- Set tubelib tubes as drawer connectors
--

if core.get_modpath("tubelib") then
	for _,v in ipairs({"A", "S"}) do
		local n = minetest.registered_nodes["tubelib:tube" .. v]
		local g = table.copy(n.groups)
		g.drawer_connector = 1
		core.override_item("tubelib:tube" .. v, {groups = g})
	end
end
