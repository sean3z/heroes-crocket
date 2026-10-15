# heroes-crocket

[crocket](https://github.com/sean3z/crocket) (C++26 reflection) implementation of the Heroes CRUD API used in the [Heroes shootout](https://github.com/sean3z/heroes-shootout) (crocket vs Rocket vs Spring Boot vs Fastify), behind the post *Where the cycles go: C++26, Rust, Java and Node on one CRUD API*.

Handlers are plain functions over plain structs; routes and JSON come from C++26 reflection. See `main.cpp`.

## API contract (identical across all four apps)

A hero is `{"id": int, "name": string, "alias": string, "power": string, "mentor": string|null}`.

| Method | Path | Success | Notes |
|---|---|---|---|
| GET | `/heroes` | 200, JSON array | first 50 heroes ordered by id |
| GET | `/heroes/{id}` | 200 | 404 if missing |
| POST | `/heroes` | 201 + `Location: /heroes/{id}` | body without `id` |
| PUT | `/heroes/{id}` | 200 | 404 if missing |
| DELETE | `/heroes/{id}` | 204 | 404 if missing |
| GET | `/metrics` | 200 | Prometheus text format |

Seed data (`init.sql`): Barry Allen, the four Robins and 995 filler rows. `./conformance.sh http://localhost:8000` runs the same 15 checks every app passed before benchmarking.

Production features on in every app: structured JSON request log per request, Prometheus metrics, 10 s request/query timeouts, a 16-connection Postgres pool.

## Run with Docker

```bash
docker network create heroes
docker run -d --name pg --network heroes -e POSTGRES_USER=heroes -e POSTGRES_PASSWORD=heroes -e POSTGRES_DB=heroes \
  -v "$PWD/init.sql:/docker-entrypoint-initdb.d/init.sql:ro" postgres:16
docker build -t heroes-crocket .
docker run --rm --network heroes -p 8000:8000 -e CROCKET_DATABASE_URL=postgresql://heroes:heroes@pg/heroes heroes-crocket
./conformance.sh http://localhost:8000
```

The `heroes`/`heroes` credentials are local defaults for the demo only; set your own.

## Configuration

| Variable | Default here | Meaning |
|---|---|---|
| `CROCKET_DATABASE_URL` | unset (libpq `PG*` vars) | Postgres connection string |
| `CROCKET_DATABASE_POOL_SIZE` | `16` | pool size; workers follow it by default |
| `CROCKET_PORT` | `8000` | listen port |
| `CROCKET_REQUEST_TIMEOUT` | `10s` | request deadline |

## Versions (as benchmarked, Oct 15, 2026)

- crocket commit `63317f2` (PR #40, "workers follow the database pool"), cloned by the Dockerfile
- GCC 16.2 via `ghcr.io/sean3z/crocket-toolchain:gcc-16.2`, `-std=c++26`, RelWithDebInfo with frame pointers
- libpqxx / libpq from the toolchain image; runtime on `debian:trixie-slim`
- PostgreSQL 16

## License

MIT (sample code). See [LICENSE](LICENSE).
