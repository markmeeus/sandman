defmodule Sandman.DotEnvLoaderTest do
  use ExUnit.Case, async: true
  alias Sandman.DotEnvLoader

  doctest Sandman.DotEnvLoader

  describe "parse/1" do
    test "returns empty map for empty string" do
      assert DotEnvLoader.parse("") == %{}
    end

    test "parses single key-value pair" do
      assert DotEnvLoader.parse("KEY=value") == %{"KEY" => "value"}
    end

    test "parses multiple key-value pairs" do
      content = "KEY1=value1\nKEY2=value2\nKEY3=value3"
      expected = %{"KEY1" => "value1", "KEY2" => "value2", "KEY3" => "value3"}
      assert DotEnvLoader.parse(content) == expected
    end

    test "ignores lines without equals sign" do
      content = "KEY1=value1\ninvalid line\nKEY2=value2"
      expected = %{"KEY1" => "value1", "KEY2" => "value2"}
      assert DotEnvLoader.parse(content) == expected
    end

    test "ignores empty lines" do
      content = "KEY1=value1\n\nKEY2=value2"
      expected = %{"KEY1" => "value1", "KEY2" => "value2"}
      assert DotEnvLoader.parse(content) == expected
    end

    test "ignores lines that start with equals sign" do
      content = "KEY1=value1\n=invalid\nKEY2=value2"
      expected = %{"KEY1" => "value1", "KEY2" => "value2"}
      assert DotEnvLoader.parse(content) == expected
    end

    test "handles values with equals signs" do
      content = "DATABASE_URL=postgresql://user:pass=word@localhost/db"
      expected = %{"DATABASE_URL" => "postgresql://user:pass=word@localhost/db"}
      assert DotEnvLoader.parse(content) == expected
    end

    test "handles empty values" do
      content = "KEY1=\nKEY2=value2"
      expected = %{"KEY1" => "", "KEY2" => "value2"}
      assert DotEnvLoader.parse(content) == expected
    end

    test "handles values with spaces" do
      content = "KEY1=value with spaces\nKEY2=another value"
      expected = %{"KEY1" => "value with spaces", "KEY2" => "another value"}
      assert DotEnvLoader.parse(content) == expected
    end

    test "handles keys with underscores and uppercase" do
      content = "DATABASE_URL=postgres://localhost\nAPI_KEY=secret123"
      expected = %{"DATABASE_URL" => "postgres://localhost", "API_KEY" => "secret123"}
      assert DotEnvLoader.parse(content) == expected
    end

    test "handles mixed valid and invalid lines" do
      content = """
      KEY1=value1
      # This is a comment
      KEY2=value2
      invalid line without equals
      KEY3=value3

      KEY4=value4
      """

      expected = %{
        "KEY1" => "value1",
        "KEY2" => "value2",
        "KEY3" => "value3",
        "KEY4" => "value4"
      }

      assert DotEnvLoader.parse(content) == expected
    end

    test "last value wins for duplicate keys" do
      content = "KEY=value1\nKEY=value2"
      expected = %{"KEY" => "value2"}
      assert DotEnvLoader.parse(content) == expected
    end
  end
end
