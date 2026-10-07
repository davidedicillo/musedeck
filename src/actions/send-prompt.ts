import { action, KeyDownEvent, SingletonAction } from "@elgato/streamdeck";
import { executeAction } from "../action-runner";

type PromptSettings = { prompt?: string };

@action({ UUID: "com.davidedicillo.muse.send-prompt" })
export class SendPrompt extends SingletonAction<PromptSettings> {
  override async onKeyDown(ev: KeyDownEvent<PromptSettings>): Promise<void> {
    await executeAction("send-prompt", ev.payload.settings.prompt, undefined, ev.action);
  }
}
