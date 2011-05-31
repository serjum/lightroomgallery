--[[----------------------------------------------------------------------------

LrGalleryUser.lua
LrGallery user account management

--------------------------------------------------------------------------------

ADOBE SYSTEMS INCORPORATED
 Copyright 2007-2010 Adobe Systems Incorporated
 All Rights Reserved.

NOTICE: Adobe permits you to use, modify, and distribute this file in accordance
with the terms of the Adobe license agreement accompanying it. If you have received
this file from a source other than Adobe, then your use, modification, or distribution
of it requires the prior written permission of Adobe.

------------------------------------------------------------------------------]]

	-- Lightroom SDK
local LrDialogs = import 'LrDialogs'
local LrFunctionContext = import 'LrFunctionContext'
local LrTasks = import 'LrTasks'

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

	-- Start async task
	LrFunctionContext.postAsyncTaskWithContext( 'LrGallery login',
		function(context)

			-- Display process
			propertyTable.accountStatus = LOC "$$$/LrGallery/AccountStatus/LoggingIn=Logging in..."
			propertyTable.loginButtonEnabled = false	
			
			LrDialogs.attachErrorDialogToFunctionContext( context )
			
			-- Call login method
			params = {}
			method = 'login'
			local data = LrGalleryAPI.callMethod(propertyTable, params, method)		
			
			-- Check result
			local username = data.params.param.value.username._value
			local token = data.params.param.value.token._value
			if not token then
				return
			end
			
			-- Save username and token
			propertyTable.username = username
			propertyTable.password = password
			propertyTable.token = token		
			
			-- Update labels
			propertyTable.accountStatus = LOC "$$$/LrGallery/AccountStatus/WaitingForLrGallery=Logged in as " .. username
			propertyTable.LR_cantExportBecause = nil
		end 
	)

end

--------------------------------------------------------------------------------

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
			local user_id = data.params.param.value.user_id._value
			local username = data.params.param.value.username._value
			local foldername = data.params.param.value.foldername._value			
			if not user_id then
				return
			end
			
			-- Save params
			propertyTable.user_id = user_id
			propertyTable.username = username			
			propertyTable.foldername = foldername		
			
			-- Say about successfull creation
			LrDialogs.message('Successfully created new user: ' .. username)
		end 
	)	

end


--------------------------------------------------------------------------------

local doingDeleteUser = false

function LrGalleryUser.deleteUser( propertyTable )

	if doingDeleteUser then 
		return 
	end
	doingDeleteUser = true

	LrFunctionContext.postAsyncTaskWithContext( 'LrGallery deleteUser',
	function( context )

		propertyTable.userManagementStatus = LOC "$$$/LrGallery/UserManagement/DeletingUser=Deleting user..."
		propertyTable.deleteUserButtonEnabled = false
		
		LrDialogs.attachErrorDialogToFunctionContext( context )
		
		context:addCleanupHandler( 
			function()
				doingDeleteUser = false
			end 
		)

		local username = LrGalleryAPI.getDeleteUserName()
	
		local params = {}
		params.username = username
		local result = LrGalleryAPI.deleteUser(propertyTable, params)
		
		LrGalleryUser.updateUserStatusTextBindings( propertyTable )
		
	end )

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

--------------------------------------------------------------------------------

function LrGalleryUser.verifyLogin( propertyTable )

	-- Observe changes to prefs and update status message accordingly.

	local function updateStatus()
	
		logger:trace( "verifyLogin: updateStatus() was triggered." )
		
		LrTasks.startAsyncTask( function()
			logger:trace( "verifyLogin: updateStatus() is executing." )
			if storedCredentialsAreValid( propertyTable ) then
			     
				local displayUserName = getDisplayUserNameFromProperties( propertyTable )
				
				propertyTable.accountStatus = LOC( "$$$/LrGallery/AccountStatus/LoggedIn=Logged in as ^1", displayUserName )
			
				if propertyTable.LR_editingExistingPublishConnection then
					propertyTable.loginButtonTitle = LOC "$$$/LrGallery/LoginButton/LogInAgain=Log In"
					propertyTable.loginButtonEnabled = false
					propertyTable.validAccount = true
				else
					propertyTable.loginButtonTitle = LOC "$$$/LrGallery/LoginButton/LoggedIn=Switch User?"
					propertyTable.loginButtonEnabled = true
					propertyTable.validAccount = true
				end
			else
				notLoggedIn( propertyTable )
			end
	
			LrGalleryUser.updateUserStatusTextBindings( propertyTable )
		end )
		
	end

	propertyTable:addObserver( 'auth_token', updateStatus )
	updateStatus()
	
end


-- UI labels text update
function LrGalleryUser.updateUserStatusTextBindings( settings )

	local nsid = settings.nsid
	
	if nsid and string.len( nsid ) > 0 then

		LrFunctionContext.postAsyncTaskWithContext( 'LrGallery account status check',
		function( context )
		
			context:addFailureHandler( function()

				-- Login attempt failed. Offer chance to re-establish connection.

				if settings.LR_editingExistingPublishConnection then
				
					local displayUserName = getDisplayUserNameFromProperties( settings )
					
					settings.accountStatus = LOC( "$$$/LrGallery/AccountStatus/LogInFailed=Log in failed, was logged in as ^1", displayUserName )

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
