<?php
/**
 * Simple test script for makeup API
 * Run: php artisan tinker < test_makeup_simple.php
 * Or: docker-compose exec workspace php artisan tinker < test_makeup_simple.php
 */

// Get a lecturer user
$user = \App\Models\User::where('role', 'GIANG_VIEN')->with('lecturer')->first();

if (!$user || !$user->lecturer) {
    echo "No lecturer found\n";
    exit;
}

echo "User: {$user->email}\n";
echo "Lecturer ID: {$user->lecturer->id}\n\n";

// Count makeup requests
$count = \App\Models\MakeupRequest::query()
    ->whereHas('leave', function ($q) use ($user) {
        $q->where('lecturer_id', $user->lecturer->id);
    })
    ->count();

echo "Makeup requests count: $count\n\n";

// Try to get one with relationships
if ($count > 0) {
    $mr = \App\Models\MakeupRequest::with([
        'leave.schedule.assignment.subject',
        'leave.schedule.assignment.classUnit',
        'leave.schedule.timeslot',
        'leave.schedule.room',
        'timeslot',
        'room',
    ])
    ->whereHas('leave', function ($q) use ($user) {
        $q->where('lecturer_id', $user->lecturer->id);
    })
    ->first();
    
    if ($mr) {
        echo "✅ Found makeup request ID: {$mr->id}\n";
        echo "Has leave: " . ($mr->leave ? 'YES' : 'NO') . "\n";
        echo "Has timeslot: " . ($mr->timeslot ? 'YES' : 'NO') . "\n";
        echo "Has room: " . ($mr->room ? 'YES' : 'NO') . "\n";
        
        // Try Resource
        try {
            $resource = new \App\Http\Resources\Lecturer\MakeupRequestResource($mr);
            $array = $resource->toArray(request());
            echo "✅ Resource toArray() successful\n";
            echo "Keys: " . implode(', ', array_keys($array)) . "\n";
        } catch (\Exception $e) {
            echo "❌ Resource error: " . $e->getMessage() . "\n";
            echo "File: {$e->getFile()}:{$e->getLine()}\n";
        }
    }
} else {
    echo "⚠️  No makeup requests found. Testing with empty query...\n";
    
    // Test empty query
    $items = \App\Models\MakeupRequest::query()
        ->whereHas('leave', function ($q) use ($user) {
            $q->where('lecturer_id', $user->lecturer->id);
        })
        ->paginate(20);
    
    echo "Paginated items: {$items->total()}\n";
    echo "✅ Query works, just no data\n";
}

echo "\n✅ Test completed\n";

