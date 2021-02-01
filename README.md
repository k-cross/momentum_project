# Momentum Project

This project uses the phoenix framework as a web server to visualize actions.
It requires that `nodejs`, `erlang` and `elixir` are installed.
Setup the project by running `make` and then run the server using `make run`.

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Secrets

There are two secret files in the project, one named `dev.secret.exs` and the other `prod.secret.exs`.
Both require the following lines in order to properly build and run:

```elixir
import Config

config :momentum,
  consumer_key: "your key",
  consumer_secret: "your secret"
```

## Misc.

  * Official phoenix website: https://www.phoenixframework.org/
