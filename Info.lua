--[[----------------------------------------------------------------------------
Info.lua
TODO: Update Headers
--------------------------------------------------------------------------------
ADOBE SYSTEMS INCORPORATED
 Copyright 2007-2010 Adobe Systems Incorporated
 All Rights Reserved.
NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.
------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 5.0,
	LrSdkMinimumVersion = 5.0, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'org.osipov.dan.lrrawremover',
	LrPluginName = LOC "$$$/LrRawRemover/PluginName=LrRawRemover",

	LrInitPlugin = "RRInit.lua",
	LrLibraryMenuItems = {
		title = "Remove RAW Versions",
		file = "RRMenuItem.lua", -- The script that runs when the item is selected
	},

	VERSION = { major=1, minor=0, revision=0, build=999999, },
}