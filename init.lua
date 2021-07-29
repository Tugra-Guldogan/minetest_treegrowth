

local modpath = minetest.get_modpath("treegrowth")

-- Add everything:
local modname = "treegrowth"
treegrowth = {}


treegrowth.heights = {
	{2,3}, -- 1 
	{3,3}, -- 2
	{3,4}, -- 3
	{3,5}, -- 4
	{4,5}, -- 5 == default:tree
}

treegrowth.leaves = {
	{1,0,1, 60}, -- 1
	{2,1,2, 30}, -- 2
	{2,0,2, 20}, -- 3
	{2,0,2, 40}, -- 4
	{3,0,2, 10}, -- 5
}

local function overridden() 
	print("pwned\n")
	
end

default.grow_tree = overridden
default.grow_new_apple_tree = overridden

local function cut_root(pos, index) 
	local height = 0
	local node 
	print("looking for root")

	
	local root_name = modname..":root_thin_"..index
	local trunk_name = modname..":tree_thin_"..index
	
	repeat
		height = height + 1
		pos.y = pos.y - 1
		node = minetest.get_node(pos)
	until node.name == root_name or height > 6 or node.name ~= trunk_name

	if node.name == root_name then
	print("cut root")
		minetest.set_node(pos, {name = trunk_name})
	end
	
end





local function reg_trunk(name, index, width, drops)
	minetest.register_node(modname..":tree_thin_"..index, {
		description = name,
		tiles = {"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {
				{-width, -0.5, -width, width, 0.5, width},
			},
		},
		is_ground_content = false,
		groups = {tree = 1, tree_thickness = index, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
		sounds = default.node_sound_wood_defaults(),

		on_place = minetest.rotate_node,
		on_destruct = function(pos, node, player)
			cut_root(pos, index)
			--minetest.node_dig(pos, node, player)
		end,
	})
	
	minetest.register_node(modname..":root_thin_"..index, {
		description = name,
		tiles = {"default_tree_top.png", "default_tree_top.png", "default_tree.png"},
		paramtype = "light",
		paramtype2 = "facedir",
		drawtype = "nodebox",
		drop = modname..":tree_thin_"..index,
		node_box = {
			type = "fixed",
			fixed = {
				{-width, -0.5, -width, width, 0.5, width},
			},
		},
		is_ground_content = false,
		groups = {
			tree = 1, 
			tree_thickness = index, 
			tree_root = 1, 
			choppy = 2, 
			oddly_breakable_by_hand = 1, 
			flammable = 2
		},
		sounds = default.node_sound_wood_defaults(),
	})
	
	minetest.register_craft( {
		output = drops,
		recipe = { {modname..":tree_thin_"..index} },
	})

	-- these are normal leaves, so to say, except they are easily replaced during growth
	-- and they never drop saplings

	minetest.register_node(modname..":leaves_"..index, {
		description = "Leaves",
		drawtype = "allfaces_optional",
		waving = 1,
		visual_scale = 1.3,
		tiles = {"default_leaves.png"},
		special_tiles = {"default_leaves_simple.png"},
		paramtype = "light",
		is_ground_content = false,
		groups = {snappy = 3, leafdecay = 3, flammable = 2, leaves = 1},
		drop = {
			max_items = 1,
			items = {
				{
					-- player will get leaves only if he get no saplings,
					-- this is because max_items is 1
					items = {'default:leaves'},
				}
			}
		},
		sounds = default.node_sound_leaves_defaults(),

		after_place_node = default.after_place_leaves,
	})
		
end

reg_trunk("Young Tree", 1, 0.1, "default:stick 2")
reg_trunk("Young Tree", 2, 0.2, "default:wood 1")
reg_trunk("Young Tree", 3, 0.3, "default:wood 2")
reg_trunk("Young Tree", 4, 0.4, "default:wood 3")




minetest.register_node(":default:sapling", {
	description = "Treegrowth Sapling",
	drawtype = "plantlike",
	visual_scale = 1.0,
	tiles = {"default_sapling.png"},
	inventory_image = "default_sapling.png",
	wield_image = "default_sapling.png",
	paramtype = "light",
	sunlight_propagates = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
	},
	groups = {snappy = 2, dig_immediate = 3, flammable = 2,
		attached_node = 1, sapling = 1},
	sounds = default.node_sound_leaves_defaults(),
})



local function place_young_leaves(tree_top, index) 

	local p = tree_top
	local leafname = modname..":leaves_"..index
	if index == 5 then
		leafname = "default:leaves"
	end
	local leafnode = {name = leafname}
	
	ld = treegrowth.leaves[index]
	
	for x = -ld[1], ld[1] do
	for y = ld[2], ld[3] do
	for z = -ld[1], ld[1] do
		local pos = {x=p.x+x, y=p.y+y, z=p.z+z }
		local name = minetest.get_node(pos).name
		if name == "air" and math.random(0,100) < ld[4] then
			minetest.set_node(pos, leafnode)
		end
	end
	end
	end
	
end

local function expand_tree(root_pos) 
	-- calculate the new thickness

	local thick = minetest.get_node_group(minetest.get_node(root_pos).name, "tree_thickness")
	local name = modname..":tree_thin_"..thick
	thick = thick + 1
	
	local newname = modname..":tree_thin_"..thick
	local rootname = modname..":root_thin_"..thick
	if thick == 5 then
		newname = "default:tree"
		rootname = "default:tree"
	end
		
	
	-- calculate a desired height
	local hinfo = treegrowth.heights[thick]
	local maxh = math.random(hinfo[1], hinfo[2]) - 1
	
	minetest.set_node(root_pos, {name = rootname})
	
	local height = 0
	local pos = {x=root_pos.x, y=root_pos.y+1, z=root_pos.z, }
	local node = minetest.get_node(pos)
	local is_leaf = minetest.get_node_group(node.name, "leaves") > 0
	while (node.name == name and height < 5) or (height < maxh and (node.name == "air" or is_leaf)) do
		minetest.set_node(pos, {name = newname})
		height = height + 1
		pos.y = pos.y + 1
		node = minetest.get_node(pos)
		is_leaf = minetest.get_node_group(node.name, "leaves") > 0
	end
	
	
	pos.y = pos.y - 1
	
	place_young_leaves(pos, thick)
	
end



minetest.register_abm({
	nodenames = {"group:tree_root"},
	neighbors = {"group:soil"},
	interval = 60,
	chance = 15,
	catch_up = true,
	action = function(pos, node)
		
		pos.y = pos.y - 1
		if minetest.get_node_group(minetest.get_node(pos).name, "soil") == 0 then
			return
		end
		pos.y = pos.y + 1
		
		expand_tree(pos)
	end,
})


minetest.register_abm({
	nodenames = {"default:sapling"},
	interval = 60,
	chance = 15,
	catch_up = true,
	action = function(pos, node)
		if default.can_grow ~= nil and not default.can_grow(pos) then
			return
		end


		local h = expand_tree(pos)


	end
})
