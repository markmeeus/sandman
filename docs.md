ff alle lua api's  opschrijven
TODO : wil zeggen, luerl encode/decode nog ff na te kijken

luerlmapper:

    "print" > OK

```
  print("a", {table="kan ook"})
```

```
    sandman.server.start(7010)
    sandman.server.post(server, "/pad", function(request)
      print(request)
      return {body = "res" .. request.body}
    end)
````
```
res = sandman.http.post("http://localhost:7010/pad", {header="value"}, sandman.json.encode({table="teste"}))
```

    sandman.http (get post put delete patch head) ok (response reeds klaar denk ik)
    sandman http.send OK


  ```
url = sandman.uri.parse("http://localhost:7000/?file=/Users/markmeeus/Documents/projects/github/sandman/test_scripts/test.md")
print(sandman.uri.tostring(url))

weirdo = "ftp://s-ite.tld/?value=put it+й"
encoded = sandman.uri.encode(weirdo)
encodedComp = sandman.uri.encodeComponent(weirdo)
print("enc    :", encoded)
print("encComp:", encodedComp)
print("dec    :", sandman.uri.decode(encoded))
print("decComp:", sandman.uri.decodeComponent(encodedComp))
  ```

    sandman.uri.parse ok
    sandman.uri.tostring ok
    sandman.uri.encode ok
    sandman.uri.decode ok
    sandman.uri.encodeComponent ok
    sandman.uri.decodeComponent ok

    sandman.json.encode OK
    sandman.json.decode OK
