<?php

namespace App\Console\Commands;

use App\Models\Schedule;
use App\Models\Assignment;
use App\Models\Timeslot;
use App\Models\Room;
use App\Models\Lecturer;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Console\Command;

class CreateTodaySchedules extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:create-today-schedules 
                            {--lecturer-name=thái sơn : Tên giảng viên}
                            {--date= : Ngày tạo (mặc định: hôm nay)}
                            {--count=9 : Số lượng schedules}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Tạo nhiều buổi học để test (mặc định: thái sơn, ngày hôm nay)';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        // Mặc định: tạo schedules cho ngày hôm nay
        $lecturerName = $this->option('lecturer-name') ?: 'thái sơn';
        $targetDate = $this->option('date') ?: Carbon::today()->toDateString(); // Ngày hôm nay động
        $targetCount = (int) ($this->option('count') ?: 9); // Mặc định 9 để tạo 3 nhóm x 3 tiết
        
        $this->info("=== Tạo buổi học để test ===");
        $this->info("Lecturer: $lecturerName");
        $this->info("Ngày: $targetDate");
        $this->info("Số lượng: $targetCount buổi học\n");

        // Tìm lecturer theo tên
        $user = User::where('role', 'GIANG_VIEN')
            ->whereRaw('LOWER(name) LIKE ?', ['%' . strtolower($lecturerName) . '%'])
            ->first();

        if (!$user) {
            $this->error("❌ Không tìm thấy lecturer với tên: $lecturerName");
            return 1;
        }

        $lecturer = $user->lecturer;
        if (!$lecturer) {
            $this->error("❌ User không có lecturer profile");
            return 1;
        }

        $lecturerId = $lecturer->id;
        $this->info("✅ Tìm thấy: {$user->name} (Lecturer ID: $lecturerId)\n");

        // Parse ngày
        try {
            $targetDateObj = Carbon::parse($targetDate);
            $targetDateStr = $targetDateObj->toDateString();
        } catch (\Exception $e) {
            $this->error("❌ Ngày không hợp lệ: $targetDate");
            return 1;
        }

        // Lấy assignments của lecturer
        $assignments = Assignment::where('lecturer_id', $lecturerId)
            ->with(['subject', 'classUnit'])
            ->get();

        if ($assignments->isEmpty()) {
            $this->error("❌ Không tìm thấy assignment nào cho lecturer: {$user->name}");
            $this->info("Hãy tạo assignment trước.");
            return 1;
        }

        $this->info("📚 Tìm thấy " . $assignments->count() . " assignment(s)\n");

        // Lấy timeslots theo ngày đích
        $dayOfWeek = $targetDateObj->dayOfWeek; // 0=CN, 1=T2, ..., 6=T7
        $timeslotDay = $dayOfWeek === 0 ? 7 : $dayOfWeek; // Convert: CN=7

        $timeslots = Timeslot::where('day_of_week', $timeslotDay)
            ->orderBy('start_time')
            ->get();

        if ($timeslots->isEmpty()) {
            // Fallback: lấy tất cả timeslots nếu không có timeslot cho ngày đó
            $timeslots = Timeslot::orderBy('day_of_week')->orderBy('start_time')->limit(20)->get();
        }

        if ($timeslots->isEmpty()) {
            $this->error("❌ Không tìm thấy timeslot nào");
            return 1;
        }

        $this->info("⏰ Tìm thấy " . $timeslots->count() . " timeslot(s)\n");

        // Lấy rooms
        $rooms = Room::orderBy('code')->get();
        if ($rooms->isEmpty()) {
            $this->error("❌ Không tìm thấy room nào");
            return 1;
        }

        $this->info("🏫 Tìm thấy " . $rooms->count() . " room(s)\n");

        // Tạo schedules GỘP (grouped sessions) để test
        // Điều kiện gộp: cùng assignment, cùng ngày, cùng phòng, các tiết liên tiếp
        
        $roomIndex = 0;
        $created = 0;
        $skipped = 0;
        $assignmentIndex = 0;
        
        // Tạo các nhóm buổi học gộp
        // Mỗi nhóm: 2-4 tiết liên tiếp, cùng assignment, cùng room, cùng ngày
        while ($created < $targetCount && $assignmentIndex < $assignments->count()) {
            $assignment = $assignments[$assignmentIndex % $assignments->count()];
            $assignmentIndex++;
            
            // Chọn một room cho nhóm này
            $room = $rooms[$roomIndex % $rooms->count()];
            $roomIndex++;
            
            // Tạo 2-4 tiết liên tiếp (để test grouped sessions)
            $groupSize = min(3, $targetCount - $created); // Tạo 3 tiết liên tiếp
            if ($groupSize < 1) break;
            
            // Lấy các timeslots liên tiếp
            // Tìm nhóm timeslots liên tiếp (end_time của tiết trước = start_time của tiết sau, hoặc gap <= 60 phút)
            $consecutiveTimeslots = [];
            $bestGroup = [];
            $bestGroupSize = 0;
            
            // Duyệt qua tất cả timeslots để tìm nhóm liên tiếp dài nhất
            for ($i = 0; $i < $timeslots->count(); $i++) {
                $currentGroup = [$timeslots[$i]];
                
                // Tìm các timeslots liên tiếp từ vị trí này
                for ($j = $i + 1; $j < $timeslots->count() && count($currentGroup) < $groupSize; $j++) {
                    $lastTs = end($currentGroup);
                    $nextTs = $timeslots[$j];
                    
                    // Tính gap giữa end_time của tiết trước và start_time của tiết sau
                    $lastEnd = $this->timeToMinutes($lastTs->end_time);
                    $nextStart = $this->timeToMinutes($nextTs->start_time);
                    
                    // Liên tiếp nếu: end_time = start_time hoặc gap <= 60 phút
                    if ($lastEnd > 0 && $nextStart > 0) {
                        $gap = $nextStart - $lastEnd;
                        if ($gap >= 0 && $gap <= 60) {
                            $currentGroup[] = $nextTs;
                        } else {
                            break; // Không liên tiếp nữa
                        }
                    } else {
                        break;
                    }
                }
                
                // Nếu nhóm này đủ lớn và tốt hơn nhóm trước, lưu lại
                if (count($currentGroup) >= min(2, $groupSize) && count($currentGroup) > $bestGroupSize) {
                    $bestGroup = $currentGroup;
                    $bestGroupSize = count($currentGroup);
                }
                
                // Nếu đã tìm được nhóm đủ lớn, dừng
                if ($bestGroupSize >= $groupSize) break;
            }
            
            // Sử dụng nhóm tốt nhất tìm được
            if (count($bestGroup) >= 2) {
                $consecutiveTimeslots = array_slice($bestGroup, 0, $groupSize);
            } else {
                // Nếu không tìm được nhóm liên tiếp, lấy các timeslots đầu tiên
                $consecutiveTimeslots = $timeslots->take($groupSize)->all();
            }
            
            // Status cho nhóm: PLANNED hoặc TEACHING để có thể test kết thúc
            $groupStatus = ($created % 2 === 0) ? 'PLANNED' : 'TEACHING';
            
            $this->info("\n📦 Tạo nhóm buổi học gộp ({$groupSize} tiết):");
            $this->info("   Môn: {$assignment->subject->name}");
            $this->info("   Lớp: {$assignment->classUnit->code}");
            $this->info("   Phòng: {$room->code}");
            $this->info("   Status: $groupStatus");
            
            // Tạo từng tiết trong nhóm
            foreach ($consecutiveTimeslots as $timeslot) {
                // Kiểm tra xem đã tồn tại chưa
                $exists = Schedule::where('assignment_id', $assignment->id)
                    ->where('session_date', $targetDateStr)
                    ->where('timeslot_id', $timeslot->id)
                    ->exists();
                
                if ($exists) {
                    $this->warn("   ⏭️  Đã tồn tại: {$timeslot->code} - Xóa để tạo mới");
                    // Xóa schedule cũ để tạo mới
                    Schedule::where('assignment_id', $assignment->id)
                        ->where('session_date', $targetDateStr)
                        ->where('timeslot_id', $timeslot->id)
                        ->delete();
                }
                
                try {
                    Schedule::create([
                        'assignment_id' => $assignment->id,
                        'session_date' => $targetDateStr,
                        'timeslot_id' => $timeslot->id,
                        'room_id' => $room->id,
                        'status' => $groupStatus, // Cùng status cho cả nhóm
                        'note' => null,
                        'makeup_of_id' => null,
                    ]);
                    
                    $created++;
                    $this->info("   ✅ [$created/$targetCount] {$timeslot->code} ({$timeslot->start_time} - {$timeslot->end_time})");
                } catch (\Exception $e) {
                    $this->error("   ❌ Lỗi khi tạo {$timeslot->code}: {$e->getMessage()}");
                    continue;
                }
            }
            
            // Nếu đã đủ số lượng, dừng
            if ($created >= $targetCount) break;
        }

        $this->info("\n=== Kết quả ===");
        $this->info("✅ Đã tạo: $created buổi học");
        $this->info("⏭️  Đã bỏ qua: $skipped buổi học (đã tồn tại)");
        $this->info("\nHoàn thành!");

        return 0;
    }
    
    /**
     * Chuyển đổi thời gian (HH:MM:SS hoặc HH:MM) thành số phút
     */
    private function timeToMinutes($timeStr)
    {
        if (empty($timeStr)) return 0;
        
        $parts = explode(':', $timeStr);
        if (count($parts) >= 2) {
            $hours = (int) $parts[0];
            $minutes = (int) $parts[1];
            return $hours * 60 + $minutes;
        }
        
        return 0;
    }
}

