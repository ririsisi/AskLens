# REASONIX.md — AskLens

## Stack

- **Backend**: Java 21 + Spring Boot 3.5.0 (Spring MVC, no WebFlux)
- **DB access**: MyBatis-Plus 3.5.15 (`BaseMapper` + `LambdaQueryWrapper`, no JdbcTemplate)
- **Auth**: JJWT 0.12.6 (HMAC-SHA256 access token) + Spring Security Crypto (BCrypt)
- **Frontend**: Vue 3.5 + TypeScript 6.0 + Vite 8 + Element Plus 2.14 + Pinia 3.0
- **Search**: PostgreSQL 16 + pgvector (HNSW, 512d COSINE_DISTANCE) + Elasticsearch 8.x (IK tokenizer)
- **AI**: Spring AI Alibaba 1.1.2.0 (DashScope — 通义千问 Chat + text-embedding-v3)
- **Docs**: Knife4j 4.5.0 (`/doc.html`)
- **Infra**: MinIO (S3 object storage), Apache PDFBox/POI (DOCX parsing)

## Layout

| Path | What lives there |
|---|---|
| `AskLens-backend/` | Spring Boot backend, `./mvnw` build |
| `AskLens-backend/src/main/java/com/asklens/` | Layered packages: `auth/`, `user/`, `group/`, `document/`, `ingestion/`, `qa/`, `assistant/`, `engine/` |
| `AskLens-backend/src/test/` | Tests (single test file exists for QaController) |
| `AskLens-frontend/` | Vue 3 + Vite SPA |
| `AskLens-frontend/src/api/` | Axios API wrappers |
| `AskLens-frontend/src/views/` | Page components (documents, qa, assistant, groups, admin) |
| `docs/` | Project documentation (V1.0–V4.0 design docs) |
| `sql/schema.sql` | DB schema DDL |
| `deploy/local/` | Docker Compose + `.env.example` for local services |

## Commands

**Backend** (from `AskLens-backend/`, JDK 21):
- `./mvnw clean compile` — compile
- `./mvnw test` — run tests (JUnit 5 + Spring MockMvc)
- `./mvnw test -Dtest=ClassName#methodName` — single test
- `./mvnw spring-boot:run` — start (port 10001, local profile)
- `./mvnw clean package -DskipTests` — build JAR

**Frontend** (from `AskLens-frontend/`):
- `npm run dev` — Vite dev server
- `npm run build` — type-check + Vite build
- `npm run lint` — oxlint + eslint (`.oxlintrc.json` + `eslint.config.ts`)
- `npm run format` — Prettier (no-semi, single-quote, 100-width)

## Conventions

- **API responses**: Every controller returns `ApiResponse<T>` record (`success`, `data`, `message`).
- **Exceptions**: Throw `BusinessException` (400), `UnauthorizedException` (401), `ForbiddenException` (403) — `GlobalExceptionHandler` maps to HTTP status codes.
- **DB enums**: Stored as VARCHAR using MyBatis `EnumTypeHandler` (`.name()` string).
- **Entity models**: Lombok `@Data` on entity classes with MyBatis-Plus `@TableName` / `@TableId`.
- **Auth**: JWT Bearer token in `Authorization` header; `CurrentUserService.getRequiredCurrentUser(request)` in controllers.
- **Frontend**: Vue 3 Composition API + named exports; `.vue` SFCs with `<script setup lang="ts">`.
- **Formatter**: Prettier with `semi: false`, `singleQuote: true`, `printWidth: 100`.
- **Frontend lint**: eslint config at `eslint.config.ts`, oxlint config at `.oxlintrc.json`.

## Watch out for

- **JDK 21 required** — the project uses record syntax, virtual threads, pattern matching. No JDK 17 compatibility.
- **`@Profile("dev")` seeds admin account** — `DevAdminInitializer` auto-creates `admin`/`admin123` when profile `dev` is active.
- **Enums use `name()` not `ordinal()`** — adding/renaming enum constants changes stored values; manage DB migration carefully.
- **Refresh tokens use rotation** — each refresh issues a new token and invalidates the old one (stored in `user_refresh_tokens` table, httpOnly cookie).
- **Static file server** — `src/main/resources/static/` serves the production frontend build under `/`.
- **`rag.auth` config prefix** — all auth-related `@ConfigurationProperties(prefix="rag.auth")` in `AuthProperties`.
- **`DefaultEnumTypeHandler`** — configured globally in `application.yml`; custom type handlers need explicit registration.
