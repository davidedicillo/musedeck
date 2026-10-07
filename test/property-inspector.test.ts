import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import test from "node:test";
import { runInNewContext } from "node:vm";

const html = readFileSync(join(import.meta.dirname, "../com.davidedicillo.muse.sdPlugin/ui/send-prompt.html"), "utf8");
const script = html.match(/<script>([\s\S]*?)<\/script>/)?.[1];

test("property inspector saves prompts to each key's own context", () => {
  assert.ok(script);
  function inspector(uuid: string, initial: string) {
    let onInput = () => {};
    const field = { value: "", addEventListener: (_event: string, callback: () => void) => { onInput = callback; } };
    const sent: unknown[] = [];
    let socket: { onopen?: () => void; readyState: number; send: (value: string) => void } | undefined;
    class FakeSocket {
      static OPEN = 1;
      readyState = 1;
      onopen?: () => void;
      send(value: string) { sent.push(JSON.parse(value)); }
      constructor(_url: string) { socket = this; }
    }
    const window: Record<string, (...args: string[]) => void> = {};
    runInNewContext(script, {
      document: { getElementById: () => field, activeElement: null }, window,
      WebSocket: FakeSocket, JSON, setTimeout: (callback: () => void) => { callback(); return 1; }, clearTimeout: () => {},
    });
    window.connectElgatoStreamDeckSocket("1234", uuid, "registerPropertyInspector", "{}", JSON.stringify({ payload: { settings: { prompt: initial } } }));
    socket?.onopen?.();
    return { field, sent, input: () => onInput() };
  }
  const first = inspector("key-one", "first saved prompt");
  const second = inspector("key-two", "second saved prompt");
  assert.equal(first.field.value, "first saved prompt");
  assert.equal(second.field.value, "second saved prompt");
  first.field.value = "changed only here";
  first.input();
  assert.deepEqual(first.sent.at(-1), {
    event: "setSettings", action: "com.davidedicillo.muse.send-prompt",
    context: "key-one", payload: { prompt: "changed only here" },
  });
  assert.equal(second.field.value, "second saved prompt");
});
