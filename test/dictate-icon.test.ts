import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import test from "node:test";

test("Dictate includes distinct recording and stop key images", () => {
  const root = "com.davidedicillo.muse.sdPlugin";
  const manifest = JSON.parse(readFileSync(`${root}/manifest.json`, "utf8"));
  const dictate = manifest.Actions.find((action: { UUID: string }) => action.UUID === "com.davidedicillo.muse.dictate");
  assert.equal(dictate.States.length, 2);
  assert.notEqual(dictate.States[0].Image, dictate.States[1].Image);
  for (const state of dictate.States) {
    assert.equal(existsSync(`${root}/${state.Image}.png`), true);
    assert.equal(existsSync(`${root}/${state.Image}@2x.png`), true);
  }
});
