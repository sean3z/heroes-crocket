// Heroes CRUD on crocket (main 36eaa12): crocket::db on Postgres, plain structs, Db& handler param.
#include <crocket/crocket.hpp>
#include <crocket/db.hpp>

#include <cstdint>
#include <optional>
#include <string>

using namespace crocket;

struct Hero {
  std::int64_t id;
  std::string name;
  std::string alias;
  std::string power;
  std::optional<std::string> mentor;
};

namespace api {

[[= http::get("/heroes")]]
auto list(Db& db) -> std::vector<Hero> {
  return db.all<Hero>().order_by(&Hero::id).limit(50);
}

[[= http::get("/heroes/{id}")]]
auto get(Db& db, std::int64_t id) -> std::optional<Hero> {
  return db.find<Hero>(id);
}

[[= http::post("/heroes")]]
auto create(Db& db, Json<Hero> body) -> Created<Hero> {
  auto hero = db.insert(*body);
  return {hero, "/heroes/" + std::to_string(hero.id)};
}

[[= http::put("/heroes/{id}")]]
auto replace(Db& db, std::int64_t id, Json<Hero> body) -> std::optional<Hero> {
  body->id = id;
  if (!db.update(*body)) return std::nullopt;
  return *body;
}

[[= http::del("/heroes/{id}")]]
auto remove(Db& db, std::int64_t id) -> std::optional<NoContent> {
  if (!db.erase<Hero>(id)) return std::nullopt;
  return NoContent{};
}

}  // namespace api

int main() {
  auto cfg = Config::from_env();
  db::Pool pool(cfg.database);
  return build(cfg)
      .manage(std::move(pool))
      .attach(Logger{})
      .attach(Metrics{})
      .mount("/", reflect_routes<^^api>())
      .launch();
}
