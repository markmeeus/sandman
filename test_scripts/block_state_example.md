```lua
-- This block should start with state :empty
-- When run, it will go to :running, then :executed
print("Block 1: Hello from the first block!")
x = 42
```

```lua
-- This block depends on the previous one
-- It should also follow the state transitions
print("Block 2: The value from previous block is:", x)
local y = x * 2
print("Block 2: Calculated value:", y)
```

```lua
-- This block will cause an error to demonstrate :errored state
print("Block 3: This will cause an error...")
--error("Intentional error to test error state")
```

```lua
-- This block should work fine if run after a successful block
print("Block 4: This should work fine")
print("Block 4: Current time:", os.time())
```
