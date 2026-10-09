import streamDeck, { action, KeyDownEvent, SingletonAction, WillAppearEvent, WillDisappearEvent } from "@elgato/streamdeck";
import { executeAction } from "../action-runner";
import { runMuseCommand } from "../muse-bridge";

@action({ UUID: "com.davidedicillo.muse.dictate" })
export class Dictate extends SingletonAction {
  private serial: Promise<void> = Promise.resolve();
  private readonly visible = new Set<string>();
  private readonly states = new Map<string, 0 | 1>();
  private timer: ReturnType<typeof setInterval> | undefined;
  private polling = false;

  override async onKeyDown(ev: KeyDownEvent): Promise<void> {
    const next = this.serial.then(async () => {
      const result = await executeAction("dictate", undefined, undefined, ev.action);
      streamDeck.logger.info(`Muse Dictate: ${result.code}`);
      if (result.ok && result.code === "dictation-stopped") await this.setAllStates(0);
      else if (result.ok && result.code.startsWith("dictating-")) await this.setAllStates(1);
    });
    this.serial = next.catch(() => {});
    await next;
  }

  override async onWillAppear(ev: WillAppearEvent): Promise<void> {
    this.visible.add(ev.action.id);
    if (!this.timer) this.timer = setInterval(() => { void this.refreshState(); }, 1500);
    await this.refreshState();
  }

  override onWillDisappear(ev: WillDisappearEvent): void {
    this.visible.delete(ev.action.id);
    this.states.delete(ev.action.id);
    if (this.visible.size === 0 && this.timer) {
      clearInterval(this.timer);
      this.timer = undefined;
    }
  }

  private async refreshState(): Promise<void> {
    if (this.polling || this.visible.size === 0) return;
    this.polling = true;
    try {
      const result = await runMuseCommand("dictation-state");
      if (result.ok && (result.code === "dictating" || result.code === "idle")) {
        await this.setAllStates(result.code === "dictating" ? 1 : 0);
      }
    } finally {
      this.polling = false;
    }
  }

  private async setAllStates(state: 0 | 1): Promise<void> {
    for (const action of this.actions) {
      if (action.isKey() && this.visible.has(action.id) && this.states.get(action.id) !== state) {
        await action.setState(state);
        this.states.set(action.id, state);
      }
    }
  }
}
