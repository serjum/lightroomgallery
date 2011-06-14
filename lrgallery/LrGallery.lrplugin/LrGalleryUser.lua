-- Lightroom SDK
local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrTasks = import 'LrTasks'
local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN)

local logger = import 'LrLogger'( 'LrGalleryAPI' )

require 'LrGalleryAPI'


--============================================================================--

LrGalleryUser = {}

--------------------------------------------------------------------------------

local function storedCredentialsAreValid( propertyTable )

	return propertyTable.username and string.len( propertyTable.username ) > 0
			and propertyTable.token

end

--------------------------------------------------------------------------------

local function notLoggedIn( propertyTable )

	propertyTable.token = nil
	
	propertyTable.nsid = nil
	propertyTable.username = nil
	propertyTable.fullname = ''
	propertyTable.auth_token = nil

	propertyTable.accountStatus = LOC "$$$/LrGallery/AccountStatus/NotLoggedIn=Not logged in"
	propertyTable.loginButtonTitle = LOC "$$$/LrGallery/LoginButton/NotLoggedIn=Log In"
	propertyTable.loginButtonEnabled = true
	propertyTable.validAccount = false

end


-- Login
function LrGalleryUser.login(propertyTable)

	propertyTable.loginButtonTitle = 'Logging in...'
	propertyTable.loginButtonEnabled = false

	-- Start async task
	LrFunctionContext.postAsyncTaskWithContext( 'LrGallery login',
		function(context)
			
			LrDialogs.attachErrorDialogToFunctionContext(context)
			
			-- Call login method
			params = {}
			method = 'login'
			local data = LrGalleryAPI.callMethod(propertyTable, params, method)			
			
			-- Check result
			local username = data.username
			local token = data.token
			if token == nil or not token then
				LrGalleryAPI.displayError(data)
				propertyTable.accountStatus = "Log in failed"
				propertyTable.loginButtonTitle = 'Log in'
				propertyTable.loginButtonEnabled = true
				return
			end
			
			-- Save username and token
			propertyTable.username = username
			propertyTable.password = password
			propertyTable.token = token		
			
			-- Update labels
			propertyTable.accountStatus = LOC "Logged in as " .. username
			propertyTable.loginButtonTitle = "Change user"
			propertyTable.loginButtonEnabled = true
			propertyTable.LR_cantExportBecause = nil
		end 
	)

end

-- Check login
function LrGalleryUser.checkLogin(propertyTable)	

	-- Start async task
	LrFunctionContext.postAsyncTaskWithContext( 'LrGallery login',
		function(context)
			-- Check if stored token is still valid
			local params = {}
			local method = 'checkLogin'
			local data = LrGalleryAPI.callMethod(propertyTable, params, method)						
			
			if not data.result then
				propertyTable.loginButtonTitle = 'Logging in...'
				LrGalleryUser.login(propertyTable)
			else
				propertyTable.accountStatus = 'Logged in as ' .. prefs.username
				propertyTable.loginButtonTitle = 'Change user'
				propertyTable.loginButtonEnabled = true
			end
		end
	)
end

-- Create new gallery user
function LrGalleryUser.createUser(propertyTable)

	-- Start async task
	LrFunctionContext.postAsyncTaskWithContext( 'LrGallery createUser',
		function(context)

			-- Display process
			propertyTable.userManagementStatus = LOC "$$$/LrGallery/UserManagement/CreatingUser=Creating user..."
			propertyTable.createUserButtonEnabled = false
			
			LrDialogs.attachErrorDialogToFunctionContext( context )					
			
			-- Call createUser method
			params = {}
			method = 'createUser'
			local data = LrGalleryAPI.callMethod(propertyTable, params, method)		
			
			-- Check result
			local user_id = data.user_id
			local username = data.username
			local foldername = data.foldername
			if not user_id then
				return
			end
			
			-- Save params
			propertyTable.user_id = user_id
			propertyTable.username = username			
			propertyTable.foldername = foldername
			
			-- Create new published collection
			local catalog = LrApplication.activeCatalog()
			local publishService = catalog:getPublishServices(_PLUGIN.id)[1]
			catalog:withWriteAccessDo('createPublishedCollection', function() 				
				publishService:createPublishedCollection(username)
			end)
			
			-- Say about successfull creation
			LrDialogs.message('Successfully created new user: ' .. username)
		end 
	)	
end


-- Delete gallery user
function LrGalleryUser.deleteUser(propertyTable)

	-- Start async task
	LrFunctionContext.postAsyncTaskWithContext( 'LrGallery deleteUser', function( context )
		propertyTable.userManagementStatus = LOC "$$$/LrGallery/UserManagement/DeletingUser=Deleting user..."
		propertyTable.deleteUserButtonEnabled = false
		
		LrDialogs.attachErrorDialogToFunctionContext( context )
		
		local params = {}
		method = 'deleteUser'
		local data = LrGalleryAPI.deleteUser(propertyTable, params)
		
		-- Check result
		local result = data.result
		local username = data.username
		if not result then
			return
		end
		
		-- Delete corresponding published collection
		local catalog = LrApplication.activeCatalog()
		local publishService = catalog:getPublishServices(_PLUGIN.id)[1]
		local publishedCollections = publishService:getChildCollections()
		for _, publishedCollection in pairs(publishedCollections) do
			if publishedCollection:getName() == username then
				catalog:withWriteAccessDo('deletePublishedCollection', function() 				
					publishedCollection:delete()
				end)
				break
			end
		end		
				
		-- Say about successfull delete
		LrDialogs.message('Successfully deleted user: ' .. username)		
	end
	)
end


--------------------------------------------------------------------------------

local function getDisplayUserNameFromProperties( propertyTable )

	local displayUserName = propertyTable.fullname
	if ( not displayUserName or #displayUserName == 0 )
		or displayUserName == propertyTable.username
	then
		displayUserName = propertyTable.username
	else
		displayUserName = LOC( "$$$/LrGallery/AccountStatus/UserNameAndLoginName=^1 (^2)",
							propertyTable.fullname,
							propertyTable.username )
	end
	
	return displayUserName

end

-- UI labels text update
function LrGalleryUser.updateUserStatusTextBindings(settings)

	local nsid = settings.nsid
	
	if nsid and string.len( nsid ) > 0 then

		LrFunctionContext.postAsyncTaskWithContext( 'LrGallery account status check',
		function( context )
		
			context:addFailureHandler( function()

				-- Login attempt failed. Offer chance to re-establish connection.

				if settings.LR_editingExistingPublishConnection then
				
					local displayUserName = getDisplayUserNameFromProperties(settings)
					
					settings.accountStatus = LOC( "$$$/LrGallery/AccountStatus/LogInFailed=Log in failed, was logged in as ^1", displayUserName)

					settings.loginButtonTitle = LOC "$$$/LrGallery/LoginButton/LogInAgain=Log In"
					settings.loginButtonEnabled = true
					settings.validAccount = false
					
					settings.isUserPro = false
					settings.accountTypeMessage = LOC "$$$/LrGallery/AccountStatus/LoginFailed/Message=Could not verify this LrGallery account. Please log in again. Please note that you can not change the LrGallery account for an existing publish connection. You must log in to the same account."

				end
			
			end )
		
			local userinfo = LrGalleryAPI.getUserInfo( settings, { userId = nsid } )
			if userinfo and ( not userinfo.ispro ) then
				settings.accountTypeMessage = LOC( "$$$/LrGallery/NonProAccountLimitations=This account is not a LrGallery Pro account, and is subject to limitations. Once a photo has been uploaded, it will not be automatically updated if it changes. In addition, there is an upload bandwidth limit each month." )
				settings.isUserPro = false
			else
				settings.accountTypeMessage = LOC( "$$$/LrGallery/ProAccountDescription=This LrGallery Pro account can utilize collections, modified photos will be automatically be re-published, and there is no monthly bandwidth limit." )
				settings.isUserPro = true
			end
			
		end )
	else

		settings.accountTypeMessage = LOC( "$$$/LrGallery/SignIn=Sign in with your LrGallery account." )
		settings.isUserPro = false

	end

end
