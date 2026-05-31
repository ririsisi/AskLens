---
type: doc
version: rag
tags: [argus, rag, ingestion, hybrid-search, qa, moc]
status: published
related:
  - "[[V2.0-项目文档]]"
  - "[[V2.0-设计决策]]"
  - "[[V3.0-项目文档]]"
  - "[[V3.0-设计决策]]"
  - "[[V4.0-设计决策]]"
  - "[[assistant-module-guide]]"
  - "[[Home]]"
---

# Argus RAG 核心原理图

> 本文档描述 Argus 项目中 **Retrieval-Augmented Generation（检索增强生成）** 的完整闭环：
> 文档如何入库、如何被检索、如何驱动大模型生成带引用的回答。
>
> 相关详细设计见 [[V2.0-设计决策]]（入库）、[[V3.0-设计决策]]（问答）、[[V4.0-设计决策]]（Agent 集成）。

**相关文档**：[[V2.0-设计决策]] · [[V3.0-设计决策]] · [[V2.0-项目文档]] · [[V3.0-项目文档]] · [[V4.0-设计决策]] · [[assistant-module-guide]] · [[Home]]

---

## 1. 一页总览

Argus 的 RAG 不是简单的「Embedding + Top-K + Prompt」，而是四层工程化设计：

| 层次 | 能力 | 核心类 |
|------|------|--------|
| **知识入库** | 分片上传 → 异步 ETL → 结构感知切片 → 双路索引 | `DocumentIngestionAsyncService`、`EtlDocumentIngestionProcessor` |
| **查询理解** | LLM 规划检索策略（DIRECT / REWRITE / DECOMPOSE） | `QueryPlanningService` |
| **多路召回** | 向量语义 + 关键词 BM25 → RRF 融合 → 类簇 + 邻居窗口 | `HybridChunkRetrievalService` |
| **证据门控** | 四级证据评估 → 拒答 / 谨慎答 → 结构化输出 + 引用溯源 | `QaChatService`、`CitationAssembler` |

### 1.1 闭环概览

```mermaid
flowchart LR
    INGEST[① 知识入库] --> RETRIEVE[② 检索增强] --> GENERATE[③ 生成回答]
```

### 1.2 ① 知识入库（V2）

```mermaid
flowchart TB
    UP[文档上传] --> MINIO[(MinIO 对象存储)]
    UP --> ETL[异步 ETL]
    ETL --> CHUNKS[(PostgreSQL<br/>document_chunks)]
    ETL --> VEC[(PGvector)]
    ETL --> ES[(Elasticsearch)]
```

### 1.3 ② 检索增强（V3）

```mermaid
flowchart TB
    Q[用户问题] --> QP[查询规划 LLM]
    QP --> HY[混合检索 RRF]
    CHUNKS[(document_chunks)] --> HY
    VEC[(PGvector)] --> HY
    ES[(Elasticsearch)] --> HY
    HY --> EV[证据评估<br/>NONE→SUFFICIENT]
```

### 1.4 ③ 生成回答

```mermaid
flowchart TB
    EV[证据评估结果] -->|有证据| PROMPT[构造 RAG Prompt]
    EV -->|无证据| REJECT[拒答 INSUFFICIENT_EVIDENCE]
    PROMPT --> LLM[问答 LLM]
    LLM --> ANS[结构化回答 + Citations]
```

---

## 2. 系统架构与存储

**数据隔离**：所有检索均在 `groupId` 维度过滤，向量库与 ES 索引均携带 `groupId` 元数据。

### 2.1 客户端入口

```mermaid
flowchart LR
    FE[Argus-frontend] --> DOC[document 分片上传]
    FE --> QA[qa POST /ask]
    FE --> ASST[assistant CHAT/KB]
```

### 2.2 入库链

```mermaid
flowchart TB
    DOC[document 分片上传] --> MINIO[(MinIO)]
    DOC --> ASYNC[DocumentIngestionAsyncService]
    ASYNC --> ETL[EtlDocumentIngestionProcessor]
    ETL --> MINIO
    ETL --> CHUNK_SVC[ChunkService] --> PG[(PostgreSQL)]
    ETL --> VEC_SVC[VectorIngestionService] --> PGV[(PGvector HNSW)]
    ASYNC --> ES_SVC[ElasticsearchChunkIndexService] --> ESIDX[(Elasticsearch)]
```

### 2.3 问答链

```mermaid
flowchart TB
    QA[qa POST /ask] --> CHAT[QaChatService]
    ASST[assistant KB_SEARCH] --> RET[ReadyChunkDocumentRetriever]
    CHAT --> RET --> HYBRID[HybridChunkRetrievalService]
    HYBRID --> QP[QueryPlanningService] --> LLM_QP[查询规划 LLM]
    HYBRID --> PGV[(PGvector)]
    HYBRID --> ESIDX[(Elasticsearch)]
    HYBRID --> PG[(PostgreSQL)]
    CHAT --> LLM_QA[问答 LLM]
    CHAT --> PARSER[QaAnswerParser]
    CHAT --> CITE[CitationAssembler]
```

---

## 3. 知识入库：ETL 流水线

上传完成后通过 **Spring Event + @Async + AFTER_COMMIT** 触发异步 ETL，失败最多重试 3 次（2s / 4s / 8s 退避）。

### 3.1 触发与异步编排

上传事务内写入 `documents`（`status=PROCESSING`）并发布事件；**事务提交后**才由 Listener 异步执行 ETL。注意：`READY` 之前还有一步 ES 索引同步（见 3.3）。

```mermaid
flowchart TD
    UPLOAD([上传事务提交<br/>documents.status=PROCESSING]) --> EVENT[publish DocumentIngestionRequestedEvent]
    EVENT --> COMMIT["TransactionalEventListener<br/>AFTER_COMMIT"]
    COMMIT --> LISTENER["DocumentIngestionAsyncListener<br/>Async"]
    LISTENER --> INGEST[DocumentIngestionAsyncService.ingestDocument]
    INGEST --> CLEAN[cleanupProcessingArtifacts<br/>清理旧 chunk / 向量 / ES]
    CLEAN --> ETL[EtlDocumentIngestionProcessor<br/>步骤 1~7]
    ETL --> ES[syncSearchIndex → Elasticsearch]
    ES --> DONE([markDocumentStatus → READY])
    INGEST -.->|"Retryable 3 次仍失败 Recover"| FAIL[status=FAILED]
```

### 3.2 ETL 前半：Extract + Transform

```mermaid
flowchart TD
    S1[1. findDocument] --> S2[2. Extract<br/>MinIO 下载 + Parser]
    S2 --> S3[3. TextCleanup<br/>换行/控制字符/空白]
    S3 --> S4[4. preview_text 落库]
    S4 --> S5[5. StructureAwareChunk<br/>结构感知切片]
```

### 3.3 ETL 后半：Load + 索引同步

步骤 8、9 由 `DocumentIngestionAsyncService` 在 Processor 完成后执行。**代码执行顺序**是先 `syncSearchIndex`（原设计文档称第 9 步），再 `markDocumentStatus → READY`（原设计文档称第 8 步）。

```mermaid
flowchart TD
    S6[6. ChunkService<br/>→ document_chunks] --> S7[7. VectorIngestionService<br/>→ vector_store]
    S7 --> S9[9. syncSearchIndex<br/>→ Elasticsearch]
    S9 --> S8[8. markDocumentStatus → READY]
```

### 3.4 结构感知切片策略

按**章节**处理，不是整篇文本线性走完全部步骤：未超 `maxTokens` 的章节直接成块；仅超大章节才继续拆分。`overlap` 在最终 `buildDocuments` 阶段施加，不属于 `mergePieces`。

```mermaid
flowchart TD
    RAW[原始文本] --> H[按 Markdown 标题分节<br/>代码块内 # 不识别]
    H --> CHECK{章节 ≤ maxTokens?}
    CHECK -->|是| PIECE[整节作为一个 piece]
    CHECK -->|否| P[按连续空行拆段落]
    P --> PS{段落 ≤ maxTokens?}
    PS -->|是| ADD[加入 pieces]
    PS -->|否| S[按句子标点拆分<br/>。！？；!?;]
    S --> C[仍超长 → 按 maxTokens 字符硬截断]
    C --> ADD
    ADD --> M[贪心合并相邻 pieces<br/>目标 targetTokens，上限 maxTokens]
    PIECE --> BUILD[buildDocuments<br/>非首块向前 overlap]
    M --> BUILD
    BUILD --> OUT[Document chunks]
```

默认参数（`ingestion.chunking`）：`target-tokens=240`，`max-tokens=320`，`overlap-tokens=32`。

### 3.5 双路索引写入

| 存储 | 表/索引 | 用途 | 写入时机 |
|------|---------|------|----------|
| PostgreSQL | `document_chunks` | 切片原文、序号、元数据 | ETL 第 6 步 |
| PGvector | `vector_store` | 语义向量（COSINE + HNSW） | ETL 第 7 步 |
| Elasticsearch | `argus-chunks-*` | IK 分词 + BM25 关键词 | ETL 第 9 步 |

向量 ID 规则：`UUID(documentId + ":" + chunkIndex)`，按 `documentId` 幂等删除后重写。

---

## 4. 检索增强：混合检索引擎

核心入口：`HybridChunkRetrievalService.retrieve(groupId, question, topK=5)`。

### 4.1 阶段 A：查询规划

```mermaid
flowchart TD
    Q([用户问题 + groupId]) --> PLAN_LLM[QueryPlanningService.plan]
    PLAN_LLM --> STRAT{策略}
    STRAT -->|DIRECT| Q1[原问题]
    STRAT -->|REWRITE| Q2[改写问句]
    STRAT -->|DECOMPOSE| Q3[1~3 条子查询]
```

### 4.2 阶段 B：双通道召回 + RRF

```mermaid
flowchart TD
    QLIST[queries] --> VEC[PgVectorRetrievalAdapter<br/>余弦相似度 top-50]
    QLIST --> KW[Elasticsearch<br/>BM25 top-50]
    VEC --> MERGE[按 chunkId 累加 RRF]
    KW --> MERGE
    MERGE --> RANK[降序取 topK=5]
```

### 4.3 阶段 C：后处理与证据评估

```mermaid
flowchart TD
    RANK[topK chunks] --> CLUSTER[buildClusters<br/>同文档连续 chunk 合并]
    CLUSTER --> WINDOW[邻居窗口 ±1 chunk]
    WINDOW --> EVAL[evaluateEvidenceLevel]
    EVAL --> BUNDLE([RetrievedEvidenceBundle])
```

### 4.4 RRF 融合公式

对每条检索语句、每个通道的 rank `r`（从 1 开始）：

```
RRF_score(chunk) += 1 / (k + r)     # 本项目 k = 0
```

同一 chunk 在向量路、关键词路、多条 query 中多次命中时分数累加；最终用 `1 - e^(-score)` 归一化到 [0, 1)。

### 4.5 证据充分度四级门控

| 等级 | 判定条件（简化） | 对 LLM 的指导 |
|------|------------------|---------------|
| **NONE** | 无检索结果 | 必须拒答 |
| **WEAK** | 单条弱命中 | 谨慎回答，说明依据有限 |
| **PARTIAL** | 双通道或 ≥2 条证据 | 只答证据覆盖部分 |
| **SUFFICIENT** | ≥2 条且（双通道命中 或 topScore≥0.85） | 正常回答，禁止臆测 |

证据为空时，`QaChatService` 直接返回 `INSUFFICIENT_EVIDENCE`，不调用问答 LLM。

---

## 5. 问答生成：RAG Prompt → LLM → 引用

### 5.1 请求与检索

```mermaid
sequenceDiagram
    participant C as 客户端
    participant QC as QaController
    participant QS as QaService
    participant CS as QaChatService
    participant R as ReadyChunkDocumentRetriever
    participant H as HybridChunkRetrievalService

    C->>QC: POST /api/qa/ask
    QC->>QS: requireGroupReadable
    QS->>CS: ask(groupId, question)
    CS->>R: retrieveEvidence
    R->>H: retrieve topK=5
    H-->>R: RetrievedEvidenceBundle
    R-->>CS: documents + evidenceLevel
```

### 5.2 生成与响应

```mermaid
sequenceDiagram
    participant CS as QaChatService
    participant LLM as 问答 LLM
    participant CA as CitationAssembler
    participant C as 客户端

    alt 证据为空 NONE
        CS-->>C: INSUFFICIENT_EVIDENCE
    else 有证据
        CS->>CS: createUserPrompt E1/E2...
        CS->>LLM: KnowledgeAnswerOutput
        CS->>CA: assemble citations
        CS-->>C: answer + citations
    end
```

Prompt 模板：`prompts/qa/rag-context.st`，证据以 `E1`、`E2`… 编号注入上下文。

---

## 6. V4 Assistant 与 RAG 的关系

Assistant 模块提供两种模式；**KB_SEARCH** 复用同一套检索引擎，但通过 Agent Tool 按需调用：

### 6.1 CHAT 模式（无检索）

```mermaid
flowchart LR
    USER[用户消息] --> AGENT[ReactAgent]
    AGENT --> REPLY[纯对话回复]
```

### 6.2 KB_SEARCH 模式（按需检索）

```mermaid
flowchart LR
    USER[用户消息] --> AGENT[ReactAgent]
    AGENT --> TOOL[AssistantKnowledgeBaseTool]
    TOOL --> HYBRID[HybridChunkRetrievalService]
    HYBRID --> AGENT
    AGENT --> REPLY[回复 + citations]
```

| 入口 | 路径 | 检索方式 | 生成方式 |
|------|------|----------|----------|
| 知识问答 V3 | `POST /api/qa/ask` | 固定先检索 | `QaChatService` 直接 RAG |
| AI 助手 V4 | `POST /api/assistant/chat` | Agent 决定是否调 Tool | `ReactAgent` 多轮推理 |

---

## 7. 端到端数据流（入库 → 问答）

### 7.1 上传阶段

```mermaid
flowchart LR
    F[PDF/DOCX/MD/TXT] --> M[MinIO]
    F --> D[documents 表]
```

### 7.2 索引阶段

```mermaid
flowchart TB
    M[MinIO 文件] --> PARSE[Parser 解析]
    PARSE --> CLEAN[TextCleanup]
    CLEAN --> CHUNK[StructureAwareChunk]
    CHUNK --> DC[(document_chunks)]
    DC --> EMB[Embedding] --> VS[(vector_store)]
    DC --> ESIDX[(ES chunk index)]
```

### 7.3 问答阶段

```mermaid
flowchart TB
    QST[question] --> QP2[QueryPlanning]
    QP2 --> VSEARCH[向量 search]
    QP2 --> KSEARCH[ES search]
    VSEARCH --> RRF[RRF + Cluster + Window]
    KSEARCH --> RRF
    DC[(document_chunks)] --> RRF
    RRF --> CTX[Evidence E1..En]
    CTX --> GEN[QA LLM] --> ANS[answer + citations]
```

---

## 8. 核心类索引

| 模块 | 类 | 职责 |
|------|-----|------|
| `document/` | `DocumentUploadService` | 分片上传、秒传、触发 ETL 事件 |
| `ingestion/service/` | `DocumentIngestionAsyncService` | 异步 ETL 编排、重试、状态更新 |
| `ingestion/service/` | `EtlDocumentIngestionProcessor` | Extract → Transform → Load 七步 |
| `ingestion/service/pipeline/transformer/` | `TextCleanupTransformer` | 文本清洗 |
| `ingestion/service/pipeline/transformer/` | `StructureAwareChunkTransformer` | 结构感知切片 |
| `ingestion/service/pipeline/` | `ChunkService` | 切片落库 PostgreSQL |
| `ingestion/vector/` | `VectorIngestionService` | Embedding 写入 PGvector |
| `engine/elasticsearch/` | `ElasticsearchChunkIndexService` | ES 索引读写、关键词检索 |
| `engine/pgvector/` | `PgVectorRetrievalAdapter` | 向量检索适配 |
| `qa/service/` | `QueryPlanningService` | LLM 查询规划 |
| `qa/rag/` | `HybridChunkRetrievalService` | 混合检索主引擎 |
| `qa/rag/` | `ReadyChunkDocumentRetriever` | Spring AI DocumentRetriever 适配 |
| `qa/service/` | `QaChatService` | RAG 问答编排 |
| `qa/support/` | `CitationAssembler` | 引用组装 |
| `assistant/agent/` | `AssistantKnowledgeBaseTool` | Agent 知识库检索 Tool |

---

## 9. 与「基础 RAG」对比

### 9.1 基础 RAG

```mermaid
flowchart LR
    B1[固定窗口切片] --> B2[单向量 Top-K]
    B2 --> B3[Prompt 拼接]
    B3 --> B4[LLM 生成]
```

### 9.2 Argus RAG

```mermaid
flowchart LR
    A1[结构感知切片] --> A2[双路索引]
    A2 --> A3[查询规划 + RRF]
    A3 --> A4[类簇 + 邻居窗口]
    A4 --> A5[证据门控]
    A5 --> A6[回答 + Citations]
```

| 维度 | 基础 RAG | Argus |
|------|----------|-------|
| 切片 | 固定字符窗口 | 标题 / 段落 / 句子层级 + overlap |
| 索引 | 单向量库 | PGvector + Elasticsearch 双路 |
| 检索 | 单次 embedding 相似度 | 查询规划 + 多 query + RRF 融合 |
| 上下文 | 单 chunk 文本 | 类簇合并 + 邻居窗口扩展 |
| 幻觉控制 | 无 | 四级证据评估 + 拒答策略 |
| 溯源 | 无 | citations（documentId, chunkId, score） |

---

> 本文档随 RAG 相关代码同步维护。修改 `HybridChunkRetrievalService`、`EtlDocumentIngestionProcessor` 或 `QaChatService` 时，请同步更新对应章节。
