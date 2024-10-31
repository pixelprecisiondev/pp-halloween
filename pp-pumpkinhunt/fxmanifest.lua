fx_version "cerulean"
description "Halloween Pumpkin Hunt"
author "PixelPrecision"
version '1.0.1'
lua54 'yes'
game "gta5"

files {
    'web/build/index.html',
    'web/build/**/*',
    'config/config.lua',
    'locales/*.json'
}

ui_page 'web/build/index.html'

client_scripts {
    "client/**/*"
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/**/*'
}

dependencies {
    'ox_lib',
    'oxmysql'
}

shared_scripts {
    '@ox_lib/init.lua'
}

data_file "DLC_ITYP_REQUEST" "stream/pp_halloween.ytyp"