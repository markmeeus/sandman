```lua
oidc_path =  "http://localhost:4000/authentication/oidc"

i = 0
while(i < 1000) do
    sandman.http.get(oidc_path .. "/.well-known/openid-configuration")
    i = i+1
end
```
