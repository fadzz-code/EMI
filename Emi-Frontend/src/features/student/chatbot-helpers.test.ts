import { describe, expect, it } from "vitest";

import {
  CHATBOT_ANSWER_PREFIX,
  CHATBOT_FALLBACK_ANSWER,
  citationsFromResponse,
  displayAnswer,
  messagesFromHistory,
  sourceLinkLabel,
  sourceTypeLabel,
} from "./chatbot-helpers";
import type { ChatbotConversationMessage, ChatbotSource } from "./types";

describe("displayAnswer", () => {
  it("strips the Basis AI prefix when present", () => {
    expect(displayAnswer(`${CHATBOT_ANSWER_PREFIX} Jawaban singkat.`)).toBe("Jawaban singkat.");
  });

  it("returns content unchanged when the prefix is absent", () => {
    expect(displayAnswer(CHATBOT_FALLBACK_ANSWER)).toBe(CHATBOT_FALLBACK_ANSWER);
  });

  it("returns an empty string unchanged", () => {
    expect(displayAnswer("")).toBe("");
  });
});

describe("sourceTypeLabel", () => {
  it("maps every known source type to its Indonesian label", () => {
    expect(sourceTypeLabel("pdf")).toBe("PDF / Dokumen");
    expect(sourceTypeLabel("docx")).toBe("Dokumen Word");
    expect(sourceTypeLabel("txt")).toBe("Berkas Teks");
    expect(sourceTypeLabel("link")).toBe("Link");
    expect(sourceTypeLabel("manual")).toBe("Teks Manual");
    expect(sourceTypeLabel(undefined)).toBe("Teks Manual");
  });
});

describe("sourceLinkLabel", () => {
  it("uses document wording for document-like source types", () => {
    expect(sourceLinkLabel("pdf")).toBe("Buka dokumen sumber");
    expect(sourceLinkLabel("docx")).toBe("Buka dokumen sumber");
    expect(sourceLinkLabel("txt")).toBe("Buka dokumen sumber");
  });

  it("uses generic wording for link/manual source types", () => {
    expect(sourceLinkLabel("link")).toBe("Buka sumber");
    expect(sourceLinkLabel("manual")).toBe("Buka sumber");
    expect(sourceLinkLabel(undefined)).toBe("Buka sumber");
  });
});

describe("citationsFromResponse", () => {
  const sourceA: ChatbotSource = { id: "a", title: "Sumber A" };
  const sourceB: ChatbotSource = { id: "b", title: "Sumber B" };

  it("prefers the sources array when it has entries", () => {
    expect(citationsFromResponse(sourceA, [sourceA, sourceB])).toEqual([sourceA, sourceB]);
  });

  it("falls back to the single source when sources array is empty", () => {
    expect(citationsFromResponse(sourceA, [])).toEqual([sourceA]);
  });

  it("falls back to the single source when sources array is undefined", () => {
    expect(citationsFromResponse(sourceA, undefined)).toEqual([sourceA]);
  });

  it("returns an empty array when there is no source at all", () => {
    expect(citationsFromResponse(null, undefined)).toEqual([]);
    expect(citationsFromResponse(null, [])).toEqual([]);
  });
});

describe("messagesFromHistory", () => {
  it("maps conversation messages preserving order and role", () => {
    const history: ChatbotConversationMessage[] = [
      { id: "1", role: "user", content: "Halo", citations: [] },
      { id: "2", role: "assistant", content: "Halo juga", citations: [{ id: "s1", title: "Sumber" }] },
    ];

    const result = messagesFromHistory(history);

    expect(result).toHaveLength(2);
    expect(result[0]).toMatchObject({ id: "1", role: "user", content: "Halo", matched: undefined });
    expect(result[1]).toMatchObject({ id: "2", role: "assistant", content: "Halo juga", matched: true });
    expect(result[1].citations).toEqual([{ id: "s1", title: "Sumber" }]);
  });

  it("marks assistant messages with no citations as unmatched", () => {
    const history: ChatbotConversationMessage[] = [
      { id: "1", role: "assistant", content: CHATBOT_FALLBACK_ANSWER, citations: [] },
    ];

    const result = messagesFromHistory(history);

    expect(result[0].matched).toBe(false);
  });

  it("returns an empty array for empty history", () => {
    expect(messagesFromHistory([])).toEqual([]);
  });
});
