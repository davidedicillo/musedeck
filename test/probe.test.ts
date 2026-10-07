import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import test from "node:test";

test("native probe reports Muse control availability without chat content", () => {
  const result = spawnSync("./com.davidedicillo.muse.sdPlugin/bin/MuseBridge", ["probe"], { encoding: "utf8" });
  assert.equal(result.status, 0, result.stderr);
  const probe = JSON.parse(result.stdout);
  assert.equal(typeof probe.frontmostBundleId === "string" || probe.frontmostBundleId === null, true);
  assert.equal(typeof probe.museRunning, "boolean");
  assert.equal(typeof probe.accessibilityTrusted, "boolean");
  assert.equal(JSON.stringify(probe).includes("Assistant message"), false);
});
