import assert from "node:assert/strict";
import test from "node:test";
import { executeAction } from "../src/action-runner.ts";
import type { MuseCommand, MuseResult } from "../src/muse-bridge.ts";

test("each key maps to its native command without a success overlay", async () => {
  const seen: Array<[MuseCommand, string | undefined]> = [];
  let ok = 0;
  const invoke = async (command: MuseCommand, prompt?: string): Promise<MuseResult> => {
    seen.push([command, prompt]);
    return { ok: true, code: "done" };
  };
  for (const action of ["open", "side-chat", "dictate", "send-prompt", "finish-send"] as const) {
    await executeAction(action, action === "send-prompt" ? "  Hello Muse  " : undefined, invoke, {
      showOk: async () => { ok++; }, showAlert: async () => { throw Error("unexpected alert"); },
    });
  }
  assert.deepEqual(seen, [["open-main", undefined], ["new-side-chat", undefined], ["dictate", undefined], ["send-prompt", "  Hello Muse  "], ["finish-send", undefined]]);
  assert.equal(ok, 0);
});

test("blank prompt and native failure show an alert", async () => {
  let invoked = 0;
  let alerted = 0;
  const invoke = async (): Promise<MuseResult> => { invoked++; return { ok: false, code: "missing" }; };
  const feedback = { showOk: async () => {}, showAlert: async () => { alerted++; } };
  await executeAction("send-prompt", "  ", invoke, feedback);
  assert.equal(invoked, 0);
  await executeAction("dictate", undefined, invoke, feedback);
  assert.equal(invoked, 1);
  assert.equal(alerted, 2);
});

test("Dictate returns the helper's start or stop state for its key icon", async () => {
  const feedback = { showOk: async () => {}, showAlert: async () => { throw Error("unexpected alert"); } };
  const started = await executeAction("dictate", undefined, async () => ({ ok: true, code: "dictating-current" }), feedback);
  const stopped = await executeAction("dictate", undefined, async () => ({ ok: true, code: "dictation-stopped" }), feedback);
  assert.equal(started.code, "dictating-current");
  assert.equal(stopped.code, "dictation-stopped");
});
