fx_version 'cerulean'
game 'gta5'

author 'mriq_qbox'
description 'mri_allowlist'
version '1.0.0'

dependency 'qb-core'
dependency 'oxmysql'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'main.lua'
}



lua54 'yes'
