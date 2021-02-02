defmodule Momentum.OAuth do
  @moduledoc """
  An OAuth 1.0 client library.

  ## Examples
  ```elixir
  creds = %OAuth.Credentials{
     consumer_key: "dpf43f3p2l4k3l03",
     consumer_secret: "kd94hf93k423kf44",
     method: :hmac_sha1,
     token: "nnch734d00sl2jdk",
     token_secret: "pfkkdhi9sl3r4s00"
  }

  params = OAuth.sign("post", "https://api.twitter.com/1.1/statuses/lookup.json", [{"id", 485086311205048320}], creds)
  #=> [
  #=>   {"oauth_signature", "ariK9GrGLzeEJDwQcmOTlf7jxeo="},
  #=>   {"oauth_consumer_key", "dpf43f3p2l4k3l03"},
  #=>   {"oauth_nonce", "L6a3Y1NeNwbU9Sqd6XnwNU+pjm6o0EyA"},
  #=>   {"oauth_signature_method", "HMAC-SHA1"},
  #=>   {"oauth_timestamp", 1517250224},
  #=>   {"oauth_version", "1.0"},
  #=>   {"oauth_token", "nnch734d00sl2jdk"},
  #=>   {"id", 485086311205048320}
  #=> ]
  {header, req_params} = OAuth.header(params)
  #=> {{"Authorization",
  #=>   "OAuth oauth_signature=\"ariK9GrGLzeEJDwQcmOTlf7jxeo%3D\", oauth_consumer_key=\"dpf43f3p2l4k3l03\", oauth_nonce=\"L6a3Y1NeNwbU9Sqd6XnwNU%2Bpjm6o0EyA\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"1517250224\", oauth_version=\"1.0\", oauth_token=\"nnch734d00sl2jdk\""},
  #=>  [{"id", 485086311205048320}]}
  :hackney.post("https://api.twitter.com/1.1/statuses/lookup.json", [header], {:form, req_params})
  #=> {:ok, 200, [...], #Reference<0.0.0.837>}
  ```

  Implementation was inspired by OAuther.
  Copyright (c) 2014, Aleksei Magusev <lexmag@me.com>
  """

  defmodule Credentials do
    defstruct [
      :consumer_key,
      :consumer_secret,
      :token,
      :token_secret,
      method: :hmac_sha1
    ]

    @type t :: %__MODULE__{
            consumer_key: String.t(),
            consumer_secret: String.t(),
            token: nil | String.t(),
            token_secret: nil | String.t(),
            method: :hmac_sha1 | :rsa_sha1 | :plaintext
          }
  end

  @type params :: [{String.t(), String.Chars.t()}]
  @type header :: {String.t(), String.t()}
  @type url_verb :: :get | :post | :delete | :put | :patch

  @spec request_token(request_token_params :: map(), url_verb()) :: {header(), params()}
  def request_token(rt_params, url_verb) do
    creds = struct(Credentials, rt_params)

    url_verb
    |> sign(rt_params.url, rt_params.options, creds)
    |> header()
  end

  @spec sign(url_verb(), URI.t() | String.t(), params, Credentials.t()) :: params
  def sign(verb, url, params, %Credentials{} = creds) do
    params = protocol_params(params, creds)
    signature = signature(to_string(verb), url, params, creds)

    [{"oauth_signature", signature} | params]
  end

  @spec header(params) :: {header, params}
  def header(params) do
    {oauth_params, req_params} = Enum.split_with(params, &protocol_param?/1)

    {{"Authorization", "OAuth " <> compose_header(oauth_params)}, req_params}
  end

  @spec protocol_params(params, Credentials.t()) :: params
  def protocol_params(params, %Credentials{} = creds) do
    [
      {"oauth_consumer_key", creds.consumer_key},
      {"oauth_nonce", nonce()},
      {"oauth_signature_method", signature_method(creds.method)},
      {"oauth_timestamp", timestamp()},
      {"oauth_version", "1.0"}
      | maybe_put_token(params, creds.token)
    ]
  end

  @spec signature(String.t(), URI.t() | String.t(), params, Credentials.t()) :: binary
  def signature(_, _, _, %Credentials{method: :plaintext} = creds), do: compose_key(creds)

  def signature(verb, url, params, %Credentials{method: :hmac_sha1} = creds) do
    :sha
    |> :crypto.hmac(compose_key(creds), base_string(verb, url, params))
    |> Base.encode64()
  end

  def signature(verb, url, params, %Credentials{method: :rsa_sha1} = creds) do
    base_string(verb, url, params)
    |> :public_key.sign(:sha, decode_private_key(creds.consumer_secret))
    |> Base.encode64()
  end

  defp protocol_param?({key, _value}), do: String.starts_with?(key, "oauth_")

  defp compose_header([_ | _] = params),
    do: Enum.map_join(params, ", ", &(percent_encode(&1) |> compose_header()))

  defp compose_header({key, value}), do: key <> "=\"" <> value <> "\""

  defp compose_key(creds) do
    [creds.consumer_secret, creds.token_secret]
    |> Enum.map_join("&", &percent_encode/1)
  end

  defp read_private_key("-----BEGIN RSA PRIVATE KEY-----" <> _ = private_key), do: private_key
  defp read_private_key(path), do: File.read!(path)

  defp decode_private_key(private_key_or_path) do
    [entry] =
      private_key_or_path
      |> read_private_key()
      |> :public_key.pem_decode()

    :public_key.pem_entry_decode(entry)
  end

  defp base_string(verb, url, params) do
    {uri, query_params} = parse_url(url)

    [verb, uri, params ++ query_params]
    |> Enum.map_join("&", &(normalize(&1) |> percent_encode()))
  end

  defp normalize(verb) when is_binary(verb), do: String.upcase(verb)
  defp normalize(%URI{host: host} = uri), do: %{uri | host: String.downcase(host)}

  defp normalize([_ | _] = params) do
    params
    |> Enum.map(&percent_encode/1)
    |> Enum.sort()
    |> Enum.map_join("&", &normalize_pair/1)
  end

  defp normalize_pair({key, value}) do
    key <> "=" <> value
  end

  defp parse_url(url) do
    uri = URI.parse(url)
    {%{uri | query: nil}, parse_query_params(uri.query)}
  end

  defp parse_query_params(params) do
    if is_nil(params) do
      []
    else
      URI.query_decoder(params)
      |> Enum.to_list()
    end
  end

  defp nonce() do
    :crypto.strong_rand_bytes(24)
    |> Base.encode64()
  end

  defp timestamp() do
    {megasec, sec, _microsec} = :os.timestamp()
    megasec * 1_000_000 + sec
  end

  defp maybe_put_token(params, value) do
    if is_nil(value) do
      params
    else
      [{"oauth_token", value} | params]
    end
  end

  defp signature_method(:plaintext), do: "PLAINTEXT"
  defp signature_method(:hmac_sha1), do: "HMAC-SHA1"
  defp signature_method(:rsa_sha1), do: "RSA-SHA1"

  defp percent_encode({key, value}), do: {percent_encode(key), percent_encode(value)}

  defp percent_encode(other) do
    other
    |> to_string()
    |> URI.encode(&URI.char_unreserved?/1)
  end
end
