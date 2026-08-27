<?php

namespace Tests\Feature;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionarySentenceExample;
use App\Models\MediaFile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class DictionaryReadContractTest extends TestCase
{
    use RefreshDatabase;

    public function test_categories_are_authenticated_active_ordered_and_count_only_active_entries_for_approved_roles(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        $student = User::factory()->student()->approved()->create();
        $zulu = DictionaryCategory::factory()->create(['name' => 'Zulu', 'created_by' => $admin->id]);
        $alpha = DictionaryCategory::factory()->create(['name' => 'Alpha', 'created_by' => $admin->id]);
        DictionaryCategory::factory()->inactive()->create(['name' => 'Hidden', 'created_by' => $admin->id]);
        DictionaryEntry::factory()->create(['category_id' => $alpha->id, 'created_by' => $admin->id]);
        DictionaryEntry::factory()->inactive()->create(['category_id' => $alpha->id, 'created_by' => $admin->id]);

        $this->getJson('/api/v1/dictionary/categories')->assertUnauthorized();

        foreach ([$admin, $teacher, $student] as $user) {
            $this->withToken($this->tokenFor($user))->getJson('/api/v1/dictionary/categories')
                ->assertOk()
                ->assertJsonPath('data.0.id', $alpha->id)
                ->assertJsonPath('data.0.entries_count', 1)
                ->assertJsonPath('data.1.id', $zulu->id)
                ->assertJsonCount(2, 'data');
        }
    }

    public function test_detail_exposes_safe_audio_contract_and_hides_inactive_sentences(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->approved()->create();
        $category = DictionaryCategory::factory()->create(['created_by' => $admin->id]);
        $audio = MediaFile::factory()->audio()->create(['uploaded_by' => $admin->id]);
        $sentenceAudio = MediaFile::factory()->audio()->create(['uploaded_by' => $admin->id]);
        $entry = DictionaryEntry::factory()->create(['code' => 'E1', 'category_id' => $category->id, 'audio_media_id' => $audio->id, 'created_by' => $admin->id]);
        foreach (['active', 'inactive'] as $status) {
            DictionarySentenceExample::query()->create([
                'id' => (string) Str::uuid(),
                'dictionary_entry_id' => $entry->id,
                'code' => strtoupper($status),
                'example_mekongga' => $status,
                'example_indonesia' => $status,
                'example_mekongga_normalized' => $status,
                'example_indonesia_normalized' => $status,
                'status' => $status,
                'audio_media_id' => $sentenceAudio->id,
                'created_by' => $admin->id,
            ]);
        }

        $response = $this->withToken($this->tokenFor($student))->getJson("/api/v1/dictionary/{$entry->id}")
            ->assertOk()
            ->assertJsonPath('data.code', 'E1')
            ->assertJsonCount(1, 'data.sentence_examples')
            ->assertJsonPath('data.sentence_examples.0.kode', 'ACTIVE');

        foreach (['data.audio', 'data.sentence_examples.0.audio'] as $path) {
            $this->assertEqualsCanonicalizing(
                ['id', 'url', 'mime_type', 'extension', 'size_bytes', 'checksum_sha256', 'updated_at'],
                array_keys($response->json($path)),
            );
        }
        $response->assertJsonMissingPath('data.audio.disk')
            ->assertJsonMissingPath('data.audio.path')
            ->assertJsonMissingPath('data.audio.stored_name');
    }

    public function test_default_pages_order_by_normalized_indonesian_then_uuid_and_keep_polysemy(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->approved()->create();
        $category = DictionaryCategory::factory()->create(['created_by' => $admin->id]);
        $ids = [
            '00000000-0000-0000-0000-000000000003' => ['Zulu', 'zulu'],
            '00000000-0000-0000-0000-000000000002' => ['Ápel', 'ápel'],
            '00000000-0000-0000-0000-000000000001' => ['Ápel', 'ápel'],
        ];
        foreach ($ids as $id => [$indonesia, $normalized]) {
            DictionaryEntry::factory()->create([
                'id' => $id,
                'category_id' => $category->id,
                'indonesia' => $indonesia,
                'indonesia_normalized' => $normalized,
                'created_by' => $admin->id,
            ]);
        }

        $token = $this->tokenFor($student);
        $first = $this->withToken($token)->getJson('/api/v1/dictionary?per_page=1&page=1')->assertOk();
        $second = $this->withToken($token)->getJson('/api/v1/dictionary?per_page=1&page=2')->assertOk();
        $third = $this->withToken($token)->getJson('/api/v1/dictionary?per_page=1&page=3')->assertOk();

        $this->assertSame(array_keys($ids)[2], $first->json('data.0.id'));
        $this->assertSame(array_keys($ids)[1], $second->json('data.0.id'));
        $this->assertSame(array_keys($ids)[0], $third->json('data.0.id'));
        $this->assertSame(3, $third->json('meta.total'));
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
