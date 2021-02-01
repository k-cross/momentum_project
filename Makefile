dev:
	mix do deps.get, compile && cd apps/momentum_web/assets && npm install

run:
	mix phx.server
