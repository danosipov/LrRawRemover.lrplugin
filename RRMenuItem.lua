RRMenuItem = {}

local LrApplication = import "LrApplication"
local LrSelection = import "LrSelection"
local LrFunctionContext = import "LrFunctionContext"
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local LrDialogs = import "LrDialogs"

require 'RRLogger'

function RRMenuItem.run()
    LrFunctionContext.postAsyncTaskWithContext( "Remving Raw version", function(context)
        RRLogger.trace("Starting run")
        local catalog = LrApplication.activeCatalog()
        local selection = catalog:getMultipleSelectedOrAllPhotos()
        local filesToDelete = RRMenuItem.findFiles(selection)
        
        if #filesToDelete == 0 then
            LrDialogs.message(
                "No RAW files to delete",
                "RAW files with multiple formats we not found. Aborting deletion. Use 'Delete Rejected Photos' instead"
            )
        else
            local confirm = LrDialogs.confirm(
                "Remove RAW FIles?",
                "About to remove " .. #filesToDelete .. " RAW files. Proceed?"
            )

            if confirm == "ok" then
                local errors = {}
                local status = true
                for _, deletion in pairs(filesToDelete) do
                    local path = deletion["path"]
                    RRLogger.info("Removing " .. path)
                    local result = LrFileUtils.moveToTrash(path)
                    if not result then
                        status = false
                        errors[#errors + 1] = result[1]
                    else
                        -- TODO Set object to remaining version path
                        -- deletion["photo"]:setRawMetadata("path", path .. ".jpg")
                    end
                end

                if status then
                    LrDialogs.message(
                        "Deletion Complete",
                        "Removed " .. #filesToDelete .. " RAW files.",
                        "info"
                    )
                else
                    LrDialogs.message(
                        "Deletion Failed",
                        "Error faced: " .. errors[0],
                        "critical"
                    )
                end
            end
        end
    end )
end

function RRMenuItem.findFiles(selection)
    local filesToDelete = {}
    for _, photo in pairs(selection) do
        local photoPath = photo:getRawMetadata("path")
        local fileFormat = photo:getRawMetadata("fileFormat")
        if fileFormat == "RAW" then
            RRLogger.logTable("path", photoPath)
            
            local dir = LrPathUtils.parent(photoPath)
            local fileName = LrPathUtils.leafName(photoPath)
            local name = LrPathUtils.removeExtension(fileName)

            local versions = 0
            for file in LrFileUtils.files(dir) do
                if LrPathUtils.removeExtension(LrPathUtils.leafName(photoPath)) == name then
                    versions = versions + 1
                end
            end

            if versions > 1 then
                filesToDelete[#filesToDelete + 1] = {
                    photo = photo,
                    path = photoPath
                }
            end
        end
    end
    return filesToDelete
end

RRMenuItem.run()