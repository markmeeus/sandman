```lua
server = sandman.server.start(3456)
sandman.server.get(server, '/', function(req) 
    sandman.document.set("mytable", {var = "from request"})
end)
```

```lua
sandman.document.set("mystr", "hello")
sandman.document.set("mybool", true)
sandman.document.set("mynumber", 12.3)
sandman.document.set("mytable", {var = "ola"})

```

```lua
print(sandman.document.get("mystr"))
print(sandman.document.get("mybool"))
print(sandman.document.get("mynumber"))
print(sandman.document.get("mytable"))

```
