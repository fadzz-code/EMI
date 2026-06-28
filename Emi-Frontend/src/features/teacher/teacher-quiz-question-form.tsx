"use client";

import { useMutation } from "@tanstack/react-query";

import { Alert, Button, Card, CardContent, CardHeader, Input, Select, Textarea } from "@/components/ui";
import { getFirstApiError } from "@/lib/api-client";

import { teacherService } from "./teacher-service";
import type { TeacherQuizOption, TeacherQuizQuestion } from "./types";

export function TeacherQuizQuestionForm({ classQuizId, editingQuestion, onCancelEdit, onSaved, token }: { classQuizId: string; editingQuestion: TeacherQuizQuestion | null; onCancelEdit: () => void; onSaved: () => void; token: string }) {
  const saveMutation = useMutation({
    mutationFn: (payload: Partial<TeacherQuizQuestion>) => editingQuestion ? teacherService.updateQuizQuestion(token, editingQuestion.id, payload) : teacherService.createQuizQuestion(token, classQuizId, payload),
    onSuccess: onSaved,
  });

  const options = normalizeOptions(editingQuestion?.options);

  return (
    <Card className="lg:col-span-2">
      <CardHeader><h2 className="text-xl font-black text-ink">{editingQuestion ? "Edit Soal" : "Tambah Soal"}</h2></CardHeader>
      <CardContent>
        <form className="grid gap-4" key={editingQuestion?.id ?? "new"} onSubmit={(event) => {
          event.preventDefault();
          const formData = new FormData(event.currentTarget);
          const questionType = String(formData.get("question_type") ?? "multiple_choice") as "multiple_choice" | "short_answer";
          const payload: Partial<TeacherQuizQuestion> = {
            question_type: questionType,
            question_text: String(formData.get("question_text") ?? ""),
            points: Number(formData.get("points") ?? 1),
            order_number: Number(formData.get("order_number") ?? 1),
            explanation: String(formData.get("explanation") ?? ""),
          };

          if (questionType === "multiple_choice") {
            payload.options = [1, 2, 3, 4].map((order) => ({
              option_text: String(formData.get(`option_${order}`) ?? ""),
              is_correct: String(formData.get("correct_option") ?? "1") === String(order),
              order_number: order,
            })).filter((option) => option.option_text.trim().length > 0);
          } else {
            payload.correct_answer_text = String(formData.get("correct_answer_text") ?? "");
            payload.use_fuzzy_matching = formData.get("use_fuzzy_matching") === "on";
            payload.fuzzy_threshold = Number(formData.get("fuzzy_threshold") ?? 85);
            payload.options = [];
          }

          saveMutation.mutate(payload);
        }}>
          {saveMutation.error ? <Alert tone="error">{getFirstApiError(saveMutation.error)}</Alert> : null}
          <div className="grid gap-4 sm:grid-cols-3">
            <label className="grid gap-2 text-sm font-black text-ink">Tipe<Select defaultValue={editingQuestion?.question_type ?? "multiple_choice"} name="question_type"><option value="multiple_choice">Pilihan ganda</option><option value="short_answer">Isian singkat</option></Select></label>
            <label className="grid gap-2 text-sm font-black text-ink">Poin<Input defaultValue={editingQuestion?.points ?? 1} min={1} name="points" type="number" required /></label>
            <label className="grid gap-2 text-sm font-black text-ink">Urutan<Input defaultValue={editingQuestion?.order_number ?? 1} min={1} name="order_number" type="number" required /></label>
          </div>
          <label className="grid gap-2 text-sm font-black text-ink">Pertanyaan<Textarea defaultValue={editingQuestion?.question_text ?? ""} name="question_text" required rows={3} /></label>
          <div className="grid gap-3 rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-black text-ink">Opsi pilihan ganda</p>
            {options.map((option) => (
              <div className="grid gap-2 sm:grid-cols-[1fr_auto]" key={option.order_number}>
                <Input defaultValue={option.option_text} name={`option_${option.order_number}`} placeholder={`Opsi ${option.order_number}`} />
                <label className="flex items-center gap-2 text-sm font-bold text-ink"><input defaultChecked={option.is_correct} name="correct_option" type="radio" value={option.order_number} /> Benar</label>
              </div>
            ))}
          </div>
          <div className="grid gap-3 rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p className="text-sm font-black text-ink">Isian singkat</p>
            <Input defaultValue={editingQuestion?.correct_answer_text ?? ""} name="correct_answer_text" placeholder="Jawaban benar" />
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="flex items-center gap-2 text-sm font-bold text-ink"><input defaultChecked={Boolean(editingQuestion?.use_fuzzy_matching)} name="use_fuzzy_matching" type="checkbox" /> Fuzzy matching</label>
              <Input defaultValue={editingQuestion?.fuzzy_threshold ?? 85} max={100} min={1} name="fuzzy_threshold" type="number" />
            </div>
          </div>
          <label className="grid gap-2 text-sm font-black text-ink">Pembahasan<Textarea defaultValue={editingQuestion?.explanation ?? ""} name="explanation" rows={2} /></label>
          <div className="flex gap-3"><Button disabled={saveMutation.isPending} type="submit">{saveMutation.isPending ? "Menyimpan..." : "Simpan Soal"}</Button>{editingQuestion ? <Button onClick={onCancelEdit} type="button" variant="secondary">Batal Edit</Button> : null}</div>
        </form>
      </CardContent>
    </Card>
  );
}

function normalizeOptions(options?: TeacherQuizOption[]) {
  return [1, 2, 3, 4].map((order) => options?.find((option) => option.order_number === order) ?? { option_text: "", is_correct: order === 1, order_number: order });
}
