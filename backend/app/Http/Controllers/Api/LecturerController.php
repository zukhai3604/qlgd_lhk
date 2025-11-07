<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Lecturer;
use Illuminate\Http\Request;

class LecturerController extends Controller
{
    /**
     * Display a listing of lecturers.
     */
    public function index(Request $request)
    {
        $query = Lecturer::with(['user', 'department.faculty']);

        // Search by name (từ user.name)
        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%");
            });
        }

        // Filter by department_id
        if ($request->has('department_id') && !empty($request->department_id)) {
            $query->where('department_id', $request->department_id);
        }

        // Filter by faculty_id via department
        if ($request->has('faculty_id') && !empty($request->faculty_id)) {
            $query->whereHas('department', function ($q) use ($request) {
                $q->where('faculty_id', $request->faculty_id);
            });
        }

        // Filter by degree - Commented out vì field degree không tồn tại trong migration
        // if ($request->has('degree') && !empty($request->degree)) {
        //     $query->where('degree', $request->degree);
        // }

        // Lấy dữ liệu và sắp xếp theo user.name
        $lecturers = $query->get()->sortBy(function ($lecturer) {
            return $lecturer->user?->name;
        })->values();

        return response()->json([
            'data' => $lecturers,
            'message' => 'Lecturers retrieved successfully',
        ]);
    }

    /**
     * Display the specified lecturer.
     */
    public function show($id)
    {
        $lecturer = Lecturer::with(['user', 'department.faculty'])->findOrFail($id);

        return response()->json([
            'data' => $lecturer,
            'message' => 'Lecturer retrieved successfully',
        ]);
    }
}
