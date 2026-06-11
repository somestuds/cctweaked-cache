local url = 'https://img.youtube.com/vi/PMM2L13f-0Q/mqdefault.jpg'
local data = http.get(url).readAll()
local bytes = { string.byte(data, 1, #data) }

_G.img = peripheral.find('tm_gpu').decodeImage(table.unpack(bytes, 1, #bytes))