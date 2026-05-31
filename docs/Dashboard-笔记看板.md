---
type: dashboard
tags: [meta]
---

# 笔记看板

> 需安装 **Dataview** 插件。用于在 Obsidian 里总览个人笔记。

## 正式文档（V2 / V3）

```dataview
TABLE version, tags, length(related) AS "关联数"
FROM ""
WHERE (type = "doc" OR type = "adr") AND (contains(tags, "v2") OR contains(tags, "v3") OR contains(tags, "rag"))
SORT version ASC
```

## 收件箱（待整理）

```dataview
TABLE status, created, module
FROM "_inbox"
WHERE status = "active" OR status = "draft"
SORT created DESC
```

## 问题排查记录

```dataview
TABLE module, status, created
WHERE type = "bug"
SORT created DESC
LIMIT 20
```

## 设计决策 ADR

```dataview
TABLE version, status, created
WHERE type = "adr"
SORT created DESC
```

## 按标签

```dataview
TABLE length(rows) AS 数量
FROM ""
WHERE file.path != this.file.path
FLATTEN tags AS tag
GROUP BY tag
SORT 数量 DESC
```

---

返回 [[Home]] · [[Obsidian-Cursor-协作指南]]
