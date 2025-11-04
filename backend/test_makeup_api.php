<?php
/**
 * Script test API makeup-requests endpoint
 * Usage: php test_makeup_api.php
 */

require __DIR__ . '/vendor/autoload.php';

$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);

// Get test user (lecturer)
$user = \App\Models\User::where('role', 'GIANG_VIEN')->with('lecturer')->first();

if (!$user || !$user->lecturer) {
    echo "❌ Không tìm thấy giảng viên để test\n";
    exit(1);
}

echo "✅ Tìm thấy user: {$user->email} (Lecturer ID: {$user->lecturer->id})\n\n";

// Create token
$token = $user->createToken('test')->plainTextToken;
echo "✅ Đã tạo token: " . substr($token, 0, 20) . "...\n\n";

// Test API endpoint
$baseUrl = 'http://localhost:8888';
$url = "$baseUrl/api/lecturer/makeup-requests";

$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'Accept: application/json',
        'Authorization: Bearer ' . $token,
    ],
    CURLOPT_TIMEOUT => 10,
]);

echo "🔍 Testing: GET $url\n";
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "📊 Response:\n";
echo "HTTP Status: $httpCode\n";

if ($error) {
    echo "❌ cURL Error: $error\n";
    exit(1);
}

if ($httpCode !== 200) {
    echo "❌ HTTP Error: $httpCode\n";
    echo "Response: $response\n";
    exit(1);
}

$data = json_decode($response, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    echo "❌ JSON Parse Error: " . json_last_error_msg() . "\n";
    echo "Raw Response: $response\n";
    exit(1);
}

echo "✅ Response parsed successfully\n\n";

echo "📋 Data Structure:\n";
echo "- Has 'data': " . (isset($data['data']) ? 'YES' : 'NO') . "\n";
echo "- Has 'links': " . (isset($data['links']) ? 'YES' : 'NO') . "\n";
echo "- Has 'meta': " . (isset($data['meta']) ? 'YES' : 'NO') . "\n";

if (isset($data['data']) && is_array($data['data'])) {
    $count = count($data['data']);
    echo "- Data count: $count\n";
    
    if ($count > 0) {
        echo "\n📝 First item keys: " . implode(', ', array_keys($data['data'][0])) . "\n";
        
        $first = $data['data'][0];
        echo "\n📄 First item sample:\n";
        echo "  - id: " . ($first['id'] ?? 'N/A') . "\n";
        echo "  - subject: " . ($first['subject'] ?? $first['subject_name'] ?? 'N/A') . "\n";
        echo "  - class_name: " . ($first['class_name'] ?? 'N/A') . "\n";
        echo "  - status: " . ($first['status'] ?? 'N/A') . "\n";
        echo "  - has timeslot: " . (isset($first['timeslot']) ? 'YES' : 'NO') . "\n";
        echo "  - has room: " . (isset($first['room']) ? 'YES' : 'NO') . "\n";
        echo "  - has leave: " . (isset($first['leave']) ? 'YES' : 'NO') . "\n";
    } else {
        echo "\n⚠️  No makeup requests found (empty array)\n";
    }
}

echo "\n✅ Test completed successfully!\n";
