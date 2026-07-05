import type { KnowledgeFeature, KnowledgePlaceholderRow } from "./types";

export const knowledgeEndpointMessage =
  "Detail sumber pengetahuan belum tersedia penuh di halaman ini.";

export const unavailableKnowledgeActions: KnowledgeFeature[] = [
  {
    label: "Tambah sumber pengetahuan",
    description: "Gunakan daftar Basis AI untuk menambah pengetahuan manual, link, atau PDF.",
  },
  {
    label: "Upload dokumen",
    description: "Upload dan ekstraksi PDF tersedia dari form tambah pengetahuan.",
  },
  {
    label: "Aktifkan/nonaktifkan sumber",
    description: "Status draft, terbit, dan arsip dikelola dari daftar Basis AI.",
  },
  {
    label: "Verifikasi dan reindex",
    description: "Verifikasi dan reindex bisa dipoles pada batch Basis AI berikutnya.",
  },
];

export const placeholderRows: KnowledgePlaceholderRow[] = [
  { label: "Total sumber pengetahuan", value: "Belum tersedia" },
  { label: "Sumber aktif", value: "Belum tersedia" },
  { label: "Draft/nonaktif", value: "Belum tersedia" },
  { label: "Perlu review/gagal proses", value: "Belum tersedia" },
];
