local QBCore = exports['qb-core']:GetCoreObject()

local function generateToken()
    local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local token = ""

    for _ = 1, 8 do
        local randomIndex = math.random(1, #charset)
        token = token .. charset:sub(randomIndex, randomIndex)
    end

    return token
end

local function getHardwareId(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if string.sub(identifier, 1, 8) == "license:" then
            return identifier
        end
    end
    return nil
end

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
    deferrals.defer()

    local src = source
    local steamId, discordId, ip, hardwareId

    local errorMsg = ""

    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if string.sub(identifier, 1, 5) == "steam" then
            steamId = identifier
        elseif string.sub(identifier, 1, 7) == "discord" then
            discordId = identifier
        elseif string.sub(identifier, 1, 3) == "ip:" then
            ip = string.sub(identifier, 4)
        end
    end

    if not steamId then
        errorMsg = "Steam ID não encontrado."
    elseif not discordId then
        errorMsg = "Discord ID não encontrado."
    elseif not ip then
        errorMsg = "IP não encontrado."
    end

    if errorMsg ~= "" then
        deferrals.done(errorMsg)
        return
    end

    hardwareId = getHardwareId(src)

    if not hardwareId then
        deferrals.done("Não foi possível obter o Hardware ID. Conexão barrada.")
        return
    end

    local result = exports.oxmysql:executeSync("SELECT * FROM accounts WHERE ip = ?", {ip})

    if result and result[1] then
        if result[1].whitelist == 1 then
            exports.oxmysql:executeSync(
                "UPDATE accounts SET ultimo_acesso = CURRENT_TIMESTAMP, ip = ?, steam_id = ?, discord_id = ? WHERE ip = ?",
                {ip, steamId or "N/A", discordId or "N/A", ip}
            )
            deferrals.done()
        else
            local token = result[1].token_id
            deferrals.done("\n\n Você não está na whitelist do servidor. \n Por favor, realize sua whitelist em nosso discord.\n discord.gg/seudiscord \n\n Seu Token ID: " .. token)
        end
    else
        local token = generateToken()
        if not token then
            deferrals.done("Erro ao gerar o token de whitelist. Tente novamente mais tarde.")
            return
        end

        exports.oxmysql:insert(
            "INSERT INTO accounts (token_id, steam_id, discord_id, ip, hardware_id, whitelist) VALUES (?, ?, ?, ?, ?, ?)",
            {token, steamId or "N/A", discordId or "N/A", ip, hardwareId or "N/A", 0},
            function(id)
                if id then
                    deferrals.done("\n\n Você não está na whitelist do servidor.\n Por favor, realize sua whitelist em nosso discord.\n discord.gg/seudiscord. \n\n Seu Token ID: " .. token)
                else
                    deferrals.done("Erro ao registrar sua conta. Por favor, tente novamente mais tarde.")
                end
            end
        )
    end
end)
