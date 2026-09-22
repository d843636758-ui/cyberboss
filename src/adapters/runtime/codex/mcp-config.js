const fs = require("fs");
const path = require("path");
const { listProjectToolNames } = require("../../../tools/tool-host");

function resolveCodexProjectToolMcpServerConfig({ cyberbossHome = "" } = {}) {
  const home = normalizeNonEmptyString(cyberbossHome)
    || process.env.CYBERBOSS_HOME
    || path.resolve(__dirname, "..", "..", "..", "..");
  const scriptPath = path.join(home, "bin", "cyberboss.js");
  if (!fs.existsSync(scriptPath)) {
    return null;
  }
  return {
    name: "cyberboss_tools",
    command: process.execPath,
    args: [scriptPath, "tool-mcp-server", "--runtime-id", "codex"],
  };
}

function buildCodexMcpConfigArgs(mcpServerConfig) {
  const configArgs = [];
  if (!mcpServerConfig || typeof mcpServerConfig !== "object") {
    return buildObMcpConfigArgs(process.env);
  }
  const name = normalizeNonEmptyString(mcpServerConfig.name) || "cyberboss_tools";
  const command = normalizeNonEmptyString(mcpServerConfig.command);
  const args = Array.isArray(mcpServerConfig.args)
    ? mcpServerConfig.args.map((value) => normalizeNonEmptyString(value)).filter(Boolean)
    : [];
  if (!command) {
    return buildObMcpConfigArgs(process.env);
  }
  configArgs.push(
    "-c",
    `mcp_servers.${name}.command=${quoteTomlString(command)}`,
    "-c",
    `mcp_servers.${name}.args=${formatTomlArray(args)}`,
  );
  for (const toolName of listProjectToolNames()) {
    configArgs.push(
      "-c",
      `mcp_servers.${name}.tools.${toolName}.approval_mode=${quoteTomlString("auto")}`,
    );
  }
  return [...configArgs, ...buildObMcpConfigArgs(process.env)];
}

function buildObMcpConfigArgs(env = process.env) {
  const url = normalizeNonEmptyString(env.CYBERBOSS_OB_MCP_URL);
  if (!url) {
    return [];
  }

  const name = "ob";
  const args = [
    "-c",
    `mcp_servers.${name}.url=${quoteTomlString(url)}`,
    "-c",
    `mcp_servers.${name}.required=true`,
    "-c",
    `mcp_servers.${name}.tool_timeout_sec=120`,
    "-c",
    `mcp_servers.${name}.default_tools_approval_mode=${quoteTomlString("auto")}`,
  ];

  if (normalizeNonEmptyString(env.CYBERBOSS_OB_BEARER_TOKEN)) {
    args.push(
      "-c",
      `mcp_servers.${name}.bearer_token_env_var=${quoteTomlString("CYBERBOSS_OB_BEARER_TOKEN")}`,
    );
  }

  return args;
}

function quoteTomlString(value) {
  return JSON.stringify(String(value ?? ""));
}

function formatTomlArray(values) {
  return `[${values.map((value) => quoteTomlString(value)).join(",")}]`;
}

function normalizeNonEmptyString(value) {
  return typeof value === "string" && value.trim() ? value.trim() : "";
}

module.exports = {
  buildCodexMcpConfigArgs,
  buildObMcpConfigArgs,
  resolveCodexProjectToolMcpServerConfig,
};
