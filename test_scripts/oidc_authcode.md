### Setting up some globals

```lua
http = sandman.http

--Use this auth url "
--http://localhost:4000/authentication/oidc/auth?client_id=foo&redirect_uri=http://localhost:8080/cb&response_type=code&scope=openid&state=abc123&nonce=xyz789
oidc_path =  "http://localhost:4000/authentication/oidc"
http.get(oidc_path .. "/.well-known/openid-configuration")
```

## starting a server to listen to the oauth callback

This server sets 2 document variables
* access_token
* id_token (OpenID Connect)

```lua
server = sandman.server.start(8080)
--[[
Fetches the access_token and id_token from code
And registers it on the document shared state
]]
function get_access_token(code) 
    form_data = "grant_type=authorization_code" .. 
    "&code=" .. code .. 
    "&client_id=foo&client_secret=bar" ..
    "&redirect_uri=http://localhost:8080/cb" 
    
    res = http.post(oidc_path .. '/token', {
        ["content-type"]= "application/x-www-form-urlencoded"
    }, form_data)
    tokens = res.json()
    sandman.document.set('access_token', tokens.access_token)    
    sandman.document.set('id_token', tokens.id_token)    
end

--[[
Add oauht /cb callback andpoint
]]
sandman.server.get(server, '/cb', function(req)            
    -- fetch token
    get_access_token(req.query.code)
    --
    return {
        body = "thank! You can now continue in Sandman"
    }
end)

```

## After this block, open this url

http://localhost:4000/authentication/oidc/auth?client_id=foo&redirect_uri=http://localhost:8080/cb&response_type=code&scope=openid&state=abc123&nonce=xyz789

```lua
print(sandman.document.get('access_token'))
print(sandman.document.get('id_token'))
form_data = "token=" .. sandman.document.get('access_token') ..     
    "&client_id=foo&client_secret=bar" 
token_info = http.post(oidc_path .. "/token/introspection",
{
    ["content-type"] = "application/x-www-form-urlencoded"
}, form_data)
print(token_info)
```
