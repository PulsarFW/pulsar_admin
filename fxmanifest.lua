fx_version 'cerulean'
games { 'gta5' }

name 'Pulsar Admin'
description 'Staff admin panel with live player list, moderation actions, and a management dashboard'
author 'Artmines - maintained for Pulsar Framework'
url 'https://pulsarframe.work'
version 'v1.0.0'

version_check 'yes'
github 'https://github.com/PulsarFW/pulsar_admin'

client_script '@pulsar_core/components/cl_error.lua'
shared_script '@pulsar_core/core/sh_pulsar.lua'
client_script '@pulsar_pwnzor/client/check.lua'

client_scripts({
	'client/client.lua',
	'client/attach.lua',
	'client/noclip/*.lua',
	'client/nui.lua',
	'client/doorpicker.lua',
	'client/ids.lua',
	'client/nuke.lua',
	'client/damage_test.lua',
})

server_scripts({
	'server/*.lua',
})

files({
	'ui/dist/index.html',
	'ui/dist/assets/*',
	'config/shared.lua',
})

ui_page 'ui/dist/index.html'
lua54 'yes'