import assert from "node:assert/strict";
import test from "node:test";
import { dictationTarget } from "../src/route.ts";

test("Dictate stays in the visible chat only when Muse was frontmost", () => {
  assert.equal(dictationTarget("com.meta.endo"), "current");
  assert.equal(dictationTarget("com.apple.finder"), "main");
  assert.equal(dictationTarget(null), "main");
});
