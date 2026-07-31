import type { Metadata } from "next";
import Link from "next/link";

import { env } from "@/lib/env";

export const metadata: Metadata = {
  title: `Kebijakan Privasi — ${env.appName}`,
  description:
    "Kebijakan privasi aplikasi EMI (Elearning Mekongga Indonesia) untuk pengguna web dan mobile.",
};

const LAST_UPDATED = "26 Juli 2026";
const SUPPORT_EMAIL = "support@emi-kolaka.id";

function Section({
  id,
  title,
  children,
}: {
  id: string;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className="scroll-mt-24">
      <h2 className="text-xl font-black text-ink">{title}</h2>
      <div className="mt-3 space-y-3 text-sm leading-relaxed text-muted-foreground">
        {children}
      </div>
    </section>
  );
}

export default function PrivacyPolicyPage() {
  return (
    <main className="min-h-screen bg-paper px-4 py-10 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-3xl">
        <Link
          href="/"
          className="text-sm font-semibold text-primary hover:underline"
        >
          ← Kembali ke {env.appName}
        </Link>

        <header className="mt-6 rounded-xl border-2 border-ink bg-white p-6 shadow-brutal sm:p-8">
          <p className="text-xs font-bold uppercase tracking-wide text-primary">
            Kebijakan Privasi
          </p>
          <h1 className="mt-2 text-3xl font-black text-ink sm:text-4xl">
            {env.appName}
          </h1>
          <p className="mt-3 text-sm text-muted-foreground">
            Terakhir diperbarui: {LAST_UPDATED}
          </p>
          <p className="mt-4 text-sm leading-relaxed text-foreground">
            Kebijakan ini menjelaskan bagaimana EMI (Elearning Mekongga
            Indonesia) mengumpulkan, menggunakan, menyimpan, dan melindungi
            data pribadi pengguna aplikasi mobile dan situs web EMI,
            termasuk pengguna dengan peran Admin, Guru, dan Siswa.
          </p>
        </header>

        <nav className="mt-6 rounded-xl border-2 border-ink bg-surface-muted p-4 text-sm">
          <p className="font-black text-ink">Daftar isi</p>
          <ol className="mt-2 list-decimal space-y-1 pl-5 text-muted-foreground">
            <li><a className="hover:underline" href="#data-dikumpulkan">Data yang kami kumpulkan</a></li>
            <li><a className="hover:underline" href="#perangkat-izin">Data perangkat &amp; izin aplikasi</a></li>
            <li><a className="hover:underline" href="#tujuan-penggunaan">Tujuan penggunaan data</a></li>
            <li><a className="hover:underline" href="#berbagi-data">Berbagi data dengan pihak ketiga</a></li>
            <li><a className="hover:underline" href="#penyimpanan-keamanan">Penyimpanan &amp; keamanan data</a></li>
            <li><a className="hover:underline" href="#hak-pengguna">Hak pengguna atas data</a></li>
            <li><a className="hover:underline" href="#hapus-akun">Penghapusan akun &amp; data</a></li>
            <li><a className="hover:underline" href="#anak">Data anak &amp; pengguna sekolah</a></li>
            <li><a className="hover:underline" href="#retensi">Retensi data</a></li>
            <li><a className="hover:underline" href="#perubahan">Perubahan kebijakan</a></li>
            <li><a className="hover:underline" href="#kontak">Hubungi kami</a></li>
          </ol>
        </nav>

        <div className="mt-8 space-y-8 rounded-xl border-2 border-ink bg-white p-6 shadow-brutal sm:p-8">
          <Section id="data-dikumpulkan" title="1. Data yang kami kumpulkan">
            <p>Kami mengumpulkan data berikut saat Anda menggunakan EMI:</p>
            <ul className="list-disc space-y-1 pl-5">
              <li>
                <strong>Data akun:</strong> nama lengkap, alamat email,
                nomor telepon (opsional), foto profil (opsional), kata
                sandi (tersimpan terenkripsi), peran (Admin/Guru/Siswa),
                sekolah, dan kelas.
              </li>
              <li>
                <strong>Data pembelajaran:</strong> progres modul, hasil
                dan riwayat kuis, hasil latihan speaking (termasuk
                rekaman audio saat Anda memilih fitur latihan berbicara),
                interaksi dengan kamus dan materi budaya.
              </li>
              <li>
                <strong>Data teknis:</strong> log aktivitas login,
                identifikasi sesi, dan informasi teknis perangkat yang
                diperlukan agar aplikasi berjalan dengan baik.
              </li>
              <li>
                <strong>Konten yang Anda unggah:</strong> foto profil,
                berkas audio latihan speaking, dan berkas yang diunggah
                oleh Admin/Guru untuk keperluan materi pembelajaran.
              </li>
            </ul>
          </Section>

          <Section id="perangkat-izin" title="2. Data perangkat & izin aplikasi">
            <p>Aplikasi mobile EMI meminta izin perangkat berikut:</p>
            <ul className="list-disc space-y-1 pl-5">
              <li>
                <strong>Mikrofon:</strong> digunakan hanya saat Anda
                secara aktif menggunakan fitur latihan Speaking untuk
                merekam suara Anda. Rekaman dikirim ke server EMI untuk
                dinilai dan disimpan sebagai bagian dari riwayat latihan
                Anda.
              </li>
              <li>
                <strong>Penyimpanan/galeri foto:</strong> digunakan saat
                Anda memilih untuk mengunggah foto profil atau berkas
                (mis. dokumen PDF, gambar materi) melalui fitur Admin/Guru.
              </li>
              <li>
                <strong>Internet:</strong> diperlukan agar aplikasi dapat
                berkomunikasi dengan server EMI.
              </li>
            </ul>
            <p>
              Kami tidak mengakses lokasi, kontak, kalender, SMS, atau
              data sensor perangkat lain yang tidak terkait langsung
              dengan fitur di atas.
            </p>
          </Section>

          <Section id="tujuan-penggunaan" title="3. Tujuan penggunaan data">
            <ul className="list-disc space-y-1 pl-5">
              <li>Menyediakan dan mengoperasikan fitur pembelajaran EMI.</li>
              <li>Autentikasi, otorisasi, dan pengelolaan sesi pengguna.</li>
              <li>
                Menampilkan progres belajar kepada Siswa, Guru, dan Admin
                sekolah sesuai peran masing-masing.
              </li>
              <li>
                Menilai hasil latihan speaking menggunakan sistem analisis
                suara internal EMI.
              </li>
              <li>
                Meningkatkan kualitas dan keandalan aplikasi (perbaikan
                bug, analisis penggunaan fitur secara agregat).
              </li>
              <li>Mematuhi kewajiban hukum yang berlaku di Indonesia.</li>
            </ul>
            <p>
              Kami tidak menggunakan data pengguna untuk iklan
              pihak ketiga dan tidak menjual data pengguna kepada siapa
              pun.
            </p>
          </Section>

          <Section id="berbagi-data" title="4. Berbagi data dengan pihak ketiga">
            <p>
              Data Anda hanya dapat diakses oleh:
            </p>
            <ul className="list-disc space-y-1 pl-5">
              <li>
                Anda sendiri, dan Guru/Admin sekolah tempat Anda terdaftar
                (sebatas data yang relevan dengan peran mereka, misalnya
                progres belajar siswa di kelas yang mereka ajar/kelola).
              </li>
              <li>
                Penyedia layanan infrastruktur (server dan penyimpanan
                data) yang kami gunakan untuk menjalankan aplikasi, yang
                terikat kewajiban kerahasiaan.
              </li>
            </ul>
            <p>
              Kami tidak membagikan data pribadi Anda kepada pengiklan,
              broker data, atau pihak ketiga untuk tujuan pemasaran.
            </p>
          </Section>

          <Section id="penyimpanan-keamanan" title="5. Penyimpanan & keamanan data">
            <ul className="list-disc space-y-1 pl-5">
              <li>
                Data disimpan di server yang kami kelola dengan kontrol
                akses berbasis peran (role-based access control).
              </li>
              <li>
                Kata sandi disimpan dalam bentuk terenkripsi (hash), tidak
                pernah disimpan dalam bentuk teks biasa.
              </li>
              <li>
                Sesi login pada aplikasi mobile disimpan secara aman di
                perangkat menggunakan penyimpanan terenkripsi bawaan
                sistem operasi.
              </li>
              <li>
                Komunikasi antara aplikasi dan server dienkripsi
                menggunakan HTTPS/TLS.
              </li>
            </ul>
          </Section>

          <Section id="hak-pengguna" title="6. Hak pengguna atas data">
            <p>Anda berhak untuk:</p>
            <ul className="list-disc space-y-1 pl-5">
              <li>Melihat dan memperbarui data profil Anda melalui halaman Profil di aplikasi.</li>
              <li>Mengganti kata sandi kapan saja.</li>
              <li>Menghapus foto profil yang telah diunggah.</li>
              <li>Meminta salinan data pribadi Anda dengan menghubungi kami.</li>
              <li>Meminta penghapusan akun dan data pribadi Anda (lihat bagian 7).</li>
            </ul>
          </Section>

          <Section id="hapus-akun" title="7. Penghapusan akun & data">
            <p>
              Anda dapat menghapus akun kapan saja melalui menu{" "}
              <strong>Profil → Hapus Akun</strong> di aplikasi mobile
              EMI. Setelah permintaan penghapusan dikonfirmasi:
            </p>
            <ul className="list-disc space-y-1 pl-5">
              <li>Akun Anda dinonaktifkan dan sesi login dihentikan.</li>
              <li>
                Data pribadi yang tidak lagi diperlukan untuk kewajiban
                hukum atau akademik (misalnya rekaman arsip nilai sekolah)
                akan dihapus atau dianonimkan dalam waktu maksimal 30 hari
                kerja.
              </li>
              <li>
                Anda juga dapat mengajukan permintaan penghapusan data
                secara manual dengan mengirim email ke{" "}
                <a
                  className="font-semibold text-primary hover:underline"
                  href={`mailto:${SUPPORT_EMAIL}`}
                >
                  {SUPPORT_EMAIL}
                </a>{" "}
                dari alamat email yang terdaftar pada akun Anda.
              </li>
            </ul>
          </Section>

          <Section id="anak" title="8. Data anak & pengguna sekolah">
            <p>
              EMI adalah aplikasi pembelajaran yang digunakan dalam
              konteks institusi pendidikan (sekolah). Untuk pengguna
              Siswa yang berusia di bawah 18 tahun, pendaftaran dan
              penggunaan akun dilakukan atas persetujuan dan pengawasan
              pihak sekolah/Guru/Admin sekolah yang bertindak selaku wali
              data pendidikan siswa. Data siswa hanya digunakan untuk
              keperluan pembelajaran dan pemantauan progres akademik oleh
              Guru dan Admin sekolah terkait.
            </p>
          </Section>

          <Section id="retensi" title="9. Retensi data">
            <p>
              Kami menyimpan data pengguna selama akun aktif digunakan.
              Data dapat disimpan lebih lama apabila diwajibkan oleh
              peraturan perundang-undangan yang berlaku (misalnya arsip
              akademik sekolah), atau dihapus lebih cepat atas permintaan
              penghapusan akun sebagaimana dijelaskan pada bagian 7.
            </p>
          </Section>

          <Section id="perubahan" title="10. Perubahan kebijakan">
            <p>
              Kami dapat memperbarui kebijakan privasi ini dari waktu ke
              waktu. Perubahan material akan diinformasikan melalui
              aplikasi atau situs web EMI, dengan tanggal pembaruan
              terbaru tercantum di bagian atas halaman ini.
            </p>
          </Section>

          <Section id="kontak" title="11. Hubungi kami">
            <p>
              Jika Anda memiliki pertanyaan mengenai kebijakan privasi
              ini atau ingin menggunakan hak Anda atas data pribadi,
              silakan hubungi kami melalui:
            </p>
            <p>
              Email:{" "}
              <a
                className="font-semibold text-primary hover:underline"
                href={`mailto:${SUPPORT_EMAIL}`}
              >
                {SUPPORT_EMAIL}
              </a>
            </p>
          </Section>
        </div>
      </div>
    </main>
  );
}
