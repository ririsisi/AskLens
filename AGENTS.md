# AskLens (答镜)

RAG + AI Agent 企业知识平台。Monorepo: 后端 (Spring Boot) + 前端 (Vue 3)。

## Quick Start

```bash
# 1. Start middleware (PostgreSQL + ES + MinIO)
scripts\start-local.cmd

# 2. Backend (port 10001)
cd AskLens-backend
# Set JAVA_HOME to JDK 21 first
./mvnw spring-boot:run          # profile=local (default)
# Or via VS Code: F5 with "AskLens Backend (local)" launch config

# 3. Frontend (port 3000, proxies /api → localhost:10001)
cd AskLens-frontend
npm install
npm run dev
```

- Dev admin: `admin` / `admin123` (only in `dev` profile)
- API docs: http://localhost:10001/doc.html

## Build & Test

### Backend (Maven wrapper, JDK 21 required)
- `./mvnw clean compile` — compile only
- `./mvnw test` — run all tests (1 test: `QaControllerTest`, WebMvcTest + Mockito)
- `./mvnw test -Dtest=QaControllerTest#methodName` — single test
- `./mvnw clean package -DskipTests` — build jar

### Frontend (Node >=20.19)
- `npm run dev` — dev server (port 3000, Vite proxies `/api` → `localhost:10001` with SSE passthrough)
- `npm run build` — type-check + build in parallel via npm-run-all2
- `npm run type-check` — vue-tsc
- `npm run lint` — oxlint then eslint (run-s)
- `npm run format` — prettier src/

## Tech Stack

- **Backend**: Java 21 + Spring Boot 3.5, MyBatis-Plus 3.5.15 (all DB), PostgreSQL 16 + pgvector (HNSW, cosine_distance), Elasticsearch 8.x (JDK HttpClient, not Spring Data ES), MinIO (S3, conditional via @ConditionalOnProperty), DashScope Chat + OpenAI-compatible Embedding, JJWT (ThreadLocal, not Spring Security), Knife4j
- **Frontend**: Vue 3.5 + Composition API, Vite 8, TypeScript 6, Element Plus 2.14, Pinia 3, marked 18
- **AI**: Spring AI Alibaba 1.1.2.0 — ReactAgent graph engine, text-embedding-v3 (512d)
- **Lombok 1.18** available but **unused** — entity getters/setters are hand-written

## Architecture

### Configuration Profiles
- `local` (default) — convenience-first, inline credentials, no DevAdminInitializer
- `dev` — security-first, all secrets via env vars, DevAdminInitializer seeds admin on startup
- Base config in `application.yml` (MyBatis-Plus, enum handler, mapper locations); profile overrides in `application-{profile}.yml`

### Package Layout (Java, com.asklens)
```
auth/          JWT auth, refresh tokens, cookies
user/          User CRUD, password change
group/         Groups, invitations, membership roles (Owner/Manager/Member)
document/      Chunked upload (init→chunks→complete/秒传), preview, soft-delete
ingestion/     ETL pipeline: reader → parser → transformer → splitter → vector + ES
qa/            Query planning (LLM), RRF hybrid search, 4-level evidence evaluation
assistant/     ReactAgent, CHAT/KB_SEARCH modes, 3-level memory compression, SSE
engine/        PGvector adapter, ES index service, MinIO storage
```

### Key Flow: Document Ingestion
```
Upload complete → Spring @TransactionalEventListener (AFTER_COMMIT)
  → @Async → @Retryable ETL pipeline:
  DocumentReader → DocumentParser → TextCleanupTransformer → DocumentSplitter
  → VectorStore.add (pgvector, batch=9) + Elasticsearch _bulk index
```
- Chunk config: target 240 tokens, max 320, overlap 32
- Stale docs stuck in PROCESSING > 30 min auto-recovered as FAILED on restart

### Key Flow: RAG Q&A
```
User question → LLM Query Planning (DIRECT/REWRITE/DECOMPOSE, max 3 parallel)
  → Dual retrieval: PGvector (HNSW cosine) + ES (IK BM25, bool/rescore)
  → RRF fusion + cluster aggregation + neighbor window expansion
  → 4-level evidence (NONE→WEAK→PARTIAL→SUFFICIENT) → LLM answer + citations
```

### Auth
- JWT access token (30 min) + refresh token (14 days, httpOnly cookie, DB rotation)
- ThreadLocal UserContext (no Spring Security)
- Filter skips: /auth/login, /register, /refresh, /logout
- Use `CurrentUserService.getRequiredCurrentUser(request)` / `requireSystemAdmin(request)`

### API Response
- Every endpoint returns `ApiResponse<T>` record: `{success, data, message}`
- Exceptions: `BusinessException`(400) / `UnauthorizedException`(401) / `ForbiddenException`(403) → `GlobalExceptionHandler`

### Database
- Enums stored as VARCHAR via `EnumTypeHandler` (`.name()` values)
- Mapper XML: `classpath*:/mappers/**/*.xml` (12 XML files)
- MapperScan: `com.asklens.**.mapper`

## Windows Notes

- `chcp 65001` before shell commands to avoid GBK/UTF-8 mixed encoding (see `.cursor/rules/windows-shell-utf8.mdc`)
- JAVA_HOME must point to JDK 21 (example path in `.vscode/launch.json`)
- Docker Desktop must be running before `scripts\start-local.cmd`
- Use `scripts\start-local.cmd` (wraps .ps1 without ExecutionPolicy issues)

## References

- `CLAUDE.md` — kept for Claude Code compatibility; this file supersedes it for OpenCode
- `.cursor/rules/obsidian-knowledge-base.mdc` — docs/ Obsidian vault conventions
- `docs/` — detailed design docs (V1.0–V4.0 project docs + design decisions)
