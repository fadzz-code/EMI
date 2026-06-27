"use client";

import Link from "next/link";
import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  ConfirmDialog,
  EmptyState,
  ErrorState,
  FilterPanel,
  Input,
  LoadingState,
  Modal,
  Pagination,
  Select,
  Table,
  TableCell,
  TableHeader,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { classService } from "@/features/admin/management/management-service";
import { getFirstApiError } from "@/lib/api-client";

import { QuizTemplateForm } from "./quiz-form";
import { quizTemplateService } from "./quiz-service";
import { formatDate, statusLabel, statusTone } from "./quiz-utils";
import type { QuizTemplate, QuizTemplatePayload, QuizTemplateStatus } from "./types";

export function QuizList() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<QuizTemplateStatus | "">("");
  const [createModalOpen, setCreateModalOpen] = useState(false);
  const [editingQuiz, setEditingQuiz] = useState<QuizTemplate | null>(null);
  const [applyTarget, setApplyTarget] = useState<QuizTemplate | null>(null);
  const [selectedClassIds, setSelectedClassIds] = useState<string[]>([]);
  const [deleteTarget, setDeleteTarget] = useState<QuizTemplate | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const filters = useMemo(
    () => ({
      search,
      status,
      page,
      per_page: 12,
    }),
    [page, search, status],
  );

  const quizzesQuery = useQuery({
    queryKey: ["admin", "quiz-templates", filters],
    queryFn: () => quizTemplateService.list(token ?? "", filters),
    enabled: Boolean(token),
  });

  const classesQuery = useQuery({
    queryKey: ["admin", "classes", "quiz-apply-targets"],
    queryFn: () => classService.list(token ?? "", { status: "active", per_page: 100 }),
    enabled: Boolean(token),
  });

  const createMutation = useMutation({
    mutationFn: (payload: QuizTemplatePayload) =>
      quizTemplateService.create(token ?? "", payload),
    onSuccess: async (quiz) => {
      setSuccessMessage(`Kuis ${quiz.title} berhasil dibuat.`);
      setCreateModalOpen(false);
      await queryClient.invalidateQueries({ queryKey: ["admin", "quiz-templates"] });
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ quizId, payload }: { quizId: string; payload: QuizTemplatePayload }) =>
      quizTemplateService.update(token ?? "", quizId, payload),
    onSuccess: async (quiz) => {
      setSuccessMessage(`Metadata kuis ${quiz.title} berhasil diperbarui.`);
      setEditingQuiz(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "quiz-templates"] });
    },
  });

  const publishMutation = useMutation({
    mutationFn: (quizId: string) => quizTemplateService.publish(token ?? "", quizId),
    onSuccess: async (quiz) => {
      setSuccessMessage(`Kuis ${quiz.title} berhasil diterbitkan.`);
      await queryClient.invalidateQueries({ queryKey: ["admin", "quiz-templates"] });
    },
  });

  const archiveMutation = useMutation({
    mutationFn: (quizId: string) => quizTemplateService.archive(token ?? "", quizId),
    onSuccess: async (quiz) => {
      setSuccessMessage(`Kuis ${quiz.title} berhasil diarsipkan.`);
      await queryClient.invalidateQueries({ queryKey: ["admin", "quiz-templates"] });
    },
  });

  const applyMutation = useMutation({
    mutationFn: ({ quizId, classIds }: { quizId: string; classIds: string[] }) =>
      quizTemplateService.applyToClasses(token ?? "", quizId, classIds),
    onSuccess: (result) => {
      setSuccessMessage(
        `Template kuis diterapkan: ${result.applied.length} kelas, dilewati: ${result.skipped.length}, gagal: ${result.failed.length}. Kuis kelas hasil apply masih perlu dipublish agar terlihat siswa.`,
      );
      setApplyTarget(null);
      setSelectedClassIds([]);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (quizId: string) => quizTemplateService.delete(token ?? "", quizId),
    onSuccess: async () => {
      setSuccessMessage("Kuis berhasil dihapus sesuai aturan soft delete backend.");
      setDeleteTarget(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "quiz-templates"] });
    },
  });

  const actionError =
    createMutation.error ??
    updateMutation.error ??
    publishMutation.error ??
    archiveMutation.error ??
    applyMutation.error ??
    deleteMutation.error;

  const quizzes = quizzesQuery.data?.items ?? [];
  const meta = quizzesQuery.data?.meta;
  const classes = classesQuery.data?.items ?? [];

  function applySearch() {
    setPage(1);
    setSearch(searchInput.trim());
  }

  function toggleClass(classId: string) {
    setSelectedClassIds((current) =>
      current.includes(classId)
        ? current.filter((id) => id !== classId)
        : [...current, classId],
    );
  }

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="yellow">ADMIN-15</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Kuis & LKPD Default</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Kelola template kuis default dari endpoint admin/quiz-templates. LKPD khusus
            belum punya endpoint terpisah, jadi layar ini mengikuti model quiz template backend.
          </p>
        </div>
        <Button onClick={() => setCreateModalOpen(true)}>Tambah Kuis</Button>
      </header>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      <FilterPanel className="md:grid-cols-[2fr_1fr_auto]">
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Cari kuis</span>
          <Input
            onChange={(event) => setSearchInput(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") {
                applySearch();
              }
            }}
            placeholder="Judul atau deskripsi kuis"
            value={searchInput}
          />
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Status</span>
          <Select
            onChange={(event) => {
              setStatus(event.target.value as QuizTemplateStatus | "");
              setPage(1);
            }}
            value={status}
          >
            <option value="">Semua status</option>
            <option value="draft">Draft</option>
            <option value="published">Terbit</option>
            <option value="archived">Diarsipkan</option>
          </Select>
        </label>
        <div className="flex items-end">
          <Button className="w-full" onClick={applySearch} variant="secondary">
            Terapkan
          </Button>
        </div>
      </FilterPanel>

      <Card>
        <CardContent>
          {quizzesQuery.isLoading ? <LoadingState title="Memuat kuis" /> : null}
          {quizzesQuery.isError ? (
            <ErrorState
              description={getFirstApiError(quizzesQuery.error)}
              onRetry={() => void quizzesQuery.refetch()}
              title="Gagal memuat kuis"
            />
          ) : null}
          {!quizzesQuery.isLoading && !quizzesQuery.isError ? (
            quizzes.length === 0 ? (
              <EmptyState
                description="Belum ada kuis default sesuai filter saat ini."
                title="Kuis kosong"
              />
            ) : (
              <div className="grid gap-4">
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Kuis</th>
                      <th className="px-4 py-3">Durasi</th>
                      <th className="px-4 py-3">Percobaan</th>
                      <th className="px-4 py-3">Soal</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Dibuat</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {quizzes.map((quiz) => (
                      <tr key={quiz.id}>
                        <TableCell>
                          <p className="font-black text-ink">{quiz.title}</p>
                          <p className="mt-1 line-clamp-2 text-xs leading-5 text-slate-600">
                            {quiz.description ?? "Tanpa deskripsi."}
                          </p>
                        </TableCell>
                        <TableCell>{quiz.duration_minutes} menit</TableCell>
                        <TableCell>{quiz.max_attempts}x</TableCell>
                        <TableCell>{quiz.questions_count ?? quiz.questions?.length ?? "-"}</TableCell>
                        <TableCell>
                          <Badge tone={statusTone(quiz.status)}>{statusLabel(quiz.status)}</Badge>
                        </TableCell>
                        <TableCell>{formatDate(quiz.created_at)}</TableCell>
                        <TableCell>
                          <div className="flex flex-wrap gap-2">
                            <Link
                              className="inline-flex min-h-9 items-center rounded-lg border-2 border-ink bg-white px-3 py-1 text-xs font-black text-ink hover:bg-yellow-100"
                              href={`/admin/quizzes/${quiz.id}/builder`}
                            >
                              Builder
                            </Link>
                            <Button
                              className="min-h-9 px-3 py-1 text-xs"
                              onClick={() => setEditingQuiz(quiz)}
                              variant="secondary"
                            >
                              Edit
                            </Button>
                            {quiz.status !== "published" ? (
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                disabled={publishMutation.isPending}
                                onClick={() => publishMutation.mutate(quiz.id)}
                                variant="secondary"
                              >
                                Terbitkan
                              </Button>
                            ) : null}
                            {quiz.status === "published" ? (
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                onClick={() => {
                                  setApplyTarget(quiz);
                                  setSelectedClassIds([]);
                                }}
                                variant="secondary"
                              >
                                Terapkan ke Kelas
                              </Button>
                            ) : null}
                            {quiz.status !== "archived" ? (
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                disabled={archiveMutation.isPending}
                                onClick={() => archiveMutation.mutate(quiz.id)}
                                variant="ghost"
                              >
                                Arsipkan
                              </Button>
                            ) : null}
                            <Button
                              className="min-h-9 px-3 py-1 text-xs"
                              disabled={deleteMutation.isPending}
                              onClick={() => setDeleteTarget(quiz)}
                              variant="danger"
                            >
                              Hapus
                            </Button>
                          </div>
                        </TableCell>
                      </tr>
                    ))}
                  </tbody>
                </Table>
                <Pagination
                  onPageChange={setPage}
                  page={meta?.current_page ?? page}
                  totalPages={meta?.last_page ?? 1}
                />
              </div>
            )
          ) : null}
        </CardContent>
      </Card>

      <Modal
        onClose={() => setCreateModalOpen(false)}
        open={createModalOpen}
        title="Tambah Kuis Default"
      >
        <QuizTemplateForm
          isSubmitting={createMutation.isPending}
          onCancel={() => setCreateModalOpen(false)}
          onSubmit={(payload) => createMutation.mutate({ ...payload, status: "draft" })}
        />
      </Modal>

      <Modal
        onClose={() => setEditingQuiz(null)}
        open={Boolean(editingQuiz)}
        title="Edit Metadata Kuis"
      >
        {editingQuiz ? (
          <QuizTemplateForm
            isSubmitting={updateMutation.isPending}
            onCancel={() => setEditingQuiz(null)}
            onSubmit={(payload) =>
              updateMutation.mutate({ quizId: editingQuiz.id, payload })
            }
            quiz={editingQuiz}
          />
        ) : null}
      </Modal>

      <Modal
        onClose={() => setApplyTarget(null)}
        open={Boolean(applyTarget)}
        title="Terapkan Kuis ke Kelas"
      >
        <div className="grid gap-4">
          <Alert tone="info">
            Publish template hanya membuat template kuis siap dipakai. Tombol ini menyalin template menjadi kuis kelas. Kuis kelas hasil apply masih berstatus draft dan harus dipublish agar tampil di siswa.
          </Alert>
          {classesQuery.isLoading ? <LoadingState title="Memuat kelas" /> : null}
          {classesQuery.isError ? <ErrorState description={getFirstApiError(classesQuery.error)} title="Gagal memuat kelas" /> : null}
          {!classesQuery.isLoading && !classesQuery.isError ? (
            classes.length === 0 ? (
              <EmptyState description="Belum ada kelas aktif untuk menerima template kuis." title="Kelas aktif kosong" />
            ) : (
              <div className="grid max-h-80 gap-2 overflow-auto rounded-xl border border-slate-200 p-3">
                {classes.map((schoolClass) => (
                  <label className="flex items-center gap-3 rounded-lg border border-slate-200 bg-white p-3 text-sm font-bold text-ink" key={schoolClass.id}>
                    <input
                      checked={selectedClassIds.includes(schoolClass.id)}
                      onChange={() => toggleClass(schoolClass.id)}
                      type="checkbox"
                    />
                    <span>{schoolClass.name} · {schoolClass.academic_year}</span>
                  </label>
                ))}
              </div>
            )
          ) : null}
          <div className="flex flex-col gap-2 sm:flex-row sm:justify-end">
            <Button onClick={() => setApplyTarget(null)} type="button" variant="ghost">
              Batal
            </Button>
            <Button
              disabled={!applyTarget || selectedClassIds.length === 0 || applyMutation.isPending}
              onClick={() => {
                if (applyTarget) {
                  applyMutation.mutate({ quizId: applyTarget.id, classIds: selectedClassIds });
                }
              }}
              type="button"
            >
              {applyMutation.isPending ? "Menerapkan..." : "Terapkan"}
            </Button>
          </div>
        </div>
      </Modal>

      <ConfirmDialog
        confirmLabel={deleteMutation.isPending ? "Menghapus..." : "Hapus Kuis"}
        description={
          deleteTarget
            ? `Kuis "${deleteTarget.title}" akan dihapus dengan soft delete sesuai backend.`
            : ""
        }
        onCancel={() => setDeleteTarget(null)}
        onConfirm={() => {
          if (deleteTarget) {
            deleteMutation.mutate(deleteTarget.id);
          }
        }}
        open={Boolean(deleteTarget)}
        title="Hapus kuis?"
      />
    </div>
  );
}
