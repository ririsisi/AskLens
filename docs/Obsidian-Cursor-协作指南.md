# Obsidian + Cursor 协作指南

> 本仓库的 **`docs/`** 目录已配置为 Obsidian Vault，与 Cursor 共用同一份 Markdown，无需同步脚本。

---

## 一、5 分钟完成 Obsidian 初始化

### 1. 打开 Vault

1. 安装 [Obsidian](https://obsidian.md/)
2. **Open folder as vault** → 选择：
   ```
   D:\Develop\Argus-master\docs
   ```
3. 打开 **Settings → Core plugins**，确认已启用：Graph、Backlinks、Templates、Outline

### 2. 安装推荐社区插件

**Settings → Community plugins → Turn on community plugins → Browse**

| 插件 | 作用 |
|------|------|
| **Obsidian Git** | 笔记随代码一起 commit/push（可选自动间隔） |
| **Dataview** | 用查询语法做「待办看板 / 笔记索引」 |
| **Templater** | 比内置 Templates 更强的模板（可选，已有内置模板可用） |

安装后 Obsidian 会读取仓库里的 `.obsidian/community-plugins.json` 提示缺失插件，按上表安装即可。

### 3. 验证

- 打开 [[Home]]，点击双链能否跳转
- 打开 **Graph view**，应能看到 V1~V4 文档节点
- `Ctrl/Cmd+P` → **Templates: Insert template** → 选「问题排查」

---

## 二、Cursor 侧用法

### 1. 用 `@` 引用知识库（最重要）

在 Cursor Chat / Agent 中：

```
@docs/RAG-核心原理图.md  根据这个原理，解释 overlap 在项目里怎么实现的
@docs/V2.0-设计决策.md   实现分片上传时要遵守哪些约束
@docs/_inbox/收件箱.md   这是我记录的坑，帮我查相关代码
```

### 2. 规则已写入 `.cursor/rules/obsidian-knowledge-base.mdc`

Agent 会优先参考 `docs/` 里的设计文档，并在你要求时把结论沉淀到 `_inbox/` 或 ADR 模板。

### 3. 推荐工作流

| 阶段 | Obsidian | Cursor |
|------|----------|--------|
| 学架构 | 读 [[Argus-学习指南]]，Graph 看模块关系 | `@docs/...` 让 AI 对照源码讲解 |
| 写功能 | `_templates/设计决策-ADR` 写决策 | `@ADR笔记` 生成代码骨架 |
| 踩坑 | `_templates/问题排查` 记录 | `@问题排查` 继续排查 |
| 会话结束 | `_templates/Cursor对话摘要` 归档 | 复制关键结论到 Obsidian |

---

## 三、文件夹约定

```
docs/
├── Home.md                 # Vault 首页（MOC）
├── Obsidian-Cursor-协作指南.md
├── V*.0-*.md               # 正式项目文档（已有）
├── RAG-核心原理图.md
├── _inbox/                 # 个人/临时笔记（新建默认落这里）
├── _templates/             # 笔记模板
├── _attachments/           # 图片附件（Obsidian 粘贴图会放这里）
└── .obsidian/              # Vault 配置（可提交，workspace 个人文件已 gitignore）
```

---

## 四、Dataview 看板（安装 Dataview 后可用）

打开 [[Dashboard-笔记看板]]，自动列出 `_inbox` 和 ADR 等待办。

---

## 五、Obsidian Git 推荐配置

详细说明与可导入的 `data.json` 见：**[[_meta/Obsidian-Git-推荐配置]]**（文件：`_meta/obsidian-git-data.json`）。

### 关键一步：basePath

Vault 是 `docs/`，Git 根是上一级 `Argus-master/`，必须设置：

| 设置项 | 值 |
|--------|-----|
| Vault git root / basePath | `..` |

否则 Obsidian Git 会报找不到仓库。

### 推荐 intervals

| 项 | 分钟 | 说明 |
|----|------|------|
| Auto backup (commit) | **10** | 笔记改动后定期本地 commit |
| Auto pull | **15** | 多机协作时拉远程 |
| Auto push | **20** | 可选；保守用户设 `disablePush: true` |
| Pull on startup | **开** | 打开 Obsidian 先同步 |
| Pull before push | **开** | 减少 push 冲突 |

### 导入步骤（简版）

1. 安装并启用 **Obsidian Git**
2. 配置已写入 `docs/.obsidian/plugins/obsidian-git/data.json`（**basePath = ..** 等推荐项已生效）
3. **完全退出并重启 Obsidian**（或 `Ctrl/Cmd+P` → Reload app without saving），再在 Settings → Obsidian Git 里确认 **Vault git root / basePath = ..**

插件文件夹路径（Windows）：

```
D:\Develop\Argus-master\docs\.obsidian\plugins\obsidian-git\
```

> `.obsidian` 是隐藏文件夹。在 Obsidian 里看不到时，可直接在 Cursor / 资源管理器地址栏粘贴上述路径。

### Commit 消息示例

```
docs(notes): auto backup 3 files 2026-05-31 11:30:00
```

---

## 六、双链写法示例

在任意笔记中：

```markdown
ETL 流水线见 [[V2.0-设计决策#ETL 流水线的 9 个步骤]]。
RAG 检索见 [[RAG-核心原理图#4. 检索增强：混合检索引擎]]。
与 [[HybridChunkRetrievalService]] 相关的个人笔记 → 写在 _inbox 并双链到 [[V3.0-设计决策]]。
```

Obsidian 会在 Graph 中显示这些连接；Cursor 读的是同一份 `.md` 文件。

---

## 七、常见问题

**Q: Cursor 能直接看 Graph 吗？**  
A: 不能。Graph 只在 Obsidian 里；Cursor 通过 `@` 读 Markdown 内容。

**Q: 双链 `[[xxx]]` 会影响 GitHub 渲染吗？**  
A: GitHub 不解析 wikilink，显示为普通文本，不影响 Cursor。

**Q: 要不要把整个 Argus-master 当 Vault？**  
A: 不建议。代码目录太大，Graph 会噪；**只把 `docs/` 当 Vault** 最干净。

---

返回 [[Home]]
