import type { Metadata } from "next";

import { AccountDeletionContent } from "@/features/auth/account-deletion-content";

export const metadata: Metadata = {
  title: "Penghapusan Akun — EMI",
  description: "Hapus akun EMI dan data pribadi secara permanen.",
};

export default function AccountDeletionPage() {
  return <AccountDeletionContent />;
}
