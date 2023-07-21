# Uri test script

```lua
uri = sandman.uri.parse("https://mark@server.com:1234/test/path?qry=1&param=2")
print("host:" .. uri.host)
print("path:" .. uri.path)
print("port:" .. uri.port)
print("query.qry:" .. uri.query.qry)
print("query.param:" .. uri.query.param)
print("queryString:" .. uri.queryString)
print("scheme:" .. uri.scheme)
print("userinfo:" .. uri.userinfo)
```
