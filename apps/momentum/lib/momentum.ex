defmodule Momentum do
  @moduledoc """
  Connect to the trading service
  """
  alias Momentum.OAuth

  @etrade_url Application.get_env(:momentum, :etrade_api_url)
  @request_token_url @etrade_url <> "/oauth/request_token"
  @access_token_url @etrade_url <> "/oauth/access_token"
  @etrade_rt_params %{
    url: @request_token_url,
    consumer_key: Application.get_env(:momentum, :consumer_key),
    consumer_secret: Application.get_env(:momentum, :consumer_secret),
    method: :hmac_sha1,
    options: [{"oauth_callback", "oob"}]
  }

  def connect do
    {header, _} = OAuth.request_token(@etrade_rt_params, :get)
    Finch.build(:get, @request_token_url, [header]) |> Finch.request(Client)
  end
end
