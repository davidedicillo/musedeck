import { action, KeyDownEvent, SingletonAction } from "@elgato/streamdeck";
import { executeAction } from "../action-runner";

@action({ UUID: "com.davidedicillo.muse.open" })
export class OpenMuse extends SingletonAction {
  override async onKeyDown(ev: KeyDownEvent): Promise<void> {
    await executeAction("open", undefined, undefined, ev.action);
  }
}
