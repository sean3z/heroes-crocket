# crocket Heroes, built from source with GCC 16.2 (C++26 reflection).
# crocket is pinned to commit 63317f2 (workers follow the pool by default), as benchmarked.
# Statically links libstdc++/libgcc and runs on ubuntu:24.04 so flamegraphs keep
# C++ runtime symbols and glibc frame pointers (plus libc6-dbg).
FROM ghcr.io/sean3z/crocket-toolchain:gcc-16.2 AS build
ARG CROCKET_REF=63317f2
RUN git clone https://github.com/sean3z/crocket /crocket && git -C /crocket checkout ${CROCKET_REF}
COPY CMakeLists.txt main.cpp /src/
RUN cmake -S /src -B /build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCROCKET_SRC=/crocket \
      -DCMAKE_C_COMPILER=/opt/gcc-16.2/bin/gcc-16.2 -DCMAKE_CXX_COMPILER=/opt/gcc-16.2/bin/g++-16.2 \
      -DCMAKE_CXX_FLAGS="-fno-omit-frame-pointer -mno-omit-leaf-frame-pointer" \
      -DCMAKE_EXE_LINKER_FLAGS="-static-libstdc++ -static-libgcc" \
 && cmake --build /build --target heroes -j \
 && mkdir /dist && cp /build/heroes /dist/

FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpq5 libssl3 zlib1g libzstd1 curl ca-certificates libc6-dbg \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /dist/heroes /app/heroes
ENV CROCKET_PORT=8000 CROCKET_DATABASE_POOL_SIZE=16 CROCKET_REQUEST_TIMEOUT=10s
EXPOSE 8000
ENTRYPOINT ["/app/heroes"]
