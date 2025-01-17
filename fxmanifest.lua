fx_version 'cerulean'
game 'gta5'

Author 'Samuel#0008'
Version '1.0.0'

client_scripts { 'client/*.lua', }

shared_scripts { '@ox_lib/init.lua', '@sd_lib/init.lua', 'config.lua', }

server_scripts { '@oxmysql/lib/MySQL.lua', 'server/*.lua'} 

files { 'locales/*.json' }

lua54 'yes'

escrow_ignore { '**/*.lua', 'config.lua' }