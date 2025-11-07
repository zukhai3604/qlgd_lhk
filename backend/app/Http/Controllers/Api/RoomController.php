<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Room;
use Illuminate\Http\Request;

class RoomController extends Controller
{
    /**
     * Display a listing of rooms.
     */
    public function index(Request $request)
    {
        $query = Room::query();

        // Search by name or code
        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('code', 'LIKE', "%{$search}%");
            });
        }

        // Filter by building
        if ($request->has('building') && !empty($request->building)) {
            $query->where('building', $request->building);
        }

        // Filter by room_type
        if ($request->has('room_type') && !empty($request->room_type)) {
            $query->where('room_type', $request->room_type);
        }

        $rooms = $query->orderBy('code')->get();

        return response()->json([
            'data' => $rooms,
            'message' => 'Rooms retrieved successfully',
        ]);
    }

    /**
     * Display the specified room.
     */
    public function show($id)
    {
        $room = Room::findOrFail($id);

        return response()->json([
            'data' => $room,
            'message' => 'Room retrieved successfully',
        ]);
    }
}
