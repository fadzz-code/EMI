"use client";

import Link from "next/link";
import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ErrorState,
  LoadingState,
  PageHeader,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { ApprovalActionDialog } from "./approval-action-dialog";
import { approvalService } from "./approval-service";
import {
  formatDateTime,
  roleLabel,
  statusLabel,
  statusTone,
} from "./approval-utils";

type DetailAction = "approve" | "reject" | null;

function DetailRow({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div className="rounded-lg border-2 border-ink bg-white p-4">
      <p className="text-xs font-black uppercase text-slate-500">{label}</p>
      <div className="mt-2 text-sm font-bold text-ink">{value ?? "-"}</div>
    </div>
  );
}

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
    <div className="grid gap-6">
      <PageHeader
        badge="Admin"
        description="Periksa detail akun, sekolah, dan kelas sebelum menyetujui atau menolak pendaftaran."
        title="Detail Review Akun"
      />

      <Link
        className="w-fit rounded-lg border-2 border-ink bg-white px-3 py-2 text-sm font-black text-ink hover:bg-yellow-100"
        href="/admin/approvals"
      >
        Kembali ke Persetujuan
      </Link>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      {detailQuery.isLoading ? <LoadingState title="Memuat detail" /> : null}

      {detailQuery.isError ? (
        <ErrorState
          description={getFirstApiError(detailQuery.error)}
          onRetry={() => void detailQuery.refetch()}
          title="Gagal memuat detail"
        />
      ) : null}

      {request ? (
        <div className="grid gap-6">
          <Card>
            <CardHeader>
              <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
                <div>
                  <h2 className="text-xl font-black text-ink">
                    {request.user?.full_name ?? "Nama tidak tersedia"}
                  </h2>
                  <p className="mt-1 text-sm text-slate-600">
                    {request.user?.email ?? "-"}
                  </p>
                </div>
                <Badge tone={statusTone(request.status)}>
                  {statusLabel(request.status)}
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4 md:grid-cols-2">
                <DetailRow label="Role Diminta" value={roleLabel(request.requested_role)} />
                <DetailRow label="Status User" value={request.user?.status} />
                <DetailRow label="Sekolah" value={request.school?.name} />
                <DetailRow
                  label="Kelas"
                  value={
                    request.school_class
                      ? `${request.school_class.name}${
                          request.school_class.academic_year
                            ? ` - ${request.school_class.academic_year}`
                            : ""
                        }`
                      : "-"
                  }
                />
                <DetailRow label="Tanggal Daftar" value={formatDateTime(request.created_at)} />
                <DetailRow label="Direview Pada" value={formatDateTime(request.reviewed_at)} />
                <DetailRow label="Reviewer" value={request.reviewed_by?.full_name} />
                <DetailRow label="Catatan Review" value={request.review_note} />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <h2 className="text-lg font-black text-ink">Keputusan Admin</h2>
            </CardHeader>
            <CardContent>
              {isPending ? (
                <div className="flex flex-col gap-3 sm:flex-row">
                  <Button onClick={() => setAction("approve")} variant="secondary">
                    Approve
                  </Button>
                  <Button onClick={() => setAction("reject")} variant="danger">
                    Reject
                  </Button>
                </div>
              ) : (
                <Alert tone="info">
                  Permintaan ini sudah diproses. Action approval tidak lagi
                  tersedia untuk request non-pending.
                </Alert>
              )}
            </CardContent>
          </Card>
        </div>
      ) : null}

      <ApprovalActionDialog
        action={action ?? "approve"}
        isSubmitting={isSubmitting}
        onClose={() => setAction(null)}
        onConfirm={handleConfirm}
        open={Boolean(action)}
      />
    </div>
  );
}
