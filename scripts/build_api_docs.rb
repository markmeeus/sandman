#!/usr/bin/env ruby

require 'json'
require 'fileutils'

class ApiDocGenerator
  def initialize
    @api_definitions_file = File.join(__dir__, '..', 'priv', 'api_definitions.json')
    @docs_dir = File.join(__dir__, '..', '..', 'sandman-docs', 'docs', '_docs')

    unless File.exist?(@api_definitions_file)
      puts "❌ API definitions file not found: #{@api_definitions_file}"
      exit 1
    end

    @definitions = JSON.parse(File.read(@api_definitions_file))
  end

  def generate_all_docs
    puts "🚀 Generating API documentation from #{@api_definitions_file}"

    # Ensure docs directory exists
    FileUtils.mkdir_p(@docs_dir)

    # Generate main API overview page
    generate_api_overview

    # Generate individual module pages
    generate_global_docs
    generate_module_docs('http', 'HTTP Client')
    generate_module_docs('server', 'HTTP Server')
    generate_module_docs('document', 'Document Context')
    generate_module_docs('json', 'JSON Utilities')
    generate_module_docs('base64', 'Base64 Utilities')
    generate_module_docs('jwt', 'JWT Utilities')
    generate_module_docs('uri', 'URI Utilities')

    puts "✅ API documentation generated successfully!"
    puts "📄 Generated files:"
    Dir.glob(File.join(@docs_dir, 'api*.md')).sort.each do |file|
      puts "   - #{File.basename(file)}"
    end
  end

  private

  def generate_api_overview
    content = <<~MARKDOWN
      ---
      layout: docs
      title: "Sandman Lua API"
      description: "Complete reference for all Lua functions available in Sandman. These functions provide HTTP client/server capabilities, data encoding/decoding, and utility functions for your scripts."
      permalink: /docs/api/
      nav_order: 2
      has_children: true
      ---

      # Sandman Lua API Overview

      Sandman provides a comprehensive Lua API for HTTP scripting, data manipulation, and server creation. The API is organized into several modules, each focused on specific functionality.

      ## API Modules

      ### [Global Functions](/docs/api-global/)
      Core functions available globally without any module prefix:
      #{generate_function_list(@definitions.reject { |k, _| k == 'sandman' })}

      #{generate_sandman_modules_overview}

      ## Quick Start Example

      Here's a simple example that demonstrates several API modules:

      ```lua
      -- Start an HTTP server
      sandman.server.start({port = 8080})

      -- Create a simple API endpoint
      sandman.server.get("/api/hello", function(req)
          local response_data = {
              message = "Hello, World!",
              timestamp = os.time(),
              user_agent = req.headers["user-agent"]
          }

          return {
              status = 200,
              headers = {["Content-Type"] = "application/json"},
              body = sandman.json.encode(response_data)
          }
      end)

      -- Make an HTTP request to external API
      local response = sandman.http.get("https://api.github.com/users/octocat")
      if response.status == 200 then
          local user_data = sandman.json.decode(response.body)
          print("GitHub user:", user_data.login)

          -- Store in document context
          sandman.document.set("github_user", user_data)
      end
      ```

      ## Error Handling

      Many API functions have "try" variants that return success/failure status instead of throwing errors:

      ```lua
      -- Safe JSON decoding
      local success, result = sandman.json.try_decode(untrusted_json)
      if success then
          print("Parsed JSON:", result)
      else
          print("JSON error:", result)
      end

      -- Safe JWT verification
      local valid, payload = sandman.jwt.try_verify(token, secret)
      if valid then
          print("User ID:", payload.user_id)
      else
          print("Invalid token:", payload)
      end
      ```

      Browse the individual module pages for detailed documentation, examples, and use cases.
    MARKDOWN

    File.write(File.join(@docs_dir, 'api.md'), content)
  end

  def generate_sandman_modules_overview
    return "" unless @definitions['sandman']

    sandman_modules = @definitions['sandman'].reject { |k, _| k == 'type' }

    sandman_modules.map do |module_name, module_def|
      title = module_title(module_name)
      description = module_description(module_name)
      functions = extract_functions(module_def)

      "### [#{title}](/docs/api-#{module_name}/)\n#{description}\n#{generate_function_list(functions, module_name)}\n"
    end.join("\n")
  end

  def generate_global_docs
    global_functions = @definitions.reject { |k, _| k == 'sandman' }

    content = <<~MARKDOWN
      ---
      layout: docs
      title: "Global Functions"
      permalink: /docs/api-global/
      nav_order: 2
      parent: "Sandman Lua API"
      ---

      # Global Functions

      These functions are available globally in the Lua environment without any prefix.

      #{generate_function_index(global_functions)}

      #{generate_functions_documentation(global_functions)}
    MARKDOWN

    File.write(File.join(@docs_dir, 'api-global.md'), content)
  end

  def generate_module_docs(module_name, title)
    return unless @definitions['sandman'] && @definitions['sandman'][module_name]

    module_def = @definitions['sandman'][module_name]
    functions = extract_functions(module_def)

    nav_order = case module_name
    when 'http' then 3
    when 'server' then 4
    when 'document' then 5
    when 'json' then 6
    when 'base64' then 7
    when 'jwt' then 8
    when 'uri' then 9
    else 10
    end

    content = <<~MARKDOWN
      ---
      layout: docs
      title: "#{title}"
      permalink: /docs/api-#{module_name}/
      nav_order: #{nav_order}
      parent: "Sandman Lua API"
      ---

      # #{title}

      #{module_description(module_name)}

      #{generate_function_index(functions, "sandman.#{module_name}")}

      #{generate_functions_documentation(functions, "sandman.#{module_name}")}
    MARKDOWN

    File.write(File.join(@docs_dir, "api-#{module_name}.md"), content)
  end

  def extract_functions(module_def)
    return {} unless module_def.is_a?(Hash)

    module_def.reject { |k, _| k == 'type' }
  end

  def generate_function_index(functions, prefix = nil)
    return "" if functions.empty?

    function_links = functions.map do |func_name, func_def|
      next unless func_def['type'] == 'function'

      full_name = prefix ? "#{prefix}.#{func_name}" : func_name
      anchor = full_name.downcase.gsub('.', '')
      display_name = if func_def['has_try']
                       full_name.sub(/\.([^.]+)$/, '.try_\\1')
                     else
                       full_name
                     end

      "- [`#{display_name}()`](##{anchor}) - #{func_def['description']}"
    end.compact

    return "" if function_links.empty?

    "## Functions\n\n#{function_links.join("\n")}\n"
  end

  def generate_functions_documentation(functions, prefix = nil)
    functions.map do |func_name, func_def|
      next unless func_def['type'] == 'function'

      full_name = prefix ? "#{prefix}.#{func_name}" : func_name
      generate_function_doc(full_name, func_def)
    end.compact.join("\n\n")
  end

  def generate_function_doc(func_name, func_def)
    anchor = func_name.downcase.gsub('.', '')
    display_name = if func_def['has_try']
                     func_name.sub(/\.([^.]+)$/, '.try_\\1')
                   else
                     func_name
                   end
    content = "## #{display_name} {##{anchor}}\n\n"
    content += "**Type:** Function  \n"
    content += "**Description:** #{func_def['description']}\n"

    if func_def['has_try']
      try_func_name = func_name.sub(/\.([^.]+)$/, '.try_\\1')
      content += "\n**⚠️ Note:** This function can throw errors. A `#{try_func_name}` alternative is available that returns `result_or_nil, error` instead of throwing.\n"
    end

    content += "\n### Usage\n\n"
    content += generate_usage_example(func_name, func_def)

    if func_def['schema']
      content += generate_schema_documentation(func_def['schema'])
    end

    content += generate_basic_example(func_name, func_def)

    content
  end

  def generate_usage_example(func_name, func_def)
    if func_def['schema'] && func_def['schema']['params']
      params = func_def['schema']['params']
      if params.is_a?(Array)
        # Generate parameter values using example_values or param names
        param_values = params.map do |p|
          param_name = p['name'] || 'param'
          if func_def['example_values'] && func_def['example_values'][param_name]
            func_def['example_values'][param_name]
          else
            param_name
          end
        end
        "```lua\n#{generate_function_call(func_name, param_values, func_def)}\n```\n"
      else
        "```lua\n#{generate_function_call(func_name, ['...'], func_def)}\n```\n"
      end
    else
      "```lua\n#{generate_function_call(func_name, ['...'], func_def)}\n```\n"
    end
  end

  def generate_function_call(func_name, params, func_def = nil)
    # Get return value name from schema if available
    return_name = if func_def && func_def['schema'] && func_def['schema']['ret_vals'] && func_def['schema']['ret_vals'].first
                    func_def['schema']['ret_vals'].first['name'] || 'result'
                  else
                    'result'
                  end

    if func_name.include?('.')
      # Module function
      if params.any?
        "#{return_name} = #{func_name}(#{params.join(', ')})"
      else
        "#{func_name}()"
      end
    else
      # Global function
      if params.any?
        "#{func_name}(#{params.join(', ')})"
      else
        "#{func_name}()"
      end
    end
  end

  def generate_schema_documentation(schema)
    content = ""

    if schema['params'] && schema['params'].is_a?(Array)
      content += "\n### Parameters\n\n"
      schema['params'].each do |param|
        content += "- **#{param['name']}: #{param['type']}**\n"
      end
    end

    if schema['ret_vals'] && schema['ret_vals'].is_a?(Array) && !schema['ret_vals'].empty?
      content += "\n### Returns\n\n"
      schema['ret_vals'].each do |ret_val|
        content += "- **#{ret_val['name'] || 'result'}: #{ret_val['type']}**\n"
      end
    end

    content
  end

  def generate_basic_example(func_name, func_def)
    example_content = "-- Basic usage\n#{generate_example_call(func_name, func_def)}"

    if func_def['has_try']
      # Get return value name for the comment and error handling
      return_name = if func_def['schema'] && func_def['schema']['ret_vals'] && func_def['schema']['ret_vals'].first
                      func_def['schema']['ret_vals'].first['name'] || 'result'
                    else
                      'result'
                    end

      try_example = generate_try_example_call(func_name, func_def)
      example_content += "\n\n-- Safe alternative (returns #{return_name}_or_nil, error):\n#{try_example}"
      example_content += "\nif #{return_name}_or_nil then\n  -- Use #{return_name}_or_nil\nelse\n  -- Handle the error\nend"
    end

    "\n### Examples\n\n```lua\n#{example_content}\n```\n"
  end

  def generate_example_call(func_name, func_def)
    # Get return value name from schema if available
    return_name = if func_def['schema'] && func_def['schema']['ret_vals'] && func_def['schema']['ret_vals'].first
                    func_def['schema']['ret_vals'].first['name'] || 'result'
                  else
                    'result'
                  end

    # Generate parameter values using example_values or param names
    if func_def['schema'] && func_def['schema']['params'] && func_def['schema']['params'].is_a?(Array)
      param_values = func_def['schema']['params'].map do |p|
        param_name = p['name'] || 'param'
        if func_def['example_values'] && func_def['example_values'][param_name]
          func_def['example_values'][param_name]
        else
          param_name
        end
      end

      if param_values.any?
        "#{return_name} = #{func_name}(#{param_values.join(', ')})"
      else
        "#{func_name}()"
      end
    else
      # Fallback for functions without proper schema
      case func_name
      when 'print'
        'print("Hello, World!")'
      else
        "-- Example usage of #{func_name}\n#{return_name} = #{func_name}()"
      end
    end
  end

  def generate_try_example_call(func_name, func_def)
    # Convert function name to try_ variant
    try_func_name = func_name.sub(/\.([^.]+)$/, '.try_\\1')

    # Get return value name from schema if available
    return_name = if func_def['schema'] && func_def['schema']['ret_vals'] && func_def['schema']['ret_vals'].first
                    func_def['schema']['ret_vals'].first['name'] || 'result'
                  else
                    'result'
                  end

    # Generate parameter values using example_values or param names
    if func_def['schema'] && func_def['schema']['params'] && func_def['schema']['params'].is_a?(Array)
      param_values = func_def['schema']['params'].map do |p|
        param_name = p['name'] || 'param'
        if func_def['example_values'] && func_def['example_values'][param_name]
          func_def['example_values'][param_name]
        else
          param_name
        end
      end

      if param_values.any?
        "#{return_name}_or_nil, error = #{try_func_name}(#{param_values.join(', ')})"
      else
        "#{return_name}_or_nil, error = #{try_func_name}()"
      end
    else
      # Fallback for functions without proper schema
      "#{return_name}_or_nil, error = #{try_func_name}()"
    end
  end

  def generate_function_list(functions, module_name = nil)
    return "" if functions.empty?

    function_items = functions.map do |func_name, func_def|
      next unless func_def['type'] == 'function'

      if module_name
        full_name = "sandman.#{module_name}.#{func_name}"
        anchor = full_name.downcase.gsub('.', '')
        display_name = if func_def['has_try']
                         "sandman.#{module_name}.try_#{func_name}"
                       else
                         func_name
                       end
        "- [`#{display_name}()`](/docs/api-#{module_name}/##{anchor}) - #{func_def['description']}"
      else
        anchor = func_name.downcase.gsub('.', '')
        display_name = if func_def['has_try']
                         "try_#{func_name}"
                       else
                         func_name
                       end
        "- [`#{display_name}()`](/docs/api-global/##{anchor}) - #{func_def['description']}"
      end
    end.compact

    function_items.empty? ? "" : function_items.join("\n")
  end

  def module_title(module_name)
    case module_name
    when 'http' then 'HTTP Client'
    when 'server' then 'HTTP Server'
    when 'document' then 'Document Context'
    when 'json' then 'JSON Utilities'
    when 'base64' then 'Base64 Utilities'
    when 'jwt' then 'JWT Utilities'
    when 'uri' then 'URI Utilities'
    else module_name.capitalize
    end
  end

  def module_description(module_name)
    case module_name
    when 'http'
      'Make HTTP requests to external services:'
    when 'server'
      'Create HTTP server endpoints and handle requests:'
    when 'document'
      'Manage document-scoped persistent data:'
    when 'json'
      'Encode and decode JSON data:'
    when 'base64'
      'Base64 encoding and decoding with URL-safe variants:'
    when 'jwt'
      'JSON Web Token creation and verification:'
    when 'uri'
      'Parse, construct, and manipulate URIs and URLs:'
    else
      "#{module_name.capitalize} utilities:"
    end
  end
end

# Run the generator if this file is executed directly
if __FILE__ == $0
  generator = ApiDocGenerator.new
  generator.generate_all_docs
end
