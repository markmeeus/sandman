defmodule Sandman.Http.Server.ConnMatch do
  # Compiles the regex and splits the routes in components
  def prepare_routes(routes) do
    routes
    |> Enum.filter(&valid_route/1)
    |> Enum.map(fn
      %{path: "/" <> path} = route-> %{ route | path: path}
      route -> route
    end)
    |> Enum.map(fn route ->
      route
      |> split_path_and_upcase_method()
      |> compile_regex()
    end)
  end

  def match(conn, routes) do
    Enum.reduce_while(routes, nil, fn route, _ ->
      case is_match?(conn, route) do
        {true, params} ->
          {:halt, {route, params}}
        _ ->
          {:cont, nil}
      end
    end)
  end

  defp is_match?(
         %{method: method, path_info: path},
         %{method: method, path_components: path}
       ) do
    {true, %{}}
  end

  defp is_match?(
         %{method: method, path_info: conn_path},
         %{method: method, path_regex: path_regex}
       ) do
    path = Enum.join(conn_path, "/")
    case Regex.named_captures(path_regex, path) do
      nil -> false
      captures -> {true, captures}
    end
  end
  defp is_match?(a, b) do
   false
  end


  defp compile_regex(route = %{path_components: path_components}) do
    parts_regex_str = path_components
    |> Enum.map(fn
      ":" <> component -> "(?<#{component}>(.*))"
      component -> component
    end)
    |> Enum.join("\/")

    regex= Regex.compile!("^" <> parts_regex_str <> "$")

    Map.put(route, :path_regex, regex)
  end

  defp split_path_and_upcase_method(route = %{path: path, method: method}) do
    route
    |> Map.put(:path_components, String.split(path, "/"))
    |> Map.put(:method, String.upcase(method))
  end

  defp valid_route(%{path: path, method: method}) when is_bitstring(path) and is_bitstring(method), do: true
  defp valid_route(_), do: false
end
