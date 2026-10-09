# Nailwing Backend Enhancement Plan

Reference architecture: Production Architecture & Operations Blueprint (1B Concurrent Users)

This document tracks all planned backend enhancements derived from a gap analysis of the
current codebase against the production blueprint. Each task has its own Git branch,
clear acceptance criteria, and test requirements.

---

## Current State — Gap Analysis Summary

| Area | Current State | Gap |
|---|---|---|
| Rate Limiting | None — all endpoints unthrottled | Auth endpoints open to brute force |
| Logging | `print()` statements only | No structured logs, no observability |
| Health Check | No endpoint exists | Load balancers have nothing to probe |
| API Docs | `drf-spectacular` installed but unwired | No OpenAPI schema exposed |
| N+1 Queries | `community_posts`, `MatchViewSet`, `MatchingService` interests | Extra DB round-trips per request |
| API Caching | `django-redis` wired but unused by app code | Expensive queries hit DB every time |
| Celery | Installed, zero config, zero tasks | All work is synchronous in request cycle |
| WebSocket | Redis password dropped, origin validator bypassed, no drain | Security and reliability gaps |
| DB Connections | No `CONN_MAX_AGE`, no pooling | New TCP connection per request |
| Duplicate Code | `user_profile` method defined twice in `AuthViewSet` | First definition is dead code |

---

## Task Overview

| # | Task | Branch | Priority | Status |
|---|---|---|---|---|
| 1 | Rate Limiting & API Throttling | `enhance/rate-limiting` | Critical | ✅ Done |
| 2 | Structured Logging + Health Check | `enhance/logging-health` | High | ✅ Done |
| 3 | Fix N+1 Queries | `enhance/query-optimization` | High | ✅ Done |
| 4 | Redis Caching for API Responses | `enhance/api-caching` | Medium | ✅ Done |
| 5 | Celery Configuration + Async Tasks | `enhance/celery-async` | Medium | ✅ Done |
| 6 | WebSocket Hardening | `enhance/websocket-hardening` | High | ✅ Done |
| 7 | DB Connection Pooling + Migration Safety | `enhance/db-pooling-cleanup` | Medium | ✅ Done |

---

## Task 1 — Rate Limiting & API Throttling

**Branch:** `enhance/rate-limiting`
**Blueprint reference:** Step 2 — Edge Processing & Rate Limiting; Step 3 — ORM Query Prevention

### Problem

Every API endpoint is completely unthrottled. The auth endpoints (`/api/auth/register/`,
`/api/auth/login/`) are `AllowAny` with no rate limit, making them vulnerable to
brute-force and credential stuffing attacks. The `find_matches` endpoint runs 6 separate
database queries per call with no protection against abuse.

### What to implement

**`core/settings.py`**
- Add `DEFAULT_THROTTLE_CLASSES` to `REST_FRAMEWORK`:
  - `AnonRateThrottle`: 20 requests/minute for unauthenticated users
  - `UserRateThrottle`: 200 requests/minute for authenticated users
- Add `DEFAULT_THROTTLE_RATES` dict:
  - `anon`: `"20/minute"`
  - `user`: `"200/minute"`
  - `auth`: `"5/minute"` (custom scope for login/register)
  - `matching`: `"10/minute"` (custom scope for find_matches — expensive)

**`authentication/views.py`**
- Apply `throttle_classes = [ScopedRateThrottle]` + `throttle_scope = "auth"` to
  `register` and `login` actions

**`matching/views.py`**
- Apply `throttle_classes = [ScopedRateThrottle]` + `throttle_scope = "matching"` to
  the `find_matches` action

**`core/settings.py` — cache backend**
- Throttle counters are stored in the Django cache; confirm `CACHES` is using Redis
  (already configured) so throttle state survives worker restarts

### Files to change

```
core/settings.py
authentication/views.py
matching/views.py
```

### Acceptance criteria

- [ ] Anonymous user hitting `/api/auth/login/` more than 5 times/minute receives `429 Too Many Requests`
- [ ] Authenticated user hitting `find_matches` more than 10 times/minute receives `429`
- [ ] Normal authenticated usage (under limits) is unaffected — returns `200`
- [ ] Throttle counters reset after the time window expires
- [ ] Tests added/updated in `authentication/tests.py` and `matching/tests.py`

### Git workflow

```bash
git checkout main
git pull origin main
git checkout -b enhance/rate-limiting

# implement changes
bash Backend/check.sh          # run locally on server
git add ...
git commit -m "feat: add API rate limiting and throttling"
git push -u origin enhance/rate-limiting
# open PR → merge to main after CI passes
```

---

## Task 2 — Structured Logging + Health Check + API Docs

**Branch:** `enhance/logging-health`
**Blueprint reference:** Step 6 — Monitoring, Telemetry & Observability

### Problem

The entire application uses `print()` statements for debugging. There is no structured
logging, no log levels, no log rotation hooks, and no correlation IDs. Load balancers
and uptime monitors have no endpoint to probe. `drf-spectacular` is installed but not
wired into `urls.py`.

### What to implement

**`core/settings.py` — LOGGING config**
- Add a `LOGGING` dictionary:
  - Console handler with `INFO` level in production, `DEBUG` in development
  - Format: `[timestamp] [level] [logger_name] message`
  - Separate loggers for: `django`, `django.request`, `django.db.backends` (SQL),
    `authentication`, `chat`, `flights`, `matching`, `recommendations`
  - `django.db.backends` logger at `DEBUG` level only when `DEBUG=True` (shows SQL queries)

**Replace `print()` with `logging` in:**
- `chat/consumers.py` — all WebSocket lifecycle print statements
- `matching/matching_service.py` — all scenario/debug print statements
- `matching/views.py` — debug prints in `find_matches`
- `flights/views.py` — status update prints
- `flights/signals.py` — signal handler prints

**Health check endpoint — new file `core/health.py`**
- Create a `HealthCheckView` (simple `APIView`, `AllowAny`):
  - Checks database: runs `SELECT 1`
  - Checks Redis: runs `PING`
  - Returns `200 OK` with JSON:
    ```json
    {
      "status": "healthy",
      "database": "ok",
      "redis": "ok",
      "version": "1.0.0"
    }
    ```
  - Returns `503 Service Unavailable` if any check fails

**`core/urls.py`**
- Register `/health/` → `HealthCheckView`
- Register `/api/docs/` → `drf-spectacular` SpectacularAPIView
- Register `/api/docs/ui/` → SpectacularSwaggerView

**`core/settings.py` — drf-spectacular**
- Add `drf_spectacular` to `INSTALLED_APPS`
- Add `SPECTACULAR_SETTINGS` dict with title, version, description

### Files to change

```
core/settings.py
core/urls.py
core/health.py          (new)
chat/consumers.py
matching/matching_service.py
matching/views.py
flights/views.py
flights/signals.py
```

### Acceptance criteria

- [ ] `GET /health/` returns `200` with `{"status": "healthy", ...}` when DB and Redis are up
- [ ] `GET /health/` returns `503` when DB is unreachable
- [ ] `GET /api/docs/ui/` returns the Swagger UI page
- [ ] No `print()` calls remain in any backend Python file
- [ ] Application logs appear with timestamps and log levels (not raw print output)
- [ ] Tests added for the health check endpoint

### Git workflow

```bash
git checkout main && git pull origin main
git checkout -b enhance/logging-health
# implement, test on server, PR to main
```

---

## Task 3 — Fix N+1 Queries

**Branch:** `enhance/query-optimization`
**Blueprint reference:** Step 3 — ORM Query Prevention; Step 4 — Read Replicas

### Problem

Multiple views have N+1 query patterns that will cause exponential DB load at scale:

1. **`FlightViewSet.get_queryset`** — loops over every flight and fires one `UPDATE`
   query per flight to sync the status. For a user with 10 flights = 11 queries instead of 1.

2. **`community_posts` action** — fetches 20 flights with no `select_related("user")`,
   then accesses `flight.user.profile_image_url` etc. inside the loop = 20 extra user
   queries per request.

3. **`MatchViewSet.get_queryset`** — no `select_related` on `user1`, `user2`, `flight1`,
   `flight2`. The `MatchSerializer` accesses all four FK fields = 4 queries per match row.

4. **`MatchingService._apply_user_filters`** — calls `user.interests.values_list(...)` and
   `other_user.interests.values_list(...)` individually per candidate inside a loop.
   For 20 match candidates = 40 extra queries.

5. **`ChatRoomList.get_queryset`** — loads all `Match` objects into Python, then iterates
   to extract user IDs. Should use a DB-level `values_list` query.

### What to implement

**`flights/views.py`**
- Replace the per-flight status UPDATE loop in `get_queryset` with a single
  `Flight.objects.filter(...).update(status=...)` bulk call using `Case/When`
- Add `select_related("user")` to the `community_posts` query

**`matching/views.py`**
- Add `select_related("user1", "user2", "flight1", "flight2")` to `get_queryset`

**`matching/matching_service.py`**
- In `find_matches_for_user`, after collecting all candidate users, batch-fetch their
  interests with a single `UserInterest.objects.filter(user__in=candidate_users)` call
- Build an `interests_map = {user_id: [interests]}` dict
- Pass `interests_map` into `calculate_common_interests` instead of re-querying per pair
- In `_apply_user_filters`, use the pre-fetched interests map

**`chat/views.py` — `ChatRoomList`**
- Replace the Python loop over Match objects with:
  ```python
  matched_user_ids = Match.objects.filter(
      Q(user1=user) | Q(user2=user), status='matched'
  ).annotate(
      other_id=Case(
          When(user1=user, then=F('user2_id')),
          default=F('user1_id')
      )
  ).values_list('other_id', flat=True)
  ```

### Files to change

```
flights/views.py
matching/views.py
matching/matching_service.py
chat/views.py
```

### Acceptance criteria

- [ ] `community_posts` generates exactly 1 DB query (verified with `django.test.utils.override_settings` + `connection.queries`)
- [ ] `MatchViewSet` list generates at most 2 queries (1 for matches + 1 prefetch)
- [ ] `find_matches` interest calculation uses at most 1 extra query for all candidates combined
- [ ] `ChatRoomList` replaces Python loop with a single annotated queryset
- [ ] All existing tests still pass after refactoring

### Git workflow

```bash
git checkout main && git pull origin main
git checkout -b enhance/query-optimization
```

---

## Task 4 — Redis Caching for API Responses

**Branch:** `enhance/api-caching`
**Blueprint reference:** Step 4 — Multi-Layer Caching; Cache-Aside Pattern

### Problem

`django-redis` is configured in `CACHES` but the Django cache API
(`from django.core.cache import cache`) is never called in any view, service, or
serializer. Every request for `community_posts`, `find_matches`, and
`get_recommendations` hits the database and external APIs every single time.

### What to implement

**`flights/views.py` — `community_posts`**
- Cache the response in Redis with key `community_posts` and TTL of 5 minutes
- Invalidate the cache key on `Flight` create/update signals

**`matching/views.py` — `find_matches`**
- Cache per-user match results with key `matches_user_{user_id}` and TTL of 2 minutes
- Invalidate on new match creation or flight update

**`recommendations/views.py` — `get_recommendations`**
- Cache per-airport recommendations with key `recommendations_{airport_code}` and TTL of 10 minutes
- Invalidate when new `AirportPlace` records are created for that airport

**`core/settings.py`**
- Add `KEY_PREFIX` to the Redis cache config to namespace keys: `"nailwing"`
- Add `TIMEOUT` default: `300` (5 minutes)

**Cache invalidation — `flights/signals.py`**
- Add `post_save` signal on `Flight` to invalidate `community_posts` cache key

### Files to change

```
core/settings.py
flights/views.py
flights/signals.py
matching/views.py
recommendations/views.py
```

### Acceptance criteria

- [ ] Second request to `community_posts` is served from Redis (verified by asserting 0 DB queries on second call)
- [ ] Cache is invalidated when a new flight is created
- [ ] `find_matches` results are cached per user for 2 minutes
- [ ] Cached responses are identical to uncached responses
- [ ] Tests cover both cache hit and cache miss paths

### Git workflow

```bash
git checkout main && git pull origin main
git checkout -b enhance/api-caching
```

---

## Task 5 — Celery Configuration + Async Task Offloading

**Branch:** `enhance/celery-async`
**Blueprint reference:** Step 2 — Asynchronous Offloading; Step 3 — Background Workers

### Problem

Celery is installed (`celery==5.5.3`) but there is no `core/celery.py`, no
`CELERY_BROKER_URL` in settings, and no task files anywhere. Every expensive
operation runs synchronously inside the HTTP request-response cycle:

- `MatchingService.find_matches_for_user` — 6+ DB queries, scoring, filtering
- `PlacesAPIService.get_places_near_airport` — external HTTP call to Google Places API
- Profile image upload to Cloudinary — synchronous in the profile PATCH handler

### What to implement

**`core/celery.py`** (new file)
- Instantiate the Celery app with Django settings
- Set `CELERY_BROKER_URL = REDIS_URL` (reuse existing Redis)
- Set `CELERY_RESULT_BACKEND = REDIS_URL`
- Configure task serialization: `json`
- Configure task time limits: soft 30s, hard 60s

**`core/__init__.py`**
- Import the Celery app so it loads with Django

**`core/settings.py`**
- Add `CELERY_BROKER_URL`, `CELERY_RESULT_BACKEND`, task serialization settings

**`matching/tasks.py`** (new file)
- `run_matching_for_user(user_id, flight_id=None)` — Celery task wrapping
  `MatchingService.find_matches_for_user`
- `matching/views.py` `find_matches` action: call `.delay()` and return a
  `202 Accepted` with a task ID, or keep sync for now with a feature flag

**`recommendations/tasks.py`** (new file)
- `fetch_airport_recommendations(airport_code)` — Celery task wrapping
  `PlacesAPIService.get_places_near_airport`, stores result in cache

**`docker-compose.yml`**
- Add `celery` service:
  ```yaml
  celery:
    build: .
    command: celery -A core worker --loglevel=info --concurrency=4
    depends_on: [redis, web]
    env_file: .env
  ```
- Add `celery-beat` service for periodic tasks (future use)

### Files to change

```
core/celery.py          (new)
core/__init__.py
core/settings.py
matching/tasks.py       (new)
recommendations/tasks.py (new)
matching/views.py
Backend/docker-compose.yml
```

### Acceptance criteria

- [ ] `celery -A core worker` starts without errors
- [ ] `run_matching_for_user.delay(user_id)` executes successfully in a worker
- [ ] `fetch_airport_recommendations.delay(airport_code)` executes and populates cache
- [ ] Docker Compose `celery` service starts alongside `web` and `redis`
- [ ] Tests mock Celery task execution (use `CELERY_TASK_ALWAYS_EAGER=True` in test settings)

### Git workflow

```bash
git checkout main && git pull origin main
git checkout -b enhance/celery-async
```

---

## Task 6 — WebSocket Hardening

**Branch:** `enhance/websocket-hardening`
**Blueprint reference:** Step 2 — Decoupled Real-Time Architecture; Step 5 — Reliability;
Step 6 — Graceful Connection Draining

### Problem

Four specific bugs and gaps exist in the current WebSocket implementation:

1. **Redis password dropped** — `parse_redis_url()` in `settings.py` extracts `(host, port)`
   but discards the `:password@` part. If Redis requires authentication in production,
   channel layer connections silently fail.

2. **Origin validator bypassed** — `core/asgi.py` wraps WebSocket routes with
   `AuthMiddlewareStack(...)` but `AllowedHostsOriginValidator` is imported and unused.
   Any origin can open a WebSocket connection.

3. **`asyncio.create_task` in sync context** — `handle_message` calls
   `asyncio.create_task(self.cache_message(...))` but `handle_message` is called from
   inside a `@database_sync_to_async` decorated method, which runs in a thread executor
   — not in an async event loop. `create_task` raises `RuntimeError` silently, meaning
   message caching never actually happens.

4. **No graceful shutdown** — When Daphne receives `SIGTERM` during a deployment, it
   drops all active WebSocket connections immediately. Clients get a hard disconnect
   with no reconnect signal.

### What to implement

**`core/settings.py` — fix `parse_redis_url`**
- Rewrite the function to correctly extract and forward the password:
  ```python
  "hosts": [{"host": host, "port": port, "password": password, "db": db}]
  ```

**`core/asgi.py` — enable origin validator**
- Wrap the WebSocket URLRouter with `AllowedHostsOriginValidator`:
  ```python
  application = ProtocolTypeRouter({
      "websocket": AllowedHostsOriginValidator(
          AuthMiddlewareStack(URLRouter(websocket_urlpatterns))
      ),
  })
  ```

**`chat/consumers.py` — fix `asyncio.create_task` bug**
- The `cache_message` method should be called with `await` directly, not via
  `asyncio.create_task`, since `handle_message` is already an `async` method.
- Move `cache_message` call to after DB save: `await self.cache_message(message_obj)`

**`chat/consumers.py` — graceful shutdown**
- Add a `SIGTERM` handler in the consumer's `connect` lifecycle or at the app level
- On shutdown signal: send a `close_code=4000` frame to the client with a
  `{"type": "reconnect", "delay": 5}` payload before closing
- This tells the Flutter client to reconnect with exponential backoff

**`core/settings.py` — persistent DB connections**
- Add `"CONN_MAX_AGE": 60` and `"CONN_HEALTH_CHECKS": True` to the `DATABASES["default"]`
  options to enable connection reuse across requests

### Files to change

```
core/settings.py
core/asgi.py
chat/consumers.py
```

### Acceptance criteria

- [ ] Channel layer connects successfully to a Redis instance that requires password auth
- [ ] WebSocket connections from non-allowed origins are rejected with `403`
- [ ] `cache_message` is called and actually executes (verified by checking Redis after
  sending a message in tests)
- [ ] On server restart, connected clients receive a reconnect signal before disconnection
- [ ] `CONN_MAX_AGE=60` is set in DATABASES config
- [ ] All existing WebSocket tests still pass

### Git workflow

```bash
git checkout main && git pull origin main
git checkout -b enhance/websocket-hardening
```

---

## Task 7 — DB Connection Pooling + Migration Safety + Code Cleanup

**Branch:** `enhance/db-pooling`
**Blueprint reference:** Step 3 — PgBouncer; Step 6 — Zero-Downtime Database Migrations

### Problem

- Django's default `CONN_MAX_AGE=0` means every HTTP request and every WebSocket
  DB call opens a fresh TCP connection to PostgreSQL. Under real concurrent load,
  Postgres will hit its `max_connections` limit.
- The `user_profile` action in `authentication/views.py` is defined twice. Python's
  method resolution silently uses the second definition — the first is dead code that
  adds confusion.
- No zero-downtime migration procedure is documented or enforced.

### What to implement

**`Backend/docker-compose.yml` — add PgBouncer**
- Add a `pgbouncer` service using `bitnami/pgbouncer`:
  ```yaml
  pgbouncer:
    image: bitnami/pgbouncer:latest
    environment:
      POSTGRESQL_HOST: <db_host>
      POSTGRESQL_PORT: 5432
      PGBOUNCER_POOL_MODE: transaction
      PGBOUNCER_MAX_CLIENT_CONN: 1000
      PGBOUNCER_DEFAULT_POOL_SIZE: 20
  ```
- Route Django's `DATABASE_URL` through PgBouncer's port

**`core/settings.py`**
- `CONN_MAX_AGE`: already handled in Task 6, confirm it is applied
- Add `OPTIONS: {"connect_timeout": 10}` to DATABASES to avoid hung connections

**`authentication/views.py`**
- Remove the first (duplicate) `user_profile` method definition
- Add a docstring to the remaining method

**`Backend/check.sh`**
- Add a migration safety check step:
  ```bash
  echo "6. Checking for unsafe migrations..."
  python manage.py migrate --check
  ```
- Add instructions for the 5-step zero-downtime migration procedure as a comment

**`.github/workflows/ci.yml`**
- Add a `migration-check` step that runs `manage.py migrate --check` to catch
  missing migrations before deployment

### Files to change

```
Backend/docker-compose.yml
core/settings.py
authentication/views.py
Backend/check.sh
.github/workflows/ci.yml
```

### Acceptance criteria

- [ ] PgBouncer service starts in Docker Compose and proxies DB connections
- [ ] Duplicate `user_profile` method is removed, only one definition remains
- [ ] `GET /api/auth/{pk}/user_profile/` still works after deduplication
- [ ] CI pipeline fails if there are unapplied migrations
- [ ] All existing tests pass

### Git workflow

```bash
git checkout main && git pull origin main
git checkout -b enhance/db-pooling
```

---

## Development Rules

1. **Never work directly on `main`** — always use a feature branch per task
2. **Run tests before pushing** — use `bash Backend/check.sh` on the server via SSH
3. **One PR per task** — keep changes focused and reviewable
4. **Tests required** — each task must include tests covering the new behaviour
5. **CI must be green** — do not merge a PR with failing CI checks

### Branches & merge order

Tasks can be done in order or in parallel. The dependency chain is:

```
Task 1 (rate limiting)      ─── independent, do first
Task 2 (logging/health)     ─── independent
Task 3 (N+1 fixes)          ─── do before Task 4 (caching)
Task 4 (caching)            ─── depends on Task 3 being clean
Task 5 (Celery)             ─── depends on Task 4 (cache layer must exist)
Task 6 (WebSocket)          ─── independent, can run parallel to 3-5
Task 7 (pooling/cleanup)    ─── do last
```

### How to start a task

```bash
# 1. Create the branch
git checkout main
git pull origin main
git checkout -b enhance/<task-name>

# 2. Implement the changes

# 3. Run tests on the server
ssh -i "$env:USERPROFILE\.ssh\github_deploy" root@164.68.109.145 \
  "cd /root/Nailwing && git fetch origin && git checkout enhance/<task-name> && \
   git pull && cd Backend && \
   /root/Nailwing/Backend/venv/bin/python manage.py test \
   --settings=core.test_settings --verbosity=1 2>&1 | tail -10"

# 4. Push and open a PR
git push -u origin enhance/<task-name>
# Open PR on GitHub → wait for CI → merge
```
