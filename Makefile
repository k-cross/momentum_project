dev:
	cd project/momentum
	mix do deps.get, compile && cd apps/momentum_web/assets && npm install

run:
	cd project/momentum
	mix phx.server
