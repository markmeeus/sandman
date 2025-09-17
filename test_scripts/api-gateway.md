```lua
http = sandman.http
a = {[1]="a", [2]="b"}
print(a)
```

```lua
clientId = "ec87cb9d0f656ebbfc3455205c593ea9001a104b6bcfc448"
secret = "6eda393c54df6d985a284446340815d820c17811e7b27ed44c73d632206bc77562f8d712b1915901ac46f25e7faf4219ffa630697fcd8588a23ef3bf480311ff5dda4e11afab2c0e84d62bc5fbadfa7a6ef80cf297e592c9471b08197ed7deb9e11ff788cccab96cc5a812063c4eca015bcf3f2a3cb5000276b1e28a2783099e6520fdf4fc55ce05f36bd56b1061512e1b8f8f427ba7d32bee7362c6b57ef2288cd3bf69707f3d8367b88536503b4ba6befaaf4bab87a7668f15f786ccdd41f19f7eadda303ccda9596f1c948583b7620fefe78131c3054e5b5781afbad868c82bbe5d9b1d339e31db606f6b0ad21ddf83a0fbf98e2c334f24960caa0420dd82"

body = "client_id=" .. clientId .. "&client_secret=" .. secret .. "&grant_type=client_credentials"

headers = {
    ["Content-Type"]="application/x-www-form-urlencoded",
    accept="*/*",
    ["content-length"]=string.len(body),
    ["user-agent"]= "curl/8.7.1"
}

res = http.post("https://apigateway-dev.apps.nprod.focus/api-gateway/token",headers, body)
--http.post("https://focus-d.politie.antwerpen.be/api-gateway/token",headers, body)

server = sandman.server.start(7596)
sandman.server.get(server, 'json', function(req) 
  return {    
    body = "no jsoan"
  }
end)
```

```lua
print(sandman.http.get('http://localhost:7596/json').json())
print(res.json().expires_in)
print(res:json().expires_in)
```

```lua
print(res.body)
```

```lua
token = sandman.json.decode(res.body)
--print(token.access_token)
ok, decoded_token = sandman.jwt.verify(token.access_token, "gcK458gU84zPwHhBIwVJf1AmqbWAYAjcg5i0bxdX164")
print(ok, decoded_token)
print( decoded_token)
```

```lua
-- Find positions of the first and second dot
local first_dot = token.access_token:find("%.")
local second_dot = token.access_token:find("%.", first_dot + 1)

-- Extract the substring between them
local payload = token.access_token:sub(first_dot + 1, second_dot - 1)

payload_decoded = 
sandman.json.decode(sandman.base64.decode(payload))
print(payload_decoded)
print("got token with these scopes:")
for i, scope in ipairs(payload_decoded.scopes) do
  print(scope)
end


```
