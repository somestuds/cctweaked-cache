local base64 = require("cc.base64")
local gpu = peripheral.find("tm_gpu")
os.sleep(4.5)

gpu.refreshSize()
gpu.setSize(64)
gpu.fill()

local audioReady = false
local videoReady = false
local time = 0

local function video()
    local fps = 0
    local frameStart = os.epoch("utc") / 1000
    local frameIndex = 0

    local function getImage(chunk)
        if chunk == nil then print("chunk was nil") end
        local decoded = base64.decode(chunk)
        local dec = gpu.decodeImage(string.byte(decoded, 1, #decoded))
        return dec
    end
    local function drawImage(chunk)
        local img = getImage(chunk)
        gpu.fill()
        gpu.drawImage(1, 1, img.ref())
        gpu.sync()
        img.free()
    end

    local function waitForFrame(i)
        local target = frameStart + (i / fps)
        local now = os.epoch("utc") / 1000
        local delay = target - now
        if delay > 0 then
            os.sleep(delay)
        end
    end

    local i = 0

    videoReady = true
    repeat
        os.sleep(0)
    until audioReady
    time = os.epoch("utc") / 1000

    local CHUNK_MASTER = {}
    

    while true do
        os.sleep(0)
        local preTime = os.epoch("utc") / 1000
        local res = http.get("http://localhost:3000/chunk/" .. i)
        assert(res, "Could not contact localhost")
        local resd = res.readAll()
        local json = textutils.unserializeJSON(resd)
        assert(json, "Failed to deserialize JSON")
        if fps == 0 then fps = json.fps end
        local chunks = json.frames

        local now = os.epoch("utc") / 1000
        local elapsed = ("%i"):format((now - preTime) * 1000)
        print("Chunk " .. i .. " took " .. elapsed .. " ms")

        if #chunks == 0 then break end

        for i = 1, #chunks do
            drawImage(chunks[i])

            waitForFrame(frameIndex)
            frameIndex = frameIndex + 1
        end
        i = i + 1
    end
end
local function audio()
    local speaker = peripheral.find("speaker")
    local dfpwm = require('cc.audio.dfpwm')
    local decoder = dfpwm.make_decoder()
    local res = http.get("http://localhost:3000/audio")
    assert(res, "Could not contact localhost")
    local resd = res.readAll()

    local CHUNK_SIZE = 16 * 1024

    local function chunks(str)
        local i = 1
        return function()
            if i > #str then return nil end

            local chunk = str:sub(i, i + CHUNK_SIZE - 1)
            i = i + CHUNK_SIZE
            return chunk
        end
    end

    local chunked = chunks(resd)
    audioReady = true
    repeat
        os.sleep(0)
    until videoReady

    for chunk in chunked do
        local buffer = decoder(chunk)
        if not buffer then break end
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

parallel.waitForAll(video, audio)
print("Finished in " .. ("%.2f"):format((os.epoch("utc") / 1000) - time) .. " seconds")
