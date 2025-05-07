const fs = require("fs");
const path = require("path");
const { spawn, execSync } = require("child_process");

function debounce(func, wait = 500, immediate) {
  let timeout;
  return function () {
    const context = this;
    const args = arguments;
    const later = function () {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };
    const callNow = immediate && !timeout;
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
    if (callNow) func.apply(context, args);
  };
}

async function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

let p = null;

async function killProcess() {
  if (!p) return;
  process.kill(-p.pid, "SIGKILL");
}

const reload = debounce(async () => {
  console.log("Reloading...");

  await killProcess(); // wait for old process to exit

  p = spawn("ags", ["run"], { shell: true, stdio: "inherit", detached: true });
  p.unref();
}, 200);

process.on("SIGINT", killProcess);
process.on("SIGTERM", killProcess);

execSync("ags", ["quit"]);

reload();
fs.watch(path.join(__dirname, "../"), { recursive: true }, reload);
