local repo = "somestuds/cctweaked-cache"
local url = "https://api.github.com/repos/" .. repo .. "/contents/" .. os.getComputerID()

local function handleSuccess()

end

local function handleHttpError()
    
end 

parallel.waitForAny()