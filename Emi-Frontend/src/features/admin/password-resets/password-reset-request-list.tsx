"use client";

import { type FormEvent, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, X } from "lucide-react";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  EmptyState,
  ErrorState,
  FilterPanel,
  FormField,
  Input,
  LoadingState,
  Modal,
  Pagination,
  Select,
  Table,
  TableCell,
  TableHeader,
  Textarea,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { adminPasswordResetService, teacherPasswordResetService } from "./password-reset-service";
import type { PasswordResetRequest, PasswordResetRequestStatus } from "./types";

const serviceByScope = {
  admin: adminPasswordResetService,
  teacher: teacherPasswordResetService,
} as const;

function statusLabel(status: PasswordResetRequestStatus) {
  if (status === "approved") return "Disetujui";
  if (status === "rejected") return "Ditolak";
  return "Menunggu";
}

function statusTone(status: PasswordResetRequestStatus): "blue" | "orange" | "neutral" {
  if (status === "approved") return "blue";
  if (status === "rejected") return "orange";
  return "neutral";
}

function formatDateTime(value?: string | null) {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "-";
  return new Intl.DateTimeFormat("id-ID", { dateStyle: "medium", timeStyle: "short" }).format(date);
}

export function PasswordResetRequestList({
  scope,
  queryKeyPrefix,
  title,
  description,
}: {
  scope: keyof typeof serviceByScope;
  queryKeyPrefix: string;
  title: string;
  description: string;
}) {
  const service = serviceByScope[scope];
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const [searchInput, setSearchInput] = useState("");
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<PasswordResetRequestStatus | "">("pending");
  const [approveTarget, setApproveTarget] = useState<PasswordResetRequest | null>(null);
  const [rejectTarget, setRejectTarget] = useState<PasswordResetRequest | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const filters = useMemo(
    () => ({
      status: status || undefined,
      search,
      page,
      per_page: 15,
    }),
    [page, search, status],
  );

  const requestsQuery = useQuery({
    queryKey: [queryKeyPrefix, "password-reset-requests", filters],
    queryFn: () => service.list(token ?? "", filters),
    enabled: Boolean(token),
  });

  const approveMutation = useMutation({
    mutationFn: (payload: { password: string; password_confirmation: string; review_note?: string }) =>
      service.approve(token ?? "", approveTarget?.id ?? "", payload),
    onSuccess: (request) => {
      setSuccessMessage(`Password ${request.user?.full_name ?? "akun"} berhasil direset. Pengguna wajib mengganti password saat login berikutnya.`);
      setApproveTarget(null);
      void queryClient.invalidateQueries({ queryKey: [queryKeyPrefix, "password-reset-requests"] });
    },
  });

  const rejectMutation = useMutation({
    mutationFn: (reviewNote: string) => service.reject(token ?? "", rejectTarget?.id ?? "", reviewNote),
    onSuccess: (request) => {
      setSuccessMessage(`Permintaan reset password ${request.user?.full_name ?? "akun"} ditolak.`);
      setRejectTarget(null);
      void queryClient.invalidateQueries({ queryKey: [queryKeyPrefix, "password-reset-requests"] });
    },
  });

  function applySearch() {
    setPage(1);
    setSearch(searchInput.trim());
  }

  function submitApprove(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    approveMutation.mutate({
      password: String(data.get("password") ?? ""),
      password_confirmation: String(data.get("password_confirmation") ?? ""),
      review_note: String(data.get("review_note") ?? "").trim() || undefined,
    });
  }

  function submitReject(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    rejectMutation.mutate(String(data.get("review_note") ?? "").trim());
  }

  const rows = requestsQuery.data?.items ?? [];
  const meta = requestsQuery.data?.meta;
  const actionError = approveMutation.error ?? rejectMutation.error;

  return (
    <div className="grid gap-6">
      <header>
        <Badge tone="blue">Persetujuan</Badge>
        <h1 className="mt-2 text-3xl font-black text-ink">{title}</h1>
        <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">{description}</p>
      </header>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      <FilterPanel className="md:grid-cols-3">
        <label className="grid gap-2 text-sm font-bold text-ink md:col-span-2">
          <span>Cari nama atau email</span>
          <Input
            onChange={(event) => setSearchInput(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === "Enter") applySearch();
            }}
            placeholder="Cari akun"
            value={searchInput}
          />
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Status</span>
          <Select
            onChange={(event) => {
              setStatus(event.target.value as PasswordResetRequestStatus | "");
              setPage(1);
            }}
            value={status}
          >
            <option value="pending">Menunggu</option>
            <option value="approved">Disetujui</option>
            <option value="rejected">Ditolak</option>
            <option value="">Semua</option>
          </Select>
        </label>
        <div className="flex items-end md:col-span-3">
          <Button className="w-full md:w-fit" onClick={applySearch} variant="secondary">
            Terapkan Filter
          </Button>
        </div>
      </FilterPanel>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Daftar Permintaan Reset Password</h2>
        </CardHeader>
        <CardContent>
          {requestsQuery.isLoading ? <LoadingState title="Memuat permintaan" /> : null}
          {requestsQuery.isError ? (
            <ErrorState
              description={getFirstApiError(requestsQuery.error)}
              onRetry={() => void requestsQuery.refetch()}
              title="Gagal memuat permintaan"
            />
          ) : null}
          {!requestsQuery.isLoading && !requestsQuery.isError ? (
            rows.length === 0 ? (
              <EmptyState
                description="Tidak ada permintaan reset password sesuai filter saat ini."
                title="Belum ada permintaan"
              />
            ) : (
              <div className="grid gap-4">
                <Table>
                  <TableHeader>
                    <tr>
                      <th className="px-4 py-3">Nama</th>
                      <th className="px-4 py-3">Email</th>
                      <th className="px-4 py-3">Role</th>
                      <th className="px-4 py-3">Diajukan</th>
                      <th className="px-4 py-3">Status</th>
                      <th className="px-4 py-3">Aksi</th>
                    </tr>
                  </TableHeader>
                  <tbody>
                    {rows.map((request) => (
                      <tr key={request.id}>
                        <TableCell className="font-black text-ink">{request.user?.full_name ?? "-"}</TableCell>
                        <TableCell>{request.user?.email ?? "-"}</TableCell>
                        <TableCell>
                          <Badge tone="neutral">{request.user?.role === "teacher" ? "Guru" : "Siswa"}</Badge>
                        </TableCell>
                        <TableCell>{formatDateTime(request.created_at)}</TableCell>
                        <TableCell>
                          <Badge tone={statusTone(request.status)}>{statusLabel(request.status)}</Badge>
                        </TableCell>
                        <TableCell>
                          {request.status === "pending" ? (
                            <div className="flex flex-wrap gap-2">
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                onClick={() => setApproveTarget(request)}
                                variant="secondary"
                              >
                                <Check aria-hidden="true" className="mr-1 size-4" />
                                Setujui
                              </Button>
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                onClick={() => setRejectTarget(request)}
                                variant="danger"
                              >
                                <X aria-hidden="true" className="mr-1 size-4" />
                                Tolak
                              </Button>
                            </div>
                          ) : (
                            <span className="text-xs font-semibold text-muted">
                              {request.reviewed_by?.full_name ? `Oleh ${request.reviewed_by.full_name}` : "-"}
                            </span>
                          )}
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
        onClose={() => setApproveTarget(null)}
        open={Boolean(approveTarget)}
        title="Setujui Reset Password"
      >
        <form className="grid gap-4" onSubmit={submitApprove}>
          <p className="text-sm text-muted">
            Tentukan password baru untuk <strong>{approveTarget?.user?.full_name}</strong>. Sampaikan password ini
            langsung ke yang bersangkutan. Pengguna akan diwajibkan mengganti password saat login berikutnya.
          </p>
          <FormField label="Password baru">
            <Input autoFocus minLength={8} name="password" required type="text" />
          </FormField>
          <FormField label="Konfirmasi password baru">
            <Input minLength={8} name="password_confirmation" required type="text" />
          </FormField>
          <FormField label="Catatan (opsional)">
            <Textarea name="review_note" />
          </FormField>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={() => setApproveTarget(null)} type="button" variant="ghost">
              Batal
            </Button>
            <Button disabled={approveMutation.isPending} type="submit">
              {approveMutation.isPending ? "Menyimpan..." : "Setujui & Reset Password"}
            </Button>
          </div>
        </form>
      </Modal>

      <Modal
        onClose={() => setRejectTarget(null)}
        open={Boolean(rejectTarget)}
        title="Tolak Permintaan Reset Password"
      >
        <form className="grid gap-4" onSubmit={submitReject}>
          <p className="text-sm text-muted">
            Jelaskan alasan penolakan permintaan reset password untuk{" "}
            <strong>{rejectTarget?.user?.full_name}</strong>.
          </p>
          <FormField label="Catatan (wajib)">
            <Textarea name="review_note" required />
          </FormField>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={() => setRejectTarget(null)} type="button" variant="ghost">
              Batal
            </Button>
            <Button disabled={rejectMutation.isPending} type="submit" variant="danger">
              {rejectMutation.isPending ? "Menyimpan..." : "Tolak Permintaan"}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
