<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\AttendanceRecord;
use App\Models\Schedule;
use App\Models\ClassUnit;
use App\Models\Student;
use App\Models\User;
use Carbon\Carbon;

class AttendanceRecordSeeder extends Seeder
{
    public function run(): void
    {
        $this->command->info('Creating attendance records...');

        // Lấy các schedule đã DONE hoặc TEACHING (các buổi đã diễn ra hoặc đang diễn ra)
        $schedules = Schedule::with(['assignment.classUnit.students'])
            ->whereIn('status', ['DONE', 'TEACHING'])
            ->whereHas('assignment.classUnit')
            ->get();

        if ($schedules->isEmpty()) {
            $this->command->warn('No schedules with DONE/TEACHING status found. Skipping AttendanceRecordSeeder.');
            return;
        }

        // Lấy giảng viên hoặc admin để làm người điểm danh
        $marker = User::whereHas('lecturer')->first() ?? User::whereHas('admin')->first();
        $markerId = $marker ? $marker->id : null;

        $statuses = ['PRESENT', 'ABSENT', 'LATE', 'EXCUSED'];
        $statusWeights = [75, 10, 10, 5]; // 75% có mặt, 10% vắng, 10% muộn, 5% có phép

        $notes = [
            null,
            null,
            null,
            'Nghỉ có phép',
            'Có lý do',
            'Báo trước',
            null,
            null,
            'Đi muộn 10 phút',
            'Đi muộn 15 phút',
        ];

        $totalRecords = 0;
        $schedulesProcessed = 0;

        foreach ($schedules as $schedule) {
            $classUnit = $schedule->assignment->classUnit;
            
            if (!$classUnit) continue;

            // Lấy danh sách sinh viên trong lớp
            $students = $classUnit->students()->orderBy('code')->get();
            
            if ($students->isEmpty()) {
                continue;
            }

            // Tạo điểm danh cho một phần sinh viên (80-95% sinh viên có điểm danh)
            $attendanceRate = rand(80, 95) / 100;
            $studentsToMark = $students->random((int)($students->count() * $attendanceRate));

            foreach ($studentsToMark as $student) {
                // Chọn status với weighted random
                $random = rand(1, 100);
                $cumulative = 0;
                $selectedStatus = 'PRESENT';
                
                foreach ($statuses as $idx => $status) {
                    $cumulative += $statusWeights[$idx];
                    if ($random <= $cumulative) {
                        $selectedStatus = $status;
                        break;
                    }
                }

                // Chọn note (chỉ có note nếu ABSENT hoặc EXCUSED hoặc một số LATE)
                $note = null;
                if ($selectedStatus === 'ABSENT' || $selectedStatus === 'EXCUSED') {
                    $note = $notes[array_rand($notes)];
                } elseif ($selectedStatus === 'LATE' && rand(0, 1)) {
                    $note = $notes[array_rand(['Đi muộn 10 phút', 'Đi muộn 15 phút'])];
                }

                // Thời gian điểm danh: trong khoảng thời gian của buổi học
                $sessionDate = Carbon::parse($schedule->session_date);
                $timeslot = $schedule->timeslot;
                
                if ($timeslot && $timeslot->start_time) {
                    $startTime = Carbon::parse($timeslot->start_time);
                    $markedAt = $sessionDate->copy()
                        ->setTime($startTime->hour, $startTime->minute)
                        ->addMinutes(rand(0, 30)); // Điểm danh trong 30 phút đầu
                } else {
                    $markedAt = $sessionDate->copy()->setTime(7, rand(0, 30));
                }

                AttendanceRecord::updateOrCreate(
                    [
                        'schedule_id' => $schedule->id,
                        'student_id' => $student->id,
                    ],
                    [
                        'status' => $selectedStatus,
                        'note' => $note,
                        'marked_by' => $markerId,
                        'marked_at' => $markedAt,
                    ]
                );

                $totalRecords++;
            }

            $schedulesProcessed++;
        }

        $this->command->info("✅ Created {$totalRecords} attendance records for {$schedulesProcessed} schedules");
    }
}

