<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\SystemReport;
use App\Models\SystemReportComment;
use App\Models\SystemReportAttachment;
use App\Models\User;
use Carbon\Carbon;

class SystemReportSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::where('role', 'ADMIN')->first();
        $lecturers = User::where('role', 'GIANG_VIEN')->limit(5)->get();
        $daoTao = User::where('role', 'DAO_TAO')->first();

        if (!$admin || $lecturers->isEmpty()) {
            $this->command->warn('⚠️ Không tìm thấy user để tạo báo cáo. Vui lòng chạy UserSeeder trước.');
            return;
        }

        $reports = [
            [
                'source_type' => 'GIANG_VIEN',
                'reporter_user_id' => $lecturers[0]->id,
                'contact_email' => $lecturers[0]->email,
                'title' => 'App bị crash khi xuất file Excel',
                'description' => 'Khi tôi cố gắng xuất lịch giảng dạy ra file Excel, ứng dụng bị crash ngay lập tức. Lỗi xảy ra 100% các lần thử.',
                'category' => 'BUG',
                'severity' => 'CRITICAL',
                'status' => 'IN_PROGRESS',
                'created_at' => Carbon::now()->subDays(2),
                'updated_at' => Carbon::now()->subHours(3),
            ],
            [
                'source_type' => 'GIANG_VIEN',
                'reporter_user_id' => $lecturers[1]->id,
                'contact_email' => $lecturers[1]->email,
                'title' => 'Điểm danh sinh viên bị lag',
                'description' => 'Khi điểm danh lớp đông (>50 sv), app bị chậm rất nhiều. Mỗi lần chọn Present/Absent phải đợi 2-3 giây mới phản hồi.',
                'category' => 'PERFORMANCE',
                'severity' => 'HIGH',
                'status' => 'NEW',
                'created_at' => Carbon::now()->subHours(12),
                'updated_at' => Carbon::now()->subHours(12),
            ],
            [
                'source_type' => 'GIANG_VIEN',
                'reporter_user_id' => $lecturers[2]->id,
                'contact_email' => $lecturers[2]->email,
                'title' => 'Thiếu môn học "Trí tuệ nhân tạo nâng cao"',
                'description' => 'Môn AI302 - Trí tuệ nhân tạo nâng cao của khoa CNTT chưa có trong hệ thống. Tôi không thể tạo lịch dạy cho môn này.',
                'category' => 'DATA_ISSUE',
                'severity' => 'MEDIUM',
                'status' => 'RESOLVED',
                'created_at' => Carbon::now()->subDays(5),
                'updated_at' => Carbon::now()->subDays(1),
                'closed_at' => Carbon::now()->subDays(1),
                'closed_by' => $admin->id,
            ],
            [
                'source_type' => 'DAO_TAO',
                'reporter_user_id' => $daoTao ? $daoTao->id : null,
                'contact_email' => $daoTao ? $daoTao->email : 'daotao@tlu.edu.vn',
                'title' => 'Thêm tính năng xuất báo cáo theo học kỳ',
                'description' => 'Hiện tại chỉ xuất được báo cáo theo tháng. Cần thêm tùy chọn xuất theo học kỳ (HK1, HK2, HK3) để tiện theo dõi.',
                'category' => 'FEEDBACK',
                'severity' => 'LOW',
                'status' => 'NEW',
                'created_at' => Carbon::now()->subDays(1),
                'updated_at' => Carbon::now()->subDays(1),
            ],
            [
                'source_type' => 'GIANG_VIEN',
                'reporter_user_id' => $lecturers[3]->id,
                'contact_email' => $lecturers[3]->email,
                'title' => 'Lỗi bảo mật: Có thể xem lịch của giảng viên khác',
                'description' => 'Tôi phát hiện khi thay đổi ID trong URL /api/lecturer/schedule?lecturer_id=X, tôi có thể xem được lịch của giảng viên khác mà không cần quyền.',
                'category' => 'SECURITY',
                'severity' => 'CRITICAL',
                'status' => 'RESOLVED',
                'created_at' => Carbon::now()->subDays(7),
                'updated_at' => Carbon::now()->subDays(4),
                'closed_at' => Carbon::now()->subDays(4),
                'closed_by' => $admin->id,
            ],
            [
                'source_type' => 'GUEST',
                'reporter_user_id' => null,
                'contact_email' => 'nguyenvana@gmail.com',
                'title' => 'Không thể đăng ký tài khoản mới',
                'description' => 'Form đăng ký tài khoản giảng viên mới không hoạt động. Sau khi nhấn Submit không có phản hồi gì.',
                'category' => 'BUG',
                'severity' => 'MEDIUM',
                'status' => 'NEW',
                'created_at' => Carbon::now()->subHours(6),
                'updated_at' => Carbon::now()->subHours(6),
            ],
            [
                'source_type' => 'GIANG_VIEN',
                'reporter_user_id' => $lecturers[4]->id,
                'contact_email' => $lecturers[4]->email,
                'title' => 'Giao diện mobile không responsive',
                'description' => 'Trên điện thoại màn hình nhỏ (iPhone SE), các nút bấm bị chồng lên nhau và không nhìn thấy được toàn bộ nội dung.',
                'category' => 'FEEDBACK',
                'severity' => 'MEDIUM',
                'status' => 'IN_PROGRESS',
                'created_at' => Carbon::now()->subDays(3),
                'updated_at' => Carbon::now()->subHours(5),
            ],
        ];

        foreach ($reports as $reportData) {
            $report = SystemReport::create($reportData);

            // Thêm comments cho một số báo cáo
            if ($report->status !== 'NEW') {
                SystemReportComment::create([
                    'report_id' => $report->id,
                    'author_user_id' => $admin->id,
                    'body' => 'Cảm ơn bạn đã báo cáo. Chúng tôi đang xem xét vấn đề này.',
                    'created_at' => $report->created_at->addHours(2),
                ]);

                if ($report->status === 'RESOLVED' || $report->status === 'CLOSED') {
                    SystemReportComment::create([
                        'report_id' => $report->id,
                        'author_user_id' => $admin->id,
                        'body' => 'Vấn đề đã được khắc phục trong phiên bản mới nhất. Vui lòng kiểm tra và phản hồi.',
                        'created_at' => $report->updated_at,
                    ]);
                }
            }

            // Thêm attachments cho báo cáo nghiêm trọng
            if ($report->severity === 'CRITICAL' && $report->category === 'BUG') {
                SystemReportAttachment::create([
                    'report_id' => $report->id,
                    'file_url' => 'https://via.placeholder.com/800x600.png?text=Screenshot+Error',
                    'file_type' => 'image/png',
                    'uploaded_by' => $report->reporter_user_id,
                    'uploaded_at' => $report->created_at,
                ]);
            }
        }

        $this->command->info("✅ Đã tạo " . count($reports) . " báo cáo hệ thống mẫu");
    }
}
