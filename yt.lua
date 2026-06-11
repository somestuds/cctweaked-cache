print("Controls: \nC - Cancel\nQ - Exit\n")

local api = "https://ipod-2to6magyna-uc.a.run.app/?v=2.1&"

local speaker = peripheral.find("speaker")
if not speaker then print("Attach a speaker") return end

local alive = true
local playing = false
local threadStarted = false
local wasError = false

local AD_ID = '9Se1cKmJ_Ik'
local AD_LINK = "patreon"
local RESULTS_MAXLENGTH = 7
local RESULT_DOT_CHAR = string.char(183) -- Middle Dot · U+00B7
local AUDIO_BITRATE = 1024
local processArguments = {...}

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

---@param url string
---@param handle any
---@returns "music"|"search"|"unknown", table|nil
local function decodeData(url, handle)
    local idi = string.find(url, "&id=")
    local searchi = string.find(url, "&search=")
    local dataType = idi and "music" or searchi and "search" or "unknown"
    if dataType == "unknown" then return dataType, nil end
    local tc = handle.readAll()
    if not tc or #tc <= 0 then return dataType, nil end
    local data = textutils.unserialiseJSON(tc)
    if data == nil then return dataType, tc end
    return dataType, data
end

local function search(query)
    http.request({
        url = api .. "search=" .. textutils.urlEncode(query),
        binary = true
    })
end

local function writeAt(x, y, text)
    term.setCursorPos(x,y)
    term.clearLine()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.write(text)
end

local function playAudio(data, info)
    playing = true
    local chunks = {}
    for i = 1, #data, AUDIO_BITRATE do
        table.insert(chunks, data:sub(i, i + AUDIO_BITRATE - 1))
    end

    local aname, aartist, aduration = info.name, info.artist, info.duration
    term.clear()
    writeAt(1, 1, "Playing " .. aname)
    writeAt(1, 2, "by " .. aartist)
    writeAt(1, 3, "0:00 / " .. aduration)

    local startTime = os.clock()+0.3
    parallel.waitForAny(
        function()
            for _, chunk in pairs(chunks) do
                if not playing or not threadStarted then break end
                local data = decoder(chunk)
                if not data then break end
                while not speaker.playAudio(data) do
                    os.pullEvent("speaker_audio_empty")
                end
            end
        end,
        function()
            while playing do
                if not playing then break end
                os.sleep(0)
                local secondsElapsed = math.floor(("%.2f"):format((os.clock()+0.3)-startTime))
                local minutes = math.floor(secondsElapsed/60)
                local seconds = secondsElapsed - (minutes*60)
                writeAt(1,3, ("%s / %s"):format(("%s:%02d"):format(minutes, seconds),aduration))
            end
        end
    )
    
    playing = false
end

local isSearching = false
local function main()
    local prcRuns = 0
    while alive do
	prcRuns = prcRuns + 1
        print("\n")
	local query
	if prcRuns == 1 and #processArguments >= 1 then
	    query = table.concat(processArguments, " ")
	else
            write("Enter song name > ")
	    isSearching = true
            query = read()
	    isSearching = false
	end
        if query == "" or #query <= 3 then return end
        threadStarted = true
        search(query)
        repeat
            os.sleep(0)
        until playing or wasError
        
        if playing and not wasError then
            repeat
                os.sleep(0)
            until not playing
        end
        if wasError then
            playing = false
            wasError = false
        end
    end
end

local function onKeyPress()
    while true do
        os.sleep(0)
        local _, key = os.pullEvent("key")
        if key == keys.q and not isSearching then
            speaker.stop()
            alive = false
            playing = false
            threadStarted = false
            break
        end
        if key == keys.c and threadStarted and not isSearching then
            speaker.stop()
            playing = false
            threadStarted = false
            wasError = true
        end
    end
end

local function split(str, sep)
  local t = {}
  local start = 1

  while true do
    local i, j = string.find(str, sep, start, true) -- plain search
    if not i then
      t[#t + 1] = string.sub(str, start)
      break
    end

    t[#t + 1] = string.sub(str, start, i - 1)
    start = j + 1
  end

  return t
end

local function onRequest()
    local chosenSongData = {}

    parallel.waitForAny(
        function () -- Http success
            while alive do
                os.sleep(0)
                local _, url, handle = os.pullEventRaw("http_success")
                if threadStarted then
                    local dataType, data = decodeData(url, handle)
                    if dataType == "unknown" or data == nil then print("Failed to play song, could not decode data") return end
                    if dataType == "search" then
                        if (#data-1 > 0) or #data > 0 then
                            local fixedData = data
                            
                            local posAd = fixedData[1]
                            if posAd.id:lower():find(AD_ID:lower()) or posAd.artist:lower():find(AD_LINK:lower()) then
                                table.remove(fixedData,1)
                            end

                            if #fixedData > 0 then
                                local results = {}
                                for i = 1, RESULTS_MAXLENGTH do
                                    local res = fixedData[i]
                                    if not res then break end
                                    local splitInfo = split(res.artist, " "..RESULT_DOT_CHAR.." ")
                                    local duration, artist = table.unpack(splitInfo)
                                    res.duration = duration
                                    res.artist = artist
                                    res.name = split(res.name, res.artist.." - ")[2] or res.name
                                    table.insert(results, res)
                                end
                                for index, res in pairs(results) do
                                    print(index .. ": "..res.name)
                                end
                                write("Select a song (1-" .. RESULTS_MAXLENGTH .. "): ")
                                local chosenIndex = read()
                                local ind = tonumber(chosenIndex)
                                if not ind or not results[ind] then 
                                    print("Invalid index, cancelling!") 
                                    playing = false
                                    threadStarted = false
                                    wasError = true
                                    chosenSongData = {}
                                    return
                                end

                                local song = results[ind]
                                chosenSongData = song
                                http.request({
                                    url = api .. "id=" .. song.id,
                                    binary = true
                                })
                            else
                                print("No results")
                                wasError = true
                                threadStarted = false
                                playing = false
                                chosenSongData = {}
                            end
                        else
                            print("No results")
                            wasError = true
                            threadStarted = false
                            playing = false
                            chosenSongData = {}
                        end
                    elseif dataType == "music" then
                        playAudio(data, chosenSongData)
                    end
                end
            end
        end,
        function () -- Http failure
            while alive do
                os.sleep(0)
                os.pullEvent("http_failure")
                print("Failed to play song, http server connection failed")
                wasError = true
            end
        end
    )
end


parallel.waitForAny(main, onKeyPress, onRequest)
print("")