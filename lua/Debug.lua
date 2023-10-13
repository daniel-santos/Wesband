--  [event]
--      name=preload
--      first_time_only=no
--      [lua]
--          code = << wesnoth.dofile "~add-ons/Wesband/lua/Debug.lua" >>
--      [/lua]
--  [/event]

-- print lua tables
function w_pt(node)
    if type(node) ~= "table" then
        if type(node) == "boolean" or type(node) == "number" or type(node) == "string" then
            std_print("w_pt Type = " .. type(node) .. ". Value = " .. node)
        else
            std_print("w_pt Type = " .. type(node) .. ".")
        end
        return
    end

    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    --print(output_str)
    std_print(output_str)
end


function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, and so on
        copy = orig
    end
    return copy
end

function wesnoth.wml_actions.dump_variable(args)
	local name = args.name or H.wml_error("[dump_variable] requires a name= key")
	local var = wml.variables[name]
	std_print("[dump_variable] name=" .. name)
	w_pt(var)
end

function mnemonic_for_type(v)
    local mnemonics = {
        table = "T",
        number = "N",
        string = "S",
        boolean = "B"
    }
    return mnemonics[type(v)] or "(" .. type(v) .. ")"
end

-- dump a wml value
function dump_wml_value(node, name, indent, indent_next, max_key_pad)
	node = node or H.wml_error("dump_wml_value needs node")
	name = name or "value"
	indent = indent or ""
	indent_next = indent_next or " "
	max_key_pad = max_key_pad or 24
    local out = name .. " = " .. mnemonic_for_type(node) .. " "

    if type(node) == "table" then
        return dump_wml_table(node, name, indent, indent_next, max_key_pad)
    elseif type(node) == "boolean" or type(node) == "number" or type(node) == "string" then
        return out .. node
    else
        return out .. "(not dumped)"
    end
end

function dump_wml_table(node, name, indent, indent_next, max_key_pad)
    if (type(node) ~= "table") then
        error("node not a table: " .. tostring(node))
    end

    local out --  = mnemonic_for_type(node) .. " "
    out = "[" .. tostring(name) .. "]\n"

    local indent_body = indent .. indent_next

    local first = true
    local key_pad = 0
    local is_array = true
    local k, v
    for k, v in pairs(node) do
        if k == 1 and type(v) == string then
            -- this is the name of the table
        else
            local key_str = tostring(k)
            if (#key_str > key_pad) then
                key_pad = #key_str
            end
            if type(k) ~= "number" then
                is_array = false
            end
            if type(v) == "table" and v[1] ~= nil and type(v[1]) == string then
                is_array = false
            end
        end
    end

    if is_array then
        key_pad = key_pad + 2
    end

    key_pad = key_pad < max_key_pad and key_pad or max_key_pad

    for k, v in pairs(node) do
        if k == 1 and type(v) == string then
            -- this is the name of the table
        else
            local line
            local key_str = tostring(k)
            if is_array then
                key_str = "[" .. key_str .. "]"
            end

            if (type(v) == "table") then
--                  std_print("table's first child is " .. type(v[1]) .. tostring(v[1]))
                    key_str = tostring(v[1])
                if v[1] ~= nil and type(v[1]) == "string" then
--                     key_str = "[" .. v[1] .. "]"
                    if #v == 2 and type(v[2]) == "table" then
                        v = v[2]
                    end
                end
                line = indent_body .. dump_wml_table(v, key_str, indent_body, indent_next, max_key_pad)
            else
                line = indent_body .. string.format("%-" .. tostring(key_pad) .. "s", key_str) ..  " = " .. mnemonic_for_type(v) .. " "
                if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                    line = line .. tostring(v)
                else
                    line = line .. "(not dumped)"
                end
            end
            out = out .. (first and "" or "\n") .. line
            first = false
        end
    end
    return out .. "\n" .. indent .. "[/" .. tostring(name) .. "]"
end

function wesnoth.wml_actions.dump_wml(args)
	local var = args.var or H.wml_error("[dump_wml] requires a var= key")
	std_print("[dump_wml] var=" .. var .. dump_wml_value(wml.variables[var]))
end

-- dump any lua value (doesn't show any userdata values, including translatable strings)
function dump_lua_value(node, name, indent_next, max_key_pad, allow_folding)
	node = node or H.wml_error("dump_lua_value needs node")
	name = name or "value"
	indent_next = indent_next or "  "
	max_key_pad = max_key_pad or 24
-- 	allow_folding = allow_folding ~= nil and allow_folding or false

	local out = name .. " = " .. mnemonic_for_type(node) .. " "

	if type(node) == "table" then
		return out .. dump_lua_table(node, indent_next, max_key_pad)
	elseif type(node) == "boolean" or type(node) == "number" or type(node) == "string" then
		return out .. tostring(node)
	else
		return out .. "(not dumped)"
	end
end

function dump_lua_table(node, indent_next, max_key_pad, indent, allow_folding)
	node = node or H.wml_error("dump_lua_table() missing required node argument")
	indent_next = indent_next or "  "
	max_key_pad = max_key_pad or 24
	indent = indent or ""
-- 	allow_folding = allow_folding ~= nil and allow_folding or false

	if (type(node) ~= "table") then
		error("node not a table: " .. tostring(node))
	end

	local out = "{"
	local indent_body = indent .. indent_next
	local nchildren = 0
	local key_pad = 0
	local is_array = true
	local k, v
	local key_str

	-- find maximum key length (as string) and determine if this is just a pure array or not
	for k, v in pairs(node) do
		key_str = tostring(k)
		if (#key_str > key_pad) then
			key_pad = #key_str
		end
		if type(k) ~= "number" then
			is_array = false
		end
		nchildren = nchildren + 1
	end
	-- allow folding tables with less than two children
	local do_folding = nchildren < 2 --  and allow_folding

	-- if array, we'll need two extra columns for []
	if is_array then
		key_pad = key_pad + 2
	end

	-- limit to max_key_pad
	key_pad = key_pad < max_key_pad and key_pad or max_key_pad
	local first = true
	do_folding = false

	for k, v in pairs(node) do
		local value
		local use_padding = not do_folding	-- we're not going to pad keys for tables or fold the table

		if type(v) == "table" then
			value = dump_lua_table(v, indent_next, max_key_pad, indent_body)
			use_padding = false
		elseif type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
			value = mnemonic_for_type(v) .. " " .. tostring(v)
		else
			value = mnemonic_for_type(v) .. " (not displayed)"
		end

		key_str = tostring(k)
		if is_array then
			key_str = "[" .. key_str .. "]"
		end
		if use_padding then
			key_str = string.format("%-" .. tostring(key_pad) .. "s", key_str)
		end
		out = out .. (do_folding and "" or "\n" .. indent_body) .. key_str ..
			" = " .. value
		first = false
	end
	return out .. ((nchildren > 1 or not do_folding) and "\n" .. indent or "")  .. "}"
end

function wesnoth.wml_actions.dump_lua(args)
	local var = args.var or H.wml_error("[dump_lua] requires a var= key")
	std_print("[dump_lua] var=" .. var .. dump_lua_value(wml.variables[var]))
end
