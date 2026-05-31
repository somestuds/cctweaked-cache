local repo = "somestuds/cctweaked-cache"
local url
local computer_id = tostring(os.getComputerID())

local sha256CachePath = "./sha.bin"
local sha256Cache = {}
local computerRootSha256 = ""
local computerRootSha256Index = "rootSha256_" .. computer_id

if fs.exists(sha256CachePath) then
    local file = fs.open(sha256CachePath, "r")
    assert(file, "Error reading sha256 cache at startup, FS error")

    local data = file.readAll()
    file.close()

    local json = textutils.unserialiseJSON(data)
    assert(json, "Malformed sha256 cache data, read at startup")

    if type(json) == 'table' then
        local crootSha256 = json[computerRootSha256Index]
        if crootSha256 then
            json[computerRootSha256Index] = nil
            computerRootSha256 = computerRootSha256
        end
        sha256Cache = json
    end
end

local function writeSha256Cache(unmergedData)
    if not fs.exists(sha256CachePath) then
        local file = fs.open(sha256CachePath, "w")
        assert(file, "Could not open write stream for new sha256 cache, FS error")

        local data = {}
        for path, sha256 in pairs(unmergedData) do
            data[path] = (sha256 ~= "" and sha256 or nil)
        end
        file.write(textutils.serialiseJSON(data))
        file.close()
    else
        local readStream = fs.open(sha256CachePath, "r")
        assert(readStream, "Could not read previous sha256 cache, FS error")

        local cachedSha256 = readStream.readAll()
        readStream.close()

        local sha256Table = textutils.unserialiseJSON(cachedSha256)
        for path, sha256 in pairs(unmergedData) do
            sha256Table[path] = (sha256 ~= "" and sha256 or nil)
        end

        local writeStream = fs.open(sha256CachePath, "w")
        assert(writeStream, "Could not write new sha256 cache, FS error")
        writeStream.write(textutils.serialiseJSON(sha256Table))
        writeStream.close()
    end
end

local function handleHttpSuccess()
    local http_url, handle
    repeat
        _, http_url, handle = os.pullEvent("http_success")
    until http_url == url
    local data = handle.readAll()
    local json = textutils.unserialiseJSON(data)
    assert(json, "Invalid JSON returned from Github API")
    assert(not (json.status and json.status == "404"), "No files found for this computer (" .. computer_id .. ")")

    local serverNodes = {}
    local unmergedSha256Cache = {}

    local function getInstalledPaths(base)
        local tbl = {}
        for _, path in pairs(fs.list(base or "")) do
            tbl[path] = true
            if fs.isDir(path) then
                for subpath, _ in pairs(getInstalledPaths(path)) do
                    tbl[subpath] = true
                end
            end
        end
        return tbl
    end

    for _, node in pairs(json) do
        ---@type "dir"|"file"
        local type = node.type

        local path = node.path.split(computer_id .. "/")[2]
        local sha256 = node.sha

        serverNodes[path] = true

        local nodeExists = fs.exists(path)
        if not nodeExists or sha256 ~= sha256Cache[path] then
            if type == "dir" and not nodeExists then fs.makeDir(path) end
            if type == "file" then
                local download_url = node.download_url
                if nodeExists then fs.delete(path) end

                local req = http.get(download_url)
                assert(req, "Could not update file @" .. path .. ", HTTP Error")
                local fileContents = req.readAll()

                local writeStream = fs.open(path, "w")
                assert(writeStream, "Could not update file @" .. path .. ", FS Error")

                writeStream.write(fileContents)
                writeStream.close()
            end
            unmergedSha256Cache[path] = sha256
        end
    end

    for path, _ in pairs(getInstalledPaths("")) do
        if not serverNodes[path] then
            fs.delete(path)
            unmergedSha256Cache[path] = ""
        end
    end

    writeSha256Cache(unmergedSha256Cache)
end

local function handleHttpError()
    local http_url, err
    repeat
        _, http_url, err = os.pullEvent("http_failure")
    until http_url == url
    print("Could not contact Github API @ " .. http_url)
    error(err)
end

parallel.waitForAll(
    function()
        if not computerRootSha256 then
            local rootUrl = textutils.urlEncode("https://api.github.com/repos/" .. repo .. "/contents")
            local response = http.get(rootUrl)
            assert(response, "Computer Folder Tree sha256 was nil and could not contact Github API to obtain it")

            local data = response.readAll()
            local json = textutils.unserialiseJSON(data)

            assert(json, "Github API returned malformed data while trying to obtain computer root sha256")
            assert(not (json.status ~= nil and json.status == "404"),
                "Repository is invalid or private, could not obtain computer root sha256")

            for _, node in pairs(json) do
                if node.type == "dir" and node.path == computer_id and node.name == computer_id then
                    computerRootSha256 = node.sha
                    writeSha256Cache({ [computerRootSha256Index] = computerRootSha256 })
                end
            end
        end
        assert(computerRootSha256, "Could not obtain tree root sha256 for Computer ID")

        url = textutils.urlEncode("https://api.github.com/repos/" ..
            repo .. "/git/trees/" .. computerRootSha256 .. "?recursive=1")
        http.request(url)
    end,
    parallel.waitForAny(handleHttpError, handleHttpSuccess)
)
