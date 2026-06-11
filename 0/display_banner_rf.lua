local gpu = peripheral.find('tm_gpu')
local basinhd = require('basinhd')
local dfp = require('cc.audio.dfpwm')
local decoder = dfp.make_decoder()
basinhd:setMouseCursorEnabled(true)

local mainFrame = basinhd:getMainFrame(gpu)

function string:split(sep)
    sep = sep or " "

    local result = {}
    local start = 1

    while true do
        local i, j = self:find(sep, start, true) -- plain search

        if not i then
            result[#result + 1] = self:sub(start)
            break
        end

        result[#result + 1] = self:sub(start, i - 1)
        start = j + 1
    end

    return result
end

--- @param url string
--- @return boolean, string?
local function httpGet(url)
    local httpReachable, whyNot = http.checkURL(url)
    if not httpReachable then
        return false, whyNot
    end

    local response = http.get(url)
    if not response then
        return false, 'Could not get response from url'
    end

    return true, response.readAll()
end

local query = table.concat(table.pack(...), ' ')
local success, ytResponse = httpGet('https://ipod-2to6magyna-uc.a.run.app/?v=2.1&search=' .. textutils.urlEncode(query))
assert(success, ytResponse)

local ytResults = textutils.unserializeJSON(ytResponse)
assert(ytResults, 'failed to parse json ytresults')
local ytVideos = {}

local i = 1
while #ytVideos < 9 do
    os.sleep(0)
    local item = ytResults[i]
    local id = item.id
    local name = item.name
    local duration, artist = table.unpack(item.artist:split(string.char(183) .. ' '))
    if id ~= '9Se1cKmJ_Ik' then
        table.insert(ytVideos, { id = id, title = name, duration = duration, artist = artist })
    end
    i = i + 1
end

local screenWidth, screenHeight = basinhd:getScreenSize()
local thumbnailWidth, thumbnailHeight = 320, 180
local videoCardPaddingY = 12

local maximumCardsPerColumn = math.floor(screenWidth / thumbnailWidth)
local maximumCardsPerRow = math.floor(screenHeight / (thumbnailHeight + videoCardPaddingY))
local remainingPixelsPerColumn = screenWidth % thumbnailWidth
local remainingPixelsPerRow = screenHeight % (thumbnailHeight + videoCardPaddingY)
local columnMargin = math.floor(remainingPixelsPerColumn / (maximumCardsPerColumn + 1))
local rowMargin = math.floor(remainingPixelsPerRow / (maximumCardsPerRow + 1))

local searchResultsFrame = mainFrame:addFrame()
    :setPositionAndSize(1, 1, screenWidth, screenHeight)

local function playyt(id)
    searchResultsFrame:setVisible(false)
    local scs, dfpwm = httpGet('https://ipod-2to6magyna-uc.a.run.app/?v=2.1&id=' .. id)
    assert(scs and dfpwm, dfpwm)

    local chunks = {}
    for i = 1, #dfpwm, 16 * 1024 do
        table.insert(chunks, dfpwm:sub(i, i + (16 * 1024) - 1))
    end

    for _, chunk in pairs(chunks) do
        if not chunk then break end
        local buffer = decoder(chunk)
        if not buffer then break end
        while not peripheral.find('speaker').playAudio(buffer, 3) do
            os.pullEvent('speaker_audio_empty')
        end
    end

    searchResultsFrame:setVisible(true)
end

local cardX, cardY = 1 + columnMargin, 1 + rowMargin
for _, video in pairs(ytVideos) do
    if cardX + thumbnailWidth > screenWidth then
        cardX = 1 + columnMargin
        cardY = cardY + thumbnailHeight + videoCardPaddingY + rowMargin
    end

    local card = searchResultsFrame:addFrame()
        :setBackground('#ff0000')
        :setBackgroundEnabled(true)
        :setPositionAndSize(cardX, cardY, thumbnailWidth, thumbnailHeight + videoCardPaddingY)

    --card:addImage()
      --  :setDesiredSize(thumbnailWidth, thumbnailHeight)
        --:setPosition(1, 1)
        --:setImage('https://img.youtube.com/vi/' .. video.id .. '/mqdefault.jpg')

    local titledivision = card:addFrame()
        :setBackgroundEnabled(false)
        :setPositionAndSize(1, 1 + thumbnailHeight, thumbnailWidth, videoCardPaddingY)

    titledivision:addText()
        :setTextAnchor('center', 'center')
        :setText(video.title)
        :setTextScale(1)

    card:addButton()
        :setPositionAndSize(1, 1, thumbnailWidth, thumbnailHeight + videoCardPaddingY)
        :setBackgroundEnabled(false)
        :setTextEnabled(false)
        :onClick(function()
            playyt(video.id)
        end)

    cardX = cardX + thumbnailWidth + columnMargin
end

basinhd:run()
