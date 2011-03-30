-- Lightroom SDK
local LrBinding = import 'LrBinding'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrView = import 'LrView'

-- Common shortcuts
local bind = LrView.bind
local share = LrView.share

-- LrGallery plug-in
require 'LrGalleryAPI'
require 'LrGalleryPublishSupport'


local exportServiceProvider = {}

for name, value in pairs( LrGalleryPublishSupport ) do
	exportServiceProvider[ name ] = value
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

local function updateCantExportBecause( propertyTable )

	if not propertyTable.validAccount then
		propertyTable.LR_cantExportBecause = LOC "$$$/LrGallery/ExportDialog/NoLogin=You haven't logged in to LrGallery yet."
		return
	end
	
	propertyTable.LR_cantExportBecause = nil

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

local function booleanToNumber( value )

	return value and 1 or 0

end

local privacyToNumber = {
	private = 0,
	public = 1,
}

local safetyToNumber = {
	safe = 1,
	moderate = 2,
	restricted = 3,
}

local contentTypeToNumber = {
	photo = 1,
	screenshot = 2,
	other = 3,
}

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

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the 
 -- user chooses this export service provider in the Export or Publish dialog, 
 -- or when the destination is already selected when the dialog is invoked, 
 -- (remembered from the previous export operation).
 -- <p>This is a blocking call. If you need to start a long-running task (such as
 -- network access), create a task using the <a href="LrTasks.html"><code>LrTasks</code></a>
 -- namespace.</p>
 -- <p>First supported in version 1.3 of the Lightroom SDK.</p>
	-- @param propertyTable (table) An observable table that contains the most
		-- recent settings for your export or publish plug-in, including both
		-- settings that you have defined and Lightroom-defined export settings
	-- @name exportServiceProvider.startDialog
	-- @class function

function exportServiceProvider.startDialog( propertyTable )

	-- Clear login if it's a new connection.
	
	if not propertyTable.LR_editingExistingPublishConnection then
		propertyTable.username = nil
		propertyTable.nsid = nil
		propertyTable.auth_token = nil
	end

	-- Can't export until we've validated the login.

	propertyTable:addObserver( 'validAccount', function() updateCantExportBecause( propertyTable ) end )
	updateCantExportBecause( propertyTable )

	-- Make sure we're logged in.

	require 'LrGalleryUser'
	LrGalleryUser.verifyLogin( propertyTable )

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
					LrGalleryUser.login( propertyTable )
					end,
				},

			},
		},
	
		{
			title = LOC "$$$/LrGallery/ExportDialog/Title=LrGallery Title",
			
			synopsis = function( props )
				if props.titleFirstChoice == 'title' then
					return LOC( "$$$/LrGallery/ExportDialog/Synopsis/TitleWithFallback=IPTC Title or ^1", displayNameForTitleChoice[ props.titleSecondChoice ] )
				else
					return props.titleFirstChoice and displayNameForTitleChoice[ props.titleFirstChoice ] or ''
				end
			end,
			
			f:column {
				spacing = f:control_spacing(),

				f:row {
					spacing = f:label_spacing(),
	
					f:static_text {
						title = LOC "$$$/LrGallery/ExportDialog/ChooseTitleBy=Set LrGallery Title Using:",
						alignment = 'right',
						width = share 'lrgalleryTitleSectionLabel',
					},
					
					f:popup_menu {
						value = bind 'titleFirstChoice',
						width = share 'lrgalleryTitleLeftPopup',
						items = {
							{ value = 'filename', title = displayNameForTitleChoice.filename },
							{ value = 'title', title = displayNameForTitleChoice.title },
							{ value = 'empty', title = displayNameForTitleChoice.empty },
						},
					},

					f:spacer { width = 20 },
	
					f:static_text {
						title = LOC "$$$/LrGallery/ExportDialog/ChooseTitleBySecondChoice=If Empty, Use:",
						enabled = LrBinding.keyEquals( 'titleFirstChoice', 'title', propertyTable ),
					},
					
					f:popup_menu {
						value = bind 'titleSecondChoice',
						enabled = LrBinding.keyEquals( 'titleFirstChoice', 'title', propertyTable ),
						items = {
							{ value = 'filename', title = displayNameForTitleChoice.filename },
							{ value = 'empty', title = displayNameForTitleChoice.empty },
						},
					},
				},
				
				f:row {
					spacing = f:label_spacing(),
					
					f:static_text {
						title = LOC "$$$/LrGallery/ExportDialog/OnUpdate=When Updating Photos:",
						alignment = 'right',
						width = share 'lrgalleryTitleSectionLabel',
					},
					
					f:popup_menu {
						value = bind 'titleRepublishBehavior',
						width = share 'lrgalleryTitleLeftPopup',
						items = {
							{ value = 'replace', title = LOC "$$$/LrGallery/ExportDialog/ReplaceExistingTitle=Replace Existing Title" },
							{ value = 'leaveAsIs', title = LOC "$$$/LrGallery/ExportDialog/LeaveAsIs=Leave Existing Title" },
						},
					},
				},
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
	
		{
			title = LOC "$$$/LrGallery/ExportDialog/PrivacyAndSafety=Privacy and Safety",
			synopsis = function( props )
				
				local summary = {}
				
				local function add( x )
					if x then
						summary[ #summary + 1 ] = x
					end
				end
				
				if props.privacy == 'private' then
					add( LOC "$$$/LrGallery/ExportDialog/Private=Private" )
					if props.privacy_family then
						add( LOC "$$$/LrGallery/ExportDialog/Family=Family" )
					end
					if props.privacy_friends then
						add( LOC "$$$/LrGallery/ExportDialog/Friends=Friends" )
					end
				else
					add( LOC "$$$/LrGallery/ExportDialog/Public=Public" )
				end
				
				local safetyStr = kSafetyTitles[ props.safety ]
				if safetyStr then
					add( safetyStr )
				end
				
				return table.concat( summary, " / " )
				
			end,
			
			place = 'horizontal',

			f:column {
				spacing = f:control_spacing() / 2,
				fill_horizontal = 1,

				f:row {
					f:static_text {
						title = LOC "$$$/LrGallery/ExportDialog/Privacy=Privacy:",
						alignment = 'right',
						width = share 'labelWidth',
					},
	
					f:radio_button {
						title = LOC "$$$/LrGallery/ExportDialog/Private=Private",
						checked_value = 'private',
						value = bind 'privacy',
					},
				},

				f:row {
					f:spacer {
						width = share 'labelWidth',
					},
	
					f:column {
						spacing = f:control_spacing() / 2,
						margin_left = 15,
						margin_bottom = f:control_spacing() / 2,
		
						f:checkbox {
							title = LOC "$$$/LrGallery/ExportDialog/Family=Family",
							value = bind 'privacy_family',
							enabled = LrBinding.keyEquals( 'privacy', 'private' ),
						},
		
						f:checkbox {
							title = LOC "$$$/LrGallery/ExportDialog/Friends=Friends",
							value = bind 'privacy_friends',
							enabled = LrBinding.keyEquals( 'privacy', 'private' ),
						},
					},
				},

				f:row {
					f:spacer {
						width = share 'labelWidth',
					},
	
					f:radio_button {
						title = LOC "$$$/LrGallery/ExportDialog/Public=Public",
						checked_value = 'public',
						value = bind 'privacy',
					},
				},
			},

			f:column {
				spacing = f:control_spacing() / 2,

				fill_horizontal = 1,

				f:row {
					f:static_text {
						title = LOC "$$$/LrGallery/ExportDialog/Safety=Safety:",
						alignment = 'right',
						width = share 'lrgallery_col2_label_width',
					},
	
					f:popup_menu {
						value = bind 'safety',
						width = share 'lrgallery_col2_popup_width',
						items = {
							{ title = kSafetyTitles.safe, value = 'safe' },
							{ title = kSafetyTitles.moderate, value = 'moderate' },
							{ title = kSafetyTitles.restricted, value = 'restricted' },
						},
					},
				},

				f:row {
					margin_bottom = f:control_spacing() / 2,
					
					f:spacer {
						width = share 'lrgallery_col2_label_width',
					},
	
					f:checkbox {
						title = LOC "$$$/LrGallery/ExportDialog/HideFromPublicSite=Hide from public site areas",
						value = bind 'hideFromPublic',
					},
				},

				f:row {
					f:static_text {
						title = LOC "$$$/LrGallery/ExportDialog/Type=Type:",
						alignment = 'right',
						width = share 'lrgallery_col2_label_width',
					},
	
					f:popup_menu {
						width = share 'lrgallery_col2_popup_width',
						value = bind 'type',
						items = {
							{ title = LOC "$$$/LrGallery/ExportDialog/Type/Photo=Photo", value = 'photo' },
							{ title = LOC "$$$/LrGallery/ExportDialog/Type/Screenshot=Screenshot", value = 'screenshot' },
							{ title = LOC "$$$/LrGallery/ExportDialog/Type/Other=Other", value = 'other' },
						},
					},
				},
			},
		},
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
function exportServiceProvider.processRenderedPhotos( functionContext, exportContext )
	
	local exportSession = exportContext.exportSession

	-- Make a local reference to the export parameters.
	
	local exportSettings = assert( exportContext.propertyTable )
		
	-- Get the # of photos.
	
	local nPhotos = exportSession:countRenditions()
	
	-- Set progress title.
	
	local progressScope = exportContext:configureProgress {
						title = nPhotos > 1
									and LOC( "$$$/LrGallery/Publish/Progress=Publishing ^1 photos to LrGallery", nPhotos )
									or LOC "$$$/LrGallery/Publish/Progress/One=Publishing one photo to LrGallery",
					}

	-- Save off uploaded photo IDs so we can take user to those photos later.
	
	local uploadedPhotoIds = {}
	
	local publishedCollectionInfo = exportContext.publishedCollectionInfo

	local isDefaultCollection = publishedCollectionInfo.isDefaultCollection

	-- Look for a photoset id for this collection.

	local photosetId = publishedCollectionInfo.remoteId

	-- Get a list of photos already in this photoset so we know which ones we can replace and which have
	-- to be re-uploaded entirely.

	local photosetPhotoIds = photosetId and LrGalleryAPI.listPhotosFromPhotoset( exportSettings, { photosetId = photosetId } )
	
	local photosetPhotosSet = {}
	
	-- Turn it into a set for quicker access later.

	if photosetPhotoIds then
		for _, id in ipairs( photosetPhotoIds ) do	
			photosetPhotosSet[ id ] = true
		end
	end
	
	local couldNotPublishBecauseFreeAccount = {}
	local lrgalleryPhotoIdsForRenditions = {}
	
	local cannotRepublishCount = 0
	
	-- Gather lrgallery photo IDs, and if we're on a free account, remember the renditions that
	-- had been previously published.

	for i, rendition in exportContext.exportSession:renditions() do
	
		local lrgalleryPhotoId = rendition.publishedPhotoId
			
		if lrgalleryPhotoId then
		
			-- Check to see if the photo is still on LrGallery.

			if not photosetPhotosSet[ lrgalleryPhotoId ] and not isDefaultCollection then
				lrgalleryPhotoId = nil
			end
			
		end
		
		if lrgalleryPhotoId and not exportSettings.isUserPro then
			couldNotPublishBecauseFreeAccount[ rendition ] = true
			cannotRepublishCount = cannotRepublishCount + 1
		end
			
		lrgalleryPhotoIdsForRenditions[ rendition ] = lrgalleryPhotoId
	
	end
	
	-- If we're on a free account, see which photos are being republished and give a warning.
	
	if cannotRepublishCount	> 0 then

		local message = ( cannotRepublishCount == 1 ) and 
							LOC( "$$$/LrGallery/FreeAccountErr/Singular/ThereIsAPhotoToUpdateOnLrGallery=There is one photo to update on LrGallery" )
							or LOC( "$$$/LrGallery/FreeAccountErr/Plural/ThereIsAPhotoToUpdateOnLrGallery=There are ^1 photos to update on LrGallery", cannotRepublishCount )

		local messageInfo = LOC( "$$$/LrGallery/FreeAccountErr/Singular/CommentsAndRatingsWillBeLostWarning=With a free (non-Pro) LrGallery account, all comments and ratings will be lost on updated photos. Are you sure you want to do this?" )
		
		local action = LrDialogs.promptForActionWithDoNotShow { 
									message = message,
									info = messageInfo, 
									actionPrefKey = "nonProRepublishWarning", 
									verbBtns = { 
										{ label = LOC( "$$$/LrGallery/Dialog/Buttons/FreeAccountErr/Skip=Skip" ), verb = "skip", },
										{ label = LOC( "$$$/LrGallery/Dialog/Buttons/FreeAccountErr/Replace=Replace" ), verb = "replace", },
									}
                                } 

		if action == "skip" then
			
			local skipRendition = next( couldNotPublishBecauseFreeAccount )
			
			while skipRendition ~= nil do
				skipRendition:skipRender()
				skipRendition = next( couldNotPublishBecauseFreeAccount, skipRendition )
			end
			
		elseif action == "replace" then

			-- We will publish as usual, replacing these photos.

			couldNotPublishBecauseFreeAccount = {}

		else

			-- User canceled

			progressScope:done()
			return

		end

	end
	
	-- Iterate through photo renditions.
	
	local photosetUrl

	for i, rendition in exportContext:renditions { stopIfCanceled = true } do
	
		-- Update progress scope.
		
		progressScope:setPortionComplete( ( i - 1 ) / nPhotos )
		
		-- Get next photo.

		local photo = rendition.photo

		-- See if we previously uploaded this photo.

		local lrgalleryPhotoId = lrgalleryPhotoIdsForRenditions[ rendition ]
		
		if not rendition.wasSkipped then

			local success, pathOrMessage = rendition:waitForRender()
			
			-- Update progress scope again once we've got rendered photo.
			
			progressScope:setPortionComplete( ( i - 0.5 ) / nPhotos )
			
			-- Check for cancellation again after photo has been rendered.
			
			if progressScope:isCanceled() then break end
			
			if success then
	
				-- Build up common metadata for this photo.
				
				local title = getLrGalleryTitle( photo, exportSettings, pathOrMessage )
		
				local description = photo:getFormattedMetadata( 'caption' )
				local keywordTags = photo:getFormattedMetadata( 'keywordTagsForExport' )
				
				local tags
				
				if keywordTags then

					tags = {}

					local keywordIter = string.gfind( keywordTags, "[^,]+" )

					for keyword in keywordIter do
					
						if string.sub( keyword, 1, 1 ) == ' ' then
							keyword = string.sub( keyword, 2, -1 )
						end
						
						if string.find( keyword, ' ' ) ~= nil then
							keyword = '"' .. keyword .. '"'
						end
						
						tags[ #tags + 1 ] = keyword

					end

				end
				
				-- LrGallery will pick up LR keywords from XMP, so we don't need to merge them here.
				
				local is_public = privacyToNumber[ exportSettings.privacy ]
				local is_friend = booleanToNumber( exportSettings.privacy_friends )
				local is_family = booleanToNumber( exportSettings.privacy_family )
				local safety_level = safetyToNumber[ exportSettings.safety ]
				local content_type = contentTypeToNumber[ exportSettings.type ]
				local hidden = exportSettings.hideFromPublic and 2 or 1
				
				-- Because it is common for LrGallery users (even viewers) to add additional tags via
				-- the LrGallery web site, so we should not remove extra keywords that do not correspond
				-- to keywords in Lightroom. In order to do so, we record the tags that we uploaded
				-- this time. Next time, we will compare the previous tags with these current tags.
				-- We use the difference between tag sets to determine if we should remove a tag (i.e.
				-- it was one we uploaded and is no longer present in Lightroom) or not (i.e. it was
				-- added by user on LrGallery and never was present in Lightroom).
				
				local previous_tags = photo:getPropertyForPlugin( _PLUGIN, 'previous_tags' ) 
	
				-- If on a free account and this photo already exists, delete it from LrGallery.

				if lrgalleryPhotoId and not exportSettings.isUserPro then

					LrGalleryAPI.deletePhoto( exportSettings, { photoId = lrgalleryPhotoId, suppressError = true } )
					lrgalleryPhotoId = nil

				end
				
				-- Upload or replace the photo.
				
				local didReplace = not not lrgalleryPhotoId
				
				lrgalleryPhotoId = LrGalleryAPI.uploadPhoto( exportSettings, {
										photo_id = lrgalleryPhotoId,
										filePath = pathOrMessage,
										title = title or '',
										description = description,
										tags = table.concat( tags, ',' ),
										is_public = is_public,
										is_friend = is_friend,
										is_family = is_family,
										safety_level = safety_level,
										content_type = content_type,
										hidden = hidden,
									} )
				
				if didReplace then
				
					-- The replace call used by LrGalleryAPI.uploadPhoto ignores all of the metadata that is passed
					-- in above. We have to manually upload that info after the fact in this case.
					
					if exportSettings.titleRepublishBehavior == 'replace' then
						
						LrGalleryAPI.callXmlMethod( exportSettings, {
												method = 'lrgallery.photos.setMeta',
												photo_id = lrgalleryPhotoId,
												title = title or '',
												description = description or '',
											} )
											
					end
	
					LrGalleryAPI.callXmlMethod( exportSettings, {
											method = 'lrgallery.photos.setPerms',
											photo_id = lrgalleryPhotoId,
											is_public = is_public,
											is_friend = is_friend,
											is_family = is_family,
											perm_comment = 3, -- everybody
											perm_addmeta = 3, -- everybody
										} )
	
					LrGalleryAPI.callXmlMethod( exportSettings, {
											method = 'lrgallery.photos.setSafetyLevel',
											photo_id = lrgalleryPhotoId,
											safety_level = safety_level,
											hidden = hidden,
										} )
	
					LrGalleryAPI.callXmlMethod( exportSettings, {
											method = 'lrgallery.photos.setContentType',
											photo_id = lrgalleryPhotoId,
											content_type = content_type,
										} )
		
				end
	
				LrGalleryAPI.setImageTags( exportSettings, {
											photo_id = lrgalleryPhotoId,
											tags = table.concat( tags, ',' ),
											previous_tags = previous_tags,
											is_public = is_public,
										} )
				
				-- When done with photo, delete temp file. There is a cleanup step that happens later,
				-- but this will help manage space in the event of a large upload.
					
				LrFileUtils.delete( pathOrMessage )
	
				-- Remember this in the list of photos we uploaded.
	
				uploadedPhotoIds[ #uploadedPhotoIds + 1 ] = lrgalleryPhotoId
				
				-- If this isn't the Photostream, set up the photoset.
				
				if not photosetUrl then
	
					if not isDefaultCollection then
	
						-- Create or update this photoset.
	
						photosetId, photosetUrl = LrGalleryAPI.createOrUpdatePhotoset( exportSettings, {
													photosetId = photosetId,
													title = publishedCollectionInfo.name,
													--		description = ??,
													primary_photo_id = uploadedPhotoIds[ 1 ],
												} )
				
					else
	
						-- Photostream: find the URL.
	
						photosetUrl = LrGalleryAPI.constructPhotostreamURL( exportSettings )
	
					end
					
				end
				
				-- Record this LrGallery ID with the photo so we know to replace instead of upload.
					
				rendition:recordPublishedPhotoId( lrgalleryPhotoId )
				
				local photoUrl
							
				if ( not isDefaultCollection ) then
					
					photoUrl = LrGalleryAPI.constructPhotoURL( exportSettings, {	
											photo_id = lrgalleryPhotoId,
											photosetId = photosetId,
											is_public = is_public,
										} )	
										
					-- Add the uploaded photos to the correct photoset.

					LrGalleryAPI.addPhotosToSet( exportSettings, {
									photoId = lrgalleryPhotoId,
									photosetId = photosetId,
								} )
					
				else
					
					photoUrl = LrGalleryAPI.constructPhotoURL( exportSettings, {
											photo_id = lrgalleryPhotoId,
											is_public = is_public,
										} )
										
				end
					
				rendition:recordPublishedPhotoUrl( photoUrl )
						
				-- Because it is common for LrGallery users (even viewers) to add additional tags
				-- via the LrGallery web site, so we can avoid removing those user-added tags that
				-- were never in Lightroom to begin with. See earlier comment.
				
				photo.catalog:withPrivateWriteAccessDo( function()
										photo:setPropertyForPlugin( _PLUGIN, 'previous_tags', table.concat( tags, ',' ) ) 
									end )
			
			end
			
		end

	end
	
	if #uploadedPhotoIds > 0 then
	
		if ( not isDefaultCollection ) then
			
			exportSession:recordRemoteCollectionId( photosetId )
					
		end
	
		-- Set up some additional metadata for this collection.

		exportSession:recordRemoteCollectionUrl( photosetUrl )
		
	end

	progressScope:done()
	
end

return exportServiceProvider
