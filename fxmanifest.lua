fx_version 'cerulean'

game 'gta5'

name "mono_garage_v2"

description "M O N O _ G A R A G E _ V 2"

author "M O N O"

version "2.0.0"

lua54 'yes'

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
}

client_scripts {
	'client/*.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/*.lua'
}

