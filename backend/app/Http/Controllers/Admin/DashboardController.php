<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Faculty;     
use App\Models\Department;  
use App\Models\User;        

class DashboardController extends Controller
{
    /**
     * Lấy các số liệu thống kê cho trang chủ admin.
     */
    public function getStats()
    {
        // Đếm tổng số Khoa
        $facultiesCount = Faculty::count();

        // Đếm tổng số Bộ môn
        $departmentsCount = Department::count();

        // Đếm tổng số người dùng có vai trò là Giảng viên
        $lecturersCount = User::where('role', 'GIANG_VIEN')->count();

        // Trả về dữ liệu dưới dạng JSON
        return response()->json([
            'faculties_count' => $facultiesCount,
            'departments_count' => $departmentsCount,
            'lecturers_count' => $lecturersCount,
        ]);
    }
}
