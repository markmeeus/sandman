```lua
print("test")


```

# hola pola
1. test
2. test

Dit is een text


```lua
s = sandman.server.start(7011)
counter = 1
req_count = 0
sandman.server.get(s, '/test', function()   
  req_count = req_count + 1
  print("handling request in lua")
  while(counter < 1000000) do
    counter = counter + 1    
  end
  return({body="ola" .. req_count})
end)

```

```lua
res = sandman.http.get("http://localhost:7011/test")
print(res)
```

```lua
uri = sandman.uri
res = sandman.http.get("https://jsonplaceholder.typicode.com/posts/1")
res = sandman.http.post("https://jsonplaceholder.typicode.com/posts/1")
function ola()
    
end
```

```lua
 a={1,2,3}
```

```lua
ola()
-- parsing url
url = uri.parse(
    "http://localhost:7000/?file=/Users/markmeeus/Documents/projects/github/sandman/test_scripts/test.md"
)
print(uri.tostring(url))


--calling
bla = "ftp://s-ite.tld/?value=put it+й"
encoded = uri.encode(bla)
encodedComp = uri.encodeComponent(bla)
print("enc    :", encoded)
print("encComp:", encodedComp)
print("dec    :", uri.decode(encoded))
print("decComp:", uri.decodeComponent(encodedComp))
```

```lua
server, err = sandman.server.start(7010)
print("started server", server, error)
sandman.server.post(server, "/pad", function(request)
  print(request)
  return {body = "res" .. request.body}
end)

```

```lua
function postBack()
  res = sandman.http.post("http://localhost:7010/pad", {testHeader="testVal"}, 
sandman.json.encode({table="some data"}))
print(res)
end
```

```lua
postBack()
-- Fetch JSON data from a public API (JSONPlaceholder)

res = sandman.http.get("https://jsonplaceholder.typicode.com/posts/1")


json = sandman.json.decode(res.body)
print(json, "\n", res.body)
print("title: => " .. json.title)
recode = sandman.json.encode(json)
-- print(recode)
rejson = sandman.json.decode(recode)
print("title: => " .. rejson.title)
```

```lua
encoded = uri.encode("https://nel.heroku.com/reports?s=VjJpH3PAuNrz6amXKRk4LtjkHFwIK0TVjVOukNsYOpE%3D\\u0026sid=e11707d5-02a7-43ef-b45e-2cf4d2036f7d\\u0026ts=1753315135")
print(encoded)
sandman.http.get(encoded)
```
