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
  EmptyState,
  ErrorState,
  FormField,
  Input,
  LoadingState,
  Modal,
  MutationAlert,
  Pagination,
  Select,
  Table,
  TableCell,
  TableHeader,
} from "@/components/ui";
import { useAuth } from "@/features/auth/auth-provider";
import { getFirstApiError } from "@/lib/api-client";

import { classService, userManagementService } from "./management-service";
import {
  classLabel,
  entityStatusLabel,
  formatDateTime,
  statusTone,
  userStatusLabel,
} from "./management-utils";
import type { ClassPayload, EntityStatus, SchoolClass } from "./types";

type ClassFormState = {
  name: string;
  grade_level: string;
  academic_year: string;
  status: EntityStatus;
};

function toForm(schoolClass: SchoolClass): ClassFormState {
  return {
    name: schoolClass.name,
    grade_level: schoolClass.grade_level ?? "",
    academic_year: schoolClass.academic_year,
    status: schoolClass.status,
  };
}

export function ClassDetailScreen({ classId }: { classId: string }) {
  const { token } = useAuth();
  const queryClient = useQueryClient();
  const [studentPage, setStudentPage] = useState(1);
  const [editOpen, setEditOpen] = useState(false);
  const [assignTeacherOpen, setAssignTeacherOpen] = useState(false);
  const [assignStudentOpen, setAssignStudentOpen] = useState(false);
  const [selectedTeacherId, setSelectedTeacherId] = useState("");
  const [selectedStudentId, setSelectedStudentId] = useState("");
  const [classForm, setClassForm] = useState<ClassFormState | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const classQuery = useQuery({
    queryKey: ["admin", "classes", classId],
    queryFn: () => classService.detail(token ?? "", classId),
    enabled: Boolean(token && classId),
  });

  const studentsQuery = useQuery({
    queryKey: ["admin", "classes", classId, "students", studentPage],
    queryFn: () =>
      classService.students(token ?? "", classId, {
        page: studentPage,
        per_page: 10,
      }),
    enabled: Boolean(token && classId),
  });

  const teachersQuery = useQuery({
    queryKey: ["admin", "users", "teachers", "approved"],
    queryFn: () =>
      userManagementService.list(token ?? "", {
        role: "teacher",
        status: "approved",
        per_page: 100,
      }),
    enabled: Boolean(token),
  });

  const studentsLookupQuery = useQuery({
    queryKey: ["admin", "users", "students", "approved"],
    queryFn: () =>
      userManagementService.list(token ?? "", {
        role: "student",
        status: "approved",
        per_page: 100,
      }),
    enabled: Boolean(token),
  });

  const updateClassMutation = useMutation({
    mutationFn: (payload: ClassPayload) => classService.update(token ?? "", classId, payload),
    onSuccess: async (schoolClass) => {
      setSuccessMessage(`Kelas ${schoolClass.name} berhasil diperbarui.`);
      setEditOpen(false);
      await queryClient.invalidateQueries({ queryKey: ["admin", "classes"] });
    },
  });

  const assignTeacherMutation = useMutation({
    mutationFn: (teacherId: string) => classService.assignTeacher(token ?? "", classId, teacherId),
    onSuccess: async () => {
      setSuccessMessage("Guru kelas berhasil ditetapkan.");
      setAssignTeacherOpen(false);
      setSelectedTeacherId("");
      await queryClient.invalidateQueries({ queryKey: ["admin", "classes"] });
      await queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
    },
  });

  const assignStudentMutation = useMutation({
    mutationFn: (studentId: string) => classService.assignStudent(token ?? "", classId, studentId),
    onSuccess: async () => {
      setSuccessMessage("Siswa berhasil ditempatkan ke kelas.");
      setAssignStudentOpen(false);
      setSelectedStudentId("");
      await queryClient.invalidateQueries({ queryKey: ["admin", "classes"] });
      await queryClient.invalidateQueries({ queryKey: ["admin", "users"] });
    },
  });

  const resultEventKey = Math.max(updateClassMutation.submittedAt, assignTeacherMutation.submittedAt, assignStudentMutation.submittedAt);
  const actionError =
    updateClassMutation.error ?? assignTeacherMutation.error ?? assignStudentMutation.error;
  const schoolClass = classQuery.data;
  const students = studentsQuery.data?.items ?? [];
  const studentsMeta = studentsQuery.data?.meta;
  const teachers = teachersQuery.data?.items ?? [];
  const studentOptions = studentsLookupQuery.data?.items ?? [];

  function openEditClass() {
    if (!schoolClass) {
      return;
    }

    setClassForm(toForm(schoolClass));
    setEditOpen(true);
  }

  function submitClass(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!classForm) {
      return;
    }

    updateClassMutation.mutate({
      name: classForm.name.trim(),
      grade_level: classForm.grade_level.trim() || null,
      academic_year: classForm.academic_year.trim(),
      status: classForm.status,
    });
  }

  return (
    <div className="grid gap-8">
      <Link
        className="w-fit rounded-lg border-2 border-border bg-surface px-3 py-2 text-sm font-black text-ink transition-colors hover:bg-primary hover:text-primary-foreground"
        href="/admin/schools-classes"
      >
        <ArrowLeft className="mr-2 inline size-4" strokeWidth={2.5} />
        Kembali ke Sekolah & Kelas
      </Link>

      <MutationAlert eventKey={resultEventKey} tone="success" visible={Boolean(successMessage)}>{successMessage}</MutationAlert>
      <MutationAlert eventKey={resultEventKey} tone="error" visible={Boolean(actionError)}>{getFirstApiError(actionError)}</MutationAlert>

      {classQuery.isLoading ? <LoadingState title="Memuat detail kelas" /> : null}
      {classQuery.isError ? (
        <ErrorState
          description={getFirstApiError(classQuery.error)}
          onRetry={() => void classQuery.refetch()}
          title="Gagal memuat detail kelas"
        />
      ) : null}

      {schoolClass ? (
        <>
          <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <Badge tone={statusTone(schoolClass.status)}>
                {entityStatusLabel(schoolClass.status)}
              </Badge>
              <h1 className="mt-2 text-3xl font-black text-ink">{schoolClass.name}</h1>
              <p className="mt-2 text-sm leading-6 text-muted">
                {schoolClass.school?.name ?? "-"} | {schoolClass.grade_level ?? "-"} |{" "}
                {schoolClass.academic_year}
              </p>
            </div>
            <div className="flex flex-col gap-2 sm:flex-row">
              <Button onClick={openEditClass} variant="secondary">
                Edit Kelas
              </Button>
              <Button onClick={() => setAssignTeacherOpen(true)}>
                Tetapkan Guru
              </Button>
              <Button onClick={() => setAssignStudentOpen(true)} variant="secondary">
                Tambah/Pindah Siswa
              </Button>
            </div>
          </header>

          <div className="grid gap-4 md:grid-cols-4">
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-muted">Sekolah</p>
                <p className="mt-2 font-black text-ink">{schoolClass.school?.name ?? "-"}</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-muted">Guru Aktif</p>
                <p className="mt-2 font-black text-ink">
                  {schoolClass.active_teacher_assignment?.teacher?.full_name ?? "-"}
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-muted">Siswa Aktif</p>
                <p className="mt-2 font-black text-ink">
                  {schoolClass.active_students_count ?? studentsMeta?.total ?? 0}
                </p>
              </CardContent>
            </Card>
            <Card>
              <CardContent>
                <p className="text-xs font-black uppercase text-muted">Dibuat</p>
                <p className="mt-2 font-black text-ink">{formatDateTime(schoolClass.created_at)}</p>
              </CardContent>
            </Card>
          </div>

          <Card>
            <CardHeader>
              <h2 className="text-xl font-black text-ink">Siswa Kelas</h2>
              <p className="mt-1 text-sm text-muted">
                Daftar siswa aktif yang saat ini ditempatkan di kelas ini.
              </p>
            </CardHeader>
            <CardContent>
              {studentsQuery.isLoading ? <LoadingState title="Memuat siswa" /> : null}
              {studentsQuery.isError ? (
                <ErrorState
                  description={getFirstApiError(studentsQuery.error)}
                  onRetry={() => void studentsQuery.refetch()}
                  title="Gagal memuat siswa kelas"
                />
              ) : null}
              {!studentsQuery.isLoading && !studentsQuery.isError ? (
                students.length === 0 ? (
                  <EmptyState
                    description="Belum ada siswa aktif di kelas ini."
                    title="Siswa kosong"
                  />
                ) : (
                  <div className="grid gap-4">
                    <Table>
                      <TableHeader>
                        <tr>
                          <th className="px-4 py-3">Nama</th>
                          <th className="px-4 py-3">Email</th>
                          <th className="px-4 py-3">Status</th>
                          <th className="px-4 py-3">Masuk Kelas</th>
                          <th className="px-4 py-3">Aksi</th>
                        </tr>
                      </TableHeader>
                      <tbody>
                        {students.map((membership) => (
                          <tr key={membership.membership_id}>
                            <TableCell className="font-black text-ink">
                              {membership.student.full_name}
                            </TableCell>
                            <TableCell>{membership.student.email}</TableCell>
                            <TableCell>
                              <Badge tone={statusTone(membership.student.status)}>
                                {userStatusLabel(membership.student.status)}
                              </Badge>
                            </TableCell>
                            <TableCell>{formatDateTime(membership.joined_at)}</TableCell>
                            <TableCell>
                              <Link
                                className="inline-flex min-h-9 items-center rounded-lg border-2 border-border bg-surface px-3 py-1 text-xs font-black text-ink transition-colors hover:bg-primary hover:text-primary-foreground"
                                href={`/admin/users/${membership.student.id}`}
                              >
                                Detail User
                              </Link>
                            </TableCell>
                          </tr>
                        ))}
                      </tbody>
                    </Table>
                    <Pagination
                      onPageChange={setStudentPage}
                      page={studentsMeta?.current_page ?? studentPage}
                      totalPages={studentsMeta?.last_page ?? 1}
                    />
                  </div>
                )
              ) : null}
            </CardContent>
          </Card>
        </>
      ) : null}

      <Modal onClose={() => setEditOpen(false)} open={editOpen} title="Edit Kelas">
        {classForm ? (
          <form className="grid gap-4" onSubmit={submitClass}>
            <FormField label="Nama kelas">
              <Input
                onChange={(event) => setClassForm((form) => form && { ...form, name: event.target.value })}
                required
                value={classForm.name}
              />
            </FormField>
            <FormField label="Tingkat / grade">
              <Input
                onChange={(event) =>
                  setClassForm((form) => form && { ...form, grade_level: event.target.value })
                }
                value={classForm.grade_level}
              />
            </FormField>
            <FormField label="Tahun ajaran">
              <Input
                onChange={(event) =>
                  setClassForm((form) => form && { ...form, academic_year: event.target.value })
                }
                required
                value={classForm.academic_year}
              />
            </FormField>
            <FormField label="Status">
              <Select
                onChange={(event) =>
                  setClassForm((form) =>
                    form ? { ...form, status: event.target.value as EntityStatus } : form,
                  )
                }
                value={classForm.status}
              >
                <option value="active">Aktif</option>
                <option value="inactive">Nonaktif</option>
              </Select>
            </FormField>
            <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
              <Button onClick={() => setEditOpen(false)} variant="ghost">
                Batal
              </Button>
              <Button disabled={updateClassMutation.isPending} type="submit" variant="secondary">
                Simpan
              </Button>
            </div>
          </form>
        ) : null}
      </Modal>

      <Modal
        onClose={() => setAssignTeacherOpen(false)}
        open={assignTeacherOpen}
        title="Tetapkan Guru Kelas"
      >
        <div className="grid gap-4">
          <Alert tone="info">
            Sistem akan menutup assignment guru aktif lama sesuai aturan satu guru aktif
            per kelas dan satu kelas aktif per guru.
          </Alert>
          <FormField label="Guru approved">
            <Select
              onChange={(event) => setSelectedTeacherId(event.target.value)}
              value={selectedTeacherId}
            >
              <option value="">Pilih guru</option>
              {teachers.map((teacher) => (
                <option key={teacher.id} value={teacher.id}>
                  {teacher.full_name} - {teacher.email}
                </option>
              ))}
            </Select>
          </FormField>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={() => setAssignTeacherOpen(false)} variant="ghost">
              Batal
            </Button>
            <Button
              disabled={!selectedTeacherId || assignTeacherMutation.isPending}
              onClick={() => assignTeacherMutation.mutate(selectedTeacherId)}
            >
              Tetapkan Guru
            </Button>
          </div>
        </div>
      </Modal>

      <Modal
        onClose={() => setAssignStudentOpen(false)}
        open={assignStudentOpen}
        title="Tambah / Pindahkan Siswa"
      >
        <div className="grid gap-4">
          <Alert tone="info">
            Sistem akan membuat membership aktif baru dan menangani aturan satu kelas aktif
            per siswa.
          </Alert>
          <FormField label="Siswa approved">
            <Select
              onChange={(event) => setSelectedStudentId(event.target.value)}
              value={selectedStudentId}
            >
              <option value="">Pilih siswa</option>
              {studentOptions.map((student) => (
                <option key={student.id} value={student.id}>
                  {student.full_name} - {student.email} ({classLabel(student.active_class)})
                </option>
              ))}
            </Select>
          </FormField>
          <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
            <Button onClick={() => setAssignStudentOpen(false)} variant="ghost">
              Batal
            </Button>
            <Button
              disabled={!selectedStudentId || assignStudentMutation.isPending}
              onClick={() => assignStudentMutation.mutate(selectedStudentId)}
            >
              Tempatkan Siswa
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
