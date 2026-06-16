"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  EmptyState,
  ErrorState,
  FilterPanel,
  Input,
  LoadingState,
  PageHeader,
  Pagination,
  Select,
  Table,
  TableCell,
  TableHeader,
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
import type {
  RegistrationRequest,
  RegistrationRequestFilters,
  RegistrationRequestedRole,
} from "./types";

type PendingAction = {
  action: "approve" | "reject";
  request: RegistrationRequest;
} | null;

export function ApprovalList() {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [requestedRole, setRequestedRole] =
    useState<RegistrationRequestedRole | "">("");
  const [pendingAction, setPendingAction] = useState<PendingAction>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const filters = useMemo<RegistrationRequestFilters>(
    () => ({
      status: "pending",
      requested_role: requestedRole,
      search,
      page,
      per_page: 15,
    }),
    [page, requestedRole, search],
  );

  const approvalsQuery = useQuery({
    queryKey: ["admin", "registration-requests", filters],
    queryFn: () => approvalService.list(token ?? "", filters),
    enabled: Boolean(token),
  });

  const approveMutation = useMutation({
    mutationFn: ({
      requestId,
      reviewNote,
    }: {
      requestId: string;
      reviewNote?: string;
    }) => approvalService.approve(token ?? "", requestId, reviewNote),
    onSuccess: (request) => {
      setSuccessMessage(`${request.user?.full_name ?? "Akun"} berhasil disetujui.`);
      setPendingAction(null);
      void queryClient.invalidateQueries({
        queryKey: ["admin", "registration-requests"],
      });
    },
  });

  const rejectMutation = useMutation({
    mutationFn: ({
      requestId,
      reviewNote,
    }: {
      requestId: string;
      reviewNote: string;
    }) => approvalService.reject(token ?? "", requestId, reviewNote),
    onSuccess: (request) => {
      setSuccessMessage(`${request.user?.full_name ?? "Akun"} berhasil ditolak.`);
      setPendingAction(null);
      void queryClient.invalidateQueries({
        queryKey: ["admin", "registration-requests"],
      });
    },
  });

  function applySearch() {
    setPage(1);
    setSearch(searchInput.trim());
  }

  function handleAction(reviewNote: string) {
    if (!pendingAction) {
      return;
    }

    if (pendingAction.action === "approve") {
      approveMutation.mutate({
        requestId: pendingAction.request.id,
        reviewNote: reviewNote || undefined,
      });
      return;
    }

    rejectMutation.mutate({
      requestId: pendingAction.request.id,
      reviewNote,
    });
  }

  const rows = approvalsQuery.data?.items ?? [];
  const meta = approvalsQuery.data?.meta;
  const isSubmitting = approveMutation.isPending || rejectMutation.isPending;
  const actionError = approveMutation.error ?? rejectMutation.error;

  return (
    <div className="grid gap-6">
      <PageHeader
        badge="Admin"
        description="Review akun Guru dan Siswa yang baru mendaftar sebelum mereka dapat login."
        title="Persetujuan Akun"
      />

      <FilterPanel>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Cari nama atau email</span>
          <Input
            onChange={(event) => setSearchInput(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") {
                applySearch();
              }
            }}
            placeholder="Contoh: andi@example.com"
            value={searchInput}
          />
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Role</span>
          <Select
            onChange={(event) => {
              setRequestedRole(event.target.value as RegistrationRequestedRole | "");
              setPage(1);
            }}
            value={requestedRole}
          >
            <option value="">Semua role</option>
            <option value="teacher">Guru</option>
            <option value="student">Siswa</option>
          </Select>
        </label>
        <div className="flex items-end">
          <Button className="w-full" onClick={applySearch} variant="secondary">
            Terapkan Filter
          </Button>
        </div>
      </FilterPanel>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      {approvalsQuery.isLoading ? <LoadingState title="Memuat permintaan" /> : null}

      {approvalsQuery.isError ? (
        <ErrorState
          description={getFirstApiError(approvalsQuery.error)}
          onRetry={() => void approvalsQuery.refetch()}
          title="Gagal memuat permintaan"
        />
      ) : null}

      {!approvalsQuery.isLoading && !approvalsQuery.isError ? (
        rows.length === 0 ? (
          <EmptyState
            description="Tidak ada akun Guru atau Siswa yang menunggu approval untuk filter saat ini."
            title="Belum ada permintaan pending"
          />
        ) : (
          <Card>
            <CardContent>
              <Table>
                <TableHeader>
                  <tr>
                    <th className="px-4 py-3">Nama</th>
                    <th className="px-4 py-3">Email</th>
                    <th className="px-4 py-3">Role</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Tanggal Daftar</th>
                    <th className="px-4 py-3">Aksi</th>
                  </tr>
                </TableHeader>
                <tbody>
                  {rows.map((request) => (
                    <tr key={request.id}>
                      <TableCell className="font-black text-ink">
                        {request.user?.full_name ?? "-"}
                      </TableCell>
                      <TableCell>{request.user?.email ?? "-"}</TableCell>
                      <TableCell>{roleLabel(request.requested_role)}</TableCell>
                      <TableCell>
                        <Badge tone={statusTone(request.status)}>
                          {statusLabel(request.status)}
                        </Badge>
                      </TableCell>
                      <TableCell>{formatDateTime(request.created_at)}</TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-2">
                          <Link
                            className="inline-flex min-h-10 items-center rounded-lg border-2 border-ink bg-white px-3 py-2 text-xs font-black text-ink hover:bg-yellow-100"
                            href={`/admin/approvals/${request.id}`}
                          >
                            Detail
                          </Link>
                          <Button
                            className="min-h-10 px-3 py-2 text-xs"
                            onClick={() => setPendingAction({ action: "approve", request })}
                            variant="secondary"
                          >
                            Approve
                          </Button>
                          <Button
                            className="min-h-10 px-3 py-2 text-xs"
                            onClick={() => setPendingAction({ action: "reject", request })}
                            variant="danger"
                          >
                            Reject
                          </Button>
                        </div>
                      </TableCell>
                    </tr>
                  ))}
                </tbody>
              </Table>
              <div className="mt-5">
                <Pagination
                  onPageChange={setPage}
                  page={meta?.current_page ?? page}
                  totalPages={meta?.last_page ?? 1}
                />
              </div>
            </CardContent>
          </Card>
        )
      ) : null}

      <ApprovalActionDialog
        action={pendingAction?.action ?? "approve"}
        isSubmitting={isSubmitting}
        onClose={() => setPendingAction(null)}
        onConfirm={handleAction}
        open={Boolean(pendingAction)}
      />
    </div>
  );
}
