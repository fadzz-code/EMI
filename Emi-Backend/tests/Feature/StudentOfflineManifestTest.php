<?php

namespace Tests\Feature;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionarySentenceExample;
use App\Models\MediaFile;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class StudentOfflineManifestTest extends TestCase
{
    use RefreshDatabase;

    public function test_manifest_requires_authenticated_student_and_supports_stable_etag(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->approved()->create();
        $teacher = User::factory()->teacher()->approved()->create();

        $this->getJson('/api/v1/student/offline/manifest')->assertUnauthorized();
        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/student/offline/manifest')->assertForbidden();

        $response = $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/offline/manifest')
            ->assertOk()
            ->assertJsonPath('data.schema', 'emi.offline-manifest')
            ->assertJsonPath('data.schema_version', 1)
            ->assertJsonPath('data.modules', [])
            ->assertJsonStructure(['data' => ['generated_at']]);
        $etag = $response->headers->get('ETag');

        $second = $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/offline/manifest');
        $this->assertSame($response->json('data.modules'), $second->json('data.modules'));
        $this->assertSame($response->json('data.dictionaries'), $second->json('data.dictionaries'));
        $this->assertSame($etag, $second->headers->get('ETag'));
        $this->withToken($this->tokenFor($student))->withHeader('If-None-Match', $etag)->getJson('/api/v1/student/offline/manifest')->assertNotModified();
    }

    public function test_module_version_tracks_published_content_order_status_relation_and_media_without_leaking_scope(): void
    {
        $admin = User::factory()->admin()->create();
        [$student, $class] = $this->studentInClass($admin);
        $media = MediaFile::factory()->lessonImage()->create(['uploaded_by' => $admin->id]);
        $module = ClassModule::factory()->published()->create(['class_id' => $class->id, 'created_by' => $admin->id]);
        $lesson = ClassLesson::factory()->published()->create([
            'class_module_id' => $module->id,
            'created_by' => $admin->id,
            'content_type' => 'image',
            'content_body' => null,
            'media_id' => $media->id,
        ]);
        $draft = ClassLesson::factory()->create(['class_module_id' => $module->id, 'created_by' => $admin->id]);
        [, $otherClass] = $this->studentInClass($admin);
        $foreign = ClassModule::factory()->published()->create(['class_id' => $otherClass->id, 'created_by' => $admin->id]);

        $version = $this->moduleVersion($student, $module->id);
        $this->assertSame($version, $this->moduleVersion($student, $module->id));
        $response = $this->manifest($student);
        $this->assertCount(1, $response->json('data.modules'));
        $response->assertJsonMissing(['id' => $foreign->id])->assertJsonMissing(['id' => $lesson->id])->assertJsonMissing(['id' => $media->id]);

        DB::table('class_lessons')->where('id', $lesson->id)->update(['content_body' => 'isi bypass timestamp']);
        $version = $this->assertModuleVersionChanged($student, $module->id, $version);
        DB::table('class_lessons')->where('id', $lesson->id)->update(['sort_order' => 9]);
        $version = $this->assertModuleVersionChanged($student, $module->id, $version);
        DB::table('media_files')->where('id', $media->id)->update(['checksum_sha256' => hash('sha256', 'changed')]);
        $version = $this->assertModuleVersionChanged($student, $module->id, $version);
        $replacement = MediaFile::factory()->lessonImage()->create(['uploaded_by' => $admin->id]);
        DB::table('class_lessons')->where('id', $lesson->id)->update(['media_id' => $replacement->id]);
        $version = $this->assertModuleVersionChanged($student, $module->id, $version);
        DB::table('class_lessons')->where('id', $lesson->id)->update(['status' => 'archived']);
        $version = $this->assertModuleVersionChanged($student, $module->id, $version);
        DB::table('class_lessons')->where('id', $draft->id)->update(['content_body' => 'still hidden']);
        $this->assertSame($version, $this->moduleVersion($student, $module->id));
    }

    public function test_category_versions_track_visible_entry_sentence_and_audio_and_exclude_inactive_packages(): void
    {
        $admin = User::factory()->admin()->create();
        [$student] = $this->studentInClass($admin);
        $category = DictionaryCategory::factory()->create(['created_by' => $admin->id]);
        $inactiveCategory = DictionaryCategory::factory()->inactive()->create(['created_by' => $admin->id]);
        $audio = MediaFile::factory()->audio()->create(['uploaded_by' => $admin->id]);
        $entry = DictionaryEntry::factory()->create(['category_id' => $category->id, 'created_by' => $admin->id, 'audio_media_id' => $audio->id]);
        $inactiveEntry = DictionaryEntry::factory()->inactive()->create(['category_id' => $category->id, 'created_by' => $admin->id]);
        $sentenceAudio = MediaFile::factory()->audio()->create(['uploaded_by' => $admin->id]);
        $sentence = DictionarySentenceExample::query()->create([
            'id' => (string) Str::uuid(),
            'dictionary_entry_id' => $entry->id,
            'code' => 'K1',
            'example_mekongga' => 'Mekongga awal',
            'example_indonesia' => 'Indonesia awal',
            'example_mekongga_normalized' => 'mekongga awal',
            'example_indonesia_normalized' => 'indonesia awal',
            'status' => 'active',
            'audio_media_id' => $sentenceAudio->id,
            'created_by' => $admin->id,
        ]);

        $response = $this->manifest($student);
        $response->assertJsonPath('data.dictionaries.0.id', $category->id)
            ->assertJsonMissing(['id' => $inactiveCategory->id])
            ->assertJsonMissing(['id' => $entry->id])
            ->assertJsonMissing(['id' => $audio->id]);
        $version = $response->json('data.dictionaries.0.version');

        DB::table('dictionary_entries')->where('id', $entry->id)->update(['english' => 'changed']);
        $version = $this->assertDictionaryVersionChanged($student, $category->id, $version);
        DB::table('dictionary_sentence_examples')->where('id', $sentence->id)->update(['example_indonesia' => 'berubah']);
        $version = $this->assertDictionaryVersionChanged($student, $category->id, $version);
        DB::table('dictionary_sentence_examples')->where('id', $sentence->id)->update(['status' => 'inactive']);
        $version = $this->assertDictionaryVersionChanged($student, $category->id, $version);
        DB::table('dictionary_sentence_examples')->where('id', $sentence->id)->update(['example_indonesia' => 'mutasi tersembunyi']);
        DB::table('media_files')->where('id', $sentenceAudio->id)->update(['metadata' => json_encode(['duration' => 2])]);
        $this->assertSame($version, $this->dictionaryVersion($student, $category->id));
        DB::table('media_files')->where('id', $audio->id)->update(['checksum_sha256' => hash('sha256', 'entry audio changed')]);
        $version = $this->assertDictionaryVersionChanged($student, $category->id, $version);
        DB::table('dictionary_entries')->where('id', $inactiveEntry->id)->update(['english' => 'hidden changed']);
        $this->assertSame($version, $this->dictionaryVersion($student, $category->id));
    }

    private function studentInClass(User $admin): array
    {
        $school = School::factory()->create(['created_by' => $admin->id]);
        $class = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $student = User::factory()->student()->approved()->create();
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $class->id, 'assigned_by' => $admin->id]);

        return [$student, $class];
    }

    private function manifest(User $student)
    {
        return $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/offline/manifest')->assertOk();
    }

    private function moduleVersion(User $student, string $id): string
    {
        return collect($this->manifest($student)->json('data.modules'))->firstWhere('id', $id)['version'];
    }

    private function dictionaryVersion(User $student, string $id): string
    {
        return collect($this->manifest($student)->json('data.dictionaries'))->firstWhere('id', $id)['version'];
    }

    private function assertModuleVersionChanged(User $student, string $id, string $before): string
    {
        $after = $this->moduleVersion($student, $id);
        $this->assertNotSame($before, $after);

        return $after;
    }

    private function assertDictionaryVersionChanged(User $student, string $id, string $before): string
    {
        $after = $this->dictionaryVersion($student, $id);
        $this->assertNotSame($before, $after);

        return $after;
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
