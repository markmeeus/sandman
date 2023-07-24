# Testing json support

```lua
jsonString = '{"this": "json", "anArray": [1,2,3]}'
decoded = sandman.json.decode(jsonString)
print("is it " .. decoded.this .. "? " .. "Array has " .. #decoded.anArray .. " elements.")
print(sandman.json.encode(decoded))
```