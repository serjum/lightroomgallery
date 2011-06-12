-- Lightroom SDK
local LrDialogs = import 'LrDialogs'

-- LrGallery plug-in
require 'LrGalleryAPI'

--[[ @sdk
--- The <i>service definition script</i> for a publish service provider associates 
 -- the code and hooks that extend the behavior of Lightroom's Publish features
 -- with their implementation for your plug-in. The plug-in's <code>Info.lua</code> file 
 -- identifies this script in the <code>LrExportServiceProvider</code> entry. The script
 -- must define the needed callback functions and properties (with the required
 -- names and syntax) and assign them to members of the table that it returns. 
 -- <p>The <code>LrGalleryPublishSupport.lua</code> file of the LrGallery sample plug-in provides 
 -- 	examples of and documentation for the hooks that a plug-in must provide in order to 
 -- 	define a publish service. Because much of the functionality of a publish service
 -- 	is the same as that of an export service, this example builds upon that defined in the
 -- 	<code>LrGalleryExportServiceProvider.lua</code> file.</p>
  -- <p>The service definition script for a publish service should return a table that contains:
 --   <ul><li>A pair of functions that initialize and terminate your publish service. </li>
 --	<li>Optional items that define the desired customizations for the Publish dialog. 
 --	    These can restrict the built-in services offered by the dialog,
 --	    or customize the dialog by defining new sections. </li>
 --	<li> A function that defines the publish operation to be performed 
 --	     on rendered photos (required).</li> 
 --	<li> Additional functions and/or properties to customize the publish operation.</li>
 --   </ul>
 -- <p>Most of these functions are the same as those defined for an export service provider.
 -- Publish services, unlike export services, cannot create presets. (You could think of the 
 -- publish service itself as an export preset.) The settings tables passed
 -- to these callback functions contain only Lightroom-defined settings, and settings that
 -- have been explicitly declared in the <code>exportPresetFields</code> list of the publish service.
 -- A callback function that you define for a publish service cannot make any changes to the
 -- settings table passed to it.</p>
 -- @module_type Plug-in provided

	module 'SDK - Publish service provider' -- not actually executed, but suffices to trick LuaDocs

--]]

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

	return {
		defaultCollectionName = LOC "$$$/LrGallery/DefaultCollectionName/Photostream=Photostream",
		defaultCollectionCanBeDeleted = false,
		canAddCollection = true,
		maxCollectionSetDepth = 0,
			-- Collection sets are not supported through the LrGallery sample plug-in.
	}
	
end

--------------------------------------------------------------------------------
--- When set to the string "disable", the "Go to Published Collection" context-menu item
 -- is disabled (dimmed) for this publish service.
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
publishServiceProvider.titleForGoToPublishedCollection = LOC "$$$/LrGallery/TitleForGoToPublishedCollection=Show in LrGallery"

--------------------------------------------------------------------------------
--- This plug-in defined callback function is called when one or more photos
 -- have been removed from a published collection and need to be removed from
 -- the service. If the service you are supporting allows photos to be deleted
 -- via its API, you should do that from this function.
 -- <p>As each photo is deleted, you should call the <code>deletedCallback</code>
 -- function to inform Lightroom that the deletion was successful. This will cause
 -- Lightroom to remove the photo from the "Delete Photos to Remove" group in the
 -- Library grid.</p>
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @name publishServiceProvider.deletePhotosFromPublishedCollection
	-- @class function
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param arrayOfPhotoIds (table) The remote photo IDs that were declared by this plug-in
		-- when they were published.
	-- @param deletedCallback (function) This function must be called for each photo ID
		-- as soon as the deletion is confirmed by the remote service. It takes a single
		-- argument: the photo ID from the arrayOfPhotoIds array.

function publishServiceProvider.deletePhotosFromPublishedCollection( publishSettings, arrayOfPhotoIds, deletedCallback )

	for i, photoId in ipairs( arrayOfPhotoIds ) do

		LrGalleryAPI.deletePhoto( publishSettings, { photoId = photoId, suppressErrorCodes = { [ 1 ] = true } } )
							-- If LrGallery says photo not found, ignore that.

		deletedCallback( photoId )

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

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called (if supplied)  
 -- to retrieve comments from the remote service, for a single collection of photos 
 -- that have been published through this service. This function is called:
  -- <ul>
    -- <li>For every photo in the published collection each time <i>any</i> photo
	-- in the collection is published or re-published.</li>
 	-- <li>When the user clicks the Refresh button in the Library module's Comments panel.</li>
	-- <li>After the user adds a new comment to a photo in the Library module's Comments panel.</li>
  -- </ul>
 -- <p>This function is not called for unpublished photos or collections that do not contain any published photos.</p>
 -- <p>The body of this function should have a loop that looks like this:</p>
	-- <pre>
		-- function publishServiceProvider.getCommentsFromPublishedCollection( settings, arrayOfPhotoInfo, commentCallback )<br/>
			--<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;for i, photoInfo in ipairs( arrayOfPhotoInfo ) do<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-- Get comments from service.<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;local comments = (depends on your plug-in's service)<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-- Convert comments to Lightroom's format.<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;local commentList = {}<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;for i, comment in ipairs( comments ) do<br/>
					-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;table.insert( commentList, {<br/>
						-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;commentId = (comment ID, if any, from service),<br/>
						-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;commentText = (text of user comment),<br/>
						-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dateCreated = (date comment was created, if available; Cocoa date format),<br/>
						-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;username = (user ID, if any, from service),<br/>
						-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;realname = (user's actual name, if available),<br/>
						-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;url = (URL, if any, for the comment),<br/>
					-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;} )<br/>
					--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;end<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-- Call Lightroom's callback function to register comments.<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;commentCallback { publishedPhoto = photoInfo, comments = commentList }<br/>
			--<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;end<br/>
			--<br/>
		-- end
	-- </pre>
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param arrayOfPhotoInfo (table) An array of tables with a member table for each photo.
		-- Each member table has these fields:
		-- <ul>
			-- <li><b>photo</b>: (<a href="LrPhoto.html"><code>LrPhoto</code></a>) The photo object.</li>
			-- <li><b>publishedPhoto</b>: (<a href="LrPublishedPhoto.html"><code>LrPublishedPhoto</code></a>)
			--	The publishing data for that photo.</li>
			-- <li><b>remoteId</b>: (string or number) The remote systems unique identifier
			-- 	for the photo, as previously recorded by the plug-in.</li>
			-- <li><b>url</b>: (string, optional) The URL for the photo, as assigned by the
			--	remote service and previously recorded by the plug-in.</li>
			-- <li><b>commentCount</b>: (number) The number of existing comments
			-- 	for this photo in Lightroom's catalog database.</li>
		-- </ul>
	-- @param commentCallback (function) A callback function that your implementation should call to record
		-- new comments for each photo; see example.

function publishServiceProvider.getCommentsFromPublishedCollection( publishSettings, arrayOfPhotoInfo, commentCallback )

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
				commentId = 1,
				commentText = data.comments,
				dateCreated = nil,
				username = nil,
				realname = nil,
				url = nil
			})
			commentCallback{publishedPhoto = photoInfo, comments = comments}
		end
	end

end

publishServiceProvider.titleForPhotoRating = LOC "$$$/LrGallery/TitleForPhotoRating=Rating"

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called (if supplied)
 -- to retrieve ratings from the remote service, for a single collection of photos 
 -- that have been published through this service. This function is called:
  -- <ul>
    -- <li>For every photo in the published collection each time <i>any</i> photo
	-- in the collection is published or re-published.</li>
 	-- <li>When the user clicks the Refresh button in the Library module's Comments panel.</li>
	-- <li>After the user adds a new comment to a photo in the Library module's Comments panel.</li>
  -- </ul>
  -- <p>The body of this function should have a loop that looks like this:</p>
	-- <pre>
		-- function publishServiceProvider.getRatingsFromPublishedCollection( settings, arrayOfPhotoInfo, ratingCallback )<br/>
			--<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;for i, photoInfo in ipairs( arrayOfPhotoInfo ) do<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-- Get ratings from service.<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;local ratings = (depends on your plug-in's service)<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-- WARNING: The value for ratings must be a single number.<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-- This number is displayed in the Comments panel, but is not<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-- otherwise parsed by Lightroom.<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-- Call Lightroom's callback function to register rating.<br/>
				--<br/>
				-- &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ratingCallback { publishedPhoto = photoInfo, rating = rating }<br/>
			--<br/>
			-- &nbsp;&nbsp;&nbsp;&nbsp;end<br/>
			--<br/>
		-- end
	-- </pre>
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @param arrayOfPhotoInfo (table) An array of tables with a member table for each photo.
		-- Each member table has these fields:
		-- <ul>
			-- <li><b>photo</b>: (<a href="LrPhoto.html"><code>LrPhoto</code></a>) The photo object.</li>
			-- <li><b>publishedPhoto</b>: (<a href="LrPublishedPhoto.html"><code>LrPublishedPhoto</code></a>)
			--	The publishing data for that photo.</li>
			-- <li><b>remoteId</b>: (string or number) The remote systems unique identifier
			-- 	for the photo, as previously recorded by the plug-in.</li>
			-- <li><b>url</b>: (string, optional) The URL for the photo, as assigned by the
			--	remote service and previously recorded by the plug-in.</li>
		-- </ul>
	-- @param ratingCallback (function) A callback function that your implementation should call to record
		-- new ratings for each photo; see example.

function publishServiceProvider.getRatingsFromPublishedCollection( publishSettings, arrayOfPhotoInfo, ratingCallback )

	-- for i, photoInfo in ipairs( arrayOfPhotoInfo ) do

		-- local rating = LrGalleryAPI.getNumOfFavorites( publishSettings, { photoId = photoInfo.remoteId } )
		-- if type( rating ) == 'string' then rating = tonumber( rating ) end

		-- ratingCallback{ publishedPhoto = photoInfo, rating = rating or 0 }

	-- end
	
end

--------------------------------------------------------------------------------
--- (optional) This plug-in defined callback function is called whenever a
 -- published photo is selected in the Library module. Your implementation should
 -- return true if there is a viable connection to the publish service and
 -- comments can be added at this time. If this function is not implemented,
 -- the new comment section of the Comments panel in the Library is left enabled
 -- at all times for photos published by this service. If you implement this function,
 -- it allows you to disable the Comments panel temporarily if, for example,
 -- the connection to your server is down.
 -- <p>This is not a blocking call. It is called from within a task created
 -- using the <a href="LrTasks.html"><code>LrTasks</code></a> namespace. In most
 -- cases, you should not need to start your own task within this function.</p>
 -- <p>First supported in version 3.0 of the Lightroom SDK.</p>
	-- @param publishSettings (table) The settings for this publish service, as specified
		-- by the user in the Publish Manager dialog. Any changes that you make in
		-- this table do not persist beyond the scope of this function call.
	-- @return (Boolean) True if comments can be added at this time.

function publishServiceProvider.canAddCommentsToService( publishSettings )

	return LrGalleryAPI.testLrGalleryConnection( publishSettings )

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
