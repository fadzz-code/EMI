"use client";

import Link from "next/link";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

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
        className="inline-flex w-fit items-center gap-2 rounded-[8px] border-2 border-transparent px-1 py-2 text-sm font-black uppercase text-[#564338] hover:text-[#9a4600]"
        href="/admin/approvals"
      >
        {"<-"} Kembali ke Daftar Persetujuan
      </Link>

      <ApprovalHero
        description="Periksa detail akun, sekolah, dan kelas sebelum menyetujui atau menolak pendaftaran."
        title="Detail Review Akun"
      />

      {successMessage ? (
        <Alert
          className="border-2 border-[#241914] font-bold shadow-[3px_3px_0_#241914]"
          tone="success"
        >
          {successMessage}
        </Alert>
      ) : null}
      {actionError ? (
        <Alert
          className="border-2 border-[#241914] font-bold shadow-[3px_3px_0_#241914]"
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
          <Card className="overflow-hidden rounded-[12px] border-2 border-[#241914] bg-[#feeae0] shadow-[6px_6px_0_#241914]">
            <div className="h-24 border-b-2 border-[#241914] bg-[#fdd758]" />
            <CardContent className="grid justify-items-center gap-5 px-6 pb-8 pt-0 text-center">
              <div className="-mt-14">
                <div className="grid size-32 place-items-center rounded-full border-4 border-[#241914] bg-[#fff8f6] p-2 shadow-[4px_4px_0_#241914]">
                  <ApprovalAvatar
                    name={request.user?.full_name}
                    role={request.requested_role}
                  />
                </div>
              </div>
              <div>
                <h2 className="text-3xl font-black leading-tight text-[#241914]">
                  {request.user?.full_name ?? "Nama tidak tersedia"}
                </h2>
                <div className="mt-3 flex justify-center">
                  <ApprovalRoleBadge role={request.requested_role} />
                </div>
                <p className="mt-4 break-all text-sm font-semibold leading-6 text-[#564338]">
                  {request.user?.email ?? "-"}
                </p>
              </div>
              <div className="mt-8 w-full rounded-[8px] border-2 border-dashed border-[#241914] bg-[#fff8f6] p-5">
                <p className="text-xs font-black uppercase text-[#564338]">
                  Status Pendaftaran
                </p>
                <div className="mt-3 flex justify-center">
                  <ApprovalStatusBadge status={request.status} />
                </div>
              </div>
            </CardContent>
          </Card>

          <div className="grid content-start gap-5">
            <Card className="overflow-hidden rounded-[12px] border-2 border-[#241914] bg-[#fff8f6] shadow-[6px_6px_0_#241914]">
              <header className="flex items-center justify-between border-b-2 border-[#241914] bg-[#fff1eb] px-5 py-4">
                <h2 className="text-2xl font-black text-[#241914]">
                  Data Institusi & Kelas
                </h2>
                <span className="text-xl font-black text-[#9a4600]">ID</span>
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

            <Card className="rounded-[12px] border-2 border-[#241914] bg-[#f3ded5] shadow-[6px_6px_0_#241914]">
              <CardContent className="grid gap-3 p-6">
                <h2 className="text-sm font-black uppercase text-[#241914]">
                  Catatan Pendaftaran / Review
                </h2>
                <div className="min-h-28 rounded-[8px] border-2 border-dashed border-[#241914] bg-[#fff8f6] p-4 text-sm font-semibold leading-7 text-[#241914]">
                  {request.review_note ??
                    "Belum ada catatan review. Catatan approve bersifat opsional, catatan reject wajib diisi."}
                </div>
                <div className="grid gap-3 text-sm sm:grid-cols-2">
                  <div>
                    <p className="font-black uppercase text-[#564338]">Direview Pada</p>
                    <p className="mt-1 font-bold text-[#241914]">
                      {formatDateTime(request.reviewed_at)}
                    </p>
                  </div>
                  <div>
                    <p className="font-black uppercase text-[#564338]">Reviewer</p>
                    <p className="mt-1 font-bold text-[#241914]">
                      {request.reviewed_by?.full_name ?? "-"}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="rounded-[12px] border-2 border-[#241914] bg-[#f9e4db] shadow-[6px_6px_0_#241914]">
              <CardContent className="grid gap-5 p-6 text-center">
                <h2 className="text-2xl font-black text-[#241914]">Keputusan Review</h2>
                {isPending ? (
                  <div className="grid gap-3 sm:grid-cols-2">
                    <Button
                      className="min-h-14 rounded-[8px] border-2 border-[#241914] bg-[#ffdad6] text-sm font-black uppercase text-[#93000a] shadow-[4px_4px_0_#241914] hover:bg-[#ffe6e2]"
                      onClick={() => setAction("reject")}
                      variant="danger"
                    >
                      Tolak Akun
                    </Button>
                    <Button
                      className="min-h-14 rounded-[8px] border-2 border-[#241914] bg-[#5bbe5d] text-sm font-black uppercase text-[#004910] shadow-[4px_4px_0_#241914] hover:bg-[#75d877]"
                      onClick={() => setAction("approve")}
                      variant="secondary"
                    >
                      Setujui Akun
                    </Button>
                  </div>
                ) : (
                  <Alert className="border-2 border-[#241914] font-bold shadow-[3px_3px_0_#241914]" tone="info">
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
