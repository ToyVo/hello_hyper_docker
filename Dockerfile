FROM rust:alpine as builder

RUN apk update && apk add --no-cache musl-dev

# Create fresh binary project, add toml and lock file and compile dependencies to cache the image build steps
RUN mkdir /rust
WORKDIR /rust
RUN USER=root cargo new --bin hello_hyper_docker
WORKDIR /rust/hello_hyper_docker
COPY ./Cargo.toml ./Cargo.toml
COPY ./Cargo.lock ./Cargo.lock
RUN cargo build --release

# Clean up new bin source and built files
RUN rm src/*.rs
RUN rm ./target/release/deps/hello_hyper_docker*

# Add source code after dependencies are built and build for real
ADD . ./
RUN cargo build --release

FROM alpine:latest

ARG APP=/usr/local/bin

EXPOSE 8000

ENV TZ=Etc/UTC APP_USER=appuser

RUN addgroup -S $APP_USER && adduser -S -g $APP_USER $APP_USER && mkdir -p ${APP}

RUN apk update && apk add --no-cache ca-certificates tzdata && rm -rf /var/cache/apk/*

COPY --from=builder /rust/hello_hyper_docker/target/release/hello_hyper_docker ${APP}/hello_hyper_docker

RUN chown -R $APP_USER:$APP_USER ${APP}

USER $APP_USER
WORKDIR ${APP}

CMD ["./hello_hyper_docker"]