// agent-mux plugin for OpenCode
// Tracks agent status in agent-mux for the tmux picker and notifications

import { exec } from "child_process";

const AGENT_MUX = `${process.env.HOME}/scripts/agent-mux`;

function run(cmd) {
  exec(cmd, { timeout: 5000 }, () => {});
}

let isIdle = true;

export const agentMux = async ({ $ }) => {
  run(`${AGENT_MUX} update opencode idle`);

  return {
    event: async ({ event }) => {
      switch (event.type) {
        case "session.created":
          run(`${AGENT_MUX} update opencode idle`);
          break;
        case "session.status":
          if (isIdle) {
            isIdle = false;
            run(`${AGENT_MUX} update opencode working`);
          }
          break;
        case "session.idle":
          isIdle = true;
          // Delay to avoid being overwritten by trailing events
          setTimeout(() => {
            if (isIdle) {
              run(`${AGENT_MUX} update opencode idle`);
            }
          }, 500);
          break;
        case "server.instance.disposed":
          run(`${AGENT_MUX} remove`);
          break;
      }
    },
  };
};
