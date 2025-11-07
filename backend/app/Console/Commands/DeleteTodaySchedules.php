<?php

namespace App\Console\Commands;

use App\Models\Schedule;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Console\Command;

class DeleteTodaySchedules extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:delete-today-schedules {--lecturer-name=thái sơn} {--date=} {--all}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Xóa schedules cho ngày hôm nay (hoặc ngày chỉ định)';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $lecturerName = $this->option('lecturer-name');
        $targetDate = $this->option('date') ?: Carbon::today()->toDateString();
        $deleteAll = $this->option('all');
        
        $this->info("=== Xóa schedules ===");
        $this->info("Ngày: $targetDate");
        
        // Mặc định xóa tất cả schedules của ngày
        $this->info("Chế độ: Xóa TẤT CẢ schedules của ngày\n");
        
        $countBefore = Schedule::whereDate('session_date', $targetDate)->count();
        $this->info("📊 Số schedules trước khi xóa: $countBefore");
        
        if ($countBefore === 0) {
            $this->warn("⚠️  Không có schedules nào để xóa");
            return 0;
        }
        
        $deleted = Schedule::whereDate('session_date', $targetDate)->delete();
        $this->info("✅ Đã xóa: $deleted schedules");
        
        $countAfter = Schedule::whereDate('session_date', $targetDate)->count();
        $this->info("📊 Số schedules sau khi xóa: $countAfter");
        $this->info("✅ Hoàn thành!");
        
        return 0;
        
        // Code cũ: chỉ xóa của lecturer cụ thể (đã comment)
        /*
        
        */
    }
}

