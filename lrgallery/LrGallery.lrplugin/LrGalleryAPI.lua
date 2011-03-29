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

local prefs = import 'LrPrefs'.prefsForPlugin()

local bind = LrView.bind
local share = LrView.share

local logger = import 'LrLogger'('LrGalleryAPI')

LrGalleryAPI = {}

local appearsAlive
--local serviceUrl = 'http://softlit.ru/service/xmlrpc'
local serviceUrl = 'XN--H1AFILGCK.XN--P1AI'
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
function LrGalleryAPI.showCredentialsDialog( message )

	LrFunctionContext.callWithContext( 'LrGalleryAPI.showCredentialsDialog', function( context )

		local f = LrView.osFactory()
	
		local properties = LrBinding.makePropertyTable( context )
		properties.password = prefs.password
		properties.sharedSecret = prefs.sharedSecret
	
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
						-- TO DO: Should validate API key (16 hex digits, etc.).
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
						-- TO DO: Should validate API key (16 hex digits, etc.).
				},
			}
		}
		
		local result = LrDialogs.presentModalDialog {
				title = LOC "$$$/LrGallery/CredentialsDialog/Title=Enter Your LrGallery username and password", 
				contents = contents,
			}
		
		if result == 'ok' then
	
			prefs.password = trim ( properties.password )
		
		else
		
			LrErrors.throwCanceled()
		
		end
	
	end )
	
end

-- Get username and password
function LrGalleryAPI.getCredentials()

	local username, password = prefs.username, prefs.password
	
	while not(
		type( username ) == 'string' and type( password ) == 'string'
	) do
	
		local message
		if username or password then
			message = LOC "$$$/LrGallery/CredentialsDialog/Invalid=Username and password below are not valid."
		end

		LrGalleryAPI.showCredentialsDialog( message )

		username, password = prefs.username, prefs.password
	
	end
	
	return username, password

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
	local xmlBuilder = LrXml.createXmlBuilder()
	xmlBuilder:beginBlock('methodCall')
	xmlBuilder:beginBlock('methodName')
	xmlBuilder:text(method)
	xmlBuilder:endBlock('methodName')
	xmlBuilder:beginBlock('params')
	for param, value in pairs(params) do
		xmlBuilder:beginBlock('param')
		xmlBuilder:beginBlock('value')
		xmlBuilder:beginBlock(param)
		xmlBuilder:text(value)
		xmlBuilder:endBlock(param)
		xmlBuilder:endBlock('value')
		xmlBuilder:endBlock('param')
	end
	xmlBuilder:endBlock('params')
	xmlBuilder:endBlock('methodCall')
	
	return xmlBuilder:serialize()
	
	--[[
	local xml = ''
		xml = xml .. '<?xml version="1.0"?>\n'
		xml = xml .. '<methodCall>\n'
		xml = xml .. '	<methodName>' .. method .. '</methodName>\n'
		xml = xml .. '	<params>\n'
	for param, value in pairs(params) do
		xml = xml .. '		<param>\n'
		xml = xml .. '			<value>\n'
		xml = xml .. '				<' .. param .. '>' .. value .. '</' .. param ..'>\n'
		xml = xml .. '			</value>\n'
		xml = xml .. '		</param>\n'		
	end
		xml = xml .. '	</params>\n'
		xml = xml .. '</methodCall>\n'

	return xml
	]]--
end

-- XML Remote procedure call
function LrGalleryAPI.callXmlMethod(propertyTable, params)

	-- Construct XML message
	local xmlString = constructXml(params.params)	
	
	-- Send message and get response
	local response, hdrs = LrHttp.post( serviceUrl, xmlString )
	
	-- Transform result to table
	local result = xml2table(response)
	
	-- Return result and raw xml response
	return result, response	
end

-- Login into the gallery
function LrGalleryAPI.login(propertyTable, params)
	
	-- Get username and password
	local username, password = getCredentials();
	
	-- Set request params
	local callParams = {
		username = params.username, 
		password = params.password, 
	}	
	params.params = callParams
	
	-- Call login method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(propertyTable, params)
	
	-- Return token
	return result.token
end

-- Create new gallery user
function LrGalleryAPI.createUser( propertyTable, params )
		
	-- Set request params
	local callParams = {
		username = params.username, 
		password = params.password,
		folder = params.folder,
	}
	params.params = callParams
	
	-- Call createUser method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(propertyTable, params)
	
	-- Return result
	return result
end

-- Upload photo
function LrGalleryAPI.uploadPhoto(propertyTable, params)
		
	-- Encode image in Base64
	local rawPhotoData = LrFileUtils.readFile(params.photoFile)
	local base64photo = LrStringUtils.encodeBase64(rawPhotoData)
		
	-- Set request params
	local callParams = {
		title = params.title,
		photo = base64photo,
	}
	params.params = callParams
	
	-- Call uploadPhoto method
	local result, xmlResponse = LrGalleryAPI.callXmlMethod(propertyTable, params)
	
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
	if not (method == 'login') and (token == nil) then
		local p = {}
		token = LrGalleryAPI.login(nil, p)
	end
	
	-- Check params table
	if not (type(params) == 'table') then
		params = {}
	end	
	params.params = {}
	params.params.method = method
	params.params.token = token
	
	-- Call the method needed and return result
	local result = LrGalleryAPI[method](propertyTable, params)
	return result
end
