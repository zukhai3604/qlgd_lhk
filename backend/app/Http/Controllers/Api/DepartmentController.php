<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Department;
use Illuminate\Http\Request;

class DepartmentController extends Controller
{
    public function index(Request $request)
    {
        $query = Department::query()
            ->with('faculty:id,code,name')
            ->orderBy('name')
            ->select(['id', 'code', 'name', 'faculty_id']);

        if ($request->filled('faculty_id')) {
            $query->where('faculty_id', $request->integer('faculty_id'));
        }

        return response()->json(['data' => $query->get()]);
    }
}

