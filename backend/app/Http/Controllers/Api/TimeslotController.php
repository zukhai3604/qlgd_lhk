<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Timeslot;
use Illuminate\Http\Request;
use OpenApi\Annotations as OA;

class TimeslotController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/timeslots",
     *   operationId="listTimeslots",
     *   tags={"Danh mục"},
     *   summary="Danh sách khung giờ học",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="day_of_week",
     *     in="query",
     *     description="Lọc theo thứ trong tuần (2=Mon, 3=Tue, ..., 7=Sat)",
     *     required=false,
     *     @OA\Schema(type="integer", example=2)
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Danh sách khung giờ học",
     *     @OA\JsonContent(
     *       @OA\Property(
     *         property="data",
     *         type="array",
     *         @OA\Items(
     *           type="object",
     *           @OA\Property(property="id", type="integer", example=1),
     *           @OA\Property(property="code", type="string", example="T2_CA1"),
     *           @OA\Property(property="day_of_week", type="integer", example=2),
     *           @OA\Property(property="start_time", type="string", format="time", example="07:00:00"),
     *           @OA\Property(property="end_time", type="string", format="time", example="07:50:00"),
     *           @OA\Property(property="period", type="integer", example=1, description="Số tiết (1-15)")
     *         )
     *       )
     *     )
     *   ),
     *   @OA\Response(
     *     response=401,
     *     description="Chưa xác thực",
     *     @OA\JsonContent(ref="#/components/schemas/ErrorResponse")
     *   )
     * )
     */
    public function index(Request $request)
    {
        $query = Timeslot::query();
        
        if ($request->has('day_of_week')) {
            $dayOfWeek = (int) $request->query('day_of_week');
            if ($dayOfWeek >= 1 && $dayOfWeek <= 7) {
                $query->where('day_of_week', $dayOfWeek);
            }
        }
        
        $timeslots = $query->orderBy('day_of_week')->orderBy('start_time')->get();
        
        // Thêm period number vào response bằng cách parse từ code
        $timeslots = $timeslots->map(function ($timeslot) {
            $period = null;
            // Parse code như "T2_CA1" -> period = 1
            if (preg_match('/CA(\d+)$/', $timeslot->code, $matches)) {
                $period = (int) $matches[1];
            }
            
            return [
                'id' => $timeslot->id,
                'code' => $timeslot->code,
                'day_of_week' => $timeslot->day_of_week,
                'start_time' => $timeslot->start_time,
                'end_time' => $timeslot->end_time,
                'period' => $period,
            ];
        });
        
        return response()->json(['data' => $timeslots]);
    }
    
    /**
     * @OA\Get(
     *   path="/api/timeslots/by-period",
     *   operationId="getTimeslotByPeriod",
     *   tags={"Danh mục"},
     *   summary="Lấy timeslot_id từ day_of_week và period",
     *   security={{"bearerAuth":{}}},
     *   @OA\Parameter(
     *     name="day_of_week",
     *     in="query",
     *     description="Thứ trong tuần (2=Mon, 3=Tue, ..., 7=Sat)",
     *     required=true,
     *     @OA\Schema(type="integer", example=2)
     *   ),
     *   @OA\Parameter(
     *     name="period",
     *     in="query",
     *     description="Số tiết (1-15)",
     *     required=true,
     *     @OA\Schema(type="integer", example=1)
     *   ),
     *   @OA\Response(
     *     response=200,
     *     description="Thông tin timeslot",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", type="object",
     *         @OA\Property(property="id", type="integer", example=1),
     *         @OA\Property(property="code", type="string", example="T2_CA1"),
     *         @OA\Property(property="day_of_week", type="integer", example=2),
     *         @OA\Property(property="start_time", type="string", example="07:00:00"),
     *         @OA\Property(property="end_time", type="string", example="07:50:00"),
     *         @OA\Property(property="period", type="integer", example=1)
     *       )
     *     )
     *   ),
     *   @OA\Response(response=404, description="Không tìm thấy timeslot"),
     *   @OA\Response(response=422, description="Tham số không hợp lệ")
     *   )
     */
    public function getByPeriod(Request $request)
    {
        $dayOfWeek = $request->query('day_of_week');
        $period = $request->query('period');
        
        if (!$dayOfWeek || !$period) {
            return response()->json([
                'message' => 'Tham số day_of_week và period là bắt buộc'
            ], 422);
        }
        
        $dayOfWeek = (int) $dayOfWeek;
        $period = (int) $period;
        
        if ($dayOfWeek < 1 || $dayOfWeek > 7) {
            return response()->json([
                'message' => 'day_of_week phải từ 1 đến 7'
            ], 422);
        }
        
        if ($period < 1 || $period > 15) {
            return response()->json([
                'message' => 'period phải từ 1 đến 15'
            ], 422);
        }
        
        $code = sprintf('T%d_CA%d', $dayOfWeek, $period);
        $timeslot = Timeslot::where('code', $code)->first();
        
        if (!$timeslot) {
            return response()->json([
                'message' => 'Không tìm thấy timeslot với code: ' . $code
            ], 404);
        }
        
        return response()->json([
            'data' => [
                'id' => $timeslot->id,
                'code' => $timeslot->code,
                'day_of_week' => $timeslot->day_of_week,
                'start_time' => $timeslot->start_time,
                'end_time' => $timeslot->end_time,
                'period' => $period,
            ]
        ]);
    }
}
