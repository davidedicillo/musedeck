import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { join } from "node:path";
import test from "node:test";

const binary = join(import.meta.dirname, "../com.davidedicillo.muse.sdPlugin/bin/MuseBridge");

test("native helper refuses an empty saved prompt before any UI interaction", () => {
  let output = "";
  try {
    output = execFileSync(binary, ["send-prompt"], { encoding: "utf8", input: "" });
  } catch (error) {
    output = (error as { stdout?: string }).stdout ?? "";
  }
  assert.deepEqual(JSON.parse(output), { code: "empty-prompt", ok: false });
});

test("packaged helper supports both Mac architectures from macOS 12", () => {
  const archs = execFileSync("/usr/bin/lipo", ["-archs", binary], { encoding: "utf8" }).trim().split(/\s+/);
  assert.deepEqual(new Set(archs), new Set(["arm64", "x86_64"]));
  for (const arch of archs) {
    const metadata = execFileSync("/usr/bin/otool", ["-arch", arch, "-l", binary], { encoding: "utf8" });
    assert.match(metadata, /cmd LC_BUILD_VERSION[\s\S]*?minos 12\.0/);
  }
});
