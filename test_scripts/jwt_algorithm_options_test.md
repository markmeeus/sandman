```lua
-- Test JWT algorithm options and fail-fast behavior
print("Testing JWT algorithm options...")

-- Create a token with HS256
payload = {
  sub = "1234567890",
  name = "John Doe",
  exp = os.time() + 3600,  -- Expires in 1 hour
  iat = os.time()
}

print("Creating HS256 token...")
token = sandman.jwt.sign(payload, "secret", "HS256")
print("Token:", token)
```

```lua
-- Test 1: Verify with correct algorithm (should succeed)
print("Test 1: Verifying with correct algorithm HS256...")
is_valid, result = sandman.jwt.verify(token, "secret", {algs = "HS256"})
print("Is valid:", is_valid)
if is_valid then
  print("Claims:", sandman.json.encode(result))
else
  print("Error:", result)
end
```

```lua
-- Test 2: Verify with wrong algorithm (should fail fast)
print("Test 2: Verifying with wrong algorithm HS512...")
is_valid2, result2 = sandman.jwt.verify(token, "secret", {algs = "HS512"})
print("Is valid:", is_valid2)
print("Error:", result2)
```

```lua
-- Test 3: Verify with multiple algorithms including correct one
print("Test 3: Verifying with multiple algorithms [HS384, HS256]...")
is_valid3, result3 = sandman.jwt.verify(token, "secret", {algs = {"HS384", "HS256"}})
print("Is valid:", is_valid3)
if is_valid3 then
  print("Claims:", sandman.json.encode(result3))
else
  print("Error:", result3)
end
```

```lua
-- Test 4: Verify with multiple wrong algorithms (should fail on first)
print("Test 4: Verifying with multiple wrong algorithms [HS384, HS512]...")
is_valid4, result4 = sandman.jwt.verify(token, "secret", {algs = {"HS384", "HS512"}})
print("Is valid:", is_valid4)
print("Error (should fail on HS384):", result4)
```

```lua
-- Test 5: Verify without algorithm options (should try defaults and succeed)
print("Test 5: Verifying without algorithm options (default behavior)...")
is_valid5, result5 = sandman.jwt.verify(token, "secret")
print("Is valid:", is_valid5)
if is_valid5 then
  print("Claims:", sandman.json.encode(result5))
else
  print("Error:", result5)
end
```

```lua
-- Test 6: Test with invalid algorithm name (should show algorithm name in error)
print("Test 6: Verifying with invalid algorithm...")
is_valid6, result6 = sandman.jwt.verify(token, "secret", {algs = "INVALID_ALG"})
print("Is valid:", is_valid6)
print("Error (should include algorithm name):", result6)
```

```lua
-- Test 7: Create and verify RS256 token (should fail with HMAC secret)
print("Test 7: Testing RSA algorithm error handling...")
-- This will fail because we're using HMAC secret for RSA algorithm
is_valid7, result7 = sandman.jwt.verify(token, "secret", {algs = "RS256"})
print("Is valid:", is_valid7)
print("Error (should include RS256):", result7)
```

```lua
-- Test 8: Test multiple invalid algorithms (should fail on first one)
print("Test 8: Testing multiple invalid algorithms...")
is_valid8, result8 = sandman.jwt.verify(token, "secret", {algs = {"INVALID1", "INVALID2"}})
print("Is valid:", is_valid8)
print("Error (should fail on INVALID1):", result8)
```

```lua
-- Test 9: Test nil token (should immediately return false)
print("Test 9: Testing nil token...")
is_valid9, result9 = sandman.jwt.verify(nil, "secret")
print("Is valid:", is_valid9)
print("Error:", result9)
```
