<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AiKnowledgeItem;
use App\Jobs\ProcessIngestionJob;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class KnowledgeController extends Controller
{
    /**
     * Menampilkan daftar dokumen referensi dan status ingestion-nya.
     */
    public function index()
    {
        // Hapus batasan ':id,name' agar Laravel aman mengambil data User (UUID)
        $items = AiKnowledgeItem::with('creator') 
                    ->orderBy('created_at', 'desc')
                    ->get();

        return response()->json([
            'status' => 'success',
            'data' => $items
        ]);
    }

    /**
     * Mengunggah dokumen baru dan memasukkan ke antrean pemrosesan.
     */
    public function upload(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'document' => 'required|file|mimes:pdf,txt,docx|max:10240', // Maks 10MB
        ]);

        $file = $request->file('document');
        $extension = $file->getClientOriginalExtension();
        
        // Simpan file ke storage lokal (storage/app/knowledge_docs)
        $path = $file->store('knowledge_docs', 'local');

        // Buat record di database
        $item = AiKnowledgeItem::create([
            'title' => $request->title,
            'source_type' => $extension,
            'source_path' => $path,
            'status' => 'pending',
            // Gunakan ID user yang sedang login (Admin)
            'created_by' => $request->user()->id, 
        ]);

        // Lempar ke Background Job (Fase 3) agar UI tidak loading lama
        ProcessIngestionJob::dispatch($item);

        return response()->json([
            'status' => 'success',
            'message' => 'Dokumen berhasil diunggah dan sedang diproses (ingestion).',
            'data' => $item
        ], 201);
    }

    /**
     * Menghapus dokumen beserta chunk embedding-nya.
     */
    public function destroy($id)
    {
        $item = AiKnowledgeItem::findOrFail($id);
        
        // Hapus file fisik dari storage
        if (Storage::disk('local')->exists($item->source_path)) {
            Storage::disk('local')->delete($item->source_path);
        }

        // Hapus record database (chunks akan otomatis terhapus karena Cascade On Delete di tabel migrasi)
        $item->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Dokumen referensi berhasil dihapus.'
        ]);
    }
}