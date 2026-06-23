import {
  Alert,
  Badge,
  Card,
  CardContent,
  CardHeader,
  FilterPanel,
  Input,
  Select,
  Table,
  TableHeader,
} from "@/components/ui";

import { KnowledgeBaseEmptyState } from "./knowledge-base-empty-state";
import { knowledgeBaseService } from "./knowledge-base-service";
import { KnowledgeBaseStatusBadge } from "./knowledge-base-status-badge";
import {
  knowledgeEndpointMessage,
  placeholderRows,
  unavailableKnowledgeActions,
} from "./knowledge-base-utils";

const disabledControlClass = "bg-slate-100 text-slate-500";

export function KnowledgeBaseList() {
  const isUnavailable = knowledgeBaseService.endpointStatus === "unavailable";

  return (
    <div className="grid gap-6">
      <header className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
        <div>
          <Badge tone="yellow">ADMIN-11</Badge>
          <h1 className="mt-2 text-3xl font-black text-ink">Basis Pengetahuan AI</h1>
          <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-600">
            Halaman admin untuk mengelola sumber pengetahuan AI EMI. Saat ini UI
            mengikuti backend aktual dan tidak membuat data atau aksi knowledge base palsu.
          </p>
        </div>
        <KnowledgeBaseStatusBadge />
      </header>

      {isUnavailable ? (
        <Alert tone="warning">
          {knowledgeEndpointMessage} Kontrak API di dokumen menyebut knowledge documents,
          tetapi route Laravel aktif belum menyediakan endpoint tersebut.
        </Alert>
      ) : null}

      <section className="grid gap-3 md:grid-cols-4">
        {placeholderRows.map((item) => (
          <Card key={item.label}>
            <CardContent>
              <p className="text-xs font-black uppercase text-slate-500">{item.label}</p>
              <p className="mt-2 text-lg font-black text-ink">{item.value}</p>
            </CardContent>
          </Card>
        ))}
      </section>

      <FilterPanel className="md:grid-cols-4">
        <label className="grid gap-2 text-sm font-bold text-ink md:col-span-2">
          <span>Cari judul/konten</span>
          <Input
            className={disabledControlClass}
            disabled
            placeholder="Aktif setelah endpoint knowledge tersedia"
          />
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Status</span>
          <Select className={disabledControlClass} disabled value="">
            <option value="">Belum tersedia</option>
          </Select>
        </label>
        <label className="grid gap-2 text-sm font-bold text-ink">
          <span>Tipe sumber</span>
          <Select className={disabledControlClass} disabled value="">
            <option value="">Belum tersedia</option>
          </Select>
        </label>
      </FilterPanel>

      <Card>
        <CardHeader>
          <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h2 className="text-xl font-black text-ink">Daftar Sumber Pengetahuan</h2>
              <p className="mt-1 text-sm leading-6 text-slate-600">
                Tabel akan memakai data backend setelah endpoint knowledge base aktif.
              </p>
            </div>
            <Badge tone="neutral">Tidak ada aksi</Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4">
            <Table>
              <TableHeader>
                <tr>
                  <th className="px-4 py-3">Judul</th>
                  <th className="px-4 py-3">Tipe</th>
                  <th className="px-4 py-3">Kategori</th>
                  <th className="px-4 py-3">Status</th>
                  <th className="px-4 py-3">Bahasa</th>
                  <th className="px-4 py-3">Chunk/Embedding</th>
                  <th className="px-4 py-3">Diubah</th>
                </tr>
              </TableHeader>
              <tbody>
                <tr>
                  <td className="border-t border-slate-200 px-4 py-3" colSpan={7}>
                    <KnowledgeBaseEmptyState />
                  </td>
                </tr>
              </tbody>
            </Table>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Aksi yang Menunggu Backend</h2>
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
