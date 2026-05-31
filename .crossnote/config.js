/**
 * Markdown Preview Enhanced — Argus 文档 Mermaid 渲染配置
 *
 * 可切换样式（改 theme / look 后 Reload 预览）：
 * - theme: neutral   → 低饱和、白底文档最清晰（当前）
 * - theme: default   → 彩色经典
 * - theme: neo       → 现代扁平（需 look: neo）
 * - theme: forest    → 绿色系
 * - look: classic    → 直角节点
 * - look: neo        → 圆角现代节点
 * - curve: linear    → 直线连线（架构图更清晰）
 * - curve: basis     → 平滑曲线
 */
module.exports = {
  mermaidConfig: {
    startOnLoad: false,
    theme: "neutral",
    look: "neo",
    flowchart: {
      curve: "linear",
      padding: 20,
      nodeSpacing: 50,
      rankSpacing: 60,
      htmlLabels: true,
      useMaxWidth: true,
      diagramPadding: 12,
      wrappingWidth: 200,
    },
    themeVariables: {
      fontSize: "14px",
      fontFamily: "Segoe UI, Microsoft YaHei, sans-serif",
      lineColor: "#555555",
      primaryColor: "#E8F4FD",
      primaryBorderColor: "#4A90D9",
      primaryTextColor: "#1a1a1a",
      secondaryColor: "#F5F5F5",
      secondaryBorderColor: "#999999",
      tertiaryColor: "#FFF8E6",
      clusterBkg: "#F7F7F7",
      clusterBorder: "#CCCCCC",
      edgeLabelBackground: "#FFFFFF",
    },
    sequence: {
      diagramMarginX: 24,
      diagramMarginY: 16,
      actorMargin: 72,
      messageMargin: 36,
      boxMargin: 8,
    },
  },
};
