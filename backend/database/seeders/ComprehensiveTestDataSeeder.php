<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Schedule;
use App\Models\LeaveRequest;
use App\Models\MakeupRequest;
use App\Models\Assignment;
use App\Models\Lecturer;
use App\Models\Timeslot;
use App\Models\Room;
use App\Models\User;
use Carbon\Carbon;

class ComprehensiveTestDataSeeder extends Seeder
{
    /**
     * Tạo dữ liệu dày đặc để test tất cả chức năng
     */
    public function run(): void
    {
        $this->command->info(' seeding Comprehensive Test Data...');

        // Tạo schedules liền kề (4 tiết) để test gộp buổi
        $this->createConsecutiveSchedules();
        
        // Tạo leave requests với nhiều trạng thái
        $this->createLeaveRequests();
        
        // Tạo makeup requests từ các leave requests đã approved
        $this->createMakeupRequests();

        $this->command->info('✅ Comprehensive Test Data seeded successfully!');
    }

    /**
     * Tạo các schedules liền kề nhau (2-4 tiết) để test chức năng gộp buổi
     */
    private function createConsecutiveSchedules(): void
    {
        $this->command->info('Creating consecutive schedules (2-4 periods)...');

        $assignments = Assignment::with(['lecturer', 'subject', 'classUnit'])
            ->whereHas('lecturer')
            ->get();

        if ($assignments->isEmpty()) {
            $this->command->warn('No assignments found. Skipping consecutive schedules.');
            return;
        }

        $rooms = Room::orderBy('code')->get();
        if ($rooms->isEmpty()) {
            $this->command->warn('No rooms found. Skipping consecutive schedules.');
            return;
        }

        $today = Carbon::today();
        
        // Tạo schedules cho các ngày: hôm qua, hôm nay, ngày mai, và 7 ngày tới
        $dates = [
            $today->copy()->subDay(), // Hôm qua
            $today, // Hôm nay
            $today->copy()->addDay(), // Ngày mai
        ];
        
        // Thêm 7 ngày tiếp theo
        for ($i = 2; $i <= 8; $i++) {
            $dates[] = $today->copy()->addDays($i);
        }

        $assignmentsCount = min(10, $assignments->count());
        
        foreach ($assignments->take($assignmentsCount) as $index => $assignment) {
            $room = $rooms[$index % $rooms->count()];
            $date = $dates[$index % count($dates)];
            
            // Tạo 2-4 tiết liền kề (tùy index để có nhiều case)
            $numPeriods = ($index % 3) + 2; // 2, 3, hoặc 4 tiết
            
            // Chọn thứ trong tuần
            $dayOfWeek = ($date->dayOfWeek == Carbon::SUNDAY) ? 1 : $date->dayOfWeek + 1; // Laravel format: 2=Mon, 7=Sat
            $startPeriod = ($index % 10) + 1; // Bắt đầu từ tiết 1-10
            
            for ($offset = 0; $offset < $numPeriods; $offset++) {
                $period = $startPeriod + $offset;
                
                if ($period > 15) break; // Không vượt quá 15 tiết
                
                $timeslot = Timeslot::where('day_of_week', $dayOfWeek)
                    ->where('code', sprintf('T%d_CA%d', $dayOfWeek, $period))
                    ->first();
                
                if (!$timeslot) continue;
                
                // Status: một số là DONE (quá khứ), một số là PLANNED (tương lai)
                $status = $date->lt(Carbon::today()) ? 'DONE' : 'PLANNED';
                
                Schedule::updateOrCreate(
                    [
                        'assignment_id' => $assignment->id,
                        'session_date' => $date->toDateString(),
                        'timeslot_id' => $timeslot->id,
                    ],
                    [
                        'room_id' => $room->id,
                        'status' => $status,
                        'note' => null,
                        'makeup_of_id' => null,
                    ]
                );
            }
        }

        $this->command->info("✅ Created consecutive schedules (2-4 periods each)");
    }

    /**
     * Tạo leave requests với nhiều trạng thái khác nhau
     */
    private function createLeaveRequests(): void
    {
        $this->command->info('Creating leave requests with various statuses...');

        // Lấy các schedules chưa có leave request (PLANNED và DONE)
        $schedules = Schedule::with(['assignment.lecturer'])
            ->whereHas('assignment.lecturer')
            ->where('status', '!=', 'CANCELED')
            ->whereDoesntHave('leaveRequests')
            ->orderBy('session_date')
            ->get();

        if ($schedules->isEmpty()) {
            $this->command->warn('No available schedules for leave requests.');
            return;
        }

        // Lấy admin để làm approver
        $admin = User::whereHas('admin')->first();
        $approverId = $admin ? $admin->id : null;

        $reasons = [
            'Ốm/khám bệnh',
            'Công tác đột xuất',
            'Việc gia đình',
            'Nghỉ phép',
            'Lý do cá nhân',
            'Hội thảo/Sự kiện',
            'Bồi dưỡng nghiệp vụ',
        ];

        $rejectionNotes = [
            'Lịch học đã được sắp xếp, không thể nghỉ vào thời điểm này',
            'Thiếu giấy tờ chứng minh',
            'Đã có quá nhiều đơn nghỉ trong kỳ này',
            'Lịch dạy bù chưa được xác nhận',
        ];

        $count = 0;
        
        // Tạo PENDING (30%)
        $pendingCount = min((int)($schedules->count() * 0.3), 20);
        foreach ($schedules->take($pendingCount) as $schedule) {
            $lecturerId = $schedule->assignment->lecturer_id;
            LeaveRequest::create([
                'schedule_id' => $schedule->id,
                'lecturer_id' => $lecturerId,
                'reason' => $reasons[array_rand($reasons)],
                'status' => 'PENDING',
                'approved_by' => null,
                'approved_at' => null,
                'note' => null,
            ]);
            $count++;
        }

        // Tạo APPROVED (30%)
        $approvedCount = min((int)($schedules->count() * 0.3), 20);
        $approvedSchedules = $schedules->skip($pendingCount)->take($approvedCount);
        foreach ($approvedSchedules as $schedule) {
            $lecturerId = $schedule->assignment->lecturer_id;
            LeaveRequest::create([
                'schedule_id' => $schedule->id,
                'lecturer_id' => $lecturerId,
                'reason' => $reasons[array_rand($reasons)],
                'status' => 'APPROVED',
                'approved_by' => $approverId,
                'approved_at' => Carbon::now()->subDays(rand(1, 7)),
                'note' => null,
            ]);
            $count++;
        }

        // Tạo REJECTED (20%)
        $rejectedCount = min((int)($schedules->count() * 0.2), 15);
        $rejectedSchedules = $schedules->skip($pendingCount + $approvedCount)->take($rejectedCount);
        foreach ($rejectedSchedules as $schedule) {
            $lecturerId = $schedule->assignment->lecturer_id;
            LeaveRequest::create([
                'schedule_id' => $schedule->id,
                'lecturer_id' => $lecturerId,
                'reason' => $reasons[array_rand($reasons)],
                'status' => 'REJECTED',
                'approved_by' => $approverId,
                'approved_at' => Carbon::now()->subDays(rand(1, 5)),
                'note' => $rejectionNotes[array_rand($rejectionNotes)],
            ]);
            $count++;
        }

        // Tạo CANCELED (20%)
        $canceledCount = min((int)($schedules->count() * 0.2), 15);
        $canceledSchedules = $schedules->skip($pendingCount + $approvedCount + $rejectedCount)->take($canceledCount);
        foreach ($canceledSchedules as $schedule) {
            $lecturerId = $schedule->assignment->lecturer_id;
            LeaveRequest::create([
                'schedule_id' => $schedule->id,
                'lecturer_id' => $lecturerId,
                'reason' => $reasons[array_rand($reasons)],
                'status' => 'CANCELED',
                'approved_by' => null,
                'approved_at' => null,
                'note' => 'Giảng viên đã hủy đơn',
            ]);
            $count++;
        }

        $this->command->info("✅ Created {$count} leave requests (PENDING, APPROVED, REJECTED, CANCELED)");
    }

    /**
     * Tạo makeup requests từ các leave requests đã APPROVED
     */
    private function createMakeupRequests(): void
    {
        $this->command->info('Creating makeup requests from approved leave requests...');

        $approvedLeaves = LeaveRequest::where('status', 'APPROVED')
            ->with(['schedule.timeslot', 'schedule.assignment'])
            ->get();

        if ($approvedLeaves->isEmpty()) {
            $this->command->warn('No approved leave requests found. Skipping makeup requests.');
            return;
        }

        $rooms = Room::orderBy('code')->get();
        if ($rooms->isEmpty()) {
            $this->command->warn('No rooms found. Skipping makeup requests.');
            return;
        }

        // Lấy admin để làm decider
        $admin = User::whereHas('admin')->first();
        $deciderId = $admin ? $admin->id : null;

        $statuses = ['PENDING', 'APPROVED', 'REJECTED'];
        $weights = [40, 40, 20]; // 40% PENDING, 40% APPROVED, 20% REJECTED

        $count = 0;
        $takeCount = min(30, $approvedLeaves->count()); // Tạo tối đa 30 makeup requests
        
        foreach ($approvedLeaves->take($takeCount) as $leave) {
            $schedule = $leave->schedule;
            if (!$schedule || !$schedule->timeslot) continue;

            // Chọn ngày dạy bù: trong vòng 1-14 ngày kể từ ngày nghỉ
            $originalDate = Carbon::parse($schedule->session_date);
            $suggestedDate = $originalDate->copy()->addDays(rand(1, 14));
            
            // Tìm timeslot cùng khung giờ trong ngày dạy bù
            $timeslotDay = $suggestedDate->dayOfWeek == Carbon::SUNDAY ? 1 : $suggestedDate->dayOfWeek + 1;
            $originalTimeslot = $schedule->timeslot;
            
            // Lấy period từ code (ví dụ: T2_CA5 -> period 5)
            preg_match('/CA(\d+)$/', $originalTimeslot->code, $matches);
            $period = isset($matches[1]) ? (int)$matches[1] : 5;
            
            $makeupTimeslot = Timeslot::where('day_of_week', $timeslotDay)
                ->where('code', sprintf('T%d_CA%d', $timeslotDay, $period))
                ->first();
            
            if (!$makeupTimeslot) {
                // Fallback: lấy timeslot đầu tiên trong ngày đó
                $makeupTimeslot = Timeslot::where('day_of_week', $timeslotDay)
                    ->orderBy('start_time')
                    ->first();
            }
            
            if (!$makeupTimeslot) continue;

            $room = $rooms[rand(0, $rooms->count() - 1)];
            
            // Chọn status với weighted random
            $random = rand(1, 100);
            $cumulative = 0;
            $selectedStatus = 'PENDING';
            foreach ($statuses as $idx => $status) {
                $cumulative += $weights[$idx];
                if ($random <= $cumulative) {
                    $selectedStatus = $status;
                    break;
                }
            }

            $makeupRequest = MakeupRequest::create([
                'leave_request_id' => $leave->id,
                'suggested_date' => $suggestedDate->toDateString(),
                'timeslot_id' => $makeupTimeslot->id,
                'room_id' => $room->id,
                'note' => $selectedStatus === 'REJECTED' ? 'Lịch này đã có buổi khác' : null,
                'status' => $selectedStatus,
                'decided_at' => $selectedStatus !== 'PENDING' ? Carbon::now()->subDays(rand(1, 3)) : null,
                'decided_by' => $selectedStatus !== 'PENDING' ? $deciderId : null,
            ]);
            
            $count++;
        }

        $this->command->info("✅ Created {$count} makeup requests (PENDING, APPROVED, REJECTED)");
    }
}
