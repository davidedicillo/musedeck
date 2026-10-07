import streamDeck from "@elgato/streamdeck";

import { OpenMuse } from "./actions/open-muse";
import { NewSideChat } from "./actions/new-side-chat";
import { Dictate } from "./actions/dictate";
import { SendPrompt } from "./actions/send-prompt";
import { FinishSend } from "./actions/finish-send";

// We can enable "trace" logging so that all messages between the Stream Deck, and the plugin are recorded. When storing sensitive information
streamDeck.logger.setLevel("info");

// Register the increment action.
streamDeck.actions.registerAction(new OpenMuse());
streamDeck.actions.registerAction(new NewSideChat());
streamDeck.actions.registerAction(new Dictate());
streamDeck.actions.registerAction(new SendPrompt());
streamDeck.actions.registerAction(new FinishSend());

// Finally, connect to the Stream Deck.
streamDeck.connect();
