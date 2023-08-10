defmodule Sandman.NewFileTemplate do
  @templ """
  # New Sandman Script
  ```lua
  -- set some easy globals
  http = sandman.http
  ```
  ```lua
  http.get("http://sandmanapp.com/welcome.json")
  ```
  """

  def contents do
    @templ
  end
end
