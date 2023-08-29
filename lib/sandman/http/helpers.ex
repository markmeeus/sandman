defmodule Sandman.Http.Helpers do
  def get_content_info_from_headers(headers) do
    content_type = Enum.find_value(headers, fn {name, value}->
      if String.downcase(name) == "content-type" do
        String.downcase(value)
      else
        nil
      end
    end)

    is_json = (content_type || "")
      |> String.contains?("application/json")
    %{content_type: content_type, is_json: is_json}
  end
end
