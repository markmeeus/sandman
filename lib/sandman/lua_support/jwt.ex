defmodule Sandman.LuaSupport.Jwt do
  alias Sandman.LuaMapper
  import Sandman.Logger

  def sign(doc_id, [data], luerl_state) do
    sign(doc_id, [data, nil], luerl_state)
  end

  def sign(doc_id, [data, secret], luerl_state) when is_bitstring(secret) or is_nil(secret) do
    sign(doc_id, [data, secret, nil], luerl_state)
  end

  def sign(doc_id, [data, secret, options], luerl_state)
      when is_bitstring(secret) or is_nil(secret) do
    decoded_data = :luerl.decode(data, luerl_state)
    decoded_options = :luerl.decode(options, luerl_state) || %{}

    {payload, _} =
      decoded_data
      |> LuaMapper.map(:any)

    {opts, _} =
      decoded_options
      |> LuaMapper.map(:any)

    alg = Map.get(opts, "alg", if(is_nil(secret), do: "none", else: "HS256"))

    token =
      cond do
        # Handle unsigned tokens (alg: "none" or no secret)
        is_nil(secret) or alg == "none" ->
          create_unsigned_token(payload)

        # Handle signed tokens
        true ->
          try do
            case Joken.generate_and_sign(%{}, payload, Joken.Signer.create(alg, secret)) do
              {:ok, token, _claims} ->
                token

              {:error, reason} ->
                log(doc_id, "JWT signing error: #{inspect(reason)}")
                nil
            end
          rescue
            error in Joken.Error ->
              log(doc_id, "JWT signer error: #{alg}: #{error.reason}")
              nil

            error ->
              log(doc_id, "JWT unexpected error: #{inspect(error)}")
              nil
          end
      end

    {[token], luerl_state}
  end

  def sign(doc_id, _, luerl_state) do
    error = "Unexpected arguments in jwt.sign"
    log(doc_id, error)
    {[nil, error], luerl_state}
  end

  def verify(doc_id, [token], luerl_state) do
    verify(doc_id, [token, nil], luerl_state)
  end

  def verify(doc_id, [token, secret], luerl_state) when is_bitstring(secret) or is_nil(secret) do
    verify(doc_id, [token, secret, nil], luerl_state)
  end

  def verify(doc_id, [nil, _, _], luerl_state) do
    {[false], luerl_state}
  end

  def verify(doc_id, [token, secret, options], luerl_state)
      when is_bitstring(secret) or is_nil(secret) do
    decoded_token = :luerl.decode(token, luerl_state)

    decoded_secret = if is_nil(secret), do: nil, else: :luerl.decode(secret, luerl_state)
    decoded_options = :luerl.decode(options, luerl_state) || %{}

    {options, _} = LuaMapper.map(decoded_options, :any)

    result =
      if is_nil(decoded_secret) do
        # Verify unsigned token manually
        case verify_unsigned_token(decoded_token) do
          {:ok, claims} -> {true, claims, nil}
          {:error, reason} -> {false, nil, reason}
        end
      else
        # For signed tokens, use specified algorithms or defaults
        default_algorithms = ["HS256", "HS384", "HS512"]

        {algorithms, fail_fast} =
          case options do
            %{"algs" => algs} when is_list(algs) -> {algs, true}
            %{"algs" => alg} when is_binary(alg) -> {[alg], true}
            _ -> {default_algorithms, false}
          end

        # Pre-create signers and fail fast if any algorithm is invalid
        signers_result =
          Enum.reduce_while(algorithms, [], fn alg, acc ->
            try do
              signer = Joken.Signer.create(alg, decoded_secret)
              {:cont, [{alg, signer} | acc]}
            rescue
              error in Joken.Error ->
                {:halt, {:error, "#{alg}: #{error.reason}"}}

              error ->
                {:halt, {:error, "#{alg}: #{inspect(error)}"}}
            end
          end)

        case signers_result do
          {:error, error_msg} ->
            {false, nil, error_msg}

          signers when is_list(signers) ->
            # Reverse to maintain original order
            signers = Enum.reverse(signers)

            last_error =
              Enum.reduce_while(signers, nil, fn {alg, signer}, _acc ->
                case Joken.verify(decoded_token, signer) do
                  {:ok, claims} ->
                    # Manually validate claims after successful verification
                    case validate_claims(claims) do
                      :ok ->
                        {:halt, {:success, claims}}

                      {:error, reason} ->
                        if fail_fast do
                          {:halt, reason}
                        else
                          {:cont, reason}
                        end
                    end

                  {:error, reason} ->
                    if fail_fast do
                      {:halt, "#{alg}: #{reason}"}
                    else
                      {:cont, "#{alg}: #{reason}"}
                    end
                end
              end)

            case last_error do
              {:success, claims} -> {true, claims, nil}
              error_reason -> {false, nil, error_reason}
            end
        end
      end

    case result do
      {true, claims, _} ->
        {encoded_claims, luerl_state} = :luerl.encode(claims, luerl_state)
        {[true, encoded_claims], luerl_state}

      {false, _, error} ->
        error_msg = format_error(error)
        {[false, error_msg], luerl_state}
    end
  end

  def verify(doc_id, _, luerl_state) do
    error = "Unexpected arguments in jwt.verify"
    log(doc_id, error)
    {[false, error], luerl_state}
  end

  # Create an unsigned JWT token manually since Joken doesn't support "none" algorithm by default
  defp create_unsigned_token(payload) do
    header = %{"alg" => "none", "typ" => "JWT"}

    encoded_header =
      header
      |> Jason.encode!()
      |> Base.url_encode64(padding: false)

    encoded_payload =
      payload
      |> Jason.encode!()
      |> Base.url_encode64(padding: false)

    # For unsigned tokens, signature is empty
    "#{encoded_header}.#{encoded_payload}."
  end

  # Verify unsigned JWT token manually
  defp verify_unsigned_token(token) do
    case String.split(token, ".") do
      [header_b64, payload_b64, ""] ->
        try do
          header = header_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()
          payload = payload_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()

          case header["alg"] do
            "none" ->
              case validate_claims(payload) do
                :ok -> {:ok, payload}
                {:error, reason} -> {:error, reason}
              end

            _ ->
              {:error, :invalid_algorithm}
          end
        rescue
          _ -> {:error, :invalid_token}
        end

      _ ->
        {:error, :invalid_format}
    end
  end

  # Validate standard JWT claims manually for unsigned tokens
  defp validate_claims(claims) do
    current_time = System.system_time(:second)

    cond do
      # Check expiration (exp claim)
      Map.has_key?(claims, "exp") and claims["exp"] <= current_time ->
        {:error, :token_expired}

      # Check not before (nbf claim)
      Map.has_key?(claims, "nbf") and claims["nbf"] > current_time ->
        {:error, :token_not_yet_valid}

      # Check issued at (iat claim) - shouldn't be in the future
      Map.has_key?(claims, "iat") and claims["iat"] > current_time + 60 ->
        {:error, :token_issued_in_future}

      # All validations passed
      true ->
        :ok
    end
  end

  # Format error reasons into user-friendly messages
  defp format_error(nil), do: "Unknown error"
  defp format_error(:invalid_format), do: "Invalid JWT format"
  defp format_error(:invalid_token), do: "Invalid token encoding"
  defp format_error(:invalid_algorithm), do: "Invalid algorithm"
  defp format_error(:token_expired), do: "Token has expired"
  defp format_error(:token_not_yet_valid), do: "Token is not yet valid"
  defp format_error(:token_issued_in_future), do: "Token issued in the future"
  defp format_error(%Joken.Error{reason: reason}), do: "JWT error: #{reason}"
  defp format_error(error) when is_atom(error), do: "JWT error: #{error}"
  defp format_error(error), do: "JWT error: #{inspect(error)}"
end
