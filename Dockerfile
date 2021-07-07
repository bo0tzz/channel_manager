FROM bitwalker/alpine-elixir:latest AS build

ENV MIX_ENV=prod

WORKDIR /build/

COPY . .
RUN mix deps.get
RUN mix release

FROM bitwalker/alpine-elixir:latest AS run

RUN apk add tzdata
ENV TZ Europe/Amsterdam

COPY --from=build /build/_build/prod/rel/channel_manager/ ./
RUN chmod +x ./bin/channel_manager
CMD ./bin/channel_manager start

