--[[----------------------------------------------------------------------------

LrGalleryAPI.lua
Common code to initiate LrGallery API requests

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
local LrBinding = import 'LrBinding'
local LrDate = import 'LrDate'
local LrDialogs = import 'LrDialogs'
local LrErrors = import 'LrErrors'
local LrFunctionContext = import 'LrFunctionContext'
local LrHttp = import 'LrHttp'
local LrMD5 = import 'LrMD5'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrView = import 'LrView'
local LrXml = import 'LrXml'
local LrTasks = import 'LrTasks'
local LrStringUtils = import 'LrStringUtils'

local prefs = import 'LrPrefs'.prefsForPlugin(_PLUGIN)

local bind = LrView.bind
local share = LrView.share

local logger = import 'LrLogger'('LrGalleryAPI')

LrGalleryAPI = {}

local appearsAlive
local serviceUrl = "http://XN--H1AFILGCK.XN--P1AI/service/publish/"
--local serviceUrl = "http://lrgallery/service/publish/"
local token = nil

local function formatError(nativeErrorCode)
	return LOC "$$$/LrGallery/Error/NetworkFailure=Could not contact the LrGallery web service. Please check your Internet connection."
end

local simpleXmlMetatable = {
	__tostring = function( self ) return self._value end
}

local function traverse(node)

	local type = string.lower( node:type() )

	if type == 'element' then

		local element = setmetatable( {}, simpleXmlMetatable )		
		element._name = node:name()		
		element._value = node:text()
		
		local count = node:childCount()

		for i = 1, count do
			local name, value = traverse( node:childAtIndex( i ) )
			if name and value then				
				element[ name ] = value
			end			
		end

		if type == 'element' then
			for k, v in pairs( node:attributes() ) do
				element[ k ] = v.value				
			end
		end
		
		return element._name, element

	end

end

local function xml2table(xmlString)
	local _, value = traverse(LrXml.parseXml(xmlString))
	return value
end

local function trim(s)
	return string.gsub( s, "^%s*(.-)%s*$", "%1" )
end

-- Show username and password dialog
function LrGalleryAPI.showCredentialsDialog(message)

	LrFunctionContext.callWithContext( 'LrGalleryAPI.showCredentialsDialog', function( context )
		local f = LrView.osFactory()
	
		local properties = LrBinding.makePropertyTable(context)
		properties.username = prefs.username
		properties.password = prefs.password
	
		-- Build dialog window contents
		local contents = f:column {
			bind_to_object = properties,
			spacing = f:control_spacing(),
			fill = 1,
	
			f:static_text {
				title = LOC "$$$/LrGallery/CredentialsDialog/Message=Please enter LrGallery username and password here",
				fill_horizontal = 1,
				width_in_chars = 55,
				height_in_lines = 2,
				size = 'small',
			},
	
			message and f:static_text {
				title = message,
				fill_horizontal = 1,
				width_in_chars = 55,
				height_in_lines = 2,
				size = 'small',
				text_color = import 'LrColor'( 1, 0, 0 ),
			} or 'skipped item',
			
			f:row {
				spacing = f:label_spacing(),
				
				f:static_text {
					title = LOC "$$$/LrGallery/CredentialsDialog/Username=Username:",
					alignment = 'right',
					width = share 'title_width',
				},
				
				f:edit_field { 
					fill_horizonal = 1,
					width_in_chars = 35, 
					value = bind 'username',
				},
			},
			f:row {
				spacing = f:label_spacing(),
				
				f:static_text {
					title = LOC "$$$/LrGallery/CredentialsDialog/Password=Password:",
					alignment = 'right',
					width = share 'title_width',
				},
				
				f:edit_field { 
					fill_horizonal = 1,
					width_in_chars = 35, 
					value = bind 'password',
				},
			}
		}
		
		local result = LrDialogs.presentModalDialog {
			title = LOC "$$$/LrGallery/CredentialsDialog/Title=Enter Your LrGallery username and password", 
			contents = contents,
		}
			
		if result == 'ok' then
			prefs.username = trim(properties.username)
			prefs.password = trim(properties.password)
		else		
			LrErrors.throwCanceled()		
		end	
	end )	
end

-- Get username and password
function LrGalleryAPI.getCredentials()
	local username, password = prefs.username, prefs.password
	
	repeat
		LrGalleryAPI.showCredentialsDialog()
		username, password = prefs.username, prefs.password
	until type(username) == 'string' and type(password) == 'string'		
	
	return username, password
end

-- Show create user dialog
function LrGalleryAPI.showCreateUserDialog(propertyTable)

	LrFunctionContext.callWithContext( 'LrGalleryAPI.showCreateUserDialog', function(context)

		local f = LrView.osFactory()
	
		local properties = LrBinding.makePropertyTable( context )
		properties.username = ''
		properties.password = ''
		properties.foldername = ''
	
		-- Build dialog window contents
		local contents = f:column {
			bind_to_object = properties,
			spacing = f:control_spacing(),
			fill = 1,
	
			f:static_text {
				title = LOC "$$$/LrGallery/CreateUserDialog/Message=Please enter new user properties",
				fill_horizontal = 1,
				width_in_chars = 55,
				height_in_lines = 2,
				size = 'small',
			},
	
			message and f:static_text {
				title = message,
				fill_horizontal = 1,
				width_in_chars = 55,
				height_in_lines = 2,
				size = 'small',
				text_color = import 'LrColor'( 1, 0, 0 ),
			} or 'skipped item',
			
			f:row {
				spacing = f:label_spacing(),
				
				f:static_text {
					title = LOC "$$$/LrGallery/CreateUserDialog/Username=Username:",
					alignment = 'right',
					width = share 'title_width',
				},
				
				f:edit_field { 
					fill_horizonal = 1,
					width_in_chars = 35, 
					value = bind 'username',
				},
			},
			f:row {
				spacing = f:label_spacing(),
				
				f:static_text {
					title = LOC "$$$/LrGallery/CreateUserDialog/Password=Password:",
					alignment = 'right',
					width = share 'title_width',
				},
				
				f:edit_field { 
					fill_horizonal = 1,
					width_in_chars = 35, 
					value = bind 'password',
				},
			},
			f:row {
				spacing = f:label_spacing(),
				
				f:static_text {
					title = LOC "$$$/LrGallery/CreateUserDialog/foldername=Folder name:",
					alignment = 'right',
					width = share 'title_width',
				},
				
				f:edit_field { 
					fill_horizonal = 1,
					width_in_chars = 35, 
					value = bind 'foldername',
				},
			}
		}
		
		local result = LrDialogs.presentModalDialog {
				title = LOC "$$$/LrGallery/CreateUserDialog/Title=Enter new user properties", 
				contents = contents,
			}
		
		if result == 'ok' then
	
			newUser = {}
			newUser.username = trim (properties.username)
			newUser.password = trim (properties.password)
			newUser.foldername = trim (properties.foldername)
			propertyTable.newUser = newUser
					
			--return username, password, foldername
		else
		
			LrErrors.throwCanceled()
		
		end
	
	end )
	
end

-- Get new user username and password
function LrGalleryAPI.getCreateUserCredentials(propertyTable)
	local username, password, foldername
	
	while not (type(username) == 'string' and type(password) == 'string' and type(foldername) == 'string') do		
		LrGalleryAPI.showCreateUserDialog(propertyTable)
		
		username = propertyTable.newUser.username
		password = propertyTable.newUser.password
		foldername = propertyTable.newUser.foldername	
	end
	
	return username, password, foldername
end

-- Show delete user dialog
function LrGalleryAPI.showDeleteUserDialog(propertyTable)
	LrFunctionContext.callWithContext( 'LrGalleryAPI.showDeleteUserDialog', function( context )
		local f = LrView.osFactory()
	
		local properties = LrBinding.makePropertyTable( context )
		properties.username = ''
	
		-- Build dialog window contents
		local contents = f:column {
			bind_to_object = properties,
			spacing = f:control_spacing(),
			fill = 1,
	
			f:static_text {
				title = LOC "$$$/LrGallery/CreateUserDialog/Message=Please enter username for delete",
				fill_horizontal = 1,
				width_in_chars = 55,
				height_in_lines = 2,
				size = 'small',
			},
	
			message and f:static_text {
				title = message,
				fill_horizontal = 1,
				width_in_chars = 55,
				height_in_lines = 2,
				size = 'small',
				text_color = import 'LrColor'( 1, 0, 0 ),
			} or 'skipped item',
			
			f:row {
				spacing = f:label_spacing(),
				
				f:static_text {
					title = LOC "$$$/LrGallery/DeleteUserDialog/Username=Username:",
					alignment = 'right',
					width = share 'title_width',
				},
				
				f:edit_field { 
					fill_horizonal = 1,
					width_in_chars = 35, 
					value = bind 'username',
				},
			},
		}
		
		local result = LrDialogs.presentModalDialog {
			title = LOC "$$$/LrGallery/DeleteUserDialog/Title=Enter username for delete", 
			contents = contents,
		}
		
		if result == 'ok' then	
			username = trim (properties.username)		
			deleteUser = {
				username = username,
			}
			propertyTable.deleteUser = deleteUser
		else		
			LrErrors.throwCanceled()
		end
	
	end )
	
end

-- Get new user username and password
function LrGalleryAPI.getDeleteUserName(propertyTable)
	local username
	
	while not (type(username) == 'string') do	
		LrGalleryAPI.showDeleteUserDialog(propertyTable)
		username = propertyTable.deleteUser.username
	end
	
	return username
end



--[[ Construct xml message of format
<?xml version="1.0"?>
<methodCall>
	<methodName>getPhotoInfo</methodName>
	<params>
		<param>
			<value>
				<username>ivanov</username>
			</value>
		</param>		
		<param>
			<value>
				<token>djk32i38dsjdk</token>
			</value>
		</param>
	</params>
 </methodCall>
]]--
local function constructXml(params)
	local xml = ''
		xml = xml .. '<?xml version="1.0"?>\n'
		xml = xml .. '<methodCall>\n'
		xml = xml .. '	<methodName>' .. params.method .. '</methodName>\n'
		xml = xml .. '	<params>\n'
	for param, value in pairs(params.params) do
		xml = xml .. '		<param>\n'
		xml = xml .. '			<value>\n'
		xml = xml .. '				<' .. param .. '>' .. value .. '</' .. param ..'>\n'
		xml = xml .. '			</value>\n'
		xml = xml .. '		</param>\n'		
	end
		xml = xml .. '	</params>\n'
		xml = xml .. '</methodCall>\n'

	return xml	
end

-- XML Remote procedure call
function LrGalleryAPI.callXmlMethod(params)	

	-- Construct XML message
	LrGalleryAPI.displayTable(params.params)
	local xmlString = "lrgalleryxml=" .. constructXml(params)
		
	-- Send message and get response		
	local response, headers = LrHttp.post(serviceUrl, xmlString, {{
			field = 'Content-Type',
			value = 'application/x-www-form-urlencoded',
		}, {
			field = 'Content-Length',
			value = tostring(#xmlString)
		}
	})
	LrDialogs.message(response)
	
	-- Transform result to table
	local result = xml2table(response)
	
	-- Return result and raw xml response
	return result, response	
end

-- Login into the gallery
function LrGalleryAPI.login(propertyTable, params)
	
	-- Get username and password
	local username, password = LrGalleryAPI.getCredentials();	
	
	-- Set request params
	local callParams = {}
	callParams.username = username 
	callParams.password = password
	params.params = callParams
	params.method = 'login'
	
	-- Call login method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(params)
	
	-- Save token to prefs
	local token = result.params.param.value.token._value
	prefs.token = token
		
	-- Include username and password in the result
	result.params.param.value['username'] = {}
	result.params.param.value['username']._value = username
	result.params.param.value['password'] = {}
	result.params.param.value['password']._value = password
	
	-- Return result
	return result
end

-- Create new gallery user
function LrGalleryAPI.createUser(propertyTable, params)
	
	-- Get new user params
	local username, password, foldername = LrGalleryAPI.getCreateUserCredentials(propertyTable)
	
	-- Set request params
	local callParams = {
		username = username, 
		password = password,
		foldername = foldername,
		token = prefs.token,
	}
	params.params = callParams
	params.method = 'createUser'
	
	-- Call login method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(params)
	
	-- Save newly created user to prefs
	local user_id = result.params.param.value.user_id._value
	createdUser = {		
		username = username,
		password = password,
		foldername = foldername
	}
	if not (type(prefs.createdUsers) == 'table') then
		prefs.createdUsers = {}
	end
	prefs.createdUsers[user_id] = createdUser
		
	-- Include username and password in the result
	result.params.param.value['username'] = {}
	result.params.param.value['username']._value = username
	result.params.param.value['foldername'] = {}
	result.params.param.value['foldername']._value = foldername
	
	-- Return result
	return result
end

-- Delete gallery user
function LrGalleryAPI.deleteUser(propertyTable, params)
	
	-- Get new user params
	local username = LrGalleryAPI.getDeleteUserName(propertyTable)
	
	-- Set request params
	local callParams = {
		username = username, 
		token = prefs.token,
	}
	params.params = callParams
	params.method = 'deleteUser'
	
	-- Call login method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(params)
		
	-- Include deleted username in the result
	result.params.param.value['username'] = {}
	result.params.param.value['username']._value = username
	
	-- Return result
	return result
end

-- Upload photo
function LrGalleryAPI.uploadPhoto(propertyTable, params)
				
	-- Read photo file content	
	local rawPhotoData = LrFileUtils.readFile(params.params.photoFile)
	
	-- Encode image in urlsafeBase64
	local base64 = LrStringUtils.encodeBase64(rawPhotoData)
	urlsafeBase64 = base64:gsub('+', '-')
	urlsafeBase64 = urlsafeBase64:gsub('/', '_')
	urlsafeBase64 = urlsafeBase64:gsub('=', '')
	params.params.image = urlsafeBase64	
	
	-- Call uploadPhoto method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(params)
	
	-- Return result
	return result
end

-- Get photo info
function LrGalleryAPI.getPhotoInfo(propertyTable, params)
		
	-- Set request params
	local callParams = {
		photo_id = params.photo_id,
	}
	params.params = callParams
	
	-- Call getPhotoInfo method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(propertyTable, params)
	
	-- Return result
	return result
end

-- Delete photo
function LrGalleryAPI.getPhotoInfo(propertyTable, params)
		
	-- Set request params
	local callParams = {
		photoid = params.photoid,
	}
	params.params = callParams
	
	-- Call deletePhoto method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(propertyTable, params)
	
	-- Return result
	return result
end

-- Logout
function LrGalleryAPI.logout(propertyTable, params)
	
	-- Call logout method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(propertyTable, params)
	
	-- Return result
	return result
end

-- Call method
function LrGalleryAPI.callMethod(propertyTable, params, method)

	-- Check login
	token = prefs.token
	if not (method == 'login') and (token == nil) then
		local p = {}
		token = LrGalleryAPI.login(nil, p)
	end
	
	-- Check params table
	if not (type(params) == 'table') then
		params = {}
	end	
	if not (type(params.params) == 'table') then
		params.params = {}
	end		
	params.method = method
	params.params.token = token
	
	-- Call the method needed and return result
	local result = LrGalleryAPI[method](propertyTable, params)
	return result
end

function LrGalleryAPI.displayTable(t)
	local message = ""
	for key, value in pairs(t) do 
		message = message .. key .. " = " .. value .. "\n"
	end	
	LrDialogs.message(message)
end