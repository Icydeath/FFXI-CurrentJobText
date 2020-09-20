_addon.name = 'CurrentJobText'
_addon.author = 'Icy'
_addon.commands = {'cjt','currentjobtext'}
_addon.version = '1.0.1'

--[[
1.0.1 - added display zone name option and pos command. //cjt zone  //cjt zone <left,right,above,below>  //cjt pos  //cjt pos <x> <y>
1.0.0 - initial release
]]
texts = require('texts')
config = require('config')
require('strings')
require('logger')

res_zones = nil
job_data = nil

local defaults = { 
	long_version = false,
	show_level = false,
	show_zone = false,
	zone_location = 'above',
}

defaults.text = {
	pos = { x = 0, y = 0 },--x = 1045, y = 800
	bg = { visible = false, alpha = 200, red = 0, green = 0, blue = 0, },
	flags = { bold = false, italic = false, },
	
	-- Orange: red = 255, green = 195, blue = 92
	text = { size = 14, font = 'Impact', alpha = 255, red = 3, green = 253, blue = 32, stroke = { alpha = 255, red = 0, green = 0, blue = 0, width = 2 } }
}

settings = config.load(defaults)

function add_spacers(str)
	local char_tbl = chars_to_table(str)
	local new_str = ''
	for i = 1, #str do
		new_str = new_str..char_tbl[i]..' '
	end
	return tostring(new_str)
end

function chars_to_table(str)
	local strc = {}
	for i = 1, #str do table.insert(strc, string.sub(str, i, i)) end
	return strc
end

function get_fullname(shortname)
	for i, x in ipairs(job_data) do
		if x.ens == shortname then return x.en end
	end
end

display_box = function()
	local str
	
	local player = windower.ffxi.get_player()
	if player then
		if settings.long_version and not job_data then 
			job_data = require('resources').jobs
		end
		if settings.show_zone and not res_zones then 
			res_zones = require('resources').zones
		end
		
		local slash = ' /  '
		local mainjob = add_spacers(settings.long_version and get_fullname(player.main_job) or player.main_job)
		local subjob = add_spacers(settings.long_version and get_fullname(player.sub_job) or player.sub_job)
		local mainlvl = player.main_job_level
		local sublvl = player.sub_job_level
		local mainjob = add_spacers(settings.long_version and get_fullname(player.main_job) or player.main_job)
		
		str = '%s%s%s':format(mainjob, slash, subjob)
		if settings.show_level then
			str = '%s%s %s%s%s':format(mainjob, mainlvl, slash, subjob, sublvl)
		end
		
		if settings.show_zone then
			local zonename = res_zones[windower.ffxi.get_info().zone].en
			if settings.zone_location == 'below' then
				str = '%s\n%s':format(str, zonename)
			elseif settings.zone_location == 'above' then
				str = '%s\n%s':format(zonename, str)
			elseif settings.zone_location == 'right' then
				str = '%s %s':format(str, zonename)
			else
				str = '%s %s':format(zonename, str)
			end
		end
	end
	
	return str
end
job_text = texts.new(display_box(), settings.text, settings)

function addon_command(...)
	local commands = {...}
	--log('Currently no commands are available for this addon. Settings can be found in the data/settings.xml')
	if commands[1] then
		if commands[1] == 'level' or commands[1] == 'lvl' then
			settings.show_level = not settings.show_level
		elseif commands[1] == 'zone' or commands[1] == 'z' then
			if commands[2] then
				commands[2] = commands[2]:lower()
				if commands[2] == 'l' then commands[2] = 'left' end
				if commands[2] == 'r' then commands[2] = 'right' end
				if commands[2] == 'a' then commands[2] = 'above' end
				if commands[2] == 'b' then commands[2] = 'below' end
				settings.zone_location = commands[2]
			else
				settings.show_zone = not settings.show_zone
			end
		elseif commands[1] == 'pos' then
			commands[2] = tonumber(commands[2])
			commands[3] = tonumber(commands[3])
			if commands[2] and commands[3] then
				settings.text.pos.x = commands[2]
				settings.text.pos.y = commands[3]
				log('	[x: '..settings.text.pos.x..'] [y:'..settings.text.pos.y..']')
				windower.send_command('lua r currentjobtext')
				return
			else
				log('	[x: '..settings.text.pos.x..'] [y:'..settings.text.pos.y..']')
			end
		elseif commands[1] == 'toggle' or commands[1] == 't' or commands[1] == 'long' or commands[1] == 'short' then
			settings.long_version = not settings.long_version
		else
			error('Invalid command.')
			log('Commands: [pos, level, toggle, zone]')
			return
		end
		
		config.save(settings, 'all')
		refresh_text()
	else
		log('//cjt [pos | level | toggle | zone]')
		log('  pos <x> <y> - sets the displayed text at the specified x/y cord.')
		log('  level - shows/hides the job levels.')
		log('  toggle - toggle between shortname[COR99 / DNC49] and fullname[Corsair99 / Dancer49]')
		log('  zone - shows/hides the zone name')
		log('  zone <(l)eft | (r)ight | (a)bove | (b)elow> - (default: left) specify where the zone name is displayed associated to the job text')
	end
end

function refresh_text()
	job_text:text(display_box())
	job_text:show()
end

windower.register_event('addon command', addon_command)
windower.register_event('job change','login','load','zone change', refresh_text)