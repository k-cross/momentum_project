defmodule Momentum.TradeServices.ETrade do
  @moduledoc """
  Connecting to ETrade and managing the logic for performing common trading actions
  withing ETrade itself.
  """
  alias Momentum.OAuth

  @etrade_url Application.get_env(:momentum, :etrade_api_url)
  @request_token_url @etrade_url <> "/oauth/request_token"
  @authorize_url "https://us.etrade.com/e/t/etws/authorize"
  @request_token_split [
    "oauth_token=",
    "%3D&oauth_token_secret=",
    "%3D&oauth_callback_confirmed="
  ]
  @access_token_url @etrade_url <> "/oauth/access_token"
  @etrade_rt_params %{
    url: @request_token_url,
    consumer_key: Application.get_env(:momentum, :consumer_key),
    consumer_secret: Application.get_env(:momentum, :consumer_secret),
    method: :hmac_sha1,
    options: [{"oauth_callback", "oob"}]
  }

  def request_token do
    {header, _} = OAuth.build_request(@etrade_rt_params, :get)
    {:ok, %{body: req_token}} =
      :get
      |> Finch.build(@request_token_url, [header])
      |> Finch.request(Client)

    case String.split(req_token, @request_token_split, trim: true) do
      [token, secret, "true"] ->
        %{token: token, token_secret: secret, callback?: true}

      [token, secret, _] ->
        %{token: token, token_secret: secret, callback?: false}
    end
  end

  def authorize_application(req_token) do
    {header, _} = OAuth.build_request(Map.merge(@etrade_rt_params, req_token), :get)

    :get
    |> Finch.build(@authorize_url, [header])
    |> Finch.request(Client)
  end
end
