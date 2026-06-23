import Link from "next/link";

import {
  Alert,
  Badge,
  Card,
  CardContent,
  CardHeader,
  FormField,
  Input,
  Textarea,
} from "@/components/ui";

import { KnowledgeBaseEmptyState } from "./knowledge-base-empty-state";
import { KnowledgeBaseStatusBadge } from "./knowledge-base-status-badge";
import { knowledgeEndpointMessage, unavailableKnowledgeActions } from "./knowledge-base-utils";

const disabledControlClass = "bg-slate-100 text-slate-500";

function DisabledInput({ value = "Belum tersedia dari backend" }: { value?: string }) {
  return <Input className={disabledControlClass} disabled value={value} />;
}

function DisabledTextarea({ value = "Belum tersedia dari backend" }: { value?: string }) {
  return <Textarea className={disabledControlClass} disabled value={value} />;
}

export function KnowledgeBaseDetail({ knowledgeId }: { knowledgeId: string }) {
  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="yellow">ADMIN-12</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Detail Pengetahuan AI</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Detail/edit sumber pengetahuan AI. Backend aktual belum menyediakan endpoint
            detail knowledge document, jadi halaman ini tampil sebagai fallback read-only.
          </p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row sm:items-center">
          <Link
            className="inline-flex min-h-11 items-center justify-center rounded-lg border-2 border-ink bg-white px-4 py-2 text-sm font-bold text-ink hover:bg-yellow-100"
            href="/admin/knowledge-base"
          >
            Kembali
          </Link>
          <KnowledgeBaseStatusBadge />
        </div>
      </header>

      <Alert tone="warning">
        {knowledgeEndpointMessage} ID dari URL hanya ditampilkan sebagai konteks, bukan
        hasil fetch data backend.
      </Alert>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h2 className="text-xl font-black text-ink">Metadata Sumber</h2>
              <p className="mt-1 text-sm leading-6 text-slate-600">
                Field detail akan aktif setelah backend menyediakan endpoint show/update.
              </p>
            </div>
            <Badge tone="neutral">Read-only</Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-2">
            <FormField label="ID yang diminta">
              <DisabledInput value={knowledgeId} />
            </FormField>
            <FormField label="Status">
              <DisabledInput />
            </FormField>
            <FormField label="Judul">
              <DisabledInput />
            </FormField>
            <FormField label="Kategori / Topik">
              <DisabledInput />
            </FormField>
            <FormField label="Bahasa">
              <DisabledInput />
            </FormField>
            <FormField label="Tipe Sumber">
              <DisabledInput />
            </FormField>
            <FormField label="Tanggal Dibuat">
              <DisabledInput />
            </FormField>
            <FormField label="Tanggal Diubah">
              <DisabledInput />
            </FormField>
            <div className="md:col-span-2">
              <FormField label="Deskripsi">
                <DisabledTextarea />
              </FormField>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Konten dan Indexing</h2>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4">
            <FormField label="Isi teks / dokumen / URL sumber">
              <DisabledTextarea />
            </FormField>
            <FormField label="Chunk dan embedding">
              <DisabledTextarea value="Belum tersedia. Endpoint chunk, embedding, verify, dan reindex belum aktif di route backend aktual." />
            </FormField>
            <KnowledgeBaseEmptyState />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Aksi Detail yang Belum Tersedia</h2>
        </CardHeader>
        <CardContent>
          <div className="grid gap-3 md:grid-cols-2">
            {unavailableKnowledgeActions.map((action) => (
              <div
                className="rounded-lg border-2 border-dashed border-ink bg-slate-50 p-4"
                key={action.label}
              >
                <p className="text-sm font-black text-ink">{action.label}</p>
                <p className="mt-1 text-xs leading-5 text-slate-600">{action.description}</p>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
