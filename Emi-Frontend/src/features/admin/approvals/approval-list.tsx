"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, Eye, Search, X } from "lucide-react";

import {
  Alert,
  Button,
  Card,
  CardContent,
  EmptyState,
  ErrorState,
  FilterPanel,
  Input,
  LoadingState,
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
  ApprovalAvatar,
  ApprovalHero,
  ApprovalInfoBox,
  ApprovalPageShell,
  ApprovalRoleBadge,
  ApprovalStatusBadge,
} from "./approval-visuals";
import { formatDateTime } from "./approval-utils";
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

  function updateRole(value: RegistrationRequestedRole | "") {
    setRequestedRole(value);
    setPage(1);
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
  const pendingCount = meta?.total ?? rows.length;

  return (
    <ApprovalPageShell>
      <ApprovalHero
        action={
          <div className="rounded-[8px] border-2 border-border bg-primary px-5 py-3 text-sm font-black text-primary-foreground shadow-emi">
            {pendingCount} request menunggu
          </div>
        }
        description="Periksa data pendaftaran dan setujui akun siswa maupun guru."
        title="Persetujuan Akun"
      />

      <ApprovalInfoBox>
        Siswa dan guru baru dapat masuk ke sistem setelah akun disetujui admin.
      </ApprovalInfoBox>

      <FilterPanel className="rounded-[12px] border-2 border-border bg-surface p-5 shadow-emi md:grid-cols-3">
        <div className="flex flex-wrap gap-2 md:col-span-3">
          {[
            { label: "Semua", value: "" },
            { label: "Siswa", value: "student" },
            { label: "Guru", value: "teacher" },
          ].map((item) => (
            <button
              className={[
                "rounded-full border-2 border-border px-4 py-2 text-xs font-black shadow-emi transition hover:-translate-y-0.5",
                requestedRole === item.value
                  ? "bg-primary text-primary-foreground"
                  : "bg-surface text-muted",
              ].join(" ")}
              key={item.label}
              onClick={() => updateRole(item.value as RegistrationRequestedRole | "")}
              type="button"
            >
              {item.label}
            </button>
          ))}
        </div>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Cari nama atau email</span>
          <Input
            className="min-h-12 rounded-[8px] border-2 border-border bg-surface shadow-emi focus:ring-primary"
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
            className="min-h-12 rounded-[8px] border-2 border-border bg-surface shadow-emi focus:ring-primary"
            onChange={(event) => updateRole(event.target.value as RegistrationRequestedRole | "")}
            value={requestedRole}
          >
            <option value="">Semua role</option>
            <option value="teacher">Guru</option>
            <option value="student">Siswa</option>
          </Select>
        </label>
        <div className="flex items-end">
          <Button
            className="w-full border-2 border-border bg-[var(--color-primary-muted)] text-ink shadow-emi hover:bg-primary/20"
            onClick={applySearch}
            variant="secondary"
          >
            <Search aria-hidden="true" className="mr-2 size-4" />
            Terapkan Filter
          </Button>
        </div>
      </FilterPanel>

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
            description="Tidak ada akun guru atau siswa yang menunggu persetujuan untuk filter saat ini."
            title="Belum ada permintaan pending"
          />
        ) : (
          <Card className="overflow-hidden rounded-[12px] border-2 border-border bg-surface shadow-emi">
            <div className="h-4 border-b-2 border-border bg-primary" />
            <CardContent className="p-0">
              <Table>
                <TableHeader className="bg-surface-muted">
                  <tr>
                    <th className="px-4 py-3">Nama Lengkap</th>
                    <th className="px-4 py-3">Peran</th>
                    <th className="px-4 py-3">Email</th>
                    <th className="px-4 py-3">Asal Sekolah</th>
                    <th className="px-4 py-3">Kelas</th>
                    <th className="px-4 py-3">Status</th>
                    <th className="px-4 py-3">Tanggal Daftar</th>
                    <th className="px-4 py-3">Aksi</th>
                  </tr>
                </TableHeader>
                <tbody>
                  {rows.map((request) => (
                    <tr key={request.id}>
                      <TableCell className="border-border font-black text-ink">
                        <div className="flex items-center gap-3">
                          <ApprovalAvatar
                            name={request.user?.full_name}
                            role={request.requested_role}
                          />
                          <span>{request.user?.full_name ?? "-"}</span>
                        </div>
                      </TableCell>
                      <TableCell>
                        <ApprovalRoleBadge role={request.requested_role} />
                      </TableCell>
                      <TableCell className="text-muted">
                        {request.user?.email ?? "-"}
                      </TableCell>
                      <TableCell className="font-semibold text-ink">
                        {request.school?.name ?? "-"}
                      </TableCell>
                      <TableCell className="text-muted">
                        {request.school_class?.name ?? "-"}
                      </TableCell>
                      <TableCell>
                        <ApprovalStatusBadge status={request.status} />
                      </TableCell>
                      <TableCell>{formatDateTime(request.created_at)}</TableCell>
                      <TableCell>
                        <div className="flex flex-wrap gap-2">
                          <Link
                             className="inline-flex min-h-10 items-center rounded-[6px] border-2 border-border bg-surface px-3 py-2 text-xs font-black text-muted shadow-emi hover:bg-surface-muted"
                            href={`/admin/approvals/${request.id}`}
                          >
                            <Eye aria-hidden="true" className="mr-1 size-4" />
                            Detail
                          </Link>
                          <Button
                             className="min-h-10 rounded-[6px] border-2 border-border bg-success px-3 py-2 text-xs text-success-foreground shadow-emi hover:bg-success/80"
                            onClick={() => setPendingAction({ action: "approve", request })}
                            variant="secondary"
                          >
                            <Check aria-hidden="true" className="mr-1 size-4" />
                            Setujui
                          </Button>
                          <Button
                             className="min-h-10 rounded-[6px] border-2 border-border bg-danger-muted px-3 py-2 text-xs text-danger shadow-emi hover:bg-danger/20"
                            onClick={() => setPendingAction({ action: "reject", request })}
                            variant="danger"
                          >
                            <X aria-hidden="true" className="mr-1 size-4" />
                            Tolak
                          </Button>
                        </div>
                      </TableCell>
                    </tr>
                  ))}
                </tbody>
              </Table>
              <div className="border-t-2 border-border bg-surface-muted p-4">
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
    </ApprovalPageShell>
  );
}
