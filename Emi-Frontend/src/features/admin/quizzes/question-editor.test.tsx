import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

vi.mock("next/image", () => ({ default: ({ alt }: { alt: string }) => <span data-alt={alt}>image</span> }));

import { Modal } from "@/components/ui/modal";
import { QuestionForm } from "./question-form";
import type { QuizTemplateQuestion } from "./types";

const submit = vi.fn(async () => undefined);

function renderQuestion(question?: QuizTemplateQuestion) {
  return renderToStaticMarkup(
    <QuestionForm isSubmitting={false} onCancel={vi.fn()} onSubmit={submit} question={question} token="token" />,
  );
}

describe("quiz question editor", () => {
  it("applies editor dimensions without changing default modal dimensions", () => {
    const editor = renderToStaticMarkup(<Modal onClose={vi.fn()} open size="editor" title="Editor">body</Modal>);
    const standard = renderToStaticMarkup(<Modal onClose={vi.fn()} open title="Standard">body</Modal>);

    expect(editor).toContain("max-w-[min(1400px,94vw)]");
    expect(editor).toContain("md:max-lg:max-w-[96vw]");
    expect(editor).toContain("max-md:h-[100dvh]");
    expect(editor).toContain("max-w-[1160px]");
    expect(standard).toContain("max-w-lg");
    expect(standard).not.toContain("max-w-[min(1400px,94vw)]");
  });

  it("keeps media preview and multiple-choice answers in editor sections", () => {
    const html = renderQuestion({
      id: "question-1",
      quiz_template_id: "quiz-1",
      question_type: "multiple_choice",
      question_text: "Question",
      points: 10,
      order_number: 1,
      explanation: null,
      correct_answer_text: null,
      use_fuzzy_matching: false,
      fuzzy_threshold: null,
      image_media_id: "media-1",
      image_media: { id: "media-1", purpose: "quiz_question_image", url: "/image.jpg", original_name: "image.jpg", mime_type: "image/jpeg", extension: "jpg", size_bytes: 1024, visibility: "public" },
      options: [{ id: "option-1", option_text: "Answer", is_correct: true, order_number: 1 }],
    } as QuizTemplateQuestion);

    expect(html).toContain("Pengaturan Soal");
    expect(html).toContain("Pertanyaan");
    expect(html).toContain("Media");
    expect(html).toContain("Pratinjau image.jpg");
    expect(html).toContain("Pilihan 1");
    expect(html).toContain("-bottom-3");
    expect(html).toContain("sm:-bottom-5");
    expect(html).not.toContain("Fuzzy matching");
  });

  it("shows short-answer controls instead of option rows", () => {
    const html = renderQuestion({
      id: "question-2",
      quiz_template_id: "quiz-1",
      question_type: "short_answer",
      question_text: "Question",
      points: 10,
      order_number: 1,
      explanation: null,
      correct_answer_text: "Answer",
      use_fuzzy_matching: true,
      fuzzy_threshold: 85,
      image_media_id: null,
      image_media: null,
      options: [],
    } as QuizTemplateQuestion);

    expect(html).toContain("Jawaban benar");
    expect(html).toContain("Koreksi jawaban mirip");
    expect(html).toContain("Tidak, harus persis sama");
    expect(html).toContain("Tingkat kemiripan");
    expect(html).toContain("Info tingkat kemiripan");
    expect(html).not.toContain("Fuzzy matching");
    expect(html).not.toContain("Threshold fuzzy");
    expect(html).not.toContain("Tambah Pilihan");
  });
});
