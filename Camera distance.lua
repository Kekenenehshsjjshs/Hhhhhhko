
-- Player Tools - versi Mobile dengan config otomatis
-- Ranx / Deprau, full modifikasi

script_name('KSKAKAKAKAKAKAKAKAKAKAKA')
script_author('Ranx / Deprau')
script_description('Alat untuk mendapatkan info pemain (Mobile)')
script_version('1.2.0')

require 'lib.moonloader'
require 'lib.sampfuncs'
local inicfg = require 'inicfg'

local useInspect, inspect = pcall(require, 'lib.inspect')
local pMarkers = {}
local cfgPath = 'playertools.ini'

local cfg = {
    detector = {
        state = true,
        interval = 2500,
        disconnectOnDetect = false,
        trackOnDetect = false,
    },
    detectingPlayers = {},
}

cfg = inicfg.load(cfg, cfgPath)

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand('pthelp', cmdPTHelp)
    sampRegisterChatCommand('det', cmdDet)
    sampRegisterChatCommand('undet', cmdUndet)
    sampRegisterChatCommand('detectlist', cmdDetectList)
    sampRegisterChatCommand('dod', cmdDod)
    sampRegisterChatCommand('tod', cmdTod)
    sampRegisterChatCommand('track', cmdTrack)
    sampRegisterChatCommand('si', cmdSI)
    if useInspect then
        sampRegisterChatCommand('dbgm', function() sampAddChatMessage(string.format('Markers: %s', inspect(pMarkers, {newline = '', indent = ''})), 0xEADE3A) end)
    end

    while true do
        local instreamChars = getAllChars()
        if cfg.detector.state and sampIsLocalPlayerSpawned() then
            for _, pHandle in pairs(instreamChars) do
                local result, pId = sampGetPlayerIdByCharHandle(pHandle)
                if result then
                    local pName = sampGetPlayerNickname(pId)
                    if arrayContains(cfg.detectingPlayers, pName) then
                        if cfg.detector.trackOnDetect and not setContains(pMarkers, pHandle) then
                            track(pHandle)
                        end
                        if cfg.detector.disconnectOnDetect then
                            sampDisconnectWithReason(0)
                        end
                        printStringNow(string.format('~r~PERINGATAN! ~y~%s[%d]~r~ terdeteksi!', pName, pId), 2000)
                    end
                end
            end
        end

        for pHandle, pMarker in pairs(pMarkers) do
            if not arrayContains(instreamChars, pHandle) then
                removeBlip(pMarker)
                pMarkers[pHandle] = nil
            end
        end
        wait(cfg.detector.interval)
    end
end

function cmdDet(params)
    if #params > 0 then
        local pName = getPlayerNameByParams(params)
        if not pName then
            printStringNow('~r~Nama/ID pemain salah', 1500)
            return
        end
        if not arrayContains(cfg.detectingPlayers, pName) then
            table.insert(cfg.detectingPlayers, pName)
            inicfg.save(cfg, cfgPath)
            printStringNow(string.format('~w~Berhasil menambahkan ~b~%s', pName), 1500)
        else
            printStringNow('~w~Pemain sudah ada di daftar deteksi', 1500)
        end
    else
        cfg.detector.state = not cfg.detector.state
        inicfg.save(cfg, cfgPath)
        printStringNow(string.format('Deteksi %s', cfg.detector.state and '~g~aktif' or '~r~mati'), 1500)
    end
end

function cmdUndet(params)
    local pName = getPlayerNameByParams(params)
    if not pName then
        printStringNow('~r~Nama/ID pemain salah', 1500)
        return
    end
    for i, v in ipairs(cfg.detectingPlayers) do
        if v == pName then
            table.remove(cfg.detectingPlayers, i)
            inicfg.save(cfg, cfgPath)
            printStringNow(string.format('~w~Berhasil menghapus ~b~%s', pName), 1500)
            return
        end
    end
    printStringNow('~w~Pemain tidak ada di daftar deteksi', 1500)
end

function cmdDetectList()
    if #cfg.detectingPlayers > 0 then
        for i, name in ipairs(cfg.detectingPlayers) do
            sampAddChatMessage(string.format("%d. %s", i, name), -1)
        end
    else
        sampAddChatMessage('Tidak ada pemain dalam daftar deteksi', -1)
    end
end

function cmdDod()
    cfg.detector.disconnectOnDetect = not cfg.detector.disconnectOnDetect
    inicfg.save(cfg, cfgPath)
    printStringNow(string.format('Disconnect on Detect %s', cfg.detector.disconnectOnDetect and '~g~aktif' or '~r~mati'), 1500)
end

function cmdTod()
    cfg.detector.trackOnDetect = not cfg.detector.trackOnDetect
    inicfg.save(cfg, cfgPath)
    printStringNow(string.format('Track on Detect %s', cfg.detector.trackOnDetect and '~g~aktif' or '~r~mati'), 1500)
end

function cmdTrack(params)
    if #params > 0 then
        local pId = tonumber(params)
        local result, pHandle = sampGetCharHandleBySampPlayerId(pId)
        if not result then
            printStringNow('~r~Pemain tidak ditemukan', 1500)
            return
        end
        track(pHandle)
        printStringNow(string.format('~w~Sedang menandai ~b~%s', sampGetPlayerNickname(pId)), 1500)
    else
        for pHandle, pMarker in pairs(pMarkers) do
            removeBlip(pMarker)
            pMarkers[pHandle] = nil
        end
        printStringNow('~r~Semua marker dihapus', 1500)
    end
end

function cmdSI()
    if not sampIsLocalPlayerSpawned() then
        printStringNow('~r~Kamu belum spawn!', 1500)
        return
    end
    for _, pHandle in pairs(getAllChars()) do
        local result, pId = sampGetPlayerIdByCharHandle(pHandle)
        if result then
            local pName = sampGetPlayerNickname(pId)
            sampAddChatMessage(string.format('%s [%d]', pName, pId), -1)
        end
    end
end

function cmdPTHelp()
    local helpLines = {
        "menampilkan bantuan skrip",
        "mendeteksi pemain",
        "menghapus pemain dari daftar deteksi",
        "menampilkan daftar pemain yang dideteksi",
        "aktif/nonaktifkan disconnect saat pemain terdeteksi",
        "aktif/nonaktifkan tracking saat pemain terdeteksi",
        "menambahkan marker pada pemain",
        "menghapus semua marker",
        "menampilkan semua pemain dalam stream"
    }

    local commands = {
        "/pthelp",
        "/det <id/nickname>",
        "/undet <id/nickname>",
        "/detectlist",
        "/dod",
        "/tod",
        "/track <id>",
        "/track",
        "/si"
    }

    for i = 1, #commands do
        sampAddChatMessage(string.format("%d. %s > %s", i, commands[i], helpLines[i]), -1)
    end
end

function track(pHandle)
    local pMarker = addBlipForChar(pHandle)
    changeBlipColour(pMarker, 7)
    pMarkers[pHandle] = pMarker
end

function getPlayerNameByParams(params)
    local pId = tonumber(params)
    if pId then
        return sampIsPlayerConnected(pId) and sampGetPlayerNickname(pId) or nil
    else
        return #params > 0 and params or nil
    end
end

function arrayContains(tab, val)
    for _, v in ipairs(tab) do
        if v == val then return true end
    end
    return false
end

function setContains(set, key)
    return set[key] ~= nil
end
