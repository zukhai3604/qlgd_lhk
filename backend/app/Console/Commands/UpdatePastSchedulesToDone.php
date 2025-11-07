<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class UpdatePastSchedulesToDone extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'app:update-past-schedules-to-done';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Cập nhật tất cả schedules đã quá thời gian (trước hôm nay hoặc hôm nay đã quá end_time) thành DONE';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('=== Cập nhật schedules đã quá thời gian thành DONE ===');
        
        $today = \Carbon\Carbon::today();
        $now = \Carbon\Carbon::now();
        $this->info("Ngày hôm nay: {$today->toDateString()}");
        $this->info("Thời gian hiện tại: {$now->format('H:i:s')}\n");
        
        // 1. Schedules trước hôm nay
        $pastCount = \App\Models\Schedule::whereDate('session_date', '<', $today)
            ->whereNotIn('status', ['DONE', 'CANCELED'])
            ->count();
        
        // 2. Schedules hôm nay nhưng đã quá thời gian (end_time < now)
        $todayPastTimeCount = \App\Models\Schedule::whereDate('session_date', $today)
            ->whereNotIn('status', ['DONE', 'CANCELED'])
            ->whereHas('timeslot', function($query) use ($now) {
                $query->where('end_time', '<', $now->format('H:i:s'));
            })
            ->count();
        
        $totalCount = $pastCount + $todayPastTimeCount;
        
        if ($totalCount === 0) {
            $this->info('✅ Không có schedules nào cần cập nhật.');
            return 0;
        }
        
        $this->info("Tìm thấy {$totalCount} schedules cần cập nhật:");
        $this->info("  - Trước hôm nay: {$pastCount}");
        $this->info("  - Hôm nay đã quá thời gian: {$todayPastTimeCount}\n");
        
        // Cập nhật schedules trước hôm nay
        $updatedPast = 0;
        if ($pastCount > 0) {
            $updatedPast = \App\Models\Schedule::whereDate('session_date', '<', $today)
                ->whereNotIn('status', ['DONE', 'CANCELED'])
                ->update(['status' => 'DONE']);
        }
        
        // Cập nhật schedules hôm nay đã quá thời gian
        $updatedToday = 0;
        if ($todayPastTimeCount > 0) {
            $updatedToday = \App\Models\Schedule::whereDate('session_date', $today)
                ->whereNotIn('status', ['DONE', 'CANCELED'])
                ->whereHas('timeslot', function($query) use ($now) {
                    $query->where('end_time', '<', $now->format('H:i:s'));
                })
                ->update(['status' => 'DONE']);
        }
        
        $this->info("✅ Đã cập nhật:");
        $this->info("  - Schedules trước hôm nay: {$updatedPast}");
        $this->info("  - Schedules hôm nay đã quá thời gian: {$updatedToday}");
        $this->info("\nHoàn thành!");
        
        return 0;
    }
}

