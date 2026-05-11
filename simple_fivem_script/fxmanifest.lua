fx_version 'cerulean'
game 'gta5'

name 'k4_police_system'
author 'boneq'
description 'Standalone police system for FiveM servers.'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

dependency 'ox_lib'

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}
