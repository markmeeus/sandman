```lua
invalid = "invalid"
if  pcall(function() 
    res = sandman.base64.decode(invalid)    
end) then
    print("res", res)
else
    print("invalid")
end

base64 = sandman.base64.encode("Hello, World!")

print(base64)
print(sandman.base64.decode(base64))

```

```lua
print(sandman.base64.encode_url("??"))
print(sandman.base64.encode("??"))

print(
    sandman.base64.decode_url("SGVsbG8sIFdvcmxkIQ")
)
invalid = "invalid:"
if  pcall(function() 
    res = sandman.base64.decode_uel(invalid)    
end) then
    print("res", res)
else
    print("invalid")
end

base64 = sandman.base64.encode_url("Hello, World!")

print(base64)
print(sandman.base64.decode_url(base64))

```
