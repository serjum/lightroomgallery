--
-- Sending Twitter Tweets from a Lightroom Plugin
-- http://regex.info/blog/lua/twitter
--
--
-- Copyright 2009-2010 Jeffrey Friedl
-- (jfriedl@yahoo.com)
-- http://regex.info/blog/
--
-- Version 5 (Dec 17, 2010)
-- (version history follows at the end of this file)
--
--
-- This requires my sha1.lua package (http://regex.info/blog/lua/sha1)
--
-- This exposes two public functions:
--
--    Twitter_AuthenticateNewCredentials()
--    Twitter_SendTweet(credential_bundle, status_text)
--
-- The first leads the user through the procedure to grant your application
-- permission to send tweets on their behalf. It returns a "credential
-- bundle" (a Lua table) that can be cached locally (such as in the plugin
-- preferences -- see LrPrefs) and used for sending subsequent tweets
-- forever, or until the user  unpermissions your application at Twitter.
--
-- For example, if you have 'TWITTER_CREDENTIALS' in your
-- exportPresetFields list (with its default set to nil) and 'P' is the
-- local copy of the property table for the plugin (e.g. as passed to
-- sectionsForBottomOfDialog, you might have:
--
--
--|     f:view {
--|        bind_to_object = P,
--|        place = 'overlapping',
--|        fill_horizontal = 1,
--|     
--|        f:static_text {
--|           fill_horizontal = 1,
--|           visible = LrBinding.keyIsNotNil 'TWITTER_CREDENTIALS',
--|           LrView.bind {
--|              key = 'TWITTER_CREDENTIALS',
--|              transform = function(credentials)
--|                             return LOC("$$$/xxx=Authenticated to Twitter as @^1",
--|                                        credentials.screen_name)
--|                          end
--|           },
--|        },
--|        f:push_button {
--|           visible = LrBinding.keyIsNil 'TWITTER_CREDENTIALS',
--|           enabled = LrBinding.keyIsNotNil '_authenticating_at_twitter',
--|           title   = "Authenticate at Twitter",
--|           action  = function()
--|                        LrFunctionContext.postAsyncTaskWithContext("authenticate at twitter",
--|                           function(context)
--|                              context:addFailureHandler(function(status, error)
--|                                                           LrDialogs.message("INTERNAL ERROR", error, "critical")
--|                                                        end)
--|                              context:addCleanupHandler(function()
--|                                                           _authenticating_at_twitter = nil
--|                                                        end)
--|                              _authenticating_at_twitter = true
--|                              P.TWITTER_CREDENTIALS = Twitter_AuthenticateNewCredentials()
--|                           end)
--|                     end
--|        }
--|     }
--
--
-- and then later during export...
--
--
--|     local P = exportContext.propertyTable
--|     
--|     if P.TWITTER_CREDENTIALS then
--|        local result = Twitter_SendTweet(P.TWITTER_CREDENTIALS,
--|                                         "I just did something with Lightroom!")
--|        if result == nil then
--|           -- user has revoked permission, so we'll uncache the credential bundle
--|           P.TWITTER_CREDENTIALS = nil
--|        end
--|     end
--|     
--
--
-- LOCAL CONFIGURATION
--
-- Modify these two functions so that each returns a string, the "Consumer Key"
-- and "Consumer Secret", respectively, that Twitter generated for your specific
-- application when you registered it at Twitter (at http://twitter.com/oauth_clients/new)
--
-- THE KEY/SECRET PAIR SHOULD BE HIDDEN FROM THE PUBLIC. BE SURE TO COMPILE THIS MODULE,
-- AND CONSIDER OBFUSCATING THE VALUES HERE, e.g. INSTEAD OF
--     return "jhjg6x89jajah2"
-- DO
--     return "j".."h".."j".."g".."6".."x".."8".."9".."j".."a".."j".."a".."h".."2"
-- AT THE VERY LEAST.
--
local function consumer_secret()   return plugin.twitter_secret()          end
local function consumer_key()      return plugin.twitter_key()             end

--
-- Have this function return something unique to your application, such as a
-- hostname or reversed hostname, e.g. I use "regex.info/flickr" for my
-- upload-to-Flickr plugin. This is used only for generating a unique random
-- string, so the user will never see it.
--
local function string_unique_to_this_ap()   return "regex.info/" .. plugin.version_tag() end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local LrMD5             = import 'LrMD5'
local LrXml             = import 'LrXml'
local LrDate            = import 'LrDate'
local LrDialogs         = import 'LrDialogs'
local LrHttp            = import 'LrHttp'
local LrStringUtils     = import 'LrStringUtils'
local LrFunctionContext = import 'LrFunctionContext'



local TwitterRequestTokenURL = 'http://api.twitter.com/oauth/request_token'
local TwitterAuthorizeURL    = 'http://api.twitter.com/oauth/authorize'
local TwitterAccessTokenURL  = 'http://api.twitter.com/oauth/access_token'

local function generate_nonce()
   return LrStringUtils.encodeBase64(LrMD5.digest(string_unique_to_this_ap())
                                  .. LrMD5.digest(tostring(math.random()) .. "random")
                                  .. tostring(LrDate.currentTime()))
end

--
-- Like URL-encoding, but following OAuth's specific semantics
--
local function oauth_encode(val)
   return tostring(val:gsub('[^-._~a-zA-Z0-9]', function(letter)
                                                   return string.format("%%%02x", letter:byte()):upper()
                                                end))
   -- The wrapping tostring() above is to ensure that only one item is returned (it's easy to
   -- forget that gsub() returns multiple items
end

-- UnixTime of 978307200 is a CocoaTime of 0
local CocoTimeShift = 978307200

--
-- Returns the current time as a Unix timestamp.
--
local function unix_timestamp()
   return tostring(CocoTimeShift + math.floor(LrDate.currentTime() + 0.5))
end

--
-- Given a url endpoint, a GET/POST method, and a table of key/value args, build
-- the query string and sign it, returning the query string (in the case of a
-- POST) or, for a GET, the final url.
--
-- The args should also contain an 'oauth_token_secret' item, except for the
-- initial token request.
--
local function oauth_sign(url, method, args)

   assert(method == "GET" or method == "POST")

   local consumer_secret = consumer_secret()
   local token_secret    = args.oauth_token_secret or ""

   --
   -- Remove the token_secret from the args, 'cause we neither send nor sign it.
   -- (we use it for signing which is why we need it in the first place)
   --
   args.oauth_token_secret = nil

   -- Twitter does only HMAC-SHA1
   args.oauth_signature_method = 'HMAC-SHA1'


   --
   -- oauth-encode each key and value, and get them set up for a Lua table sort.
   --
   local keys_and_values = { }

   for key, val in pairs(args) do
      table.insert(keys_and_values,  {
                      key = oauth_encode(key),
                      val = oauth_encode(val)
                   })
   end

   --
   -- Sort by key first, then value
   --
   table.sort(keys_and_values, function(a,b)
                          if a.key < b.key then
                             return true
                          elseif a.key > b.key then
                             return false
                          else
                             return a.val < b.val
                          end
                       end)

   --
   -- Now combine key and value into key=value
   --
   local key_value_pairs = { }
   for _, rec in pairs(keys_and_values) do
      table.insert(key_value_pairs, rec.key .. "=" .. rec.val)
   end

   --
   -- Now we have the query string we use for signing, and, after we add the
   -- signature, for the final as well.
   --
   local query_string_except_signature = table.concat(key_value_pairs, "&")

   --

   -- Don't need it for Twitter, but if this routine is ever adapted for
   -- general OAuth signing, we may need to massage a version of the url to
   -- remove query elements, as described in http://oauth.net/core/1.0#rfc.section.9.1.2
   --
   -- More on signing:
   --   http://www.hueniverse.com/hueniverse/2008/10/beginners-gui-1.html
   --
   local SignatureBaseString = method .. '&' .. oauth_encode(url) .. '&' .. oauth_encode(query_string_except_signature)
   local key = oauth_encode(consumer_secret) .. '&' .. oauth_encode(token_secret)

   --
   -- Now have our text and key for HMAC-SHA1 signing
   --
   local hmac_binary = hmac_sha1_binary(key, SignatureBaseString)

   --
   -- Base64 encode it
   --
   local hmac_b64 = LrStringUtils.encodeBase64(hmac_binary)

   --
   -- Now append the signature to end up with the final query string
   --
   local query_string = query_string_except_signature .. '&oauth_signature=' .. oauth_encode(hmac_b64)

   if method == "GET" then
      -- return the full url
      return url .. "?" .. query_string
   else
      -- for a post, just return the query string, so it can be included in the POST payload
      return query_string
   end
end

--
-- Show a dialog to the user inviting them to enter the 6-digit PIN that
-- the twitter page should have shown them after they granted this
-- application permission for access.
--
-- We return the PIN (as a string) if they provide it, nil otherwise.
--
local function GetUserPIN(context)

   local PropertyTable = LrBinding.makePropertyTable(context)
   PropertyTable.PIN = ""

   local v = LrView.osFactory()
   local result = LrDialogs.presentModalDialog {
      title = LOC("$$$/xxx=Twitter Authentication PIN"),
      contents = v:view {
         bind_to_object = PropertyTable,
         v:static_text {
            title = LOC("$$$/xxx=After you have granted this application access at Twitter, enter the seven-digit PIN they provided:")
         },
         v:view {
            margin_top    = 30,
            margin_bottom = 30,
            place_horizontal = 0.5,
            place = 'horizontal',
            v:static_text {
               title = LOC("$$$/xxx=PIN"),
               font = {
                  name = "<system/default>",
                  size = 40, -- this is big, to match the way Twitter presents the PIN to the user
               }
            },
            v:spacer { width = 30 },
            v:edit_field {
               width_in_digits = 9, -- make a bit bigger than needed so the PIN will never "wrap" in the little box
               wraps = false,
               alignment = 'center',
               value = LrView.bind 'PIN',
               font = {
                  name = "<system/default>",
                  size = 40,
               },
               validate = function(view, value)
                             -- strip all whitespace, just in case some came over with a cut-n-paste
                             value = value:gsub('%s+', '')
                             if value:match('^[0-9][0-9][0-9][0-9][0-9][0-9][0-9]?$') then
                                return true, value
                             else
                                return false, value, LOC("$$$/xxx=A Twitter authentication PIN is a seven-digit number")
                             end
                          end
            }
         }
      }
   }

   if result == "ok" and PropertyTable.PIN:match("^[0-9][0-9][0-9][0-9][0-9][0-9][0-9]?$") then
      return PropertyTable.PIN
   else
      return nil
   end
end


--
-- If an HTTP request returns nothing, check the headers and return some kind of reasonable
-- error message.
--
local function error_from_header(reply, headers)

   if not headers.status then
      return LOC("$$$/xxx=couldn't connect to twitter -- Internet connection down?")
   end

   local note = LOC("$$$/xxx=Unexpected HTTP error reply #^1 from Twitter", headers.status)

   if reply then
      local error = reply:match("<error>(.-)</error>")
      if error then
         note = note .. ": " .. error
      end
   end

   return note
end

--
-- Start a sequence that allows the user to authenticate their Twitter account
-- to the plugin. This can't be run on the main LR task, so be sure it's downwind
-- of a LrTask.startAsyncTask() or LrFunctionContext.postAsyncTaskWithContext().
--
-- On failure, it returns nil and an error message.
--
-- On success, it returns a "credential bundle" table along the lines of:
--       
--       {
--          oauth_token        = "jahdhYHajdkajaeh"
--          oauth_token_secret = "GFWFGN$7gIN9Nf8huN&G^G#736nx7N&ZY#SyZz",
--          user_id            = "14235768",
--          screen_name        = "jfriedl",
--       }
--
-- You should cache this credential-bundle table somewhere (e.g. in the
-- Lightroom Prefs) and use it for subsequent interaction with Twitter on behalf
-- of the user, forever, unless attempting to use it results in an error
-- (at which point you probably want to uncache it).
-- 
function Twitter_AuthenticateNewCredentials()
   --
   -- First ping Twitter to get a request token.
   --
   local url = oauth_sign(TwitterRequestTokenURL,
                          "GET",
                          {
                             oauth_consumer_key = consumer_key(),
                             oauth_timestamp    = unix_timestamp(),
                             oauth_version      = '1.0',
                             oauth_callback     = "oob",
                             oauth_nonce        = generate_nonce(),
                          })

   local result, headers = LrHttp.get(url)

   if not result or headers.status ~= 200 then
      return nil, error_from_header(result, headers)
   end

   local token        = result:match('oauth_token=([^&]+)')
   local token_secret = result:match('oauth_token_secret=([^&]+)')

   if not token then
      return nil, LOC("$$$/xxx=couldn't get request token from Twitter")
   end

   --
   -- Tell the user that they'll have to permission their account to allow this
   -- app to have access, and give them a chance to bail.
   --
   local url = TwitterAuthorizeURL .. '?oauth_token=' .. oauth_encode(token)

   local result = LrDialogs.confirm(LOC("$$$/xxx=For this plugin to update your status at Twitter, you must grant it permission. Jump to the authentication page at Twitter?"),
                                    LOC("$$$/xxx=If you are currently logged into Twitter with your browser, you will authenticate under that login."),
                                    LOC("$$$/xxx=View authentication page at Twitter"))

   if result ~= "ok" then
      return nil, "canceled"
   end


   --
   -- Now have the user visit the authorize url (with that token) to log in to Twitter
   -- and permission their account for your application.
   --
   LrHttp.openUrlInBrowser(url)

   LrTasks.sleep(1) -- give the browser a chance to open

   --
   -- Now must get PIN from user
   --
   local PIN -- will be filled in by next call.... if NIL, then bail because user canceled

   LrFunctionContext.callWithContext("Twitter authentication PIN",
              function(context)
                 --
                 -- Set up a failure handle, just in case there's a programming bug in
                 -- this code. (my standard practice after creating a new context)
                 --
                 context:addFailureHandler(function(status, error)
                                              LrDialogs.message(LOC("$$$/xxx=INTERNAL ERROR"),
                                                                error,
                                                                "critical")
                                           end)

                 PIN = GetUserPIN(context)
              end)

   if not PIN then
      return nil, "canceled"
   end

   --
   -- Now that your app should have permission, go to Twitter and get the
   -- authentication token that will let you interact with Twitter on behalf of the
   -- user.
   --
   local url = oauth_sign(TwitterAccessTokenURL,
                          "GET",
                          {
                             oauth_consumer_key = consumer_key(),
                             oauth_timestamp    = unix_timestamp(),
                             oauth_version      = '1.0',
                             oauth_callback     = "oob",
                             oauth_nonce        = generate_nonce(),
                             oauth_token        = token,
                             oauth_token_secret = token_secret,
                             oauth_verifier     = PIN,
                          })

   local result, headers = LrHttp.get(url)

   if not result or headers.status ~= 200 then
      return nil, error_from_header(result, headers)
   end

   local oauth_token        = result:match(       'oauth_token=([^&]+)')
   local oauth_token_secret = result:match('oauth_token_secret=([^&]+)')
   local user_id            = result:match(           'user_id=([^&]+)')
   local screen_name        = result:match(       'screen_name=([^&]+)')

   if oauth_token and oauth_token_secret and user_id and screen_name then
      --
      -- Got it
      --
      return {
         oauth_token        = oauth_token,
         oauth_token_secret = oauth_token_secret,
         user_id            = user_id,
         screen_name        = screen_name,
      }

   end

   return nil, LOC("$$$/xxx=Unexpected reply from Twitter: ^1",  result)

end

--
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-account%C2%A0verify_credentials
--
function Twitter_VerifyCredentials(credential_bundle)

   assert(type(credential_bundle)                    == 'table')
   assert(type(credential_bundle.oauth_token)        == 'string')
   assert(type(credential_bundle.oauth_token_secret) == 'string')

   local url = "http://api.twitter.com/1/account/verify_credentials.xml"

   local QUERY = {
      oauth_consumer_key = consumer_key(),
      oauth_timestamp    = unix_timestamp(),
      oauth_version      = '1.0',
      oauth_callback     = "oob",
      oauth_nonce        = generate_nonce(),
      oauth_token        = credential_bundle.oauth_token,
      oauth_token_secret = credential_bundle.oauth_token_secret,
   }

   local full_url = oauth_sign(url, "GET", QUERY)

   return LrHttp.get(full_url)

end

local function GetTagText(xml_arg, tagpath)

   local xslt = [[<?xml version="1.0"?><xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:output method="text"/><xsl:template match="]] .. tagpath .. [["><xsl:value-of select="text()"/></xsl:template><xsl:template match="text()"/></xsl:stylesheet>]]

   -- xml arg can be a string or an XML DOM
   local xml_obj = type(xml_arg) == 'string' and LrXml.parseXml(xml_arg) or xml_arg
   return xml_obj:transform(xslt)

end


function Twitter_CurrentStatusID(credential_bundle)
   -- a side effect is that this'll return the current status
   local xml = LrXml.parseXml(Twitter_VerifyCredentials(credential_bundle) or "")
   return GetTagText(xml, "/user/status/id")
end


--
-- Twitter_SendTweet(credential_bundle, status_text)
--
-- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0update
--
-- Given a credential bundle (as returned by Twitter_AuthenticateNewCredentials),
-- and the text of a new tweet, send it.
--
-- Returns true on success, nil if the user has revoked permission for your app
-- (and thus the credential bundle should be discarded and no longer cached),
-- and false on other failure (e.g. network is down)
--
-- ARGS is an optional table of key/value pairs, with keys from among:
--     lat
--     long
--
function Twitter_SendTweet(credential_bundle, status_text, ARGS)

   assert(type(status_text)                          == 'string')
   assert(type(credential_bundle)                    == 'table')
   assert(type(credential_bundle.oauth_token)        == 'string')
   assert(type(credential_bundle.oauth_token_secret) == 'string')

   
   local PriorID = Twitter_CurrentStatusID(credential_bundle)

   local url = "http://api.twitter.com/1/statuses/update.xml"

   local QUERY = {
      status             = status_text,
      oauth_consumer_key = consumer_key(),
      oauth_timestamp    = unix_timestamp(),
      oauth_version      = '1.0',
      oauth_callback     = "oob",
      oauth_nonce        = generate_nonce(),
      oauth_token        = credential_bundle.oauth_token,
      oauth_token_secret = credential_bundle.oauth_token_secret,
   }

   if ARGS and ARGS.lat and ARGS.long then
      -- the next bit lops each value off at 8 digits (as per the API), but gets rid of trailing zeros to keep it tidy
      local lat = tonumber(ARGS.lat)
      local lon = tonumber(ARGS.long)
      -- don't add if it's 0,0.... sorry to those on a boat off Africa
      if lat and lon and (lat ~= 0 or lon ~= 0) then
         QUERY.lat  = sprintf("%.8f", lat):gsub('0+$', '')
         QUERY.long = sprintf("%.8f", lon):gsub('0+$', '')
      end
   end

   -- http://apiwiki.twitter.com/Twitter-REST-API-Method%3A-statuses%C2%A0update
   local query_string = oauth_sign(url, "POST", QUERY)

   --
   -- Twitter requires the Content-Type and Content-Length be set, or they refuse the authentication.
   --
   local result, headers = LrHttp.post(url,
                                       query_string,
                                       {
                                          {
                                             field = 'Content-Type',
                                             value = 'application/x-www-form-urlencoded',
                                          },
                                          {
                                             field = 'Content-Length',
                                             value = tostring(#query_string)
                                          }
                                       })

   if not result then
      return nil, error_from_header(headers)
   end

   if result:match("Failed to validate") then
      return nil -- user revoked permission
   end

   local ID = GetTagText(result, "/status/id")

   if ID == PriorID then
      LrDialogs.message(LOC("$$$/xxx=The tweet was rejected by Twitter"),
                        LOC("$$$/xxx=They don't say why... it may have been too long, a repeat of a recent tweat, or something else."),
                        "warning")
      return false, LOC("$$$/xxx=Tweet rejected by Twitter")
   end

   -- Lots of stuff in the result....
   --
   --|   <?xml version="1.0" encoding="UTF-8"?>
   --|   <status>
   --|     <created_at>Thu May 28 07:14:12 +0000 2009</created_at>
   --|     <id>94890718</id>
   --|     <text>testing: 2009-05-28T07:14:06.062+00:00</text>
   --|     <source>&lt;a href="http://regex.info/blog/lightroom-goodies/flickr"&gt;Jeffrey's Export-to-Flickr Lightroom Plugin&lt;/a&gt;</source>
   --|     <truncated>false</truncated>
   --|     <in_reply_to_status_id></in_reply_to_status_id>
   --|     <in_reply_to_user_id></in_reply_to_user_id>
   --|     <favorited>false</favorited>
   --|     <in_reply_to_screen_name></in_reply_to_screen_name>
   --|     <user>
   --|       <id>309446</id>
   --|       <name>just testing</name>
   --|       <screen_name>my_test_account</screen_name>
   --|       <location></location>
   --|       <description></description>
   --|       <profile_image_url>http://static.twitter.com/images/default_profile_normal.png</profile_image_url>
   --|       <url></url>
   --|       <protected>true</protected>
   --|       <followers_count>43248</followers_count>
   --|       <profile_background_color>9ae4e8</profile_background_color>
   --|       <profile_text_color>000000</profile_text_color>
   --|       <profile_link_color>0000ff</profile_link_color>
   --|       <profile_sidebar_fill_color>e0ff92</profile_sidebar_fill_color>
   --|       <profile_sidebar_border_color>87bc44</profile_sidebar_border_color>
   --|       <friends_count>193827</friends_count>
   --|       <created_at>Thu May 28 04:09:04 +0000 2009</created_at>
   --|       <favourites_count>0</favourites_count>
   --|       <utc_offset>32400</utc_offset>
   --|       <time_zone>Tokyo</time_zone>
   --|       <profile_background_image_url>http://static.twitter.com/images/themes/theme1/bg.gif</profile_background_image_url>
   --|       <profile_background_tile>false</profile_background_tile>
   --|       <statuses_count>2</statuses_count>
   --|       <notifications>false</notifications>
   --|       <following>false</following>
   --|     </user>
   --|   </status>


   -- For lack of a better idea, I'll pick the presense of "<created_at>" as a signal of success.
   if result:match('<created_at>') then
      return true, result
   else
      return false, result -- some kind of failure... unknown response
   end
end


--[[---------------------------------------------------------------------------------------------------

Version History

Version 1 (May 29, 2009)
      Initial public release

Version 2 (June 14, 2009)

      Sigh, it seems Twitter suddenly changed OAuth versions in a way that
      unilaterally breaks all prior applications, without notice. Sigh. They're a
      young company, I guess, but I'd have thought they'd have someone with
      a least a little industry experience making these kinds of important decisions.

      Anyway, this version supports OAuth 1.0a, and provides better error detection
      and reporting, for the next time they pull a stunt like this.

Version 3 (Feb 2, 2010)

      Geotagging support.
      Also returns the full result from Twitter as a 2nd return value for Twitter_SendTweet.
      Added Twitter_VerifyCredentials()

Version 4 (Mar 22, 2010)

      Added a tostring() oauth_encode() to ensure that it returns a single item, just to be safe
      in the future.

Version 5 (Dec 17, 2010)

      Updated Twitter urls as per
      http://groups.google.com/group/twitter-api-announce/browse_thread/thread/46ca6fcb9ea7eb49/34b013f4d092737f?show_docid=34b013f4d092737f&pli=1


--]]---------------------------------------------------------------------------------------------------