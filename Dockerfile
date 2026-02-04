# Builder stage
FROM rust:alpine as builder

WORKDIR /usr/src/sthp

# Install musl-dev for compilation
RUN apk add --no-cache musl-dev

# Create a dummy main.rs to cache dependencies
RUN USER=root cargo new --bin sthp
WORKDIR /usr/src/sthp/sthp
COPY Cargo.toml Cargo.lock ./

# Build dependencies only (release profile)
RUN cargo build --release --locked

# Remove the dummy source
RUN rm src/*.rs

# Copy the actual source code
COPY src ./src

# Build the actual application (touch main.rs to force rebuild)
RUN touch src/main.rs && cargo build --release --locked

# Runtime stage
FROM alpine:latest

# Install CA certificates (good practice for network apps)
RUN apk add --no-cache ca-certificates

WORKDIR /usr/local/bin

# Copy the binary from the builder stage
COPY --from=builder /usr/src/sthp/sthp/target/release/sthp .

# Expose the default port
EXPOSE 8080

# Run the application
# We listen on 0.0.0.0 to be accessible outside the container
ENTRYPOINT ["./sthp", "--listen-ip", "0.0.0.0"]
