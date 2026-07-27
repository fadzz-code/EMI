import { PasswordResetRequestList } from "@/features/admin/password-resets/password-reset-request-list";

export const metadata = {
  title: "Persetujuan Reset Password | EMI Speaking",
};

export default function TeacherPasswordResetsPage() {
  return (
    <PasswordResetRequestList
      description="Setujui atau tolak permintaan reset password dari siswa di kelas Anda."
      queryKeyPrefix="teacher"
      scope="teacher"
      title="Persetujuan Reset Password Siswa"
    />
  );
}
