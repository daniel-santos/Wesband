--  [event]
--      name=preload
--      first_time_only=no
--      [lua]
--          code = << wesnoth.dofile "~add-ons/Wesband/lua/Debug.lua" >>
--      [/lua]
--  [/event]

function mnemonic_for_type(t)
    local mnemonics = {
        table = "T",
        number = "N",
        string = "S",
        boolean = "B"
    }
    local result = mnemonics[t]
    return result == nil and t or result
end

-- print lua tables
function mr_dump(node, indent, indent_next, max_pad)
    local out = mnemonic_for_type(type(node)) .. " "
    if type(node) ~= "table" then
        if type(node) == "boolean" or type(node) == "number" or type(node) == "string" then
            return out .. node
        else
            return out .. "(not dumped)"
        end
        return
    end

    out = out .. "{\n"
    local indent_body = indent .. indent_next

    local first = true
    local key_pad = 0
    local is_array = true
    for k, v in pairs(node) do
        local key_str = tostring(k)
        if (#key_str > key_pad) then
            key_pad = #key_str
        end
        if type(k) ~= "number" then
            is_array = false
        end
    end

    if is_array then
        key_pad = key_pad + 2
    end

    key_pad = key_pad < max_pad and key_pad or max_pad

    local line
    for k, v in pairs(node) do
        local key_str = tostring(k)
        if is_array then
            key_str = "[" .. key_str .. "]"
        end

        if (type(v) == "table") then
            line = indent_body .. key_str .. " = " .. mr_dump(v, indent_body, indent_next, max_pad)
        else
            line = indent_body .. string.format("%-" .. tostring(key_pad) .. "s", key_str) ..  " = " .. mnemonic_for_type(type(v)) .. " "
            if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                line = line .. tostring(v)
            else
                line = line .. "(not dumped)"
            end
        end
        out = out .. (first and "" or ",\n") .. line
        first = false
    end
    return out .. (first and "}" or "\n" .. indent .. "}")

--     local cache, stack, output = {},{},{}
--     local depth = 1
--
--     while true do
--         local size = 0
--         for k,v in pairs(node) do
--             size = size + 1
--         end
--
--         local cur_index = 1
--         for k,v in pairs(node) do
--             if (cache[node] == nil) or (cur_index >= cache[node]) then
--
--                 if (string.find(output_str,"}",output_str:len())) then
--                     output_str = output_str .. ",\n"
--                 elseif not (string.find(output_str,"\n",output_str:len())) then
--                     output_str = output_str .. "\n"
--                 end
--
--                 -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
--                 table.insert(output,output_str)
--                 output_str = ""
--
--                 local key
--                 if (type(k) == "number" or type(k) == "boolean") then
--                     key = "["..tostring(k).."]"
--                 else
--                     key = "['"..tostring(k).."']"
--                 end
--
--                 if (type(v) == "number" or type(v) == "boolean") then
--                     output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
--                 elseif (type(v) == "table") then
--                     output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
--                     table.insert(stack,node)
--                     table.insert(stack,v)
--                     cache[node] = cur_index+1
--                     break
--                 else
--                     output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
--                 end
--
--                 if (cur_index == size) then
--                     output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
--                 else
--                     output_str = output_str .. ","
--                 end
--             else
--                 -- close the table
--                 if (cur_index == size) then
--                     output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
--                 end
--             end
--
--             cur_index = cur_index + 1
--         end
--
--         if (size == 0) then
--             output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
--         end
--
--         if (#stack > 0) then
--             node = stack[#stack]
--             stack[#stack] = nil
--             depth = cache[node] == nil and depth + 1 or depth - 1
--         else
--             break
--         end
--     end

--     -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
--     table.insert(output,output_str)
--     output_str = table.concat(output)
--
--     --print(output_str)
--     std_print(output_str)
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
	std_print(name .. " = " .. mr_dump(var, "", "  ", 24) .. "\n")
end
