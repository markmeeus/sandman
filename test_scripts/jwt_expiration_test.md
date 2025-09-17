```lua
-- Test JWT expiration validation
print("Testing JWT expiration validation...")

-- Create a token that expires in the past
current_time = os.time()
expired_payload = {
  sub = "1234567890",
  name = "John Doe",
  exp = current_time - 3600,  -- Expired 1 hour ago
  iat = current_time - 7200   -- Issued 2 hours ago
}

print("Creating expired token...")
expired_token = sandman.jwt.sign(expired_payload, "secret")
print("Expired token:", expired_token)

-- Try to verify the expired token
print("Verifying expired token...")
is_valid, result = sandman.jwt.verify(expired_token, "secret")
print("Is valid:", is_valid)
print("Result:", result)
```

```lua
-- Test with unsigned expired token
print("Testing unsigned expired token...")

unsigned_expired_payload = {
  sub = "9876543210",
  name = "Jane Doe",
  exp = os.time() - 1800,  -- Expired 30 minutes ago
  iat = os.time() - 3600   -- Issued 1 hour ago
}

print("Creating unsigned expired token...")
unsigned_expired_token = sandman.jwt.sign(unsigned_expired_payload)
print("Unsigned expired token:", unsigned_expired_token)

-- Try to verify the unsigned expired token
print("Verifying unsigned expired token...")
is_valid2, result2 = sandman.jwt.verify(unsigned_expired_token)
print("Is valid:", is_valid2)
print("Result:", result2)
```

```lua
-- Test with future token (not yet valid)
print("Testing future token...")

future_payload = {
  sub = "1111111111",
  name = "Future User",
  nbf = os.time() + 3600,  -- Not valid for another hour
  iat = os.time()
}

print("Creating future token...")
future_token = sandman.jwt.sign(future_payload)
print("Future token:", future_token)

-- Try to verify the future token
print("Verifying future token...")
is_valid3, result3 = sandman.jwt.verify(future_token)
print("Is valid:", is_valid3)
print("Result:", result3)
```

```lua
-- Test with valid token (should work)
print("Testing valid token...")

valid_payload = {
  sub = "5555555555",
  name = "Valid User",
  exp = os.time() + 3600,  -- Expires in 1 hour
  iat = os.time(),         -- Issued now
  nbf = os.time() - 60     -- Valid since 1 minute ago
}

print("Creating valid token...")
valid_token = sandman.jwt.sign(valid_payload, "secret")
print("Valid token:", valid_token)

-- Verify the valid token
print("Verifying valid token...")
is_valid4, result4 = sandman.jwt.verify(valid_token, "secret")
print("Is valid:", is_valid4)
if is_valid4 then
  print("Claims:", sandman.json.encode(result4))
else
  print("Error:", result4)
end
```
