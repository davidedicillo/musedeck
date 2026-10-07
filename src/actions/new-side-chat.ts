import { action, KeyDownEvent, SingletonAction } from "@elgato/streamdeck";
import { executeAction } from "../action-runner";

@action({ UUID: "com.davidedicillo.muse.side-chat" })
export class NewSideChat extends SingletonAction {
  override async onKeyDown(ev: KeyDownEvent): Promise<void> {
    await executeAction("side-chat", undefined, undefined, ev.action);
  }
}
