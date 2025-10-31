# Sandman

![alt text](<external/icons/Rounded 128.png>)

**Executable notebooks for HTTP APIs**

Sandman combines Postman, Jupyter Notebooks, and Lua into a single tool. You can create executable notebooks with Lua code blocks and Markdown documentation—optimized for HTTP client and server workflows with full request/response inspection. Everything lives in plain Markdown files, making it perfect for version control.

Sandman is currently a desktop tool, everything runs on your machine. I have plans to add a cli so that Sandman could be automated, to run your markdown files as tests in a CI tool for instance.

## Immutable Blocks
Blocks in Sandman build upon the state of the previous block. Each block can add to or modify the state, but cannot change what previous blocks have already established. This creates a unidirectional flow: you can freely iterate on a block until you're satisfied, then move on to the next one—confident that earlier blocks won't break.

This design means you can develop longer workflows incrementally. Earlier blocks remain stable while you experiment with later ones, ensuring your entire workflow stays intact as you build it out.

## Use Cases

- **Living Documentation** - Document endpoints with working examples
- **API Testing** - Create test suites that double as documentation
- **Workflow Testing** - Test multi-step API flows with real state
- **API Mocking** - Spin up mock servers to replace external dependencies
- **Integration Testing** - Test webhook receivers and API clients together
- **Onboarding** - New team members run notebooks to learn the API
- **Exploration** - Experiment with third-party APIs interactively

![Sandman Screenshot](screenshot.jpg)

## Getting Started

### Download

Download the latest version of Sandman for macOS from [GitHub Releases](https://github.com/markmeeus/sandman/releases/).

**Requirements:**
- macOS (Apple Silicon only for now)
- No other dependencies needed

### Quick Start

1. **Download and Install**
   - Download `Sandman-{version}-silicon.dmg` from the [releases page](https://github.com/markmeeus/sandman/releases/)
   - Double click and drag `sandman` app to your Applications folder
   - Open Sandman

2. **Create Your First Notebook**
   - Open a folder in Sandman
   - Create a new `.md` file (e.g., `my-first-test.md`)
   - Add a Lua code block with some executable code
   - Run it with `CTRL + Enter` or click the Run button

3. **Start Building**
   - Mix Markdown documentation with executable Lua code
   - Chain requests together with shared state
   - iterate and inspect your requests in the inspector
   - Commit your notebooks to git like any other file

See the complete [documentation](https://sandmanapp.com) for API reference and advanced usage.

### Key Features

- 📝 **Executable Documentation** - Your docs and tests are the same file. If it runs, it's correct.
- 🔄 **Stateful Workflows** - Each code block builds on previous blocks' state. Chain requests together naturally.
- 🌐 **Client & Server** - Make HTTP requests *and* create HTTP endpoints in the same notebook.
- 📊 **Request Inspection** - Every HTTP request and response is automatically captured and inspectable.
- 📦 **Git-Native** - Plain Markdown files with executable Lua blocks. Perfect for version control.
- 🖥️ **Desktop App** - Interactive app for macOS (Windows & Linux coming soon).

## Sandbox
Sandman code runs in an application level sandbox. This means that all code you write is parsed and executed by Sandman code (thanks to Robert Virding and his great [Luerl](https://github.com/rvirding/luerl) library).
All OS access has been disabled, so that Sandman files can't access anything sensitive.
This means that a Sandman file is quite safe to run, the only way it can break out of the sandbox is with HTTP traffic.

## Navigating with Shortcuts
You can navigate Sandman with shortcuts (more to come)

### left panel:
* **OPTION + 1** : Inspector
* **OPTION + 2** : Log
* **OPTION + 3** : Docs

### right panel
The right panel can be in one of 2 modes: moving or editing. You can switch from moving to editing with ENTER and back with ESC

### right panel moving state
* **ENTER** : enter edit mode in the current block
* **up/down** : select next previous block
* **CTRL + ENTER** : run current block
* **CTRL + SHIFT + ENTER** : run current block and move to next block
* **CMD + SHIFT + ENTER** : run all blocks

### right panel editing state
* **ESC** : exit edit mode back into move mode

## out-of-flow variables
If one of your blocks is time-depentent, a token that times out for instance, you should be able to run the previous blocks and end up with a similar functioning state.

In the rare case rerunning isn't possible - when working with webhooks for instance - you can store data at document level with `sandman.document.get`' and `sandman.document.set`. But beware that using these breaks your unidirectional flow.

## Quick Examples

### Making HTTP Requests

```lua
-- Fetch data from an API
response = sandman.http.get("https://api.github.com/users/octocat")
print("Status:", response.status)

-- Parse JSON response
user = sandman.json.decode(response.body)
print("Username:", user.login)
print("Repos:", user.public_repos)

-- Use data from previous block in next request
repos_response = sandman.http.get(user.repos_url)
repos = sandman.json.decode(repos_response.body)
print("Found", #repos, "repositories")
```

### Creating HTTP Endpoints

```lua
-- Start a local HTTP server
server = sandman.server.start(8080)

-- Add a GET endpoint
sandman.server.get(server, "/hello", function(request)
    return {
        body = "Hello, " .. (request.query.name or "World") .. "!"
    }
end)

-- Add a POST endpoint
sandman.server.post(server, "/api/users", function(request)
    local data = sandman.json.decode(request.body)
    return {
        status = 201,
        body = sandman.json.encode({
            message = "User created",
            user = data
        })
    }
end)

print("Server running on http://localhost:8080")
```

### Testing Webhooks

```lua
-- Set up a webhook receiver
server = sandman.server.start(7010)

webhook_data = nil
sandman.server.post(server, "/webhook", function(request)
    webhook_data = sandman.json.decode(request.body)
    print("Received webhook:", webhook_data)
    return {body = "ok"}
end)
```

In another block, trigger the webhook
```lua
response = sandman.http.post("http://localhost:7010/webhook",
    {["Content-Type"] = "application/json"},
    sandman.json.encode({event = "test", timestamp = os.time()})
)

-- Verify the webhook was received
print("Webhook data:", webhook_data)
```

### Complete API Workflow

```lua
-- Authenticate
auth_response = sandman.http.post("https://api.example.com/auth/login",
    {["Content-Type"] = "application/json"},
    sandman.json.encode({
        email = "user@example.com",
        password = "secret"
    })
)

auth_data = sandman.json.decode(auth_response.body)
token = auth_data.token

-- Use token in subsequent requests
user_response = sandman.http.get("https://api.example.com/user/profile",
    {["Authorization"] = "Bearer " .. token}
)

profile = sandman.json.decode(user_response.body)
print("Logged in as:", profile.name)

-- Update profile
update_response = sandman.http.put("https://api.example.com/user/profile",
    {
        ["Authorization"] = "Bearer " .. token,
        ["Content-Type"] = "application/json"
    },
    sandman.json.encode({bio = "Updated from Sandman!"})
)
```

## Environment Variables
At some point you may want to share your sandman files with others. But you probably want to separate passwords and secrets from the code. Sandman supports reading environment variable with the restriction that they should be prefixed with 'SANDMAN'. (see sandbox)

Sandman will also look for a file with that same name as your markdown file, but ending in .env where you can define or override environment variable of your system.

Then in code:
```lua
password = sandman.getenv("SANDMAN_MY_PASSWORD")
```

## global vs local variables
Global variables defined in a block are visible to the next blocks, local variables aren't. In Lua variables are global by default, so you can just declare variables like this:

```lua
visible_in_next_block = "hello from previous block"
local hidden_from_next_block = "nothing to see here"
```

## Building from Source
Sandman has 2 components, a backend written in Elixir and a frontend for each platform (currently only macos).
If you want to run Sandman from code, you would need to start the backend and frontend separately.
In this mode, the backend will listen to port 7000. Running the frontend in debug mode, it will try to connect to this port.

### Running the backend
Make sure you have the correct Elixir and Erlang versions installed (see .tool-versions)
1. Checkout source code
2. `mix deps.get` in the root of the project

Now you can start the backend with
* `mix phx.server`

Most of the functionality happens in the backend, exposed via a web endpoint. So once your backend is running, you can open a file by opening [http://localhost:7000/?file=<absolute_path_to_a_markdown_file>](http://localhost:7000/?file=/absolute/path/to/file)

### Running the frontend
If you also want to run the frontend from code, you should have XCode installed. The frontend code can be found in the frontend folder. You should be able to just open the project and run it. It should connect to the port 7000.

## Project Status

Sandman is in **active beta development**. It's functional and already useful for real work, but:

- ✅ **Working**: HTTP client, HTTP server, JSON/Base64/JWT utilities, notebook execution, request inspection
- 🚧 **In Progress**: CLI version, improved error handling, better code editor, more comprehensive docs
- 📋 **Planned**: Windows & Linux support, CLI/CI/CD integration, Plugin system, Interactive Document UI components

Bug reports, feature requests, and contributions are more than welcome!

## Contributing

Contributions are welcome! Whether it's:
- 🐛 Bug reports
- 💡 Feature requests
- 📖 Documentation improvements
- 🔧 Code contributions

Please open an issue or pull request on GitHub.

## License

[See LICENSE file for details]

Made with ❤️ by developers tired of API docs that lie
