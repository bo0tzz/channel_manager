FROM elixir:alpine AS build

ENV MIX_ENV=prod

WORKDIR /build/
RUN mix local.hex --force
RUN mix local.rebar --force

COPY . .
RUN mix deps.get
RUN mix release

FROM elixir:alpine AS run

RUN apk add tzdata
ENV TZ Europe/Amsterdam

COPY --from=build /build/_build/prod/rel/channel_manager/ ./
RUN chmod +x ./bin/channel_manager
CMD ./bin/channel_manager start

