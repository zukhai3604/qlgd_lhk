<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ClassUnit;
use Illuminate\Http\Request;

class ClassUnitController extends Controller
{
    /**
     * Get all classes list
     */
    public function index(Request $request)
    {
        $query = ClassUnit::with(['department.faculty']);

        // Optional search by name
        if ($request->has('search')) {
            $search = $request->input('search');
            $query->where('name', 'LIKE', "%{$search}%");
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

        $classes = $query->orderBy('name')->get();

        return response()->json([
            'data' => $classes,
            'message' => 'Classes retrieved successfully',
        ]);
    }

    /**
     * Get a single class by ID
     */
    public function show($id)
    {
        $class = ClassUnit::with(['department.faculty'])->findOrFail($id);

        return response()->json([
            'data' => $class,
            'message' => 'Class retrieved successfully',
        ]);
    }
}
