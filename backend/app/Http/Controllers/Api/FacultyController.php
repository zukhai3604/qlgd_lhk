<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Faculty;

class FacultyController extends Controller
{
    public function index()
    {
        $faculties = Faculty::query()
            ->orderBy('name')
            ->get(['id', 'code', 'name']);

        return response()->json(['data' => $faculties]);
    }
}

