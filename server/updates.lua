CreateThread(function()
    local url = "https://raw.githubusercontent.com/EightServices/es_givecar/master/version.txt"

    local function getAnticombatlogVersion()
        local file = io.open(GetResourcePath(GetCurrentResourceName()).."/version.txt", "r")
        if file then
            local local_version = file:read("*all")
            file:close()
            return local_version:match("^%s*(.-)%s*$")
        else
            print("version.txt not found!")
            return nil
        end
    end

    local local_version = getAnticombatlogVersion()

    if local_version then
        PerformHttpRequest(url, function(statusCode, responseText, headers)
            if statusCode == 200 then
                responseText = responseText:match("^%s*(.-)%s*$")

                if responseText == local_version then
                    print(string.format("Version %s\nYou are running on the latest version", local_version))
                else
                    print(string.format("Version %s\nYou are currently running an outdated version, please update to version %s", local_version, responseText))
                end
            else
                print("Failed to retrieve version from URL.")
            end
        end, 'GET')
    end
end)