local function githubUrl(username,repo,path)
    return "https://api.github.com/repos/"..username.."/"..repo.."/"..path
end

local function getUnwrappedResponse(url)
    local response = {http.get(url)}
    if not response[1] then
        error(response[2])
    end
    return textutils.unserializeJSON(response[1].readAll())
end

local function ptabs(n)
    local str = ""
    for i=1,n do
        str = str.."  "
    end
    return str
end

local function downloadRepo(path,url,tab)
    tab = tab or 0
    local response = getUnwrappedResponse(url)
    for _,p in pairs(response) do
        term.write(ptabs(tab))
        print(p.path)
        if p.download_url then
            local h = fs.open(path..p.path,"w")
            h.write(getUnwrappedResponse(p.download_url))
            h.close()
        else
            downloadRepo(path,p.url,tab+1)
        end
    end
end
