"use client";

import { type FormEvent, useMemo, useState } from "react";
import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { School as SchoolIcon, UsersRound } from "lucide-react";

import {
  Alert,
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  ConfirmDialog,
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

import { classService, schoolService } from "./management-service";
import {
  entityStatusLabel,
  normalizeNullable,
  statusTone,
} from "./management-utils";
import type { ClassPayload, EntityStatus, School, SchoolClass, SchoolPayload } from "./types";

type SchoolFormState = {
  name: string;
  address: string;
  phone: string;
  status: EntityStatus;
};

type ClassFormState = {
  school_id: string;
  name: string;
  grade_level: string;
  academic_year: string;
  status: EntityStatus;
};

const defaultSchoolForm: SchoolFormState = {
  name: "",
  address: "",
  phone: "",
  status: "active",
};

const defaultClassForm: ClassFormState = {
  school_id: "",
  name: "",
  grade_level: "",
  academic_year: "",
  status: "active",
};

function toSchoolForm(school?: School | null): SchoolFormState {
  return school
    ? {
        name: school.name,
        address: school.address ?? "",
        phone: school.phone ?? "",
        status: school.status,
      }
    : defaultSchoolForm;
}

function toClassForm(schoolClass?: SchoolClass | null): ClassFormState {
  return schoolClass
    ? {
        school_id: schoolClass.school_id,
        name: schoolClass.name,
        grade_level: schoolClass.grade_level ?? "",
        academic_year: schoolClass.academic_year,
        status: schoolClass.status,
      }
    : defaultClassForm;
}

function schoolPayload(form: SchoolFormState): SchoolPayload {
  return {
    name: form.name.trim(),
    address: normalizeNullable(form.address),
    phone: normalizeNullable(form.phone),
    status: form.status,
  };
}

function classPayload(form: ClassFormState): ClassPayload {
  return {
    school_id: form.school_id,
    name: form.name.trim(),
    grade_level: normalizeNullable(form.grade_level),
    academic_year: form.academic_year.trim(),
    status: form.status,
  };
}

export function SchoolsClassesScreen() {
  const { token } = useAuth();
  const [activeTable, setActiveTable] = useState<"schools" | "classes">("schools");
  const queryClient = useQueryClient();
  const [schoolPage, setSchoolPage] = useState(1);
  const [classPage, setClassPage] = useState(1);
  const [schoolSearchInput, setSchoolSearchInput] = useState("");
  const [schoolSearch, setSchoolSearch] = useState("");
  const [classSearchInput, setClassSearchInput] = useState("");
  const [classSearch, setClassSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<EntityStatus | "">("");
  const [classSchoolFilter, setClassSchoolFilter] = useState("");
  const [editingSchool, setEditingSchool] = useState<School | null>(null);
  const [editingClass, setEditingClass] = useState<SchoolClass | null>(null);
  const [schoolModalOpen, setSchoolModalOpen] = useState(false);
  const [classModalOpen, setClassModalOpen] = useState(false);
  const [schoolForm, setSchoolForm] = useState<SchoolFormState>(defaultSchoolForm);
  const [classForm, setClassForm] = useState<ClassFormState>(defaultClassForm);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [deleteSchoolTarget, setDeleteSchoolTarget] = useState<School | null>(null);
  const [deleteClassTarget, setDeleteClassTarget] = useState<SchoolClass | null>(null);

  const schoolFilters = useMemo(
    () => ({
      search: schoolSearch,
      status: statusFilter,
      page: schoolPage,
      per_page: 10,
    }),
    [schoolPage, schoolSearch, statusFilter],
  );

  const classFilters = useMemo(
    () => ({
      search: classSearch,
      status: statusFilter,
      school_id: classSchoolFilter,
      page: classPage,
      per_page: 10,
    }),
    [classPage, classSchoolFilter, classSearch, statusFilter],
  );

  const schoolsQuery = useQuery({
    queryKey: ["admin", "schools", schoolFilters],
    queryFn: () => schoolService.list(token ?? "", schoolFilters),
    enabled: Boolean(token),
  });

  const classesQuery = useQuery({
    queryKey: ["admin", "classes", classFilters],
    queryFn: () => classService.list(token ?? "", classFilters),
    enabled: Boolean(token),
  });

  const createSchoolMutation = useMutation({
    mutationFn: (payload: SchoolPayload) => schoolService.create(token ?? "", payload),
    onSuccess: async (school) => {
      setSuccessMessage(`Sekolah ${school.name} berhasil dibuat.`);
      closeSchoolModal();
      await queryClient.invalidateQueries({ queryKey: ["admin", "schools"] });
    },
  });

  const updateSchoolMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: SchoolPayload }) =>
      schoolService.update(token ?? "", id, payload),
    onSuccess: async (school) => {
      setSuccessMessage(`Sekolah ${school.name} berhasil diperbarui.`);
      closeSchoolModal();
      await queryClient.invalidateQueries({ queryKey: ["admin", "schools"] });
    },
  });

  const deactivateSchoolMutation = useMutation({
    mutationFn: (id: string) => schoolService.deactivate(token ?? "", id),
    onSuccess: async (school) => {
      setSuccessMessage(`Sekolah ${school.name} berhasil dinonaktifkan.`);
      await queryClient.invalidateQueries({ queryKey: ["admin", "schools"] });
    },
  });

  const forceDeleteSchoolMutation = useMutation({
    mutationFn: (id: string) => schoolService.forceDelete(token ?? "", id),
    onSuccess: async () => {
      setSuccessMessage(`Sekolah ${deleteSchoolTarget?.name ?? ""} berhasil dihapus permanen.`);
      setDeleteSchoolTarget(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "schools"] });
    },
  });

  const createClassMutation = useMutation({
    mutationFn: (payload: ClassPayload) => classService.create(token ?? "", payload),
    onSuccess: async (schoolClass) => {
      setSuccessMessage(`Kelas ${schoolClass.name} berhasil dibuat.`);
      closeClassModal();
      await queryClient.invalidateQueries({ queryKey: ["admin", "classes"] });
    },
  });

  const updateClassMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: ClassPayload }) =>
      classService.update(token ?? "", id, payload),
    onSuccess: async (schoolClass) => {
      setSuccessMessage(`Kelas ${schoolClass.name} berhasil diperbarui.`);
      closeClassModal();
      await queryClient.invalidateQueries({ queryKey: ["admin", "classes"] });
    },
  });

  const deactivateClassMutation = useMutation({
    mutationFn: (id: string) => classService.deactivate(token ?? "", id),
    onSuccess: async (schoolClass) => {
      setSuccessMessage(`Kelas ${schoolClass.name} berhasil dinonaktifkan.`);
      await queryClient.invalidateQueries({ queryKey: ["admin", "classes"] });
    },
  });

  const forceDeleteClassMutation = useMutation({
    mutationFn: (id: string) => classService.forceDelete(token ?? "", id),
    onSuccess: async () => {
      setSuccessMessage(`Kelas ${deleteClassTarget?.name ?? ""} berhasil dihapus permanen.`);
      setDeleteClassTarget(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "classes"] });
    },
  });

  const actionError =
    createSchoolMutation.error ??
    updateSchoolMutation.error ??
    deactivateSchoolMutation.error ??
    forceDeleteSchoolMutation.error ??
    createClassMutation.error ??
    updateClassMutation.error ??
    deactivateClassMutation.error ??
    forceDeleteClassMutation.error;

  function openCreateSchool() {
    setEditingSchool(null);
    setSchoolForm(defaultSchoolForm);
    setSchoolModalOpen(true);
  }

  function openEditSchool(school: School) {
    setEditingSchool(school);
    setSchoolForm(toSchoolForm(school));
    setSchoolModalOpen(true);
  }

  function closeSchoolModal() {
    setSchoolModalOpen(false);
    setEditingSchool(null);
    setSchoolForm(defaultSchoolForm);
  }

  function openCreateClass() {
    setEditingClass(null);
    setClassForm({
      ...defaultClassForm,
      school_id: classSchoolFilter,
    });
    setClassModalOpen(true);
  }

  function openEditClass(schoolClass: SchoolClass) {
    setEditingClass(schoolClass);
    setClassForm(toClassForm(schoolClass));
    setClassModalOpen(true);
  }

  function closeClassModal() {
    setClassModalOpen(false);
    setEditingClass(null);
    setClassForm(defaultClassForm);
  }

  function submitSchool(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const payload = schoolPayload(schoolForm);

    if (editingSchool) {
      updateSchoolMutation.mutate({ id: editingSchool.id, payload });
      return;
    }

    createSchoolMutation.mutate(payload);
  }

  function submitClass(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const payload = classPayload(classForm);

    if (editingClass) {
      updateClassMutation.mutate({ id: editingClass.id, payload });
      return;
    }

    createClassMutation.mutate(payload);
  }

  const schools = schoolsQuery.data?.items ?? [];
  const classes = classesQuery.data?.items ?? [];
  const schoolMeta = schoolsQuery.data?.meta;
  const classMeta = classesQuery.data?.meta;

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="blue">Admin</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Sekolah & Kelas</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
            Kelola data master sekolah, kelas, guru pengampu, dan status aktif untuk
            kebutuhan registrasi serta pembelajaran.
          </p>
        </div>
        <Button onClick={activeTable === "schools" ? openCreateSchool : openCreateClass}>
          {activeTable === "schools" ? "Tambah Sekolah" : "Tambah Kelas"}
        </Button>
      </header>

      {successMessage ? <Alert tone="success">{successMessage}</Alert> : null}
      {actionError ? <Alert tone="error">{getFirstApiError(actionError)}</Alert> : null}

      <div className="grid grid-cols-2 gap-2 rounded-xl border-2 border-ink bg-white p-2 sm:w-fit">
        <Button onClick={() => setActiveTable("schools")} variant={activeTable === "schools" ? "primary" : "ghost"}>
          <SchoolIcon className="size-5" strokeWidth={2.5} />
          Sekolah
        </Button>
        <Button onClick={() => setActiveTable("classes")} variant={activeTable === "classes" ? "primary" : "ghost"}>
          <UsersRound className="size-5" strokeWidth={2.5} />
          Kelas
        </Button>
      </div>

      <FilterPanel className="md:grid-cols-3">
        {activeTable === "schools" ? (
          <label className="grid gap-2 text-sm font-bold text-ink">
            <span>Cari sekolah</span>
            <Input
              onChange={(event) => setSchoolSearchInput(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  setSchoolPage(1);
                  setSchoolSearch(schoolSearchInput.trim());
                }
              }}
              placeholder="Nama sekolah"
              value={schoolSearchInput}
            />
          </label>
        ) : (
          <label className="grid gap-2 text-sm font-bold text-ink">
            <span>Cari kelas</span>
            <Input
              onChange={(event) => setClassSearchInput(event.target.value)}
              onKeyDown={(event) => {
                if (event.key === "Enter") {
                  setClassPage(1);
                  setClassSearch(classSearchInput.trim());
                }
              }}
              placeholder="Nama kelas"
              value={classSearchInput}
            />
          </label>
        )}
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Status</span>
          <Select
            onChange={(event) => {
              setStatusFilter(event.target.value as EntityStatus | "");
              setSchoolPage(1);
              setClassPage(1);
            }}
            value={statusFilter}
          >
            <option value="">Semua status</option>
            <option value="active">Aktif</option>
            <option value="inactive">Nonaktif</option>
          </Select>
        </label>
        <div className="flex items-end">
          <Button
            className="w-full"
            onClick={() => {
              setSchoolPage(1);
              setClassPage(1);
              setSchoolSearch(schoolSearchInput.trim());
              setClassSearch(classSearchInput.trim());
            }}
            variant="secondary"
          >
            Terapkan
          </Button>
        </div>
      </FilterPanel>

<div className="grid gap-8">
        {activeTable === "schools" ? <Card>
          <CardHeader>
            <div className="flex items-center justify-between gap-3">
              <div>
                <h2 className="text-xl font-black text-ink">Daftar Sekolah</h2>
                <p className="mt-1 text-sm text-muted">
                  Data sekolah dipakai saat pendaftaran akun dan pengelompokan kelas.
                </p>
              </div>
              <Badge tone="neutral">{schoolMeta?.total ?? schools.length} data</Badge>
            </div>
          </CardHeader>
          <CardContent>
            {schoolsQuery.isLoading ? <LoadingState title="Memuat sekolah" /> : null}
            {schoolsQuery.isError ? (
              <ErrorState
                description={getFirstApiError(schoolsQuery.error)}
                onRetry={() => void schoolsQuery.refetch()}
                title="Gagal memuat sekolah"
              />
            ) : null}
            {!schoolsQuery.isLoading && !schoolsQuery.isError ? (
              schools.length === 0 ? (
                <EmptyState
                  description="Belum ada sekolah sesuai filter saat ini."
                  title="Sekolah kosong"
                />
              ) : (
                <div className="grid gap-4">
                  <Table>
                    <TableHeader>
                      <tr>
                        <th className="px-4 py-3">Nama</th>
                        <th className="px-4 py-3">Kontak</th>
                        <th className="px-4 py-3">Status</th>
                        <th className="px-4 py-3">Aksi</th>
                      </tr>
                    </TableHeader>
                    <tbody>
                      {schools.map((school) => (
                        <tr key={school.id}>
                          <TableCell>
                            <p className="font-black text-ink">{school.name}</p>
                            <p className="mt-1 text-xs text-muted">{school.address ?? "-"}</p>
                          </TableCell>
                          <TableCell>{school.phone ?? "-"}</TableCell>
                          <TableCell>
                            <Badge tone={statusTone(school.status)}>
                              {entityStatusLabel(school.status)}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <div className="flex flex-wrap gap-2">
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                onClick={() => {
                                  setClassSchoolFilter(school.id);
                                  setClassPage(1);
                                  setActiveTable("classes");
                                }}
                                variant="ghost"
                              >
                                Lihat Kelas
                              </Button>
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                onClick={() => openEditSchool(school)}
                                variant="secondary"
                              >
                                Edit
                              </Button>
                              {school.status === "active" ? (
                                <Button
                                  className="min-h-9 px-3 py-1 text-xs"
                                  disabled={deactivateSchoolMutation.isPending}
                                  onClick={() => deactivateSchoolMutation.mutate(school.id)}
                                  variant="danger"
                                >
                                  Nonaktifkan
                                </Button>
                              ) : (
                                <Button
                                  className="min-h-9 px-3 py-1 text-xs"
                                  onClick={() => setDeleteSchoolTarget(school)}
                                  variant="danger"
                                >
                                  Hapus
                                </Button>
                              )}
                            </div>
                          </TableCell>
                        </tr>
                      ))}
                    </tbody>
                  </Table>
                  <Pagination
                    onPageChange={setSchoolPage}
                    page={schoolMeta?.current_page ?? schoolPage}
                    totalPages={schoolMeta?.last_page ?? 1}
                  />
                </div>
              )
            ) : null}
          </CardContent>
        </Card> : null}

        {activeTable === "classes" ? <Card>
          <CardHeader>
            <div className="flex items-center justify-between gap-3">
              <div>
                <h2 className="text-xl font-black text-ink">Daftar Kelas</h2>
                <p className="mt-1 text-sm text-muted">
                  Pilih sekolah untuk melihat kelas terkait dan mengelola relasi gurunya.
                </p>
              </div>
              <Badge tone="neutral">{classMeta?.total ?? classes.length} data</Badge>
            </div>
          </CardHeader>
          <CardContent>
            <label className="mb-4 grid gap-2 text-sm font-bold text-ink">
              <span>Filter sekolah</span>
              <Select
                onChange={(event) => {
                  setClassSchoolFilter(event.target.value);
                  setClassPage(1);
                }}
                value={classSchoolFilter}
              >
                <option value="">Semua sekolah</option>
                {schools.map((school) => (
                  <option key={school.id} value={school.id}>
                    {school.name}
                  </option>
                ))}
              </Select>
            </label>

            {classesQuery.isLoading ? <LoadingState title="Memuat kelas" /> : null}
            {classesQuery.isError ? (
              <ErrorState
                description={getFirstApiError(classesQuery.error)}
                onRetry={() => void classesQuery.refetch()}
                title="Gagal memuat kelas"
              />
            ) : null}
            {!classesQuery.isLoading && !classesQuery.isError ? (
              classes.length === 0 ? (
                <EmptyState
                  description="Belum ada kelas sesuai filter saat ini."
                  title="Kelas kosong"
                />
              ) : (
                <div className="grid gap-4">
                  <Table>
                    <TableHeader>
                      <tr>
                        <th className="px-4 py-3">Kelas</th>
                        <th className="px-4 py-3">Sekolah</th>
                        <th className="px-4 py-3">Guru</th>
                        <th className="px-4 py-3">Status</th>
                        <th className="px-4 py-3">Aksi</th>
                      </tr>
                    </TableHeader>
                    <tbody>
                      {classes.map((schoolClass) => (
                        <tr key={schoolClass.id}>
                          <TableCell>
                            <p className="font-black text-ink">{schoolClass.name}</p>
                            <p className="mt-1 text-xs text-muted">
                              {schoolClass.grade_level ?? "-"} | {schoolClass.academic_year}
                            </p>
                          </TableCell>
                          <TableCell>{schoolClass.school?.name ?? "-"}</TableCell>
                          <TableCell>
                            {schoolClass.active_teacher_assignment?.teacher?.full_name ?? "-"}
                          </TableCell>
                          <TableCell>
                            <Badge tone={statusTone(schoolClass.status)}>
                              {entityStatusLabel(schoolClass.status)}
                            </Badge>
                          </TableCell>
                          <TableCell>
                            <div className="flex flex-wrap gap-2">
                              <Link
                                className="inline-flex min-h-9 items-center rounded-lg border-2 border-border bg-surface px-3 py-1 text-xs font-black text-ink transition-colors hover:bg-primary hover:text-primary-foreground"
                                href={`/admin/classes/${schoolClass.id}`}
                              >
                                Detail
                              </Link>
                              <Button
                                className="min-h-9 px-3 py-1 text-xs"
                                onClick={() => openEditClass(schoolClass)}
                                variant="secondary"
                              >
                                Edit
                              </Button>
                              {schoolClass.status === "active" ? (
                                <Button
                                  className="min-h-9 px-3 py-1 text-xs"
                                  disabled={deactivateClassMutation.isPending}
                                  onClick={() => deactivateClassMutation.mutate(schoolClass.id)}
                                  variant="danger"
                                >
                                  Nonaktifkan
                                </Button>
                              ) : (
                                <Button
                                  className="min-h-9 px-3 py-1 text-xs"
                                  onClick={() => setDeleteClassTarget(schoolClass)}
                                  variant="danger"
                                >
                                  Hapus
                                </Button>
                              )}
                            </div>
                          </TableCell>
                        </tr>
                      ))}
                    </tbody>
                  </Table>
                  <Pagination
                    onPageChange={setClassPage}
                    page={classMeta?.current_page ?? classPage}
                    totalPages={classMeta?.last_page ?? 1}
                  />
                </div>
              )
            ) : null}
          </CardContent>
        </Card> : null}
      </div>

      <Modal
        onClose={closeSchoolModal}
        open={schoolModalOpen}
        title={editingSchool ? "Edit Sekolah" : "Tambah Sekolah"}
      >
        <form className="grid gap-4" onSubmit={submitSchool}>
          <FormField label="Nama sekolah">
            <Input
              onChange={(event) => setSchoolForm((form) => ({ ...form, name: event.target.value }))}
              required
              value={schoolForm.name}
            />
          </FormField>
          <FormField label="Alamat">
            <Textarea
              onChange={(event) => setSchoolForm((form) => ({ ...form, address: event.target.value }))}
              value={schoolForm.address}
            />
          </FormField>
          <FormField label="Telepon">
            <Input
              onChange={(event) => setSchoolForm((form) => ({ ...form, phone: event.target.value }))}
              value={schoolForm.phone}
            />
          </FormField>
          <FormField label="Status">
            <Select
              onChange={(event) =>
                setSchoolForm((form) => ({ ...form, status: event.target.value as EntityStatus }))
              }
              value={schoolForm.status}
            >
              <option value="active">Aktif</option>
              <option value="inactive">Nonaktif</option>
            </Select>
          </FormField>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={closeSchoolModal} variant="ghost">
              Batal
            </Button>
            <Button
              disabled={createSchoolMutation.isPending || updateSchoolMutation.isPending}
              type="submit"
              variant="secondary"
            >
              Simpan Sekolah
            </Button>
          </div>
        </form>
      </Modal>

      <Modal
        onClose={closeClassModal}
        open={classModalOpen}
        title={editingClass ? "Edit Kelas" : "Tambah Kelas"}
      >
        <form className="grid gap-4" onSubmit={submitClass}>
          {!editingClass ? (
            <FormField label="Sekolah">
              <Select
                onChange={(event) => setClassForm((form) => ({ ...form, school_id: event.target.value }))}
                required
                value={classForm.school_id}
              >
                <option value="">Pilih sekolah</option>
                {schools.map((school) => (
                  <option key={school.id} value={school.id}>
                    {school.name}
                  </option>
                ))}
              </Select>
            </FormField>
          ) : null}
          <FormField label="Nama kelas">
            <Input
              onChange={(event) => setClassForm((form) => ({ ...form, name: event.target.value }))}
              required
              value={classForm.name}
            />
          </FormField>
          <FormField label="Tingkat / grade level">
            <Input
              onChange={(event) =>
                setClassForm((form) => ({ ...form, grade_level: event.target.value }))
              }
              placeholder="Contoh: 7"
              value={classForm.grade_level}
            />
          </FormField>
          <FormField label="Tahun ajaran">
            <Input
              onChange={(event) =>
                setClassForm((form) => ({ ...form, academic_year: event.target.value }))
              }
              placeholder="Contoh: 2026/2027"
              required
              value={classForm.academic_year}
            />
          </FormField>
          <FormField label="Status">
            <Select
              onChange={(event) =>
                setClassForm((form) => ({ ...form, status: event.target.value as EntityStatus }))
              }
              value={classForm.status}
            >
              <option value="active">Aktif</option>
              <option value="inactive">Nonaktif</option>
            </Select>
          </FormField>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={closeClassModal} variant="ghost">
              Batal
            </Button>
            <Button
              disabled={createClassMutation.isPending || updateClassMutation.isPending}
              type="submit"
            >
              Simpan Kelas
            </Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        confirmLabel={forceDeleteSchoolMutation.isPending ? "Menghapus..." : "Ya, Hapus Permanen"}
        description={
          deleteSchoolTarget
            ? `Sekolah "${deleteSchoolTarget.name}" beserta seluruh kelas, modul, kuis, dan data terkait di dalamnya akan dihapus permanen dan tidak dapat dikembalikan.`
            : ""
        }
        onCancel={() => setDeleteSchoolTarget(null)}
        onConfirm={() => {
          if (deleteSchoolTarget) forceDeleteSchoolMutation.mutate(deleteSchoolTarget.id);
        }}
        open={Boolean(deleteSchoolTarget)}
        title="Hapus sekolah secara permanen?"
      />

      <ConfirmDialog
        confirmLabel={forceDeleteClassMutation.isPending ? "Menghapus..." : "Ya, Hapus Permanen"}
        description={
          deleteClassTarget
            ? `Kelas "${deleteClassTarget.name}" beserta seluruh modul, kuis, dan data terkait di dalamnya akan dihapus permanen dan tidak dapat dikembalikan.`
            : ""
        }
        onCancel={() => setDeleteClassTarget(null)}
        onConfirm={() => {
          if (deleteClassTarget) forceDeleteClassMutation.mutate(deleteClassTarget.id);
        }}
        open={Boolean(deleteClassTarget)}
        title="Hapus kelas secara permanen?"
      />
    </div>
  );
}
