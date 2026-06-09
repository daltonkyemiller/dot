// installed by switchboard
// safe to edit. this plugin only fires when a switchboard daemon socket exists.
// SWITCHBOARD_INTEGRATION_ID=opencode
// SWITCHBOARD_INTEGRATION_VERSION=1

import net from "node:net";
import fs from "node:fs";

const SOURCE = "switchboard:opencode";

function resolvePaneId() {
  return process.env.SWITCHBOARD_PANE_ID || process.env.TMUX_PANE || "";
}

function resolveSocketPath() {
  if (process.env.SWITCHBOARD_SOCKET_PATH) return process.env.SWITCHBOARD_SOCKET_PATH;
  const runtime = process.env.XDG_RUNTIME_DIR || "/tmp";
  return `${runtime}/switchboard/switchboard.sock`;
}

let reportSeq = Date.now() * 1000;
function nextReportSeq() {
  reportSeq += 1;
  return reportSeq;
}

function reportState(action) {
  const paneId = resolvePaneId();
  const socketPath = resolveSocketPath();
  if (!paneId) return Promise.resolve();
  try {
    if (!fs.statSync(socketPath).isSocket()) return Promise.resolve();
  } catch {
    return Promise.resolve();
  }

  const id = `${SOURCE}:${Date.now()}:${Math.floor(Math.random() * 1_000_000).toString().padStart(6, "0")}`;
  const params = action === "release"
    ? { pane_id: paneId, source: SOURCE, agent: "opencode", seq: nextReportSeq() }
    : {
        pane_id: paneId,
        source: SOURCE,
        agent: "opencode",
        state: action,
        seq: nextReportSeq(),
        pid: process.pid,
      };
  const request = {
    id,
    method: action === "release" ? "pane.release_agent" : "pane.report_agent",
    params,
  };

  return new Promise((resolve) => {
    const client = net.createConnection(socketPath, () => {
      client.write(`${JSON.stringify(request)}\n`);
    });
    const finish = () => {
      client.destroy();
      resolve();
    };
    client.setTimeout(500, finish);
    client.on("data", finish);
    client.on("error", finish);
    client.on("end", finish);
    client.on("close", resolve);
  });
}

export const SwitchboardAgentStatePlugin = async () => {
  if (!resolvePaneId()) return {};

  return {
    event: async ({ event }) => {
      const type = event?.type;
      const properties = event?.properties ?? {};

      switch (type) {
        case "permission.asked":
        case "question.asked":
          await reportState("blocked");
          break;
        case "permission.replied": {
          const reply = properties.reply ?? properties.response;
          if (reply === "reject") {
            await reportState("idle");
          } else if (reply === "once" || reply === "always") {
            await reportState("working");
          }
          break;
        }
        case "question.replied":
          await reportState("working");
          break;
        case "question.rejected":
          await reportState("idle");
          break;
        case "session.status": {
          const status = typeof properties.status === "string"
            ? properties.status
            : properties.status?.type;
          if (status === "busy" || status === "retry") {
            await reportState("working");
          } else if (status === "idle") {
            await reportState("idle");
          }
          break;
        }
        case "session.idle":
          await reportState("idle");
          break;
        default:
          break;
      }
    },
  };
};
