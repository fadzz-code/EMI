"use client";

import Link from "next/link";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft, Check, X } from "lucide-react";

import {
  Alert,
  Button,
  Card,
  CardContent,
  ErrorState,
  LoadingState,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { ApprovalActionDialog } from "./approval-action-dialog";
import { approvalService } from "./approval-service";
import {
  ApprovalAvatar,
  ApprovalHero,
  ApprovalPageShell,
  ApprovalRoleBadge,
  ApprovalStatusBadge,
  DetailCell,
  getClassName,
} from "./approval-visuals";
import { formatDateTime } from "./approval-utils";

type DetailAction = "approve" | "reject" | null;

export function ApprovalDetail({ requestId }: { requestId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [action, setAction] = useState<DetailAction>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const detailQuery = useQuery({
    queryKey: ["admin", "registration-requests", requestId],
    queryFn: () => approvalService.detail(token ?? "", requestId),
    enabled: Boolean(token && requestId),
  });

  const approveMutation = useMutation({
    mutationFn: (reviewNote: string) =>
      approvalService.approve(token ?? "", requestId, reviewNote || undefined),
    onSuccess: async (request) => {
      setSuccessMessage(`${request.user?.full_name ?? "Akun"} berhasil disetujui.`);
      setAction(null);
      await queryClient.invalidateQueries({
        queryKey: ["admin", "registration-requests"],
      });
    },
  });

  const rejectMutation = useMutation({
    mutationFn: (reviewNote: string) =>
      approvalService.reject(token ?? "", requestId, reviewNote),
    onSuccess: async (request) => {
      setSuccessMessage(`${request.user?.full_name ?? "Akun"} berhasil ditolak.`);
      setAction(null);
      await queryClient.invalidateQueries({
        queryKey: ["admin", "registration-requests"],
      });
    },
  });

  function handleConfirm(reviewNote: string) {
    if (action === "approve") {
      approveMutation.mutate(reviewNote);
      return;
    }

    if (action === "reject") {
      rejectMutation.mutate(reviewNote);
    }
  }

  const request = detailQuery.data;
  const isPending = request?.status === "pending";
  const actionError = approveMutation.error ?? rejectMutation.error;
  const isSubmitting = approveMutation.isPending || rejectMutation.isPending;

  return (
    <ApprovalPageShell>
      <Link
        className="inline-flex w-fit items-center gap-2 rounded-[8px] border-2 border-transparent px-1 py-2 text-sm font-black uppercase text-muted hover:text-primary"
        href="/admin/approvals"
      >
        <ArrowLeft aria-hidden="true" className="size-4" /> Kembali ke Daftar Persetujuan
      </Link>

      <ApprovalHero
        description="Periksa detail akun, sekolah, dan kelas sebelum menyetujui atau menolak pendaftaran."
        title="Detail Review Akun"
      />

      {successMessage ? (
        <Alert
          className="border-2 border-border font-bold shadow-emi"
          tone="success"
        >
          {successMessage}
        </Alert>
      ) : null}
      {actionError ? (
        <Alert
          className="border-2 border-border font-bold shadow-emi"
          tone="error"
        >
          {getFirstApiError(actionError)}
        </Alert>
      ) : null}

      {detailQuery.isLoading ? <LoadingState title="Memuat detail" /> : null}

      {detailQuery.isError ? (
        <ErrorState
          description={getFirstApiError(detailQuery.error)}
          onRetry={() => void detailQuery.refetch()}
          title="Gagal memuat detail"
        />
      ) : null}

      {request ? (
        <div className="grid gap-6 xl:grid-cols-[0.82fr_1.8fr]">
          <Card className="overflow-hidden rounded-[12px] border-2 border-border bg-surface-muted shadow-emi">
            <div className="h-24 border-b-2 border-border bg-[var(--color-primary-muted)]" />
            <CardContent className="grid justify-items-center gap-5 px-6 pb-8 pt-0 text-center">
              <div className="-mt-14">
                <div className="grid size-32 place-items-center rounded-full border-4 border-border bg-surface p-2 shadow-emi">
                  <ApprovalAvatar
                    name={request.user?.full_name}
                    role={request.requested_role}
                  />
                </div>
              </div>
              <div>
                <h2 className="text-3xl font-black leading-tight text-ink">
                  {request.user?.full_name ?? "Nama tidak tersedia"}
                </h2>
                <div className="mt-3 flex justify-center">
                  <ApprovalRoleBadge role={request.requested_role} />
                </div>
                <p className="mt-4 break-all text-sm font-semibold leading-6 text-muted">
                  {request.user?.email ?? "-"}
                </p>
              </div>
              <div className="mt-8 w-full rounded-[8px] border-2 border-dashed border-border bg-surface p-5">
                <p className="text-xs font-black uppercase text-muted">
                  Status Pendaftaran
                </p>
                <div className="mt-3 flex justify-center">
                  <ApprovalStatusBadge status={request.status} />
                </div>
              </div>
            </CardContent>
          </Card>

          <div className="grid content-start gap-5">
            <Card className="overflow-hidden rounded-[12px] border-2 border-border bg-surface shadow-emi">
              <header className="flex items-center justify-between border-b-2 border-border bg-surface-muted px-5 py-4">
                <h2 className="text-2xl font-black text-ink">
                  Data Institusi & Kelas
                </h2>
                <span className="text-xl font-black text-primary">ID</span>
              </header>
              <CardContent className="grid p-0 sm:grid-cols-2">
                <DetailCell label="Asal Sekolah" value={request.school?.name} />
                <DetailCell label="Tingkat Kelas" value={getClassName(request)} />
                <DetailCell
                  label="Tanggal Pendaftaran"
                  value={formatDateTime(request.created_at)}
                />
                <DetailCell label="Status User" value={request.user?.status} />
              </CardContent>
            </Card>

            <Card className="rounded-[12px] border-2 border-border bg-surface-muted shadow-emi">
              <CardContent className="grid gap-3 p-6">
                <h2 className="text-sm font-black uppercase text-ink">
                  Catatan Pendaftaran / Review
                </h2>
                <div className="min-h-28 rounded-[8px] border-2 border-dashed border-border bg-surface p-4 text-sm font-semibold leading-7 text-ink">
                  {request.review_note ??
                    "Belum ada catatan review. Catatan approve bersifat opsional, catatan reject wajib diisi."}
                </div>
                <div className="grid gap-3 text-sm sm:grid-cols-2">
                  <div>
                    <p className="font-black uppercase text-muted">Direview Pada</p>
                    <p className="mt-1 font-bold text-ink">
                      {formatDateTime(request.reviewed_at)}
                    </p>
                  </div>
                  <div>
                    <p className="font-black uppercase text-muted">Reviewer</p>
                    <p className="mt-1 font-bold text-ink">
                      {request.reviewed_by?.full_name ?? "-"}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="rounded-[12px] border-2 border-border bg-surface-muted shadow-emi">
              <CardContent className="grid gap-5 p-6 text-center">
                <h2 className="text-2xl font-black text-ink">Keputusan Review</h2>
                {isPending ? (
                  <div className="grid gap-3 sm:grid-cols-2">
                    <Button
                       className="min-h-14 rounded-[8px] border-2 border-border bg-danger-muted text-sm font-black uppercase text-danger shadow-emi hover:bg-danger/20"
                      onClick={() => setAction("reject")}
                      variant="danger"
                    >
                      <X aria-hidden="true" className="mr-2 size-4" />
                      Tolak Akun
                    </Button>
                    <Button
                       className="min-h-14 rounded-[8px] border-2 border-border bg-success text-sm font-black uppercase text-success-foreground shadow-emi hover:bg-success/80"
                      onClick={() => setAction("approve")}
                      variant="secondary"
                    >
                      <Check aria-hidden="true" className="mr-2 size-4" />
                      Setujui Akun
                    </Button>
                  </div>
                ) : (
                  <Alert className="border-2 border-border font-bold shadow-emi" tone="info">
                    Permintaan ini sudah diproses. Action approval tidak lagi
                    tersedia untuk request non-pending.
                  </Alert>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      ) : null}

      <ApprovalActionDialog
        action={action ?? "approve"}
        isSubmitting={isSubmitting}
        onClose={() => setAction(null)}
        onConfirm={handleConfirm}
        open={Boolean(action)}
      />
    </ApprovalPageShell>
  );
}
