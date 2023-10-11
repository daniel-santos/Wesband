
function wesnoth.wml_actions.unit_action_info(cfg)
	local unit_var = cfg.unit or H.wml_error("[unit_action_info] requires a unit= key")
	local dest_var = cfg.dest or H.wml_error("[unit_action_info] requires a dest= key")
	local unit = wml.variables[unit_var] or H.wml_error("[unit_action_info] unit not valid")
	local vars = wml.variables[unit_var .. ".variables"] or H.wml_error("[unit_action_info] unit missing [variables]")
	local magic_casting = wml.variables[unit_var .. ".variables.abilities.magic_casting"]

	local simple_action = vars.simple_action or 0
	local attacks = unit.attacks_left
	if (vars.blocked_attacks or 0) > 0 then
		attacks = 0
	end

	local casting_actions = vars.casting_actions
	local power = magic_casting and magic_casting.power or 0
	local speed = magic_casting and magic_casting.speed or 0
	local have_magic = speed > 0 and power > 0

	-- The maxiumum casting actions possible this turn
	local casting_actions_max = casting_actions +
								(simple_action > 0 and speed or 0) +
								(attacks > 0 and speed or 0)
	local text = string.format("Available actions: %d attack(s), %d simple",
							   attacks, simple_action)
	if have_magic then
		text = text .. string.format(", %d (%d) casting time",
									 casting_actions, casting_actions_max)
	end

	wml.variables[dest_var] = {
		simple_action = simple_action,
		attacks = attacks,
		text = text,
		[1] = {
			[1] = "casting",
			[2] = {
				power = power,
				speed = speed,
				actions = casting_actions,
				actions_max = casting_actions_max > 0 and casting_actions_max or 0,
				mana = magic_casting.mana or 0
			}
		}
	}
end

-- function wesnoth.wml_actions.create_spell(cfg)
-- end
--
-- function wesnoth.wml_actions.create_spell(cfg)
-- end

function wesnoth.wml_actions.cast_spell(cfg)
	local var = cfg.variable or H.wml_error("[cast_spell] requires a variable= key")
	local clear = cfg.clear


-- [event]
--     name=cast_spell
--     first_time_only=no
--     #setup must set cast_time and mana_cost variables
--
--     [if]
--         [variable]
--             name=current_unit.variables.simple_action
--             numerical_equals=0
--         [/variable]
--         [and]
--             [variable]
--                 name=current_unit.attacks_left
--                 numerical_equals=0
--             [/variable]
--             [or]
--                 [variable]
--                     name=current_unit.variables.blocked_attacks
--                     numerical_equals=1
--                 [/variable]
--             [/or]
--         [/and]
--         [and]
--             [variable]
--                 name=current_unit.variables.casting_actions
--                 less_than=$cast_time
--             [/variable]
--         [/and]
--         [then]
--             [message]
--                 speaker=narrator
--                 message=_ "You do not have enough actions left to cast this."
--                 side_for=$current_unit.side
--                 image=wesnoth-icon.png
--             [/message]
--         [/then]
--         [else]
--             [if]
--                 [variable]
--                     name=current_unit.variables.abilities.magic_casting.mana
--                     less_than=$mana_cost
--                 [/variable]
--                 [then]
--                     [message]
--                         speaker=narrator
--                         message=_ "You do not have enough mana left to cast this."
--                         side_for=$current_unit.side
--                         image=wesnoth-icon.png
--                     [/message]
--                 [/then]
--                 [else]
--                     {{CASTING_ACTION_EFFECT}}
--                     [if]
--                         [variable]
--                             name=current_unit.variables.complete_action
--                             numerical_equals=1
--                         [/variable]
--                         [then]
--                             {EXPEND_CASTING_ACTION current_unit}
--                             {CLEAR_VARIABLE current_unit.variables.complete_action}
--                             [unstore_unit]
--                                 variable=current_unit
--                             [/unstore_unit]
--                         [/then]
--                     [/if]
--                 [/else]
--             [/if]
--         [/else]
--     [/if]
-- [/event]
end

