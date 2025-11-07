<?php

namespace App\Observers;

use App\Models\SystemReport;
use App\Models\Notification;
use App\Models\Admin;

class SystemReportObserver
{
    public function created(SystemReport $report): void
    {
        // Gửi thông báo cho tất cả admin
        $adminUserIds = Admin::pluck('user_id'); // bảng admins đã có

        $rows = $adminUserIds->map(function ($uid) use ($report) {
            return [
                'receiver_id' => $uid,
                'type'        => 'report',
                'title'       => 'Báo cáo mới',
                'content'     => $report->title,
                'data'        => json_encode([
                    'report_id' => $report->id,
                    'severity'  => $report->severity,
                    'category'  => $report->category,
                    'source'    => $report->source_type,
                ]),
                'created_at'  => now(),
            ];
        })->toArray();

        if (!empty($rows)) {
            Notification::insert($rows);
        }
    }
}
