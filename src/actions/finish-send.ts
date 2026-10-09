import streamDeck, { action, KeyDownEvent, SingletonAction } from "@elgato/streamdeck";
import { executeAction } from "../action-runner";

@action({ UUID: "com.davidedicillo.muse.finish-send" })
export class FinishSend extends SingletonAction {
  override async onKeyDown(ev: KeyDownEvent): Promise<void> {
    const result = await executeAction("finish-send", undefined, undefined, ev.action);
    streamDeck.logger.info(`Muse Finish & Send: ${result.code}`);
  }
}
