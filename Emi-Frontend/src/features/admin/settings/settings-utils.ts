export function roleLabel(role?: string) {
  if (role === "admin") {
    return "Admin";
  }

  if (role === "teacher") {
    return "Guru";
  }

  if (role === "student") {
    return "Siswa";
  }

  return "Belum tersedia";
}
