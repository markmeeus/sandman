```lua
-- Test JWT functionality with unsigned tokens
print("Testing JWT functionality...")

-- Test 1: Create an unsigned token (no secret)
payload = {
  sub = "1234567890",
  name = "John Doe",
  iat = 1516239022
}

print("Creating unsigned JWT token...")
unsigned_token = sandman.jwt.sign(payload)
print("Unsigned token:", unsigned_token)

-- Test 2: Verify the unsigned token
print("Verifying unsigned token...")
is_valid, claims = sandman.jwt.verify(unsigned_token)
print("Is valid:", is_valid)
if claims then
  print("Claims:", sandman.json.encode(claims))
end
```

```lua
-- Test 3: Create a signed token with secret
secret = "my-secret-key"
payload2 = {
  sub = "9876543210",
  name = "Jane Doe",
  iat = 1516239022
}

print("Creating signed JWT token...")
signed_token = sandman.jwt.sign(payload2, secret)
print("Signed token:", signed_token)

-- Test 4: Verify the signed token
print("Verifying signed token...")
is_valid2, claims2 = sandman.jwt.verify(signed_token, secret)
print("Is valid:", is_valid2)
if claims2 then
  print("Claims:", sandman.json.encode(claims2))
end
```

```lua
-- Test 5: Test with explicit algorithm
payload3 = {
  sub = "1111111111",
  name = "Test User",
  iat = 1516239022
}

print("Creating token with explicit 'none' algorithm...")
options = { alg = "none" }
none_token = sandman.jwt.sign(payload3, nil, options)
print("None algorithm token:", none_token)

-- Verify it
print("Verifying 'none' algorithm token...")
is_valid3, result3 = sandman.jwt.verify(none_token)
print("Is valid:", is_valid3)
if is_valid3 then
  print("Claims:", sandman.json.encode(result3))
else
  print("Error:", result3)
end
```

```lua
-- Test 6: Test error cases
print("Testing error cases...")

-- Invalid token format
print("Testing invalid token format...")
is_valid4, error4 = sandman.jwt.verify("invalid.token")
print("Is valid:", is_valid4)
print("Error:", error4)

-- Wrong secret
print("Testing wrong secret...")
signed_token_copy = signed_token  -- from previous block
is_valid5, error5 = sandman.jwt.verify(signed_token_copy, "wrong-secret")
print("Is valid:", is_valid5)
print("Error:", error5)

-- Corrupted token
print("Testing corrupted token...")
corrupted = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.corrupted.signature"
is_valid6, error6 = sandman.jwt.verify(corrupted, "secret")
print("Is valid:", is_valid6)
print("Error:", error6)
```
