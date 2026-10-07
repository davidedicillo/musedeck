// @ts-ignore Node's test runner needs the .ts suffix; Rollup resolves it during the plugin build.
import { runMuseCommand, type MuseCommand, type MuseResult } from "./muse-bridge.ts";

export type ActionName = "open" | "side-chat" | "dictate" | "send-prompt" | "finish-send";
export type Feedback = { showOk(): Promise<void>; showAlert(): Promise<void> };

const commands: Record<ActionName, MuseCommand> = {
  open: "open-main",
  "side-chat": "new-side-chat",
  dictate: "dictate",
  "send-prompt": "send-prompt",
  "finish-send": "finish-send",
};

export async function executeAction(
  action: ActionName,
  prompt: string | undefined,
  invoke: (command: MuseCommand, prompt?: string) => Promise<MuseResult> = runMuseCommand,
  feedback: Feedback,
): Promise<MuseResult> {
  if (action === "send-prompt" && !prompt?.trim()) {
    await feedback.showAlert();
    return { ok: false, code: "empty-prompt" };
  }
  const result = await invoke(commands[action], action === "send-prompt" ? prompt : undefined);
  if (result.ok) await feedback.showOk();
  else await feedback.showAlert();
  return result;
}
