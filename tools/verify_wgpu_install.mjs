import { existsSync, statSync } from "node:fs";
import { join } from "node:path";
import { spawnSync } from "node:child_process";

const [home, saBin] = process.argv.slice(2);
if (!home || !saBin) {
  console.error("usage: node tools/verify_wgpu_install.mjs <SA_PLUGINS_HOME> <sa-bin>");
  process.exit(2);
}

function requireFile(path) {
  if (!existsSync(path) || !statSync(path).isFile()) {
    console.error(`missing installed file: ${path}`);
    process.exit(1);
  }
}

const wgpuCurrent = join(home, "installed", "wgpu", "current");
const saxCurrent = join(home, "installed", "sax", "current");

requireFile(join(saxCurrent, "libsax.so"));
requireFile(join(wgpuCurrent, "libwgpu.so"));
requireFile(join(wgpuCurrent, "sap.json"));
requireFile(join(wgpuCurrent, "sa", "wgpu.sai"));
requireFile(join(wgpuCurrent, "sa", "wgpu.sal"));
requireFile(join(wgpuCurrent, "share", "wgpu_airlock.js"));
requireFile(join(wgpuCurrent, "share", "wgpu.sai"));
requireFile(join(wgpuCurrent, "share", "wgpu.sal"));
requireFile(join(wgpuCurrent, "share", "demos", "rotating_cube.sax"));

const env = { ...process.env, SA_PLUGINS_HOME: home, SA_PLUGIN_DEV: "1" };
delete env.SA_PLUGINS_PATH;
const skills = spawnSync(saBin, ["skills"], { env, encoding: "utf8" });
if (skills.status !== 0) {
  console.error(skills.stderr || skills.stdout || `sa skills exited with ${skills.status}`);
  process.exit(1);
}
for (const needle of ["wgpu", "sax.wgpu"]) {
  if (!skills.stdout.includes(needle)) {
    console.error(`installed skills output missing ${needle}`);
    process.exit(1);
  }
}
