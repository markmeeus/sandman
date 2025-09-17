```lua
ref = sandman.server.start(7010)
server = {
    get = function(path, handler)
        sandman.server.get(ref, path, handler)
    end
}
sandman.client = sandman.http
```

```lua
counter =1
--sandman.server.get(server, "/test", function(request) 
--    counter = counter + 1    
--    print(request)
--    return {body= "counter:" .. counter}
--end)
print(server)

server.get('/test', function(req)
    return {body="new server"}
end)
```

```lua

```

```lua
print(counter)
res = sandman.http.get('http://localhost:7010/test')
res = sandman.client.get('http://localhost:7010/test')
print(res.body)
```
