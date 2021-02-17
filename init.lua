fire_plus = {
	burn_interval = 1,
	tnt_explode_radius = 1.5,
	burning = {--[[
		["playername"] = {
			burns_left = <number>,
			hud_id     = <hud id>,
			sound_id   = <sound id>,
			particlespawner_id = <particlespawner id>
		}
	]]},
	ignition_nodes = {
		--["nodename"] = {burns = <table with min/max or number>, damage = <table with min/max or number>}
		["default:lava"] = {burns = 2, damage = 4},
		["fire:"]        = {burns = 4, damage = 2},
	},
	extinguishers = {
		"default:water",
		"default:river_water",
		"default:snow"
	}
}

dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/api.lua")

local time = 0
local img_num = 1
local img_num_max = 8
minetest.register_globalstep(function(dtime)
	time = time + dtime

	if time < 0.1 then
		return
	else
		time = 0
	end

	-- Put out players in extinguisher nodes
	for _, player in pairs(minetest.get_connected_players()) do

		local name = player:get_player_name()

		if fire_plus.burning[name] then

			-- change HUD to next image to simulate animation
			--local img_name = "fire_basic_flame_"..img_num..".png"
			img_name = "fire_basic_flame_animated.png".."^[verticalframe:"..img_num_max..":"..img_num
			--minetest.log(dump(img_name))
			player:hud_remove(fire_plus.burning[name].hud_id)
			fire_plus.burning[name].hud_id = player:hud_add({
					hud_elem_type = "image",
					position  = {x = 0.5, y = 0.95},
					offset    = {x = 0, y = 0},
					text      = img_name,
					alignment = -1,
					scale     = {x = 100, y = 32},
					number    = 0xFFFFFF,
				})
			if img_num >= img_num_max then
				img_num = 1
			else
				img_num = img_num + 1
			end
			
			local nodename = minetest.get_node(player:get_pos()).name
			local nodename_head = minetest.get_node(vector.add(player:get_pos(),
					vector.new(0, 1, 0))).name

			for _, extinguisher in pairs(fire_plus.extinguishers) do

				if nodename:find(extinguisher) or nodename_head:find(extinguisher) then

					minetest.sound_play("fire_extinguish_flame", {
						to_player = name,
						gain = 1.0,
					})

					fire_plus.extinguish_player(name)

					return
				end
			end
		end
	end
end)

-- Ignite players in ignition nodes
minetest.register_on_player_hpchange(function(player, _, reason)
	if reason.type == "node_damage" and reason.node then
		for igniter, def in pairs(fire_plus.ignition_nodes) do
			if reason.node:find(igniter) then
				fire_plus.burn_player(player, def.burns or 4, def.damage or 2)
				break
			end
		end
	end
end)

minetest.register_on_punchplayer(function(player, hitter, _, toolcaps, _, dmg)
	if hitter and hitter:is_player() and toolcaps.damage_groups.burns and player and player:get_hp() - dmg > 0 then
		fire_plus.burn_player(player, toolcaps.damage_groups.burn_time or 4, toolcaps.damage_groups.burns)
	end

	return false
end)

minetest.register_on_respawnplayer(function(player)
	local name = player:get_player_name()

	if fire_plus.burning[name] then
		fire_plus.extinguish_player(name)
	end
end)
