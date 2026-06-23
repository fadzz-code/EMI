import type { KnowledgeFeature, KnowledgePlaceholderRow } from "./types";

export const knowledgeEndpointMessage =
  "Endpoint basis pengetahuan AI belum terdaftar di routes/api.php.";

export const unavailableKnowledgeActions: KnowledgeFeature[] = [
  {
    label: "Tambah sumber pengetahuan",
    description: "Membutuhkan POST /knowledge-documents atau endpoint admin yang setara.",
  },
  {
    label: "Upload dokumen",
    description: "Belum ada endpoint upload dokumen knowledge base yang aktif.",
  },
  {
    label: "Aktifkan/nonaktifkan sumber",
    description: "Belum ada field status atau endpoint update knowledge yang tersedia.",
  },
  {
    label: "Verifikasi dan reindex",
    description: "Kontrak API menyebut verify/reindex, tetapi route aktual belum tersedia.",
  },
];

export const placeholderRows: KnowledgePlaceholderRow[] = [
  { label: "Total sumber pengetahuan", value: "Belum tersedia" },
  { label: "Sumber aktif", value: "Belum tersedia" },
  { label: "Draft/nonaktif", value: "Belum tersedia" },
  { label: "Perlu review/gagal proses", value: "Belum tersedia" },
];
