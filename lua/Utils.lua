H = wesnoth.require "lua/helper.lua"
-- W = wml.fire
W = H.set_wml_action_metatable {}
-- Define your global constants here.
on_mouse_over={}

--H.set_wml_var_metatable(_G)

-- Define your global functions here.

-- chat tags,
-- have to override default [chat] tag to allow for no-speaker messages
-- can enter speaker="" for just a general statement, will not show <>
function wesnoth.wml_actions.chat(cfg)
	local side_list = wesnoth.get_sides(cfg)
	local message = tostring(cfg.message) or
		helper.wml_error "[chat] missing required message= attribute."

	local speaker = cfg.speaker
	if speaker then
		speaker = tostring(speaker)
	else
		speaker = ""
	end

	for index, side in ipairs(side_list) do
		if side.controller == "human" then
			wesnoth.message(speaker, message)
			break
		end
	end
end

-- command line alteration of units in the [variables] container
-- :lua unit.talentpoints=100
-- function modu(var, val)
--   local x, y = wesnoth.get_selected_tile()
--   H.modify_unit({ x = x, y = y }, { ["variables."..var] = val })
-- end
-- unit = setmetatable({}, { __newindex = function(t, k, v) modu(k, v) end })

--! [store_shroud]
--! melinath

-- Given side= and variable=, stores that side's shroud data in that variable
-- Example:
-- [store_shroud]
--     side=1
--     variable=shroud_data
-- [/store_shroud]
function wesnoth.wml_actions.store_shroud(cfg)
	local team_num = cfg.side or H.wml_error("[store_shroud] expects a side= attribute.")
	local var = cfg.variable or H.wml_error("[store_shroud] expects a variable= attribute.")
	--local team = wesnoth.get_side(team_num)
	local team = wesnoth.sides[team_num]
	local current_shroud = team.__cfg.shroud_data
	wml.variables[var] = current_shroud
end

--! [set_shroud]
--! melinath

-- Given shroud data, removes the shroud in the marked places on the map.
-- Example:
-- [set_shroud]
--     side=1
--     shroud_data=$shroud_data # stored with store_shroud, for example!
-- [/set_shroud]
function wesnoth.wml_actions.set_shroud(cfg)
	local team_num = cfg.side or H.wml_error("[store_shroud] expects a side= attribute.")
	local shroud = cfg.shroud_data or H.wml_error("[store_shroud] expects a shroud_data= attribute.")
	if shroud == nil then
		H.wml_error("[set_shroud] was passed a nil shroud string")
	elseif string.sub(shroud,1,1)~="|" then
		H.wml_error("[set_shroud] was passed an invalid shroud string.")
	else
		local w,h,b=wesnoth.get_map_size()
		local shroud_x= (1-b)
		for r in string.gmatch(shroud,"|(%d*)") do
			local shroud_y=(1-b)
			for c in string.gmatch(r,"%d") do
				if c == "1" then
					W.remove_shroud { side = team_num, x = shroud_x, y = shroud_y }
				else
					W.place_shroud { side = team_num, x = shroud_x, y = shroud_y }
				end
				shroud_y=shroud_y+1
			end
			shroud_x=shroud_x+1
		end
	end
end

function wesnoth.wml_actions.get_distance(cfg)
	local x1 = cfg.x1 or H.wml_error("[get_distance] expects a x1= attribute")
	local y1 = cfg.y1 or H.wml_error("[get_distance] expects a y1= attribute")
	local x2 = cfg.x2 or H.wml_error("[get_distance] expects a x2= attribute")
	local y2 = cfg.y2 or H.wml_error("[get_distance] expects a y2= attribute")
	local var_name = cfg.variable or "distance"
	wml.variables[var_name] = wesnoth.map.distance_between(x1, y1, x2, y2)
end

function wesnoth.wml_actions.get_defense(cfg)
	local terrain = cfg.terrain or wesnoth.get_terrain(cfg.x, cfg.y) or H.wml_error("[get_defense] expects either a terrain= attribute or x= and y= attributes")
	local u
	if cfg.unit then
		local upath = wml.variables[cfg.unit]
		u = wesnoth.get_units({ id = upath.id })[1]
	else
		u = (wesnoth.create_unit { type = cfg.type or H.wml_error("[get_defense] expects either a unit= attribute or a type= attribute") })
	end
	local var = cfg.variable or "defense"
	wml.variables[var] = wesnoth.unit_defense(u, terrain)
end

function wesnoth.wml_actions.get_move_cost(cfg)
	local terrain = cfg.terrain or wesnoth.get_terrain(cfg.x, cfg.y) or H.wml_error("[get_move_cost] expects either a terrain= attribute or x= and y= attributes")
	local u
	if cfg.unit then
		local upath = wml.variables[cfg.unit]
		u = wesnoth.get_units({ id = upath.id })[1]
	else
		u = (wesnoth.create_unit { type = cfg.type }) or H.wml_error("[get_defense] expects either a unit= attribute or a type= attribute")
	end
	local var = cfg.variable or "movement_cost"
	wml.variables[var] = wesnoth.unit_movement_cost(u, terrain)
end

function wesnoth.wml_actions.generate_shop_details(cfg)
	local shop = cfg.shop or H.wml_error("[generate_shop_details]: no shop attribute given")

	local unit_type, shop_descriptors

	if shop == "weapon" or shop == "armor" then
		unit_type = H.rand("Master Bowman,Swordsman,Spearman,Sergeant,Pikeman,Longbowman,Javelineer,Heavy Infantryman,Bowman,Dwarvish Dragonguard,Dwarvish Fighter,Dwarvish Guardsman,Dwarvish Sentinel,Dwarvish Thunderer,Elvish Ranger,Elvish Marksman,Elvish Hero,Elvish Fighter,Elvish Captain,Elvish Archer")
		if shop == "weapon" then
			shop_descriptors = "Arms,Blades"
		else
			shop_descriptors = "Armor,Vestments,Shields"
		end
	elseif shop == "magic" then
		unit_type = H.rand("White Mage,Silver Mage,Red Mage,Mage of Light,Arch Mage,Elvish Shaman,Elvish Sorceress,Elvish Sylph,Dwarvish Runemaster")
		shop_descriptors = "Apothecary,Library,Magic Shoppe,Magical Supplies,Alchemy Store"
	elseif shop == "tavern" then
		unit_type = H.rand("Ruffian,Thug,Dwarvish Dragonguard,Dwarvish Fighter,Dwarvish Guardsman,Dwarvish Sentinel,Dwarvish Thunderer")
		shop_descriptors = "Tavern,Pub,Public House"
	else
		H.wml_error(string.format("[generate_name]: invalid shop attribute given: %s", shop))
	end

	local u = wesnoth.create_unit { type = unit_type, random_gender = "yes" }

	wml.variables[string.format("shop_names.%s", shop)] = u.name
	wesnoth.wml_actions.set_variable({ name = string.format("shop_names.%s2", shop), rand = shop_descriptors })
	wml.variables[string.format("shop_names.%s3", shop)] = u.__cfg.profile
end

-- lifted from: add-ons/Custom_Campaign/lua/wml-tags.lua
function wesnoth.wml_actions.wbd_sort_array ( cfg )
        -- [wbd_sort_array]
                        -- name=name of the array
                        -- first_key=to sort by
                        -- second_key=to sort by if first key is equal
        -- [/wbd_sort_array]
        local tArray = wml.array_access.get(cfg.name)
        local function top_down_left_right(uFirstElem, uSecElem)
                if uFirstElem[cfg.first_key] == uSecElem[cfg.first_key] then
                        return uFirstElem[cfg.second_key] < uSecElem[cfg.second_key]
                end
                return uFirstElem[cfg.first_key] < uSecElem[cfg.first_key]
        end
        table.sort(tArray, top_down_left_right)
        wml.array_access.set(cfg.name, tArray)
end

-- parse_container - convert a WML Lua container into a more Lua-friendly
-- structure. The result will contain a pair of Lua tables for each level
-- of the WML container:
-- parsed.k = key/scalar-value pairs from the WML container
-- parsed.c = key/container pairs from the WML container
function parse_container(wml)
	local parsed
	if not (type(wml) == "table") then
		parsed = wml
	else
		-- parsed contains two tables named k and c
		parsed = { k = {}, c = {} }
		-- copy the key/value pair of each table in the wml into parsed.k
		for k,v in pairs(wml) do
			if not (type(v) == "table") then
				parsed.k[k] = v
			end
		end

		-- iterate through wml again
		for i = 1, #wml do
			-- convert all wml children that are tables/arrays into a valid
			-- child in c (not to overlap with k namespace) into
			if not parsed.c[wml[i][1]] then
				parsed.c[wml[i][1]] = {}
			end
			table.insert(parsed.c[wml[i][1]], parse_container(wml[i][2]))
		end
	end
	return parsed
end

-- unparse (the previously parsed) data back into a WML Lua container
function unparse_container(parsed)
	local wml = {}
	for k,v in pairs(parsed.k) do
		wml[k] = v
	end
	for k,v in pairs(parsed.c) do
		for i = 1, #v do
			table.insert(wml, { k, unparse_container(v[i]) })
		end
	end
	return wml
end

-- This takes it one step further than parse_container, but throws if you
-- happen to have a scalar key that overlaps with a child container.
function wml2lua_table(wml)
	if not (type(wml) == "table") then
		return wml
	end
	local result = {}
	local k, v

	-- std_print(dump_lua_value(wml, "wml", "  "))

	-- first copy the scalars in, because that's the easy part.
	for k, v in pairs(wml) do
		if type(v) ~= "table" then
			result[k] = v
		end
	end

	for k, v in pairs(wml) do
		if type(v) == "table" then
-- 			if type(key) ~= "string" then H.wml_error(string.format("malformed")) end
-- 			if #v ~= 2 then H.wml_error(string.format("malformed")) end
			local key = v[1]
			if result[key] == nil then
				result[key] = {}
			elseif type(result[key]) ~= "table" then
				H.wml_error(string.format("Cannot use wml2lua_table on this WML container " ..
						    "because the key %s maps to both a scalar and a container, though" ..
							"this is valid WML.", key))
			end
			table.insert(result[key], wml2lua_table(v[2]))
		end
	end

	return result
end

function lua_table2wml(t)
	if type(t) ~= "table" then
		H.wml_error(string.format("not a table"))
	end
	local wml = {}
	local k, v

	-- first scalars first in case there's a numeric key with a scalar value.
	for k, v in pairs(t) do
		if type(v) ~= "table" then
			wml[k] = v
		end
	end
	for k, v in pairs(t) do
		if type(v) == "table" then
			table.insert(wml, {k , lua_table2wml(v)})
		end
	end

	return wml
end

local function typeof(val)
	return type(val)
end



-- This takes it one step further than parse_container, but throws if you
-- happen to have a scalar key that overlaps with a child container.
function noarr_wml2lua_table(wml)
	if not (type(wml) == "table") then
		return wml
	end
	local result = {}
	local k, v

	-- first copy the scalars in, because that's the easy part.
	for k, v in pairs(wml) do
		if type(v) ~= "table" then
			result[k] = v
		end
	end

	for k, v in pairs(wml) do
		if type(v) == "table" then
			local key = v[1]
			if result[key] ~= nil then
				local reason
				if type(result[key]) == "table" then
					reason = "is an array"
				else
					reason = "maps to both a scalar and a container"
				end
				H.wml_error(string.format("Cannot use noarr_wml2lua_table on this WML container " ..
						    "because the key %s %s, though" ..
							"this is valid WML.", key, reason))
			end
			result[key] = noarr_wml2lua_table(v[2])
		end
	end

	return result
end

function noarr_lua_table2wml(t)
	if type(t) ~= "table" then
		H.wml_error(string.format("not a table"))
	end
	local wml = {}
	local k, v

	for k, v in pairs(t) do
		if type(v) ~= "table" then
			wml[k] = v
		else
			table.insert(wml, {k , noarr_lua_table2wml(v)})
		end
	end

	return wml
end

-- function wesnoth.wml_actions.register_mouse_over_wml(args)
-- 	local tag = args.tag or H.wml_error("[register_mouse_over_wml] requires tag=")
-- 	local cmd
--
-- 	local k, v
-- 	for k, v in pairs(wml.parsed(args)) do
-- 		if type(v) == "table" and type(v[1]) == "string" and v[1] == "command" and type(v[2]) == "table" then
-- 			cmd = v[2]
-- 		end
-- 	end
--
--
-- end

-- returns true if we should auto-upgrade this NPC, false to leave the talnet points unspent
function wesnoth.wml_conditionals.do_npc_upgrade(cfg)
    local id = cfg.id or wml.error("[do_npc_upgrade] tag requires 'id' attribute")
--     std_print(dump_wml_value(wesnoth.sides.get(wesnoth.units.get(43,36).side).controller))
    local upgrade_npcs = wml.variables["opts.upgrade_npcs"]
    local unit = wesnoth.units.get(id)
    std_print(dump_wml_value({upgrade_npcs = upgrade_npcs, id = id, unit_side = unit and unit.side or nil}, "do_npc_upgrade"))

    if not unit then return true end
    std_print(dump_wml_value(upgrade_npcs, "upgrade_npcs"))
    return wesnoth.sides.get(unit.side).controller == "ai" or (not upgrade_npcs)
end
