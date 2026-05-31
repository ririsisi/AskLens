# Obsidian Git 推荐配置

> Vault 在 `docs/`，Git 仓库根在 `AskLens/`。必须设置 **`basePath: ".."`**，否则插件找不到 `.git`。

## 一键导入

1. 安装社区插件 **Obsidian Git**
2. 启用后关闭 Obsidian
3. 将本目录的 `obsidian-git-data.json` **复制**到：
   ```
   docs/.obsidian/plugins/obsidian-git/data.json
   ```
   （`plugins/` 目录在首次启用插件后才会生成；若没有，先在 Obsidian 里开关一次插件）
4. 重新打开 Obsidian → Settings → Obsidian Git，核对下列项

## 推荐参数说明

| 设置项 | 推荐值 | 说明 |
|--------|--------|------|
| **Vault git root (basePath)** | `..` | 指向 `AskLens/.git` |
| **Auto backup interval** | `10` 分钟 | 有改动时自动 commit |
| **Auto push interval** | `20` 分钟 | 自动 push（可关） |
| **Auto pull interval** | `15` 分钟 | 多机协作时拉远程 |
| **Pull on startup** | 开 | 启动 Obsidian 时 pull |
| **Pull before push** | 开 | push 前先 pull，减少冲突 |
| **Auto backup after file change** | 开 | 保存笔记后尽快备份 |
| **Sync method** | merge | 合并远程变更 |
| **Disable push** | 关 | 需要 push 时保持关闭 |

## Commit 消息模板

```
docs(notes): auto backup {{numFiles}} files {{date}}
```

仅备份 `docs/` 下的笔记；若 commit 里出现 `AskLens-backend/` 等代码改动，说明 basePath 未设为 `..`，或你在 Obsidian 外也改了代码——可一并提交，或在终端分开 commit。

## 没有 Git 远程时（本地单机开发）

若 `git remote -v` 为空（未关联 GitHub/Gitee），**不要开启 auto pull/push**，否则会弹窗要求填写远程地址。

推荐 **仅本地 commit**（当前 `data.json` 已按此配置）：

| 项 | 值 |
|----|-----|
| `disablePush` | `true` |
| `autoPushInterval` | `0` |
| `autoPullInterval` | `0` |
| `autoPullOnBoot` | `false` |
| `autoSaveInterval` | `10`（仅本地自动 commit） |

以后若添加了远程（如 `git remote add origin ...`），再把 `disablePush` 改回 `false` 并设置 pull/push 间隔即可。

## 保守方案（不自动 push）

若不想 Obsidian 自动 push，在 `data.json` 中改：

```json
"disablePush": true,
"autoPushInterval": 0
```

笔记仍会自动 **commit** 到本地；push 改在 Cursor 终端手动：

```powershell
cd D:\Develop\AskLens
git push
```

## 与 Cursor 协作注意

- Obsidian Git 与 Cursor 共用同一 Git 仓库，可能同时改文件 → 以 **pull before push** 降低冲突
- 大改代码时在 Cursor commit；Obsidian 侧重 `docs/` 笔记 commit
- 冲突时在 Cursor 或终端 resolve，Obsidian 里 reload vault

---

返回 [[Obsidian-Cursor-协作指南]] · [[Home]]
