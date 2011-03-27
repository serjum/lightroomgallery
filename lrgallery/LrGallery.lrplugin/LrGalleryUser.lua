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
			and propertyTable.nsid 
			and propertyTable.auth_token

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

--------------------------------------------------------------------------------

local doingLogin = false

function LrGalleryUser.login( propertyTable )

	if doingLogin then return end
	doingLogin = true

	LrFunctionContext.postAsyncTaskWithContext( 'LrGallery login',
	function( context )

		-- Clear any existing login info, but only if creating new account.
		-- If we're here on an existing connection, that's because the login
		-- token was rejected. We need to retain existing account info so we
		-- can cross-check it.

		if not propertyTable.LR_editingExistingPublishConnection then
			notLoggedIn( propertyTable )
		end

		propertyTable.accountStatus = LOC "$$$/LrGallery/AccountStatus/LoggingIn=Logging in..."
		propertyTable.loginButtonEnabled = false
		
		LrDialogs.attachErrorDialogToFunctionContext( context )
		
		-- Make sure login is valid when done, or is marked as invalid.
		
		context:addCleanupHandler( function()

			doingLogin = false

			if not storedCredentialsAreValid( propertyTable ) then
				notLoggedIn( propertyTable )
			end
			
			-- Hrm. New API doesn't make it easy to show what operation failed.
			-- LrDialogs.message( LOC "$$$/LrGallery/LoginFailed=Failed to log in." )

		end )
		
		-- Make sure we have an API key.
		
		LrGalleryAPI.getCredentials()

		-- Show request for authentication dialog.
	
		local authRequestDialogResult = LrDialogs.confirm(
			LOC "$$$/LrGallery/AuthRequestDialog/Message=Lightroom needs your permission to upload images to LrGallery.",
			LOC "$$$/LrGallery/AuthRequestDialog/HelpText=If you click Authorize, you will be taken to a web page in your web browser where you can log in. When you're finished, return to Lightroom to complete the authorization.",
			LOC "$$$/LrGallery/AuthRequestDialog/AuthButtonText=Authorize",
			LOC "$$$/LrDialogs/Cancel=Cancel" )
	
		if authRequestDialogResult == 'cancel' then
			return
		end
	
		-- Request the frob that we need for authentication.
		
		propertyTable.accountStatus = LOC "$$$/LrGallery/AccountStatus/WaitingForLrGallery=Waiting for response from flickr.com..."

		require 'LrGalleryAPI'
		local frob = LrGalleryAPI.openAuthUrl()
	
		local waitForAuthDialogResult = LrDialogs.confirm(
			LOC "$$$/LrGallery/WaitForAuthDialog/Message=Return to this window once you've authorized Lightroom on flickr.com.",
			LOC "$$$/LrGallery/WaitForAuthDialog/HelpText=Once you've granted permission for Lightroom (in your web browser), click the Done button below.",
			LOC "$$$/LrGallery/WaitForAuthDialog/DoneButtonText=Done",
			LOC "$$$/LrDialogs/Cancel=Cancel" )
	
		if waitForAuthDialogResult == 'cancel' then
			return
		end
	
		-- User has OK'd authentication. Get the user info.
		
		propertyTable.accountStatus = LOC "$$$/LrGallery/AccountStatus/WaitingForLrGallery=Waiting for response from flickr.com..."

		local data = LrGalleryAPI.callXmlMethod( propertyTable, { method = 'flickr.auth.getToken', frob = frob, suppressError = true, skipAuthToken = true } )
		
		local auth = data.auth
		
		if not auth then
			return
		end
		
		-- If editing existing connection, make sure user didn't try to change user ID on us.
		
		if propertyTable.LR_editingExistingPublishConnection then
		
			if auth.user and propertyTable.nsid ~= auth.user.nsid then
				LrDialogs.message( LOC "$$$/LrGallery/CantChangeUserID=You can not change LrGallery accounts on an existing publish connection. Please log in again with the account you used when you first created this connection." )
				return
			end
		
		end
		
		-- Now we can read the LrGallery user credentials. Save off to prefs.
	
		propertyTable.nsid = auth.user.nsid
		propertyTable.username = auth.user.username
		propertyTable.fullname = auth.user.fullname
		propertyTable.auth_token = auth.token._value
		
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

--------------------------------------------------------------------------------

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
