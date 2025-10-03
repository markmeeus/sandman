defmodule Sandman.LuaSupport.JwtTest do
  use ExUnit.Case, async: true
  alias Sandman.LuaSupport.Jwt

  # Mock luerl_state for testing
  @luerl_state "dummy"
  @test_doc "test-doc"

  describe "sign/5" do
    test "signs a token with HS256 algorithm" do
      data = %{"user_id" => 123, "role" => "admin"}
      secret = "my-secret-key"
      options = %{"alg" => "HS256"}

      {result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)

      assert is_list(result)
      assert length(result) == 1
      token = hd(result)
      assert is_binary(token)
      assert String.contains?(token, ".")
    end

    test "signs an unsigned token when secret is nil" do
      data = %{"user_id" => 123, "role" => "admin"}
      secret = nil
      options = %{"alg" => "none"}

      {result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)

      assert is_list(result)
      assert length(result) == 1
      token = hd(result)
      assert is_binary(token)
      assert String.ends_with?(token, ".")
    end

    test "signs an unsigned token when algorithm is none" do
      data = %{"user_id" => 123, "role" => "admin"}
      secret = "some-secret"
      options = %{"alg" => "none"}

      {result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)

      assert is_list(result)
      assert length(result) == 1
      token = hd(result)
      assert is_binary(token)
      assert String.ends_with?(token, ".")
    end

    test "uses HS256 as default algorithm when secret is provided" do
      data = %{"user_id" => 123, "role" => "admin"}
      secret = "my-secret-key"
      options = %{}

      {result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)

      assert is_list(result)
      assert length(result) == 1
      token = hd(result)
      assert is_binary(token)
      assert String.contains?(token, ".")
    end

    test "returns error for invalid algorithm" do
      data = %{"user_id" => 123, "role" => "admin"}
      secret = "my-secret-key"
      options = %{"alg" => "INVALID"}

      result = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)

      assert {:error, error_msg, _state} = result
      assert is_binary(error_msg)
    end
  end

  describe "decode/3" do
    test "decodes a valid JWT token" do
      # Create a test token
      header = %{"alg" => "HS256", "typ" => "JWT"}
      payload = %{"user_id" => 123, "role" => "admin"}

      encoded_header = header |> Jason.encode!() |> Base.url_encode64(padding: false)
      encoded_payload = payload |> Jason.encode!() |> Base.url_encode64(padding: false)
      token = "#{encoded_header}.#{encoded_payload}.signature"

      {result, _state} = Jwt.decode(@test_doc, [token], @luerl_state)

      assert is_list(result)
      assert length(result) == 2
      [decoded_payload, decoded_header] = result
      assert decoded_payload == payload
      assert decoded_header == header
    end

    test "decodes an unsigned token" do
      # Create an unsigned test token
      header = %{"alg" => "none", "typ" => "JWT"}
      payload = %{"user_id" => 123, "role" => "admin"}

      encoded_header = header |> Jason.encode!() |> Base.url_encode64(padding: false)
      encoded_payload = payload |> Jason.encode!() |> Base.url_encode64(padding: false)
      token = "#{encoded_header}.#{encoded_payload}."

      {result, _state} = Jwt.decode(@test_doc, [token], @luerl_state)

      assert is_list(result)
      assert length(result) == 2
      [decoded_payload, decoded_header] = result
      assert decoded_payload == payload
      assert decoded_header == header
    end

    test "returns error for invalid token format" do
      token = "invalid.token"

      result = Jwt.decode(@test_doc, [token], @luerl_state)

      assert {:error, error_msg, _state} = result
      assert error_msg == "Invalid JWT format"
    end

    test "returns error for malformed token" do
      token = "not-a-valid.token.format"

      result = Jwt.decode(@test_doc, [token], @luerl_state)

      assert {:error, error_msg, _state} = result
      assert error_msg == "Invalid token encoding"
    end
  end

  describe "verify/5" do
    test "verifies a valid signed token" do
      # First create a token
      data = %{"user_id" => 123, "role" => "admin"}
      secret = "my-secret-key"
      options = %{"alg" => "HS256"}

      {sign_result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)
      token = hd(sign_result)

      # Now verify it
      {verify_result, _state} = Jwt.verify(@test_doc, [token, secret, options], @luerl_state)

      assert is_list(verify_result)
      assert length(verify_result) == 2
      [claims, header] = verify_result
      assert claims["user_id"] == 123
      assert claims["role"] == "admin"
      assert header["alg"] == "HS256"
    end

    test "verifies an unsigned token" do
      # Create an unsigned token
      data = %{"user_id" => 123, "role" => "admin"}
      secret = nil
      options = %{"alg" => "none"}

      {sign_result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)
      token = hd(sign_result)

      # Verify it
      {verify_result, _state} = Jwt.verify(@test_doc, [token, nil, options], @luerl_state)

      assert is_list(verify_result)
      assert length(verify_result) == 2
      [claims, header] = verify_result
      assert claims["user_id"] == 123
      assert claims["role"] == "admin"
      assert header["alg"] == "none"
    end

    test "rejects token with wrong secret" do
      # Create a token with one secret
      data = %{"user_id" => 123, "role" => "admin"}
      secret1 = "secret1"
      options = %{"alg" => "HS256"}

      {sign_result, _state} = Jwt.sign(@test_doc, [data, secret1, options], @luerl_state)
      token = hd(sign_result)

      # Try to verify with different secret
      secret2 = "secret2"
      result = Jwt.verify(@test_doc, [token, secret2, options], @luerl_state)

      assert {:error, error_msg, _state} = result
      assert is_binary(error_msg)
    end

    test "rejects expired token" do
      # Create an expired token
      current_time = System.system_time(:second)
      expired_time = current_time - 3600  # 1 hour ago

      data = %{"user_id" => 123, "role" => "admin", "exp" => expired_time}
      secret = nil
      options = %{"alg" => "none"}

      {sign_result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)
      token = hd(sign_result)

      result = Jwt.verify(@test_doc, [token, nil, options], @luerl_state)

      assert {:error, error_msg, _state} = result
      assert error_msg == "Token has expired"
    end

    test "rejects token not yet valid" do
      # Create a token that's not yet valid
      current_time = System.system_time(:second)
      future_time = current_time + 3600  # 1 hour from now

      data = %{"user_id" => 123, "role" => "admin", "nbf" => future_time}
      secret = nil
      options = %{"alg" => "none"}

      {sign_result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)
      token = hd(sign_result)

      result = Jwt.verify(@test_doc, [token, nil, options], @luerl_state)

      assert {:error, error_msg, _state} = result
      assert error_msg == "Token is not yet valid"
    end

    test "verifies token with specific algorithm" do
      data = %{"user_id" => 123, "role" => "admin"}
      secret = "my-secret-key"
      options = %{"alg" => "HS256"}

      {sign_result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)
      token = hd(sign_result)

      # Verify with specific algorithm
      verify_options = %{"algs" => "HS256"}
      {verify_result, _state} = Jwt.verify(@test_doc, [token, secret, verify_options], @luerl_state)

      assert is_list(verify_result)
      assert length(verify_result) == 2
      [claims, header] = verify_result
      assert claims["user_id"] == 123
      assert header["alg"] == "HS256"
    end

    test "rejects token with wrong algorithm" do
      data = %{"user_id" => 123, "role" => "admin"}
      secret = "my-secret-key"
      options = %{"alg" => "HS256"}

      {sign_result, _state} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)
      token = hd(sign_result)

      # Try to verify with different algorithm
      verify_options = %{"algs" => "HS384"}
      result = Jwt.verify(@test_doc, [token, secret, verify_options], @luerl_state)

      assert {:error, error_msg, _state} = result
      assert is_binary(error_msg)
    end
  end

  describe "integration tests" do
    test "complete workflow: sign, decode, verify" do
      # Test data
      data = %{"user_id" => 123, "role" => "admin", "iat" => System.system_time(:second)}
      secret = "my-secret-key"
      options = %{"alg" => "HS256"}

      # 1. Sign the token
      {sign_result, state1} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)
      assert is_list(sign_result)
      token = hd(sign_result)

      # 2. Decode the token (without verification)
      {decode_result, state2} = Jwt.decode(@test_doc, [token], state1)
      assert is_list(decode_result)
      [decoded_payload, decoded_header] = decode_result
      assert decoded_payload["user_id"] == 123
      assert decoded_header["alg"] == "HS256"

      # 3. Verify the token
      {verify_result, _state3} = Jwt.verify(@test_doc, [token, secret, options], state2)
      assert is_list(verify_result)
      [verified_payload, verified_header] = verify_result
      assert verified_payload["user_id"] == 123
      assert verified_header["alg"] == "HS256"
    end

    test "unsigned token workflow" do
      # Test data
      data = %{"user_id" => 456, "role" => "user"}
      secret = nil
      options = %{"alg" => "none"}

      # 1. Sign the token
      {sign_result, state1} = Jwt.sign(@test_doc, [data, secret, options], @luerl_state)
      assert is_list(sign_result)
      token = hd(sign_result)
      assert String.ends_with?(token, ".")

      # 2. Decode the token
      {decode_result, state2} = Jwt.decode(@test_doc, [token], state1)
      assert is_list(decode_result)
      [decoded_payload, decoded_header] = decode_result
      assert decoded_payload["user_id"] == 456
      assert decoded_header["alg"] == "none"

      # 3. Verify the token
      {verify_result, _state3} = Jwt.verify(@test_doc, [token, nil, options], state2)
      assert is_list(verify_result)
      [verified_payload, verified_header] = verify_result
      assert verified_payload["user_id"] == 456
      assert verified_header["alg"] == "none"
    end
  end
end
