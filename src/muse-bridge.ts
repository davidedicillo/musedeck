import { execFile } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export type MuseCommand = "open-main" | "new-side-chat" | "dictate" | "dictation-state" | "send-prompt" | "finish-send";
export type MuseResult = { ok: boolean; code: string };
export type NativeInvoke = (
  binary: string,
  args: string[],
  input: string,
) => Promise<{ stdout: string; exitCode: number }>;

const helperPath = join(dirname(fileURLToPath(import.meta.url)), "MuseBridge");

const invokeNative: NativeInvoke = (binary, args, input) => new Promise((resolve) => {
  const child = execFile(binary, args, {
    encoding: "utf8",
    timeout: 20_000,
    maxBuffer: 64 * 1024,
  }, (error, stdout) => {
    resolve({ stdout, exitCode: error ? 1 : 0 });
  });
  child.stdin?.end(input);
});

export async function runMuseCommand(
  command: MuseCommand,
  prompt?: string,
  invoke: NativeInvoke = invokeNative,
): Promise<MuseResult> {
  if (command === "send-prompt" && !prompt?.trim()) {
    return { ok: false, code: "empty-prompt" };
  }
  try {
    const { stdout } = await invoke(helperPath, [command], command === "send-prompt" ? prompt! : "");
    const result: unknown = JSON.parse(stdout);
    if (typeof result === "object" && result !== null && "ok" in result && "code" in result &&
        typeof result.ok === "boolean" && typeof result.code === "string") {
      return { ok: result.ok, code: result.code };
    }
    return { ok: false, code: "invalid-helper-response" };
  } catch {
    return { ok: false, code: "invalid-helper-response" };
  }
}
