# 学习进度 · 大模型面试题轨道

> 导师每次开课先读这里，下课后回写这里。状态：✅ 已掌握 / 🟡 学过待巩固 / ⬜ 未开始。
> 配套大脑：`tutor.md`；复习队列共用 `../review-log.md`。

## 当前位置

- **上次学到**：**02 核心框架**继续推进。① ReAct **对比题**（vs CoT：闭卷无接地 / vs Plan-and-Execute：路径是否依赖上一步真实结果）已完成理解+输出+话术入库；② **Reflexion** 理解过关（解决"教训不跨轮复用"、三角色 Actor/Evaluator/Reflector、Act→Eval→Reflect→Retry、反思须"具体可执行"），但**输出待巩固**（循环/角色说糊、"重试"误写"重拾"，已入复习队列）；③ **LATS** 刚开了个 WHY 头（"岔路多+错误晚暴露时 ReAct 一条路走到黑的风险/如何别吊死"），**学生未作答即下课**。
- **今天/下次从这里接**：从 **LATS 的 WHY 问题**接着答（树搜索/MCThS 直觉），再往后 **LangChain → LangGraph（可挂 AskLens 图引擎，ReactAgent 即建于 Spring AI Alibaba 图引擎）→ 多 Agent**，收尾 02 模块。可选并行：`面试模拟` 压测 ReAct / Reflexion。
- **最近一次学习日期**：2026-06-15
- **配置变更**：已在 `tutor.md` 第三节加入铁规则「🔒 话术必存档」——任何时候产出可背诵话术都必须当场写入 `notes/面试话术库.md`（不限于显式 `★话术`）。

## 总览（对应 `docs/01-面试八股文/` 9 模块，按推荐主线排序）

> 推荐主线（已有基础者）：02 → 03 → 04 → 05 → 08 → 07 → 06 → 09 → 01

- 🟡 02 核心框架（ReAct / Plan-and-Execute / Reflexion / LangGraph）— **必考**。ReAct 已学透+挂项目+对比题+话术；Plan-and-Execute 已在对比题中讲清主场（步骤清晰可预知）；Reflexion 理解过关、输出待巩固。**剩余未开始：LATS（进行中-WHY未答）/ LangChain / LangGraph / 多 Agent**
- ⬜ 03 RAG 技术（分块 / 向量库 / 混合检索 / RRF / 重排 / GraphRAG）— 高频，**可大量挂 AskLens**
- ⬜ 04 工具调用（Function Calling / MCP / 工具路由 / 安全）— MCP 热点
- ⬜ 05 记忆系统（短期/长期 / 摘要压缩 / 检索策略）— **可挂 AskLens 三级记忆压缩**
- ⬜ 08 工程化实践（模型路由 / 熔断 / Token 优化 / 可观测 / 部署）— 企业级加分
- ⬜ 07 大模型基础（Transformer / Attention / KV Cache / LoRA / RLHF/DPO）— 纯理论，薄弱区重点补
- ⬜ 06 多智能体（协作模式 / 通信 / 冲突解决）
- ⬜ 09 Prompt 工程（CoT / Few-shot / ReAct 模板 / 注入防御）
- ⬜ 01 基础概念（Agent 定义/组成/分类，查漏补缺）

## 项目故事（真实 = AskLens，进度独立跟踪）

- ⬜ 1 分钟 / 3 分钟项目介绍（用 AskLens 真实经历，参考 `docs/05` 脚手架）
- ⬜ 「你的角色 / 做了哪些事」话术（诚实表述职责边界）
- ⬜ RAG 模块 STAR（挂 AskLens：查询规划 + RRF + 四级证据）
- ⬜ 幻觉抑制 STAR（挂 AskLens：四级证据评估 NONE→SUFFICIENT + 拒答 + 引用溯源）
- ⬜ 「这是你自己做的还是公司在用的」诚实应对话术

---

## 课堂日志（最新在上）

> 格式：日期 | 模块 | 学到了什么 / 下次注意

- 2026-06-15(晚) | 02 核心框架·对比题+Reflexion | ① ReAct vs CoT（CoT 闭卷、无 Action/Observation、只能自省→易幻觉）；ReAct vs Plan-and-Execute（关键判据：下一步是否强依赖上一步真实结果/路径是否事先可知，依赖动态反馈用 ReAct，可预知路线用 P&E）。② Reflexion：补 ReAct"教训不跨轮复用"短板，三角色 Actor/Evaluator/Reflector，循环 Act→Eval→Reflect→Retry，反思须具体可执行。③ LATS 仅开 WHY 头未答。**配置**：tutor.md 加「话术必存档」铁规则，话术库新增 ReAct三框架对比 + Reflexion 两条。**注意点**：Reflexion 输出说糊（"重拾"误、循环/角色不清，已入复习队列）；Observation"程序生成"今热身答对一次（升 🟡）。
- 2026-06-15 | 02 核心框架·ReAct | 学了 ReAct 的 WHY（模型知识过时+不会算→需工具；且依赖关系使"边做边想"优于"开局定死计划"）、Thought/Action/Observation 三件套、Observation 必须系统生成（防幻觉）。挂 AskLens：ReactAgent 工厂 + knowledgeBaseSearch 工具，两道防死循环闸（recursionLimit(10) + hasCompletedSearch 守卫）。话术已入库。**注意点：学生两次把"Observation 由程序生成"说成"人为观察"，已入复习队列。** 下次从 ReAct 对比题接。
