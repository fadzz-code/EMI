<?php

namespace App\Services;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Smalot\PdfParser\Parser;

class AiPdfSourceIngestionService
{
    public const PLACEHOLDER_CONTENT = 'Dokumen PDF telah diproses sebagai sumber Basis AI. Isi lengkap disimpan per halaman dan digunakan untuk pencarian Chatbot AI.';

    public function __construct(
        private readonly AiKnowledgeChunkingService $chunkingService,
        private readonly AuditLogService $auditLogService,
        private readonly AiPdfPageClassifier $pageClassifier,
    ) {}

    public function import(array $data, UploadedFile $file, User $actor, Request $request): array
    {
        return DB::transaction(function () use ($data, $file, $actor, $request): array {
            $filename = Str::uuid().'.pdf';
            $path = $file->storeAs('ai-knowledge-sources', $filename, 'public');
            $sourceUrl = $path ? Storage::disk('public')->url($path) : null;

            $item = AiKnowledgeItem::query()->create([
                'title' => $data['title'],
                'category' => $data['category'] ?? null,
                'content' => self::PLACEHOLDER_CONTENT,
                'source_type' => 'pdf',
                'source_url' => $sourceUrl,
                'status' => $data['status'] ?? 'draft',
                'created_by' => $actor->id,
            ]);

            $pages = $this->extractPages(file_get_contents($file->getRealPath()));
            $skippedCount = 0;

            foreach ($pages as $page) {
                if ($page['skipped']) {
                    $skippedCount++;

                    continue;
                }

                $item->sourcePages()->create([
                    'page_number' => $page['page_number'],
                    'content' => $page['content'],
                    'content_hash' => hash('sha256', $page['content']),
                    'char_count' => mb_strlen($page['content']),
                    'word_count' => str_word_count($page['content']),
                    'metadata' => $page['metadata'],
                ]);
            }

            if (! $item->sourcePages()->exists()) {
                throw new Exception('PDF tidak memiliki teks yang dapat dibaca. PDF hasil scan/foto belum didukung tanpa OCR.');
            }

            $chunkCount = $this->chunkingService->rebuild($item->refresh());
            $this->auditLogService->record('ai_knowledge_item.created', $item, $actor, null, $item->only(['title', 'category', 'source_type', 'status']), [], $request);

            return [
                'item_id' => $item->id,
                'page_count' => $item->sourcePages()->count(),
                'chunk_count' => $chunkCount,
                'skipped_page_count' => $skippedCount,
                'source_url' => $sourceUrl,
            ];
        });
    }

    private function extractPages(string $pdfContent): array
    {
        if (strpos($pdfContent, '%PDF') !== 0) {
            throw new Exception('File bukan PDF yang valid.');
        }

        $pdf = (new Parser)->parseContent($pdfContent);
        $pages = [];

        foreach ($pdf->getPages() as $index => $page) {
            $pageNumber = $index + 1;
            $original = trim($page->getText());
            $classification = $this->pageClassifier->classify($original, $pageNumber);
            $cleaned = $classification['content'];
            $skipReason = in_array($classification['page_type'], ['empty', 'low_quality_ocr'], true) ? $classification['skip_reason'] : null;

            $pages[] = [
                'page_number' => $pageNumber,
                'content' => $cleaned,
                'skipped' => $skipReason !== null,
                'metadata' => [
                    'source' => 'pdf',
                    'page_number' => $pageNumber,
                    'original_char_count' => mb_strlen($original),
                    'cleaned_char_count' => mb_strlen($cleaned),
                    'skipped_reason' => $skipReason,
                    'page_type' => $classification['page_type'],
                    'searchable' => $classification['searchable'],
                    'skip_reason' => $classification['skip_reason'],
                    'ocr_noise_score' => $classification['ocr_noise_score'],
                ],
            ];
        }

        return $pages;
    }

}
