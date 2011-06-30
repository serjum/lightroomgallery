-- Lightroom SDK
local LrDialogs = import 'LrDialogs'
local LrMD5 = import 'LrMD5'

-- LrGallery plug-in
require 'LrGalleryAPI'

-- Plugin prefs
local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN)

local publishServiceProvider = {}

publishServiceProvider.small_icon = 'small_lrgallery.png'
publishServiceProvider.publish_fallbackNameBinding = 'fullname'


publishServiceProvider.titleForPublishedCollection = LOC "$$$/LrGallery/TitleForPublishedCollection=Photoset"
publishServiceProvider.titleForPublishedCollection_standalone = LOC "$$$/LrGallery/TitleForPublishedCollection/Standalone=Photoset"
publishServiceProvider.titleForPublishedSmartCollection = LOC "$$$/LrGallery/TitleForPublishedSmartCollection=Smart Photoset"
publishServiceProvider.titleForPublishedSmartCollection_standalone = LOC "$$$/LrGallery/TitleForPublishedSmartCollection/Standalone=Smart Photoset"

--------------------------------------------------------------------------------
--- (optional) If you provide this plug-in defined callback function, Lightroom calls it to
 -- retrieve the default collection behavior for this publish service, then use that information to create
 -- a built-in <i>default collection</i> for this service (if one does not yet exist). 
 -- This special collection is marked in italics and always listed at the top of the list of published collections.
 -- <p>This callback should return a table that configures the default collection. The
 -- elements of the configuration table are optional, and default as shown.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @return (table) A table with the following fields:
	  -- <ul>
	   -- <li><b>defaultCollectionName</b>: (string) The name for the default
	   -- 	collection. If not specified, the name is "untitled" (or
	   --   a language-appropriate equivalent). </li>
	   -- <li><b>defaultCollectionCanBeDeleted</b>: (Boolean) True to allow the 
	   -- 	user to delete the default collection. Default is true. </li>
	   -- <li><b>canAddCollection</b>: (Boolean)  True to allow the 
	   -- 	user to add collections through the UI. Default is true. </li>
	   -- <li><b>maxCollectionSetDepth</b>: (number) A maximum depth to which 
	   --  collection sets can be nested, or zero to disallow collection sets. 
 	   --  If not specified, unlimited nesting is allowed. </li>
	  -- </ul>
	-- @name publishServiceProvider.getCollectionBehaviorInfo
	-- @class function

function publishServiceProvider.getCollectionBehaviorInfo( publishSettings )

	local loggedUsername = prefs.username
	if not loggedUsername then
		loggedUsername = "lr"
	end
	return {		
		defaultCollectionName = LOC "$$$/LrGallery/DefaultCollectionName/Photostream=" .. loggedUsername,
		defaultCollectionCanBeDeleted = false,
		canAddCollection = true,
		maxCollectionSetDepth = 0,
	}
	
end

--------------------------------------------------------------------------------
--- When set to the string "disable", the "Go to Published Collection" context-menu item
 -- is disabled (dimmed) for this publish service.
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
publishServiceProvider.titleForGoToPublishedCollection = LOC "$$$/LrGallery/TitleForGoToPublishedCollection=Show in LrGallery"

-- On Delete photo
function publishServiceProvider.deletePhotosFromPublishedCollection( publishSettings, arrayOfPhotoIds, deletedCallback )

	for i, photoId in ipairs( arrayOfPhotoIds ) do

		-- Get photo info
		params = {}	
		params.params = {
			photoid = photoId,
		}
		method = 'deletePhoto'
		local data = LrGalleryAPI.callMethod(propertyTable, params, method)
		
		if (data.result) then
			deletedCallback(photoId)
		else
			LrDialogs.message("Error while deleting photo from LrGallery")
		end
	end
	
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called whenever a new
 -- publish service is created and whenever the settings for a publish service
 -- are changed. It allows the plug-in to specify which metadata should be
 -- considered when Lightroom determines whether an existing photo should be
 -- moved to the "Modified Photos to Re-Publish" status.
 -- <p>This is a blocking call.</p>
	-- @name publishServiceProvider.metadataThatTriggersRepublish
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @return (table) A table containing one or more of the following elements
		-- as key, Boolean true or false as a value, where true means that a change
		-- to the value does trigger republish status, and false means changes to the
		-- value are ignored:
		-- <ul>
		  -- <li><b>default</b>: All built-in metadata that appears in XMP for the file.
		  -- You can override this default behavior by explicitly naming any of these
		  -- specific fields:
		    -- <ul>
			-- <li><b>rating</b></li>
			-- <li><b>label</b></li>
			-- <li><b>title</b></li>
			-- <li><b>caption</b></li>
			-- <li><b>gps</b></li>
			-- <li><b>gpsAltitude</b></li>
			-- <li><b>creator</b></li>
			-- <li><b>creatorJobTitle</b></li>
			-- <li><b>creatorAddress</b></li>
			-- <li><b>creatorCity</b></li>
			-- <li><b>creatorStateProvince</b></li>
			-- <li><b>creatorPostalCode</b></li>
			-- <li><b>creatorCountry</b></li>
			-- <li><b>creatorPhone</b></li>
			-- <li><b>creatorEmail</b></li>
			-- <li><b>creatorUrl</b></li>
			-- <li><b>headline</b></li>
			-- <li><b>iptcSubjectCode</b></li>
			-- <li><b>descriptionWriter</b></li>
			-- <li><b>iptcCategory</b></li>
			-- <li><b>iptcOtherCategories</b></li>
			-- <li><b>dateCreated</b></li>
			-- <li><b>intellectualGenre</b></li>
			-- <li><b>scene</b></li>
			-- <li><b>location</b></li>
			-- <li><b>city</b></li>
			-- <li><b>stateProvince</b></li>
			-- <li><b>country</b></li>
			-- <li><b>isoCountryCode</b></li>
			-- <li><b>jobIdentifier</b></li>
			-- <li><b>instructions</b></li>
			-- <li><b>provider</b></li>
			-- <li><b>source</b></li>
			-- <li><b>copyright</b></li>
			-- <li><b>rightsUsageTerms</b></li>
			-- <li><b>copyrightInfoUrl</b></li>
			-- <li><b>copyrightStatus</b></li>
			-- <li><b>keywords</b></li>
		    -- </ul>
		  -- <li><b>customMetadata</b>: All plug-in defined custom metadata (defined by any plug-in).</li>
		  -- <li><b><i>(plug-in ID)</i>.*</b>: All custom metadata defined by the plug-in with the specified ID.</li>
		  -- <li><b><i>(plug-in ID).(field ID)</i></b>: One specific custom metadata field defined by the plug-in with the specified ID.</li>
		-- </ul>

function publishServiceProvider.metadataThatTriggersRepublish( publishSettings )

	return {

		default = false,
		title = true,
		keywords = true,
		dateCreated = true,

		-- also (not used by LrGallery sample plug-in):
			-- customMetadata = true,
			-- com.whoever.plugin_name.* = true,
			-- com.whoever.plugin_name.field_name = true,

	}

end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when new or updated
 -- photos are about to be published to the service. It allows you to specify whether
 -- the user-specified sort order should be followed as-is or reversed. The LrGallery
 -- sample plug-in uses this to reverse the order on the Photostream so that photos
 -- appear in the LrGallery web interface in the same sequence as they are shown in the 
 -- library grid.
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
	-- @param collectionInfo
	-- @name publishServiceProvider.shouldReverseSequenceForPublishedCollection
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param publishedCollectionInfo (<a href="LrPublishedCollectionInfo.html"><code>LrPublishedCollectionInfo</code></a>) an object containing publication information for this published collection.
	-- @return (boolean) true to reverse the sequence when publishing new photos

function publishServiceProvider.shouldReverseSequenceForPublishedCollection( publishSettings, collectionInfo )

	return collectionInfo.isDefaultCollection

end

-------------------------------------------------------------------------------
--- This plug-in callback function is called when the user has renamed a
 -- published collection via the Publish Services panel user interface. This is
 -- your plug-in's opportunity to make the corresponding change on the service.
 -- <p>If your plug-in is unable to update the remote service for any reason,
 -- you should throw a Lua error from this function; this causes Lightroom to revert the change.</p>
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @name publishServiceProvider.renamePublishedCollection
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param info (table) A table with these fields:
	 -- <ul>
	  -- <li><b>isDefaultCollection</b>: (Boolean) True if this is the default collection.</li>
	  -- <li><b>name</b>: (string) The new name being assigned to this collection.</li>
		-- <li><b>parents</b>: (table) An array of information about parents of this collection, in which each element contains:
			-- <ul>
				-- <li><b>localCollectionId</b>: (number) The local collection ID.</li>
				-- <li><b>name</b>: (string) Name of the collection set.</li>
				-- <li><b>remoteCollectionId</b>: (number or string) The remote collection ID assigned by the server.</li>
			-- </ul> </li>
 	  -- <li><b>publishService</b>: (<a href="LrPublishService.html"><code>LrPublishService</code></a>)
	  -- 	The publish service object.</li>
	  -- <li><b>publishedCollection</b>: (<a href="LrPublishedCollection.html"><code>LrPublishedCollection</code></a>
		-- or <a href="LrPublishedCollectionSet.html"><code>LrPublishedCollectionSet</code></a>)
	  -- 	The published collection object being renamed.</li>
	  -- <li><b>remoteId</b>: (string or number) The ID for this published collection
	  -- 	that was stored via <a href="LrExportSession.html#exportSession:recordRemoteCollectionId"><code>exportSession:recordRemoteCollectionId</code></a></li>
	  -- <li><b>remoteUrl</b>: (optional, string) The URL, if any, that was recorded for the published collection via
	  -- <a href="LrExportSession.html#exportSession:recordRemoteCollectionUrl"><code>exportSession:recordRemoteCollectionUrl</code></a>.</li>
	 -- </ul>

function publishServiceProvider.renamePublishedCollection( publishSettings, info )

	if info.remoteId then

		LrGalleryAPI.createOrUpdatePhotoset( publishSettings, {
							photosetId = info.remoteId,
							title = info.name,
						} )

	end
		
end

-------------------------------------------------------------------------------
--- This plug-in callback function is called when the user has deleted a
 -- published collection via the Publish Services panel user interface. This is
 -- your plug-in's opportunity to make the corresponding change on the service.
 -- <p>If your plug-in is unable to update the remote service for any reason,
 -- you should throw a Lua error from this function; this causes Lightroom to revert the change.</p>
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @name publishServiceProvider.deletePublishedCollection
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param info (table) A table with these fields:
	 -- <ul>
	  -- <li><b>isDefaultCollection</b>: (Boolean) True if this is the default collection.</li>
	  -- <li><b>name</b>: (string) The new name being assigned to this collection.</li>
		-- <li><b>parents</b>: (table) An array of information about parents of this collection, in which each element contains:
			-- <ul>
				-- <li><b>localCollectionId</b>: (number) The local collection ID.</li>
				-- <li><b>name</b>: (string) Name of the collection set.</li>
				-- <li><b>remoteCollectionId</b>: (number or string) The remote collection ID assigned by the server.</li>
			-- </ul> </li>
 	  -- <li><b>publishService</b>: (<a href="LrPublishService.html"><code>LrPublishService</code></a>)
	  -- 	The publish service object.</li>
	  -- <li><b>publishedCollection</b>: (<a href="LrPublishedCollection.html"><code>LrPublishedCollection</code></a>
		-- or <a href="LrPublishedCollectionSet.html"><code>LrPublishedCollectionSet</code></a>)
	  -- 	The published collection object being renamed.</li>
	  -- <li><b>remoteId</b>: (string or number) The ID for this published collection
	  -- 	that was stored via <a href="LrExportSession.html#exportSession:recordRemoteCollectionId"><code>exportSession:recordRemoteCollectionId</code></a></li>
	  -- <li><b>remoteUrl</b>: (optional, string) The URL, if any, that was recorded for the published collection via
	  -- <a href="LrExportSession.html#exportSession:recordRemoteCollectionUrl"><code>exportSession:recordRemoteCollectionUrl</code></a>.</li>
	 -- </ul>

function publishServiceProvider.deletePublishedCollection( publishSettings, info )

	import 'LrFunctionContext'.callWithContext( 'publishServiceProvider.deletePublishedCollection', function( context )
	
		local progressScope = LrDialogs.showModalProgressDialog {
							title = LOC( "$$$/LrGallery/DeletingCollectionAndContents=Deleting photoset ^[^1^]", info.name ),
							functionContext = context }
	
		if info and info.photoIds then
		
			for i, photoId in ipairs( info.photoIds ) do
			
				if progressScope:isCanceled() then break end
			
				progressScope:setPortionComplete( i - 1, #info.photoIds )
				LrGalleryAPI.deletePhoto( publishSettings, { photoId = photoId } )
			
			end
		
		end
	
		if info and info.remoteId then
	
			LrGalleryAPI.deletePhotoset( publishSettings, {
								photosetId = info.remoteId,
								suppressError = true,
									-- LrGallery has probably already deleted the photoset
									-- when the last photo was deleted.
							} )
	
		end
			
	end )

end

-- On Get Comments
function publishServiceProvider.getCommentsFromPublishedCollection(publishSettings, arrayOfPhotoInfo, commentCallback)

	for i, photoInfo in ipairs( arrayOfPhotoInfo ) do
		
		-- Get photo info
		params = {}	
		params.params = {
			photoid = photoInfo.remoteId,
		}		
		method = 'getPhotoInfo'
		local data = LrGalleryAPI.callMethod(propertyTable, params, method)
		
		-- Update comments
		if (data.comments) then
			local comments = {}

			table.insert(comments, {
				commentId = LrMD5.digest(data.comments),
				commentText = data.comments,
				dateCreated = nil,
				username = nil,
				realname = nil,
				url = nil
			})
			commentCallback{publishedPhoto = photoInfo, comments = comments}
			
			-- Store the last comment for this photo in prefs
			if not prefs.lastComments then
				prefs.lastComments = {}
			end
			prefs.lastComments[photoInfo.remoteId] = data.comments
			
		end
	end

end

publishServiceProvider.titleForPhotoRating = LOC "$$$/LrGallery/TitleForPhotoRating=Rating"

-- On Get Rating
function publishServiceProvider.getRatingsFromPublishedCollection(publishSettings, arrayOfPhotoInfo, ratingCallback)

	for i, photoInfo in ipairs(arrayOfPhotoInfo) do
	
		-- Get photo info
		params = {}	
		params.params = {
			photoid = photoInfo.remoteId,
		}		
		method = 'getPhotoInfo'
		local data = LrGalleryAPI.callMethod(propertyTable, params, method)
		
		local rating = data.rating
		if type(rating) == 'string' then 
			rating = tonumber(rating) 
		end
		local flag = data.accepted
		local color = ''
		if (flag == 'yes') then
			color = 'green'
		elseif (flag == 'no') then
			color = 'red'
		elseif (flag  == 'none') then
			color = 'yellow'
		else
			color = 'none'
		end
		
		-- Update rating
		ratingCallback{publishedPhoto = photoInfo, rating = rating or 0}
		
		local photo = photoInfo.photo				
		photo.catalog:withWriteAccessDo('updatePhotoRating', function(context)
			photo:setRawMetadata('rating', rating)			
			if color ~= '' then
				photo:setRawMetadata('label', color)
			end
		end)			
		
	end	
end

-- Check if we can add comments
function publishServiceProvider.canAddCommentsToService( publishSettings )

	--return LrGalleryAPI.testLrGalleryConnection( publishSettings )
	-- TODO: add ability to write comments when to-gallery sync will be implemented
	
	return false	

end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called when the user adds 
 -- a new comment to a published photo in the Library module's Comments panel. 
 -- Your implementation should publish the comment to the service.
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param remotePhotoId (string or number) The remote ID of the photo as previously assigned
		-- via a call to <code>recordRemotePhotoId()</code>.
	-- @param commentText (string) The text of the new comment.
	-- @return (Boolean) True if comment was successfully added to service.

function publishServiceProvider.addCommentToPublishedPhoto( publishSettings, remotePhotoId, commentText )

	local success = LrGalleryAPI.addComment( publishSettings, {
							photoId = remotePhotoId,
							commentText = commentText,
						} )
	
	return success

end

LrGalleryPublishSupport = publishServiceProvider
