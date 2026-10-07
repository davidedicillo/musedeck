# Support and Setup Guide for Muse Controls

Publisher: David DiCillo. Muse Controls is an independent plugin for Meta Muse on macOS, and is not affiliated with Meta.

## Requirements

- macOS 12 or later
- Stream Deck software 7.1 or later, with a keypad device
- Meta Muse for Mac, installed and signed in
- Accessibility access for Stream Deck (setup step 2 below)

## Setup

1. Install Muse Controls from Elgato Marketplace, or double click the .streamDeckPlugin file.
2. Allow Accessibility: Open System Settings, then Privacy and Security, then Accessibility, and turn on Stream Deck. Without this, keys will show an error instead of operating Muse.
3. Drag actions onto keys: In Stream Deck, find Muse Controls in the action list and drag any of the five actions onto free keys.
4. For Send Saved Prompt: Select that key in Stream Deck and type your text into the Prompt for this key field. Each key keeps its own prompt.

## The five actions

- Open Muse: Opens or focuses Muse and selects Main chat, even if a side chat was open.
- New Side Chat: Opens or focuses Muse and creates a new side chat, ready for input.
- Dictate: Press once to start dictation. If Muse is frontmost, dictation starts in the chat you are viewing. If another app is frontmost, it starts in Main chat. The key changes to Stop while recording. Press again to stop without sending.
- Finish and Send: Finishes an active dictation and sends it. When idle, it sends a draft already in the composer. An empty composer sends nothing.
- Send Saved Prompt: Sends the prompt saved on that key to the visible chat. If no prompt is set, it shows an error and sends nothing. If a draft is already in the composer, it shows an error and leaves the draft alone.

## Troubleshooting

- A key shows an error: Check that Muse is installed, signed in, and that Stream Deck has Accessibility access. Then try Open Muse first so Muse is running.
- Dictate went to Main chat instead of my side chat: That is by design when Muse was not the frontmost app at the moment you pressed the key. Bring Muse to the front first to dictate in a side chat.
- Send Saved Prompt did nothing: Open that key in Stream Deck and confirm the Prompt for this key field is not empty, and that the composer in Muse has no unsent draft.
- A Muse update changed a control: The plugin operates Muse visible controls, so a Muse layout change can require a plugin update. Note what happened and report it through the support link on the Marketplace listing.

## Privacy

The plugin collects no data. See PRIVACY.md for the full policy, including the brief clipboard use for saved prompts.
