-- Lightroom SDK
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'
local LrTasks = import 'LrTasks'

-- Common shortcuts
local bind = LrView.bind
local share = LrView.share

-- LrGallery plug-in
require 'LrGalleryAPI'
require 'LrGalleryUser'
require 'LrGalleryPublishSupport'


local exportServiceProvider = {}

for name, value in pairs( LrGalleryPublishSupport ) do
	exportServiceProvider[name] = value
end

--- (optional) Plug-in defined value declares whether this plug-in supports the Lightroom
 -- publish feature. If not present, this plug-in is available in Export only.
 -- When true, this plug-in can be used for both Export and Publish. When 
 -- set to the string "only", the plug-in is visible only in Publish.
exportServiceProvider.supportsIncrementalPublish = 'only'

--------------------------------------------------------------------------------
--- (optional) Plug-in defined value declares which fields in your property table should
 -- be saved as part of an export preset or a publish service connection. If present,
 -- should contain an array of items with key and default values. For example:
	-- <pre>
		-- exportPresetFields = {<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'username', default = "" },<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'fullname', default = "" },<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'nsid', default = "" },<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'privacy', default = 'public' },<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'privacy_family', default = false },<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;{ key = 'privacy_friends', default = false },<br/>
		-- }<br/>
	-- </pre>
 -- <p>The <code>key</code> item should match the values used by your user interface
 -- controls.</p>
 -- <p>The <code>default</code> item is the value to the first time
 -- your plug-in is selected in the Export or Publish dialog. On second and subsequent
 -- activations, the values chosen by the user in the previous session are used.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
exportServiceProvider.exportPresetFields = {
	{ key = 'username', default = "" },
	{ key = 'password', default = "" },	
}

--- (optional) Plug-in defined value suppresses the display of the named sections in
 -- the Export or Publish dialogs. You can use either <code>hideSections</code> or 
 -- <code>showSections</code>, but not both. If present, this should be an array 
 -- containing one or more of the following strings:
	-- <ul>
		-- <li>exportLocation</li>
		-- <li>fileNaming</li>
		-- <li>fileSettings</li>
		-- <li>imageSettings</li>
		-- <li>outputSharpening</li>
		-- <li>metadata</li>
		-- <li>watermarking</li>
	-- </ul>
 -- <p>You cannot suppress display of the "Connection Name" section in the Publish Manager dialog.</p>
 -- <p>If you suppress the "exportLocation" section, the files are rendered into
 -- a temporary folder which is deleted immediately after the Export operation
 -- completes.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
exportServiceProvider.hideSections = { 'exportLocation' }

exportServiceProvider.allowFileFormats = { 'JPEG' }
exportServiceProvider.allowColorSpaces = { 'sRGB' }
exportServiceProvider.hidePrintResolution = true
exportServiceProvider.canExportVideo = false -- video is not supported through this sample plug-in

-- LRGALLERY SPECIFIC: Helper functions and tables.

local function updateCantExportBecause(propertyTable)
	if not propertyTable.validAccount then
		propertyTable.LR_cantExportBecause = LOC "$$$/LrGallery/ExportDialog/NoLogin=You haven't logged in to LrGallery yet."
	else
		propertyTable.LR_cantExportBecause = nil
	end
	
	return
end

local displayNameForTitleChoice = {
	filename = LOC "$$$/LrGallery/ExportDialog/Title/Filename=Filename",
	title = LOC "$$$/LrGallery/ExportDialog/Title/Title=IPTC Title",
	empty = LOC "$$$/LrGallery/ExportDialog/Title/Empty=Leave Blank",
}

local kSafetyTitles = {
	safe = LOC "$$$/LrGallery/ExportDialog/Safety/Safe=Safe",
	moderate = LOC "$$$/LrGallery/ExportDialog/Safety/Moderate=Moderate",
	restricted = LOC "$$$/LrGallery/ExportDialog/Safety/Restricted=Restricted",
}

local function booleanToNumber(value)
	return value and 1 or 0
end

local function getLrGalleryTitle( photo, exportSettings, pathOrMessage )

	local title
			
	-- Get title according to the options in LrGallery Title section.

	if exportSettings.titleFirstChoice == 'filename' then
				
		title = LrPathUtils.leafName( pathOrMessage )
				
	elseif exportSettings.titleFirstChoice == 'title' then
				
		title = photo:getFormattedMetadata 'title'
				
		if ( not title or #title == 0 ) and exportSettings.titleSecondChoice == 'filename' then
			title = LrPathUtils.leafName( pathOrMessage )
		end

	end
				
	return title

end

-- On start dialog
function exportServiceProvider.startDialog(propertyTable)

	-- Disable login button
	propertyTable.loginButtonTitle = 'Checking login...'
	propertyTable.loginButtonEnabled = false

	-- Check if login is valid
	LrGalleryUser.checkLogin(propertyTable)
end

--- (optional) This plug-in defined callback function is called when the user 
 -- chooses this export service provider in the Export or Publish dialog. 
 -- It can create new sections that appear above all of the built-in sections 
 -- in the dialog (except for the Publish Service section in the Publish dialog, 
 -- which always appears at the very top).
 -- <p>Your plug-in's <a href="#exportServiceProvider.startDialog"><code>startDialog</code></a>
 -- function, if any, is called before this function is called.</p>
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
	-- @param f (<a href="LrView.html#LrView.osFactory"><code>LrView.osFactory</code> object)
		-- A view factory object.
	-- @param propertyTable (table) An observable table that contains the most
		-- recent settings for your export or publish plug-in, including both
		-- settings that you have defined and Lightroom-defined export settings
	-- @return (table) An array of dialog sections (see example code for details)
	-- @name exportServiceProvider.sectionsForTopOfDialog
function exportServiceProvider.sectionsForTopOfDialog( f, propertyTable )

	return {
	
		{
			title = LOC "$$$/LrGallery/ExportDialog/Account=LrGallery Account",
			
			synopsis = bind 'accountStatus',

			f:row {
				spacing = f:control_spacing(),

				f:static_text {
					title = bind 'accountStatus',
					alignment = 'right',
					fill_horizontal = 1,
				},

				f:push_button {
					width = tonumber( LOC "$$$/locale_metric/LrGallery/ExportDialog/LoginButton/Width=90" ),
					title = bind 'loginButtonTitle',
					enabled = bind 'loginButtonEnabled',
					action = function()
						require 'LrGalleryUser'
						LrGalleryUser.login(propertyTable)
					end,
				},

			},
		},
		
		{
			title = LOC "$$$/LrGallery/ExportDialog/Account=User management",
			
			synopsis = bind 'userManagement',

			f:row {
				spacing = f:control_spacing(),

				f:push_button {
					width = tonumber( LOC "$$$/locale_metric/LrGallery/ExportDialog/LoginButton/Width=90" ),
					title = LOC "$$$/locale_metric/LrGallery/ExportDialog/UserManagement/Create=Create user...",
					--enabled = bind 'createUserButtonEnabled',
					action = function()
						require 'LrGalleryUser'
						LrGalleryUser.createUser( propertyTable )
					end,
				},
				
				--[[f:push_button {
					width = tonumber( LOC "$$$/locale_metric/LrGallery/ExportDialog/LoginButton/Width=90" ),
					title = LOC "$$$/locale_metric/LrGallery/ExportDialog/UserManagement/Delete=Delete user...",
					--enabled = bind 'deleteUserButtonEnabled',
					action = function()
						require 'LrGalleryUser'
						LrGalleryUser.deleteUser(propertyTable)
					end,
				}]]--,

			},
		},				
	}

end

--- (optional) This plug-in defined callback function is called when the user 
 -- chooses this export service provider in the Export or Publish dialog. 
 -- It can create new sections that appear below all of the built-in sections in the dialog.
 -- <p>Your plug-in's <a href="#exportServiceProvider.startDialog"><code>startDialog</code></a>
 -- function, if any, is called before this function is called.</p>
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
	-- @param f (<a href="LrView.html#LrView.osFactory"><code>LrView.osFactory</code> object)
		-- A view factory object
	-- @param propertyTable (table) An observable table that contains the most
		-- recent settings for your export or publish plug-in, including both
		-- settings that you have defined and Lightroom-defined export settings
	-- @return (table) An array of dialog sections (see example code for details)
function exportServiceProvider.sectionsForBottomOfDialog( f, propertyTable )

	return {
			
	}

end

--- (optional) This plug-in defined callback function is called for each exported photo
 -- after it is rendered by Lightroom and after all post-process actions have been
 -- applied to it. This function is responsible for transferring the image file 
 -- to its destination, as defined by your plug-in. The function that
 -- you define is launched within a cooperative task that Lightroom provides. You
 -- do not need to start your own task to run this function; and in general, you
 -- should not need to start another task from within your processing function.
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
	-- @param functionContext (<a href="LrFunctionContext.html"><code>LrFunctionContext</code></a>)
		-- function context that you can use to attach clean-up behaviors to this
		-- process; this function context terminates as soon as your function exits.
	-- @param exportContext (<a href="LrExportContext.html"><code>LrExportContext</code></a>)
		-- Information about your export settings and the photos to be published.
function exportServiceProvider.processRenderedPhotos(functionContext, exportContext)
			
	-- Get export session
	local exportSession = exportContext.exportSession
		
	-- Get number of photos.	
	local nPhotos = exportSession:countRenditions()
	
	-- Set progress title.	
	local progressScope = exportContext:configureProgress {
		title = nPhotos > 1
			and LOC("$$$/LrGallery/Publish/Progress=Publishing ^1 photos to LrGallery", nPhotos)
			or LOC "$$$/LrGallery/Publish/Progress/One=Publishing one photo to LrGallery",
	}

	-- Iterate through photo renditions
	local alreadyPublishedNow = {}
	for i, rendition in exportContext:renditions{stopIfCanceled = true} do
		
		-- Update progress indicator
		progressScope:setPortionComplete((i - 1) / nPhotos)
		
		local success, renderedFile = rendition:waitForRender()
		
		-- Check if we already published the photo in this session
		if (alreadyPublishedNow[rendition]) then
			rendition:skipRender()
		end
		
		-- Check if the photo was already published earlier
		local lrgalleryPhotoId = rendition.publishedPhotoId
		
		-- If it was published, delete it first
		if lrgalleryPhotoId then
			params = {}
			params.params = {
				photoid = lrgalleryPhotoId
			}
			method = 'deletePhoto'
			local data = LrGalleryAPI.callMethod(propertyTable, params, method)
			local photoDeleted = data.result
		end
		
		-- Upload photo
		params = {}
		params.params = {
			username = exportContext.publishedCollectionInfo.name,			
			filename = rendition.photo:getFormattedMetadata('fileName'),
			photoname = rendition.photo:getFormattedMetadata('fileName'),
			--photoFile = rendition.photo:getRawMetadata('path'),
			photoFile = renderedFile,
		}		
		method = 'uploadPhoto'
		local data = LrGalleryAPI.callMethod(propertyTable, params, method)
		
		-- Save uploaded photo ID
		lrgalleryPhotoId = data.photo_id
		rendition:recordPublishedPhotoId(lrgalleryPhotoId)
		
		-- Add this rendition to published now list
		alreadyPublishedNow[rendition] = true
	end
	
	-- End process
	progressScope:done()
end

return exportServiceProvider
