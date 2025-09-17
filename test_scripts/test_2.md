```lua
get = sandman.http.get
payload = {
  sub = "user:42",  
}
payload.iat = math.floor(os.time())
payload.exp = payload.iat + 1
jwt = sandman.jwt.sign(payload, "A_SECRET", {alg="HS512"})
print(jwt, reason)

verified, claims = sandman.jwt.verify(jwt, "A_SECRET", {algs={"HS512", "HS512"}})
print(verified, claims)

--[[
verified, claims = sandman.jwt.verify(
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NTc0NDczNTIsImlhdCI6MTc1NzQ0NzM1MSwic3ViIjoidXNlcjo0MiJ9.vhxZNoDZGtGqz3S-HeaL2nQhzD-NGS06DDMiimjTxws",
  "A_SECRET")
print(verified, claims)
  ]]

```

```lua
get('https://apigateway-dev.apps.nprod.focus/api/5345/test',
{
    Authorization= "Bearer test-token"
})
```
