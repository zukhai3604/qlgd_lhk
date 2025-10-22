<?php

namespace Tests\Feature;

use App\Models\Lecturer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LecturerReportTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->artisan('migrate');
        $this->seed();
    }

    public function testLecturerCanViewOwnReport(): void
    {
        $user = User::where('email', 'nguyenvanan@tlu.edu.vn')->firstOrFail();
        $lecturer = $user->lecturer ?? Lecturer::where('user_id', $user->id)->firstOrFail();

        Sanctum::actingAs($user, ['*']);

        $response = $this->getJson(sprintf(
            '/api/reports/lecturers/%d?semester=2025-2026%%20HK1',
            $lecturer->id
        ));

        $response->assertOk()
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'subject_id',
                        'subject_code',
                        'subject_name',
                        'total_sessions',
                        'done_sessions',
                        'canceled_sessions',
                        'upcoming_sessions',
                        'total_periods',
                        'done_periods',
                        'progress_ratio',
                        'progress_text',
                    ],
                ],
                'meta' => [
                    'lecturer_id',
                ],
            ]);

        $payload = $response->json('data');
        $this->assertIsArray($payload);
        $this->assertNotEmpty($payload);

        $first = $payload[0];
        $this->assertEquals(
            $first['done_sessions'] + $first['canceled_sessions'] + $first['upcoming_sessions'],
            $first['total_sessions']
        );
        $this->assertMatchesRegularExpression('/^\d+\/\d+ buổi$/', $first['progress_text']);
    }

    public function testLecturerCannotViewOthersReport(): void
    {
        $user = User::where('email', 'nguyenvanan@tlu.edu.vn')->firstOrFail();
        $otherLecturer = Lecturer::where('user_id', '!=', $user->id)->first();
        $this->assertNotNull($otherLecturer, 'Seed must provide multiple lecturers');

        Sanctum::actingAs($user, ['*']);

        $response = $this->getJson(sprintf('/api/reports/lecturers/%d', $otherLecturer->id));
        $response->assertForbidden();
    }
}

