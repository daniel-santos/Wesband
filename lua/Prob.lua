-- these are global functions for ease of use in lua scripts as well as WML

function prob_list_eval(cfg)
	local i
	local total_weight = 0

	list = wml.parsed(cfg)
	list.literal = false

-- 	std_print(dump_lua_value(list, "parsed_list", "  "))

	local pl = {
		count   = 0,
		items   = tostring(list.items):split(","),
		weights = tostring(list.weights):split(",")
	}
-- 	std_print(dump_lua_value(pl, "pl"))

	if #pl.items ~= #pl.weights then
		H.wml_error("in prob_list " .. list.name .. ", count of items and weights do not match")
	end

	pl.count = #pl.items

	for i = 1, pl.count do
		local weight = tonumber(pl.weights[i])
		if not weight then
			H.wml_error(string.format("in prob_list %s, weight entry %d is not a number: '%s'",
									  list.name, i, pl.weights[i]))
		end
		total_weight = total_weight + weight
		table.insert(list, {"entry", {item = pl.items[i], weight = weight}})
	end

	list.count = pl.count
	list.total_weight = total_weight
-- 	std_print(dump_lua_value(list, "list"))
	return list
end

function wesnoth.wml_actions.prob_list(cfg)
	local name    = cfg.name or H.wml_error("[prob_list] requires a name= key")
	local lcfg    = wml.literal(cfg)
	local items   = lcfg.items or H.wml_error("[prob_list] requires a items= key")
	local weights = lcfg.weights or H.wml_error("[prob_list] requires a weights= key")
	local literal = cfg.literal or false
	local list    = {
		name    = name,
		items   = items,
		weights = weights,
		literal = literal
	}

	wml.variables[name] = nil
-- 	wml.variables[string.format("%s.weights", name)] = cfg.weights
-- 	wml.variables[string.format("%s.entries[0].item", name)] = "hello"
-- 	wml.variables[string.format("%s.entries[1].item", name)] = "helol"
-- 	std_print(dump_lua_value(wml.variables[name], name))

	-- If not using late expansion, then expand then now
	wml.variables[name] = literal and list or prob_list_eval(wml.tovconfig(list))
	if literal then
-- 		std_print(dump_lua_value(wml.variables[name], name))
	end
end

function wesnoth.wml_actions.prob_list_old(cfg)
	local list = cfg.name or H.wml_error("[prob_list] requires a name= key")
	local items = cfg.items or H.wml_error("[prob_list] requires a items= key")
	local weights = cfg.weights or H.wml_error("[prob_list] requires a weights= key")
	local entries = {}
	for i in string.gmatch(items, "[%s]*([^,]+),?") do
		table.insert(entries, i)
	end
	wml.variables[string.format("%s.weights", list)] = wml.literal(cfg).weights
	if #entries > 0 then
		local ct, ix = 0, 0
		for w in string.gmatch(weights, "[%s]*([%d]+),?") do
			if ix == 0 then
				wml.variables[list] = nil
			end
			local i = entries[ix + 1]
			if i then
				ct = ct + w
				wml.variables[string.format("%s.entry[%d].item", list, ix)] = i
				wml.variables[string.format("%s.entry[%d].weight", list, ix)] = w
				ix = ix + 1
			else
				break
			end
		end
		wml.variables[string.format("%s.total_weight", list)] = ct
	end
end

function wesnoth.wml_actions.set_prob(cfg)
	local weight, list, id
	local function probClear()
		local item_count = wml.variables[string.format("%s.entry.length", list)] or 0
		for i = 0, item_count - 1 do
			if wml.variables[string.format("%s.entry[%i].item", list, i)] == id then
				wml.variables[string.format("%s.total_weight", list)] = wml.variables[string.format("%s.total_weight", list)] - wml.variables[string.format("%s.entry[%i].weight", list, i)]
				wml.variables[string.format("%s.entry[%i]", list, i)] = nil
				break
			end
		end
	end

	local function probSet()
		local item_count = wml.variables[string.format("%s.entry.length", list)] or 0
		for i = 0, item_count - 1 do
			if wml.variables[string.format("%s.entry[%i].item", list, i)] == id then
				wml.variables[string.format("%s.total_weight", list)] = wml.variables[string.format("%s.total_weight", cfg.name)] - wml.variables[string.format("%s.entry[%i].weight", list, i)] + weight
				wml.variables[string.format("%s.entry[%i].weight", list, i)] = weight
				break
			end
		end
	end

	local function probAdd()
		local success = false
		local item_count = wml.variables[string.format("%s.entry.length", list)] or 0
		for i = 0, item_count - 1 do
			if wml.variables[string.format("%s.entry[%i].item", list, i)] == id then
				wml.variables[string.format("%s.entry[%i].weight", list, i)] = wml.variables[string.format("%s.entry[%i].weight", list, i)] + weight
				success = true
				break
			end
		end
		if not success then
			W.set_variables {
					name = string.format("%s.entry", list),
					mode = "append",
					{ "value", {
						item = id,
						weight = weight
					} }
				}
		end
		local count = wml.variables[string.format("%s.total_weight", list)] or 0
		wml.variables[string.format("%s.total_weight", list)] = count + weight
	end

	local function probSub()
		local item_count = wml.variables[string.format("%s.entry.length", list)] or 0
		for i = 0, item_count - 1 do
			if wml.variables[string.format("%s.entry[%i].item", list, i)] == id then
				local old = wml.variables[string.format("%s.entry[%i].weight", list, i)]
				if old <= weight then
					wml.variables[string.format("%s.entry[%i]", list, i)] = nil
					wml.variables[string.format("%s.total_weight", list)] = wml.variables[string.format("%s.total_weight", list)] - old
				else
					wml.variables[string.format("%s.entry[%i].weight", list, i)] = old - weight
					wml.variables[string.format("%s.total_weight", list)] = wml.variables[string.format("%s.total_weight", list)] - weight
				end
				break
			end
		end
	end

	local function probScale()
		local item_count = wml.variables[string.format("%s.entry.length", list)] or 0
		for i = 0, item_count - 1 do
			if wml.variables[string.format("%s.entry[%i].item", list, i)] == id then
				local old = wml.variables[string.format("%s.entry[%i].weight", list, i)]
				local new = math.max(1, math.floor(old * weight * 0.01 + 0.5))
				wml.variables[string.format("%s.entry[%i].weight", list, i)] = new
				wml.variables[string.format("%s.total_weight", list)] = wml.variables[string.format("%s.total_weight", list)] - old + new
				break
			end
		end
	end

	local var
	local function probUnion()
		local item_count = wml.variables[string.format("%s.entry.length", var)] or 0
		for i = 0, item_count -1 do
			id = wml.variables[string.format("%s.entry[%i].item", var, i)]
			weight = wml.variables[string.format("%s.entry[%i].weight", var, i)]
			probAdd()
		end
	end

	local function probDiff()
		local item_count = wml.variables[string.format("%s.entry.length", var)] or 0
		for i = 0, item_count -1 do
			id = wml.variables[string.format("%s.entry[%i].item", var, i)]
			weight = wml.variables[string.format("%s.entry[%i].weight", var, i)]
			probSub()
		end
	end

	local op = cfg.op or H.wml_error("[set_prob] requires an op= key.")
	list = cfg.name or H.wml_error("[set_prob] requires a name= key.")
	if op == "clear" then
		id = cfg.item or H.wml_error("[set_prob] clear requires an item= key.")
		probClear()
	elseif op == "set" then
		id = cfg.item or H.wml_error("[set_prob] set requires an item= key.")
		weight = cfg.weight or H.wml_error("[set_prob] set requires a weight= key.")
		if weight > 0 then
			probSet()
		else
			probClear()
		end
	elseif op == "add" then
		id = cfg.item or H.wml_error("[set_prob] add requires an item= key.")
		weight = cfg.weight or H.wml_error("[set_prob] add requires a weight= key.")
		if weight > 0 then
			probAdd()
		elseif cfg.weight < 0 then
			weight = 0 - weight
			probSub()
		end
	elseif op == "sub" then
		id = cfg.item or H.wml_error("[set_prob] sub requires an item= key.")
		weight = cfg.weight or H.wml_error("[set_prob] sub requires a weight= key.")
		if weight > 0 then
			probSub()
		elseif weight < 0 then
			weight = 0 - weight
			probAdd()
		end
	elseif op == "scale" then
		id = cfg.item or H.wml_error("[set_prob] scale requires an item= key.")
		weight = cfg.weight or H.wml_error("[set_prob] scale requires a weight= key.")
		if weight <= 0 then
			probClear()
		elseif weight ~= 100 then
			probScale()
		end
	elseif op == "union" then
		var = cfg.with_list or H.wml_error("[set_prob] union operation requires a with_list= key.")
		probUnion()
	elseif op == "diff" then
		var = cfg.with_list or H.wml_error("[set_prob] diff operation requires a with_list= key.")
		probDiff()
	else
		H.wml_error(string.format("Invalid [set_prob] operation: %s.", op))
	end
end

function wesnoth.wml_actions.get_prob(cfg)
	local var   = cfg.variable	or H.wml_error("[get_prob] requires a variable= key.")
	local name  = cfg.name		or H.wml_error("[get_prob] requires a name= key.")
	local list  = wml.variables[name]
	if list.literal then
		list = prob_list_eval(wml.tovconfig(list))
	end
	local val = H.rand("0.." .. tostring(list.total_weight))
	local i
-- std_print(dump_lua_value(list, "list"))
-- std_print(dump_lua_value({name=name, entries = entries}, "info"))
	for i = 1, #list do
		local v = list[i]
		if v and type(v) == "table" and type(v[1]) == "string" and v[1] == "entry" then
			val = val - v[2].weight
			if val <= 0 then
				wml.variables[var] = v[2].item
				return
			end
		end
	end

	H.wml_error(string.format("Failed to find an entry for %s", list))
end
