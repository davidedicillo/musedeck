import assert from "node:assert/strict";
import test from "node:test";
import { runMuseCommand, type NativeInvoke } from "../src/muse-bridge.ts";

test("a saved prompt goes through stdin, never process arguments", async () => {
  let seen: { args: string[]; input: string } | undefined;
  const invoke: NativeInvoke = async (_binary, args, input) => {
    seen = { args, input };
    return { stdout: '{"ok":true,"code":"sent"}', exitCode: 0 };
  };
  const result = await runMuseCommand("send-prompt", "hello Muse", invoke);
  assert.deepEqual(result, { ok: true, code: "sent" });
  assert.deepEqual(seen, { args: ["send-prompt"], input: "hello Muse" });
});

test("blank prompt never launches the helper", async () => {
  const invoke: NativeInvoke = async () => { throw new Error("helper should not run"); };
  assert.deepEqual(await runMuseCommand("send-prompt", "  \n", invoke), { ok: false, code: "empty-prompt" });
});

test("a missing control and malformed helper output are errors", async () => {
  const missing: NativeInvoke = async () => ({ stdout: '{"ok":false,"code":"control-missing"}', exitCode: 1 });
  assert.deepEqual(await runMuseCommand("open-main", undefined, missing), { ok: false, code: "control-missing" });
  const malformed: NativeInvoke = async () => ({ stdout: "oops", exitCode: 0 });
  assert.deepEqual(await runMuseCommand("open-main", undefined, malformed), { ok: false, code: "invalid-helper-response" });
});
