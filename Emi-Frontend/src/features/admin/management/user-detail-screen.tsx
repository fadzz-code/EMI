"use client";

import { type FormEvent, useState } from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowLeft } from "lucide-react";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ErrorState,
  FormField,
  Input,
  LoadingState,
  Modal,
  Select,
  Textarea,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";
import type { UserRole } from "@/lib/roles";

import { classService, userManagementService } from "./management-service";
import {
  activeClassLabel,
  classLabel,
  formatDateTime,
  roleLabel,
  statusTone,
  userStatusLabel,
} from "./management-utils";
import type { ManagedUser, UserPayload, UserStatus } from "./types";

type UserFormState = {
  full_name: string;
  email: string;
  phone: string;
};

function toForm(user: ManagedUser): UserFormState {
  return {
    full_name: user.full_name,
    email: user.email,
    phone: user.phone ?? "",
  };
}

function userPayload(form: UserFormState): UserPayload {
  return {
    full_name: form.full_name.trim(),
    email: form.email.trim(),
    phone: form.phone.trim() || null,
  };
}

function DetailItem({ label, value }: { label: string; value?: React.ReactNode }) {
  return (
    <div className="h-full rounded-xl border-2 border-border bg-surface-muted p-4">
      <p className="text-xs font-black uppercase text-muted">{label}</p>
      <div className="mt-2 text-sm font-bold text-ink">{value ?? "-"}</div>
    </div>
  );
}

export function UserDetailScreen({ userId }: { userId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [editOpen, setEditOpen] = useState(false);
  const [statusOpen, setStatusOpen] = useState(false);
  const [assignOpen, setAssignOpen] = useState(false);
  const [resetPasswordOpen, setResetPasswordOpen] = useState(false);
  const [permanentDeleteOpen, setPermanentDeleteOpen] = useState(false);
  const [deleteConfirmation, setDeleteConfirmation] = useState("");
  const [form, setForm] = useState<UserFormState | null>(null);
  const [targetStatus, setTargetStatus] = useState<Extract<UserStatus, "approved" | "inactive">>("approved");
  const [statusReason, setStatusReason] = useState("");
  const [selectedClassId, setSelectedClassId] = useState("");
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const userQuery = useQuery({
    queryKey: ["admin", "users", userId],
    queryFn: () => userManagementService.detail(token ?? "", userId),
    enabled: Boolean(token && userId),
  });

  const classesQuery = useQuery({
    queryKey: ["admin", "classes", "active-options"],
    queryFn: () =>
      classService.list(token ?? "", {
        status: "active",
        per_page: 100,
      }),
    enabled: Boolean(token),
  });

  const updateMutation = useMutation({
    mutationFn: (payload: UserPayload) => userManagementService.update(token ?? "", userId, payload),
    onSuccess: async (user) => {
      setSuccessMessage(`Data ${user.full_name} berhasil diperbarui.`);
      setEditOpen(false);
      await queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
    },
  });

  const statusMutation = useMutation({
    mutationFn: ({
      status,
      reason,
    }: {
      status: Extract<UserStatus, "approved" | "inactive">;
      reason?: string;
    }) => userManagementService.updateStatus(token ?? "", userId, status, reason),
    onSuccess: async (user) => {
      setSuccessMessage(`Status ${user.full_name} berhasil diperbarui.`);
      setStatusOpen(false);
      setStatusReason("");
      await queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
    },
  });

  const resetPasswordMutation = useMutation({
    mutationFn: (payload: { password: string; password_confirmation: string }) =>
      userManagementService.forcePasswordReset(token ?? "", userId, payload),
    onSuccess: async (user) => {
      setSuccessMessage(`Password ${user.full_name} berhasil direset. Pengguna wajib mengganti password saat login berikutnya.`);
      setResetPasswordOpen(false);
      await queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
    },
  });

  const permanentDeleteMutation = useMutation({
    mutationFn: () => userManagementService.permanentlyDelete(token ?? "", userId, deleteConfirmation),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      window.location.assign("/admin/users");
    },
  });

  const assignMutation = useMutation<unknown, Error, { role: UserRole; classId: string }>({
    mutationFn: ({ role, classId }: { role: UserRole; classId: string }) => {
      if (role === "teacher") {
        return classService.assignTeacher(token ?? "", classId, userId);
      }

      return classService.assignStudent(token ?? "", classId, userId);
    },
    onSuccess: async () => {
      setSuccessMessage("Penempatan kelas berhasil diperbarui.");
      setAssignOpen(false);
      setSelectedClassId("");
      await queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
      await queryClient.invalidateQueries({ queryKey: ["admin", "classes"] });
    },
  });

  const user = userQuery.data;
  const classes = classesQuery.data?.items ?? [];
  const actionError = updateMutation.error ?? statusMutation.error ?? assignMutation.error ?? resetPasswordMutation.error ?? permanentDeleteMutation.error;
  const canAssign = user?.role === "teacher" || user?.role === "student";

  function openEdit() {
    if (!user) {
      return;
    }

    setForm(toForm(user));
    setEditOpen(true);
  }

  function submitUser(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!form) {
      return;
    }

    updateMutation.mutate(userPayload(form));
  }

  function submitStatus(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    statusMutation.mutate({
      status: targetStatus,
      reason: targetStatus === "inactive" ? statusReason.trim() : undefined,
    });
  }

  function submitResetPassword(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    resetPasswordMutation.mutate({
      password: String(data.get("password") ?? ""),
      password_confirmation: String(data.get("password_confirmation") ?? ""),
    });
  }

  return (
    <div className="grid gap-8">
      <Link
        className="w-fit rounded-lg border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink transition-colors hover:bg-primary hover:text-primary-foreground"
        href="/admin/users"
      >
        <ArrowLeft className="mr-2 inline size-4" strokeWidth={2.5} />
        Kembali ke Data Guru & Siswa
      </Link>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      {userQuery.isLoading ? <LoadingState title="Memuat detail pengguna" /> : null}
      {userQuery.isError ? (
        <ErrorState
          description={getFirstApiError(userQuery.error)}
          onRetry={() => void userQuery.refetch()}
          title="Gagal memuat pengguna"
        />
      ) : null}

      {user ? (
        <>
          <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <div className="flex flex-wrap gap-2">
                <Badge tone="neutral">{roleLabel(user.role)}</Badge>
                <Badge tone={statusTone(user.status)}>{userStatusLabel(user.status)}</Badge>
                {user.password_must_change ? (
                  <Badge tone="orange">Wajib ganti password</Badge>
                ) : null}
              </div>
              <h1 className="mt-2 text-3xl font-black text-ink">{user.full_name}</h1>
              <p className="mt-2 text-sm text-muted">{user.email}</p>
            </div>
            <div className="flex flex-col gap-2 sm:flex-row">
              <Button onClick={openEdit} variant="secondary">
                Edit Pengguna
              </Button>
              <Button onClick={() => setResetPasswordOpen(true)} variant="secondary">
                Reset Password
              </Button>
              <Button onClick={() => setStatusOpen(true)} variant="danger">
                Ubah Status
              </Button>
              {canAssign ? (
                <>
                  <Button onClick={() => setAssignOpen(true)}>
                    {user.role === "teacher" ? "Tetapkan Guru" : "Tempatkan Siswa"}
                  </Button>
                  <Button onClick={() => setPermanentDeleteOpen(true)} variant="danger">
                    Hapus Permanen
                  </Button>
                </>
              ) : null}
            </div>
          </header>

          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <DetailItem label="Nama" value={user.full_name} />
            <DetailItem label="Email" value={user.email} />
            <DetailItem label="Telepon" value={user.phone} />
            <DetailItem label="Role" value={roleLabel(user.role)} />
            <DetailItem label="Status" value={userStatusLabel(user.status)} />
            <DetailItem label="Sekolah Aktif" value={user.active_school?.name} />
            <DetailItem label="Kelas Aktif" value={activeClassLabel(user)} />
            <DetailItem label="Dibuat" value={formatDateTime(user.created_at)} />
            <DetailItem label="Disetujui Pada" value={formatDateTime(user.approved_at)} />
            <DetailItem label="Terakhir Diubah" value={formatDateTime(user.updated_at)} />
          </div>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Konteks Kelas</h2>
            </CardHeader>
            <CardContent>
              {user.role === "teacher" ? (
                <div className="grid gap-3">
                  <p className="text-sm text-muted">
                    Guru memakai assignment aktif. Gunakan aksi tetapkan guru untuk memindahkan
                    assignment ke kelas lain.
                  </p>
                  <DetailItem
                    label="Penempatan Aktif"
                    value={user.active_assignment ? classLabel(user.active_class) : "-"}
                  />
                </div>
              ) : user.role === "student" ? (
                <div className="grid gap-3">
                  <p className="text-sm text-muted">
                    Siswa memakai membership aktif. Gunakan aksi tempatkan siswa untuk memindahkan
                    membership ke kelas lain.
                  </p>
                  <DetailItem
                    label="Membership Aktif"
                    value={user.active_membership ? classLabel(user.active_class) : "-"}
                  />
                </div>
              ) : (
                <Alert tone="info">
                  Penempatan kelas hanya tersedia untuk Guru dan Siswa.
                </Alert>
              )}
            </CardContent>
          </Card>
        </>
      ) : null}

      <Modal onClose={() => setEditOpen(false)} open={editOpen} title="Edit Pengguna">
        {form ? (
          <form className="grid gap-4" onSubmit={submitUser}>
            <FormField label="Nama lengkap">
              <Input
                onChange={(event) => setForm((current) => current && { ...current, full_name: event.target.value })}
                required
                value={form.full_name}
              />
            </FormField>
            <FormField label="Email">
              <Input
                onChange={(event) => setForm((current) => current && { ...current, email: event.target.value })}
                required
                type="email"
                value={form.email}
              />
            </FormField>
            <FormField label="Telepon">
              <Input
                onChange={(event) => setForm((current) => current && { ...current, phone: event.target.value })}
                value={form.phone}
              />
            </FormField>
            <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
              <Button onClick={() => setEditOpen(false)} variant="ghost">
                Batal
              </Button>
              <Button disabled={updateMutation.isPending} type="submit" variant="secondary">
                Simpan
              </Button>
            </div>
          </form>
        ) : null}
      </Modal>

      <Modal onClose={() => setStatusOpen(false)} open={statusOpen} title="Update Status Pengguna">
        <form className="grid gap-4" onSubmit={submitStatus}>
          <Alert tone="warning">
            Perubahan status hanya mendukung status disetujui atau nonaktif. Alasan wajib
            diisi saat menonaktifkan akun.
          </Alert>
          <FormField label="Status baru">
            <Select
              onChange={(event) =>
                setTargetStatus(event.target.value as Extract<UserStatus, "approved" | "inactive">)
              }
              value={targetStatus}
            >
              <option value="approved">Disetujui</option>
              <option value="inactive">Nonaktif</option>
            </Select>
          </FormField>
          {targetStatus === "inactive" ? (
            <FormField label="Alasan nonaktif">
              <Textarea
                onChange={(event) => setStatusReason(event.target.value)}
                required
                value={statusReason}
              />
            </FormField>
          ) : null}
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={() => setStatusOpen(false)} variant="ghost">
              Batal
            </Button>
            <Button
              disabled={statusMutation.isPending || (targetStatus === "inactive" && !statusReason.trim())}
              type="submit"
              variant="danger"
            >
              Simpan Status
            </Button>
          </div>
        </form>
      </Modal>

      <Modal onClose={() => setResetPasswordOpen(false)} open={resetPasswordOpen} title="Reset Password Pengguna">
        <form className="grid gap-4" onSubmit={submitResetPassword}>
          <Alert tone="warning">
            Admin dapat mereset password kapan saja tanpa persetujuan siapa pun. Sampaikan password baru ini
            langsung ke pengguna. Pengguna akan diwajibkan mengganti password saat login berikutnya.
          </Alert>
          <FormField label="Password baru">
            <Input autoFocus minLength={8} name="password" required type="text" />
          </FormField>
          <FormField label="Konfirmasi password baru">
            <Input minLength={8} name="password_confirmation" required type="text" />
          </FormField>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={() => setResetPasswordOpen(false)} type="button" variant="ghost">
              Batal
            </Button>
            <Button disabled={resetPasswordMutation.isPending} type="submit" variant="secondary">
              {resetPasswordMutation.isPending ? "Menyimpan..." : "Reset Password"}
            </Button>
          </div>
        </form>
      </Modal>

      <Modal
        onClose={() => {
          setPermanentDeleteOpen(false);
          setDeleteConfirmation("");
        }}
        open={permanentDeleteOpen}
        title="Hapus Akun Permanen"
      >
        <div className="grid gap-4">
          <Alert tone="error">
            Akun, penempatan kelas, dan data pribadi akan dihapus permanen. Konten pembelajaran milik Guru dipindahkan ke Admin pelaksana. Tindakan ini tidak dapat dibatalkan.
          </Alert>
          <FormField label='Ketik "hapus permanen" untuk konfirmasi'>
            <Input
              autoComplete="off"
              onChange={(event) => setDeleteConfirmation(event.target.value)}
              value={deleteConfirmation}
            />
          </FormField>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={() => setPermanentDeleteOpen(false)} variant="ghost">Batal</Button>
            <Button
              disabled={deleteConfirmation !== "hapus permanen" || permanentDeleteMutation.isPending}
              onClick={() => permanentDeleteMutation.mutate()}
              variant="danger"
            >
              {permanentDeleteMutation.isPending ? "Menghapus..." : "Hapus Permanen"}
            </Button>
          </div>
        </div>
      </Modal>

      <Modal
        onClose={() => setAssignOpen(false)}
        open={assignOpen}
        title={user?.role === "teacher" ? "Tetapkan Guru ke Kelas" : "Tempatkan Siswa ke Kelas"}
      >
        {user && canAssign ? (
          <div className="grid gap-4">
            <Alert tone="info">
              Sistem akan menjaga aturan satu guru atau siswa aktif pada kelas yang dipilih.
            </Alert>
            <FormField label="Kelas aktif">
              <Select
                onChange={(event) => setSelectedClassId(event.target.value)}
                value={selectedClassId}
              >
                <option value="">Pilih kelas</option>
                {classes.map((schoolClass) => (
                  <option key={schoolClass.id} value={schoolClass.id}>
                    {schoolClass.school?.name ?? "-"} - {classLabel(schoolClass)}
                  </option>
                ))}
              </Select>
            </FormField>
            <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
              <Button onClick={() => setAssignOpen(false)} variant="ghost">
                Batal
              </Button>
              <Button
                disabled={!selectedClassId || assignMutation.isPending}
                onClick={() => assignMutation.mutate({ role: user.role, classId: selectedClassId })}
              >
                Simpan Penempatan
              </Button>
            </div>
          </div>
        ) : null}
      </Modal>
    </div>
  );
}
