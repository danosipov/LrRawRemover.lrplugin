RRMenuItem = {}

local LrApplication = import "LrApplication"
local LrSelection = import "LrSelection"
local LrFunctionContext = import "LrFunctionContext"
local LrPathUtils = import "LrPathUtils"
local LrFileUtils = import "LrFileUtils"
local LrDialogs = import "LrDialogs"
local LrProgressScope = import "LrProgressScope"

require 'RRLogger'

function RRMenuItem.run()
    LrFunctionContext.postAsyncTaskWithContext( "Remving Raw version", function(context)
        RRLogger.trace("Starting run")
        context:addFailureHandler( function(status, message)
            LrDialogs.message(
                "Deletion Failed",
                "Error: " .. message,
                "critical"
            )
        end )

        local progress = LrProgressScope({title = "Listing files and versions", functionContext = context})
        progress:setIndeterminate()

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
                "About to remove " .. #filesToDelete .. " RAW file(s). Proceed?"
            )

            if confirm == "ok" then
                progress:setCaption("Removing Files")
                local status = true
                local forceDelete = false
                catalog:withWriteAccessDo("Remove Raw", function(ctx)
                    for i, deletion in ipairs(filesToDelete) do
                        RRLogger.logTable("deletion", deletion)
                        local path = deletion["path"]
                        RRLogger.info("Removing " .. path)
                        local result, err = RRMenuItem.removeFile(path, forceDelete)
                        if not result then
                            RRLogger.warn("Failure to delete, Err: " .. err)
                        end

                        if not result and not forceDelete then
                            status = false
                            local forceConfirm = LrDialogs.confirm(
                                "Delete Permanently?",
                                "Unable to move " .. LrPathUtils.leafName(path) .. " to recycle bin. Error: " .. err,
                                "Delete All Permanently",
                                "Skip",
                                "Cancel"
                            )
                            if forceConfirm == "other" then
                                progress:cancel()
                                return false
                            elseif forceConfirm == "ok" then
                                result, err = RRMenuItem.removeFile(path, true)
                                forceDelete = true
                                status = result
                            elseif forceConfirm == "cancel" then
                                -- Nothing?
                            end
                        end

                        if result then
                            for _, version in pairs(deletion["versions"]) do
                                local versionExtension = LrPathUtils.extension(version):lower()
                                if version ~= path and (versionExtension == "jpg" or versionExtension == "jpeg") then
                                    local newPhoto = catalog:addPhoto(version, deletion["photo"], "above")
                                    RRMenuItem.copyProperties(deletion["photo"], newPhoto)
                                end
                            end
                        end

                        progress:setPortionComplete(i, #filesToDelete)
                    end
                end )

                if status then
                    progress:done()
                    LrDialogs.message(
                        "Deletion Complete",
                        "Removed " .. #filesToDelete .. " RAW files. Synchronize folder to remove the deleted photos from Lightroom Catalog.",
                        "info"
                    )
                else
                    LrDialogs.message(
                        "Deletion Failed",
                        "Errors encountered during deletion",
                        "critical"
                    )
                end
            end
        end
    end )
end

function RRMenuItem.removeFile(path, force)
    local result, err = LrFileUtils.moveToTrash(path)
    if not result and force then
        return LrFileUtils.delete(path)
    else
        return result, err
    end
end

function RRMenuItem.copyProperties(from, to)
    to:setRawMetadata("rating", from:getRawMetadata("rating"))
    to:setRawMetadata("caption", from:getFormattedMetadata("caption"))
    to:setRawMetadata("title", from:getFormattedMetadata("title"))
    to:setRawMetadata("label", from:getFormattedMetadata("label"))
    to:setRawMetadata("pickStatus", from:getRawMetadata("pickStatus"))
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

            local versions = {}
            for file in LrFileUtils.files(dir) do
                if LrPathUtils.removeExtension(LrPathUtils.leafName(file)) == name then
                    versions[#versions + 1] = file
                end
            end

            if #versions > 1 then
                filesToDelete[#filesToDelete + 1] = {
                    photo = photo,
                    path = photoPath,
                    versions = versions
                }
            end
        end
    end
    return filesToDelete
end

RRMenuItem.run()