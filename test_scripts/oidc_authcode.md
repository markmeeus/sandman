# Focus OIDC-Connect Playground

This playground show how to use the focus OAUTH2 / OpenID-Connect authentication in the authorization_code flow.



### Setting up some globals and helper functions

First we setup some helper functions, these are used to get, refresh and introspect tokens

```lua
http = sandman.http

--Use this auth url "
--http://localhost:4000/authentication/oidc/auth?client_id=foo&redirect_uri=http://localhost:8080/cb&response_type=code&scope=openid&state=abc123&nonce=xyz789
oidc_path =  "http://localhost:4000/authentication/oidc"
client_id = "2e11feba0e0348d317971c52488dd79125943d750b8e6df1"
client_secret = "bar"
http.get(oidc_path .. "/.well-known/openid-configuration")

--[[
Fetches the access_token and id_token from code
And registers it on the document shared state
]]
function get_access_token(code) 
    form_data = "grant_type=authorization_code" .. 
    "&code=" .. code .. 
    "&client_id=" .. client_id .. "&client_secret=" .. client_secret ..
    "&resource=urn:focus:api"..
    "&redirect_uri=http://localhost:8080/cb" 
    
    res = http.post(oidc_path .. '/token', {
        ["content-type"]= "application/x-www-form-urlencoded"
    }, form_data)
    tokens = res.json()
    sandman.document.set('access_token', tokens.access_token)    
    sandman.document.set('id_token', tokens.id_token)    
    sandman.document.set('refresh_token', tokens.refresh_token)
end

--[[
Uses the token endpoint to refresh token
]]
function refresh_token(refresh_token)
    form_data = "grant_type=refresh_token" .. 
    "&refresh_token=" .. refresh_token ..
    "&client_id=" .. client_id .. "&client_secret=" .. client_secret ..
    "&resource=urn:focus:api" ..
    "&scope=openid email profile offline_access messaging.contacts/:userId.post&state=abc123" ..
    "&redirect_uri=http://localhost:8080/cb" 

    res = http.post(oidc_path .. '/token', {
        ["content-type"]= "application/x-www-form-urlencoded"
    }, form_data)
    return sandman.json.decode(res.body)
end

--[[
Uses introspection endpoint with specific token and prints info
]]
function introspect_token(name, token)
    form_data = "token=" .. token ..     
        "&client_id=" .. client_id .. "&client_secret=" .. client_secret
    introspection_response = http.post(oidc_path .. "/token/introspection",
    {
        ["content-type"] = "application/x-www-form-urlencoded"
    }, form_data)
    token_info = sandman.json.decode(introspection_response.body)    
    print(name .. ":")
    print(token_info)
    print("scope:", token_info.scope)
    print("------------")
end
```

## Start a server for the oauth callback

The authorization_code flow will redirect the user to a defined redirect_uri.

This block creates a server and handles the callback

The callback fetches the tokens and adds them to document state
* access_token
* id_token (OpenID Connect)
* refresh_token (if flow request offline_access scope)

```lua
-- Start callback server. This is the client backend
server = sandman.server.start(8080)

--[[
Add oauht /cb callback andpoint
]]
sandman.server.get(server, '/cb', function(req)                
    if(req.query.code) then
        -- fetch token
        get_access_token(req.query.code)
        return {
            body = "thanks! You can now continue in Sandman"
        }
    else
        return {
            body = "We did not get a code, did you cancel?"
        }
    end    
    
end)

```

# Login with Focus
![Hello World](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJgAAACYCAIAAACXoLd2AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyhpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNS1jMDIxIDc5LjE1NTc3MiwgMjAxNC8wMS8xMy0xOTo0NDowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENDIDIwMTQgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6ODAyMkMyRTBGODhCMTFFM0I3QUFEMjZGOUM3MzYyQTYiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6ODAyMkMyRTFGODhCMTFFM0I3QUFEMjZGOUM3MzYyQTYiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo1RDQyMEZEN0Y4OEIxMUUzQjdBQUQyNkY5QzczNjJBNiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo1RDQyMEZEOEY4OEIxMUUzQjdBQUQyNkY5QzczNjJBNiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PkTB1mcAABqjSURBVHja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
)

## Now open one of these urls

[login with focus zonder email](http://localhost:4000/authentication/oidc/auth?client_id=2e11feba0e0348d317971c52488dd79125943d750b8e6df1&redirect_uri=http://localhost:8080/cb&response_type=code&scope=openid messaging.contacts/:userId.post&state=abc123&resource=urn:focus:api)

[login with focus](http://localhost:4000/authentication/oidc/auth?client_id=2e11feba0e0348d317971c52488dd79125943d750b8e6df1&redirect_uri=http://localhost:8080/cb&response_type=code&scope=openid email  messaging.contacts/:userId.post&state=abc123&resource=urn:focus:api)

[login with focus and refresh token](http://localhost:4000/authentication/oidc/auth?client_id=2e11feba0e0348d317971c52488dd79125943d750b8e6df1&redirect_uri=http://localhost:8080/cb&response_type=code&scope=openid email profile offline_access messaging.contacts/:userId.post&state=abc123&resource=urn:focus:api&prompt=consent)



```lua
--[[
    LOG TOKENS (use introspection endpoint for access and refreshtoken)
]]
introspect_token('access_token', sandman.document.get('access_token'))

print("id_token:")
print(sandman.jwt.decode(sandman.document.get("id_token")))
print("------------")

introspect_token('refresh_token', sandman.document.get('refresh_token'))
```

### Refresh and introspect access_token

```lua
new_token = refresh_token( 
    sandman.document.get("refresh_token")
).access_token
introspect_token("new_token", new_token)
```

### Fetch signing keys

```lua
print(sandman.http.get('http://localhost:4000/authentication/oidc/jwks').body)
```

### call messaging api

The requested scope has only access to the messaging contacts api

[swagger](http://localhost:4000/api-gateway/swagger/5345?urls.primaryName=messaging)

```lua
http.post('http://localhost:4000/api-gateway/api/5345/messaging/v1/contacts/p1', 
    {
        authorization =  "Bearer " .. sandman.document.get('access_token'),
        ["content-type"] = "application/json"
    },
    sandman.json.encode({
        searchTerm = "Mark"
    })
)
```
