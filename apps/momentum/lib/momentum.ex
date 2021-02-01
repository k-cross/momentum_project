defmodule Momentum do
  @moduledoc """
  Connect to the trading service
  """
  alias Momentum.OAuth

  @etrade_url Application.get_env(:momentum, :etrade_api_url)
  @request_token_url @etrade_url <> "/oauth/request_token"
  @access_token_url @etrade_url <> "/oauth/access_token"
  @etrade_credentials OAuth.credentials(
                        consumer_key: Application.get_env(:momentum, :consumer_key),
                        consumer_secret: Application.get_env(:momentum, :consumer_secret),
                        method: :hmac_sha1
                      )

  def connect do
    params = OAuth.sign("get", @request_token_url, [{"oauth_callback", "oob"}], @etrade_credentials)
    {header, req_params} = OAuth.header(params)

    Finch.build(:get, @request_token_url, header) |> Finch.request(Client, req_params)
  end
end
