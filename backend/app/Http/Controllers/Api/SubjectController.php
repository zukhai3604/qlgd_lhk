<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Subject;
use Illuminate\Http\Request;

class SubjectController extends Controller
{
    /**
     * Get all subjects list
     */
    public function index(Request $request)
    {
        $query = Subject::with(['department.faculty']);

        // Optional search by name or code
        if ($request->has('search')) {
            $search = $request->input('search');
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('code', 'LIKE', "%{$search}%");
            });
        }

        // Optional filter by department
        if ($request->has('department_id')) {
            $query->where('department_id', $request->input('department_id'));
        }

        // Optional filter by faculty
        if ($request->has('faculty_id')) {
            $query->whereHas('department', function ($q) use ($request) {
                $q->where('faculty_id', $request->input('faculty_id'));
            });
        }

        $subjects = $query->orderBy('code')->get();

        return response()->json([
            'data' => $subjects,
            'message' => 'Subjects retrieved successfully',
        ]);
    }

    /**
     * Get a single subject by ID
     */
    public function show($id)
    {
        $subject = Subject::with(['department.faculty'])->findOrFail($id);

        return response()->json([
            'data' => $subject,
            'message' => 'Subject retrieved successfully',
        ]);
    }
}
