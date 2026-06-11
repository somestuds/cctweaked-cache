local gpu = peripheral.find("tm_gpu")
gpu.refreshSize()
gpu.setSize(64)
gpu.refreshSize()
gpu.fill()
gpu.sync()

local function httpGet(url)
    local res = http.get(url)
    if res then
        return res.readAll()
    end
end

local ix = 320
local iy = 210

local youtubeIds = {}
local query = table.concat({ ... }, " ")
local results = httpGet('https://ipod-2to6magyna-uc.a.run.app/?v=2.1&search=' .. textutils.urlEncode(query))
assert(results, "Failed to fetch results")
local json = textutils.unserializeJSON(results)
assert(json, "Failed to deserialize JSON")
print(#json)
local i = 1
while #youtubeIds < 9 do
    os.sleep(0)
    local item = json[i]
    local id = item.id
    if id ~= '9Se1cKmJ_Ik' and string.find(id, "patreon") == nil then
        table.insert(youtubeIds, { id = id, title = item.name })
    end
    i = i + 1
end

local sw, sh = gpu.getSize()
local cardsPerColumn = math.floor(sw / ix)
local leftoverPixelsPerColumn = (sw % ix)
local leftoverPixelsPerRow = nil
local cardMargin = leftoverPixelsPerColumn / (cardsPerColumn + 1)
local x, y = 1 + cardMargin, 1
print(sw, sh)
for _, tbl in pairs(youtubeIds) do
    if y + iy > sh or y + 180 > sh then
        return
    end
    local img = httpGet('https://img.youtube.com/vi/' .. tbl.id .. '/mqdefault.jpg')
    local decoded_image = gpu.decodeImage(string.byte(img, 1, #img))
    local img_ref = decoded_image.ref()
    if x + ix > sw then
        x = 1 + cardMargin
        y = y + iy
    end
    gpu.drawImage(x, y, img_ref)
    decoded_image.free()



    -- print(x, y + 180, y + 180 > sh)
    gpu.drawText(x, y + 180, string.sub(tbl.title, 1, 56), 0xFFFFFF, 0x000000, 1.5)
    x = x + ix + cardMargin
end
print("Done")
gpu.sync()
