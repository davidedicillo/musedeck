# Notes for Elgato Reviewers: Muse Controls v0.4.0.0

Thank you for reviewing. This plugin needs a specific test setup, because it controls another Mac app.

## Test setup, in order

1. Use a Mac on macOS 12 or later with Stream Deck software 7.1 or later.
2. Install the Meta Muse Mac app (bundle ID com.meta.endo) and sign in with any Muse account. The plugin has no test account of its own, and needs no API key.
3. Install Muse Controls from the submitted .streamDeckPlugin file.
4. Grant Accessibility: System Settings, Privacy and Security, Accessibility, turn on Stream Deck. Keys show an alert state without this, by design.
5. Drag the five Muse Controls actions onto keys.

## Suggested test pass

- Open Muse: Start from a side chat in Muse, press the key, Muse comes to the front on Main chat.
- New Side Chat: Press the key, a new empty side chat opens, ready for input.
- Dictate: With Muse frontmost, press Dictate, the key changes to a Stop state while Muse records, press again to stop without sending.
- Finish and Send: Dictate a short phrase, then press Finish and Send, the transcript is sent in the visible chat. Also try it with an empty composer: nothing is sent.
- Send Saved Prompt: Set a short harmless prompt in the key Property Inspector, for example Say hello in one sentence. Press the key in a disposable chat, exactly one message is sent. Clear the prompt and press again: an error shows and nothing is sent.

## Behavior notes

- The plugin operates Muse visible accessibility controls. It does not call any private Meta API, does not read conversation history, and stores no credentials.
- To insert and verify a saved prompt, the helper briefly uses the macOS clipboard, then restores its previous contents.
- Dictation routing is intentional: if Muse is not frontmost when Dictate is pressed, it records in Main chat. If Muse is frontmost, it records in the visible chat.
- Affiliation: This is an independent plugin by David DiCillo, not affiliated with Meta. That statement appears in the listing, the gallery footer, and the support guide.
