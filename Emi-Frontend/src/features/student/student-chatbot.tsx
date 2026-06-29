import { Badge, Card, CardContent, CardHeader, Input, PageHeader } from "@/components/ui";

const promptChips = [
  "Apa arti kata ini?",
  "Bantu saya memahami materi ini.",
  "Ceritakan tentang Budaya Mekongga.",
];

export function StudentChatbot() {
  return (
    <div className="grid gap-6">
      <PageHeader badge="Segera tersedia" description="Asisten AI akan membantu Anda bertanya tentang kosakata, modul, kuis, dan Budaya Mekongga." title="Chatbot AI" />

      <Card>
        <CardHeader>
          <div className="flex items-start justify-between gap-3">
            <div>
              <h2 className="text-xl font-black text-ink">Asisten Belajar EMI</h2>
              <p className="mt-2 text-sm text-slate-600">Fitur Chatbot AI belum aktif.</p>
            </div>
            <Badge tone="yellow">Segera tersedia</Badge>
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-2xl border-2 border-ink bg-blue-50 p-4">
            <p className="text-sm font-bold text-blue-950">Nanti, chatbot akan menjawab pertanyaan berdasarkan kosakata, modul, kuis, dan konten Budaya Mekongga yang tersedia di EMI.</p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Contoh pertanyaan</h2>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2">
            {promptChips.map((prompt) => (
              <span className="rounded-full border-2 border-ink bg-white px-4 py-2 text-sm font-black text-ink" key={prompt}>{prompt}</span>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <h2 className="text-xl font-black text-ink">Chat</h2>
        </CardHeader>
        <CardContent>
          <div className="grid gap-3">
            <Input disabled placeholder="Chatbot AI belum aktif." />
            <p className="text-sm text-slate-600">Input dinonaktifkan sampai endpoint AI tersedia. Tidak ada respons AI palsu yang ditampilkan.</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
