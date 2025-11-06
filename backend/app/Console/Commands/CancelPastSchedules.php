<?php

namespace App\Console\Commands;

use App\Models\Schedule;
use Carbon\Carbon;
use Illuminate\Console\Command;

class CancelPastSchedules extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'schedules:cancel-past';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Tự động hủy các buổi học đã qua thời gian';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $now = Carbon::now();
        $today = Carbon::today();
        
        $this->info("🔍 Đang kiểm tra schedules đã qua thời gian (trước {$now->format('Y-m-d H:i:s')})...");
        
        // Lấy các schedules đã qua thời gian nhưng vẫn còn PLANNED, TEACHING, hoặc MAKEUP_PLANNED
        // Bao gồm:
        // 1. Schedules có session_date < today → đã qua thời gian
        // 2. Schedules có session_date = today nhưng start_time < now (đã bắt đầu) → cancel nếu không có điểm danh
        $pastSchedules = Schedule::whereIn('status', ['PLANNED', 'TEACHING', 'MAKEUP_PLANNED'])
            ->with(['attendanceRecords', 'timeslot'])
            ->get()
            ->filter(function ($schedule) use ($now, $today) {
                // Nếu session_date < today → đã qua thời gian
                if ($schedule->session_date < $today) {
                    return true;
                }
                
                // Nếu session_date = today, kiểm tra start_time
                // Cancel nếu đã qua start_time (lớp đã bắt đầu) mà không có điểm danh
                if ($schedule->session_date->isSameDay($today) && $schedule->timeslot) {
                    $startTime = $schedule->timeslot->start_time;
                    if ($startTime) {
                        // Kết hợp session_date và start_time để so sánh với now
                        $scheduleStartDateTime = Carbon::parse($schedule->session_date->format('Y-m-d') . ' ' . $startTime);
                        // Nếu đã qua start_time → đã bắt đầu, cần kiểm tra
                        return $scheduleStartDateTime < $now;
                    }
                }
                
                return false;
            });
        
        if ($pastSchedules->isEmpty()) {
            $this->info("✅ Không có schedules nào cần cập nhật");
            return 0;
        }
        
        $this->info("📊 Tìm thấy {$pastSchedules->count()} schedules cần cập nhật");
        
        $doneCount = 0;
        $canceledCount = 0;
        
        foreach ($pastSchedules as $schedule) {
            // Kiểm tra xem có điểm danh không
            $hasAttendance = $schedule->attendanceRecords->isNotEmpty();
            
            if ($hasAttendance) {
                // Nếu có điểm danh → đánh dấu DONE
                $schedule->status = 'DONE';
                $schedule->save();
                $doneCount++;
            } else {
                // Nếu không có điểm danh → đánh dấu CANCELED
                $schedule->status = 'CANCELED';
                if (empty($schedule->note)) {
                    $schedule->note = 'Tự động hủy do đã qua thời gian';
                }
                $schedule->save();
                $canceledCount++;
            }
        }
        
        $total = $doneCount + $canceledCount;
        $this->info("✅ Đã cập nhật {$total} schedules:");
        $this->info("   - DONE: {$doneCount} (có điểm danh)");
        $this->info("   - CANCELED: {$canceledCount} (không có điểm danh)");
        
        return 0;
    }
}
