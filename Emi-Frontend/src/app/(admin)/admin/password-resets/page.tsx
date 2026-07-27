import { PasswordResetRequestList } from "@/features/admin/password-resets/password-reset-request-list";

export const metadata = {
  title: "Persetujuan Reset Password | EMI Speaking",
};

export default function AdminPasswordResetsPage() {
  return (
    <PasswordResetRequestList
      description="Setujui atau tolak permintaan reset password dari guru dan siswa di seluruh sekolah."
      queryKeyPrefix="admin"
      scope="admin"
      title="Persetujuan Reset Password"
    />
  );
}
