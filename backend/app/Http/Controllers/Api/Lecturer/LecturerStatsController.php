<?php

namespace App\Http\Controllers\Api\Lecturer;

use App\Http\Controllers\Controller;
use App\Models\Schedule;
use App\Models\LeaveRequest;
use App\Models\MakeupRequest;
use App\Models\Semester;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use OpenApi\Annotations as OA;

class LecturerStatsController extends Controller
{
    /**
     * @OA\Get(
     *   path="/api/lecturer/stats",
     *   operationId="lecturerStats",
     *   tags={"Lecturer - Thống kê"},
     *   summary="Thống kê theo học kỳ hiện tại",
     *   security={{"bearerAuth":{}}},
     *   @OA\Response(
     *     response=200,
     *     description="Thống kê tổng quan",
     *     @OA\JsonContent(
     *       @OA\Property(property="data", type="object",
     *         @OA\Property(property="taught", type="integer", example=10),
     *         @OA\Property(property="remaining", type="integer", example=34),
     *         @OA\Property(property="leave_count", type="integer", example=0),
     *         @OA\Property(property="makeup_count", type="integer", example=2)
     *       ),
     *       @OA\Property(property="semester", type="object", nullable=true)
     *     )
     *   )
     * )
     */
    public function index(Request $request): JsonResponse
    {
        $lecturerId = optional($request->user()->lecturer)->id;
        
        if (!$lecturerId) {
            return response()->json(['message' => 'Forbidden'], 403);
        }
        
        // Lấy học kỳ hiện tại tự động dựa trên date range
        // Logic: Ưu tiên học kỳ đang diễn ra (start_date <= today <= end_date)
        // Nếu không có, lấy học kỳ gần nhất theo start_date
        $currentSemester = Semester::getCurrentOrLatest();
        
        if (!$currentSemester) {
            return response()->json([
                'data' => [
                    'taught' => 0,
                    'remaining' => 0,
                    'leave_count' => 0,
                    'makeup_count' => 0,
                ],
                'semester' => null,
            ]);
        }
        
        // Lấy tất cả schedules để group thành "buổi học"
        // Load cả leaveRequests và makeupRequests để tránh N+1 queries
        $schedules = Schedule::whereHas('assignment', function($q) use ($lecturerId, $currentSemester) {
            $q->where('lecturer_id', $lecturerId)
              ->where('semester_id', $currentSemester->id);
        })
        ->with([
            'assignment.subject', 
            'assignment.classUnit', 
            'timeslot', 
            'room', 
            'leaveRequests' => function($q) {
                $q->where('status', 'APPROVED');
            }
        ])
        ->get()
        ->sortBy(function($schedule) {
            // Sort theo session_date và start_time (giống frontend)
            $date = $schedule->session_date ? $schedule->session_date->format('Y-m-d') : '9999-99-99';
            $time = $schedule->timeslot && $schedule->timeslot->start_time 
                ? $schedule->timeslot->start_time 
                : '99:99:99';
            return $date . ' ' . $time;
        })
        ->values();
        
        // Group các schedules liền kề thành "buổi học"
        $groupedSessions = $this->groupConsecutiveSchedules($schedules);
        
        // DEBUG: Log để kiểm tra (có thể xóa sau khi test)
        \Log::info('Stats Debug', [
            'total_schedules' => $schedules->count(),
            'total_groups' => count($groupedSessions),
            'groups_with_multiple' => collect($groupedSessions)->filter(function($g) {
                return count($g['schedules']) > 1;
            })->count(),
            'taught_count' => collect($groupedSessions)->filter(function($group) {
                $firstSchedule = $group['schedules'][0];
                return in_array($firstSchedule->status, ['DONE', 'MAKEUP_DONE']);
            })->count(),
            'remaining_count' => collect($groupedSessions)->filter(function($group) {
                $firstSchedule = $group['schedules'][0];
                return in_array($firstSchedule->status, ['PLANNED', 'TEACHING', 'MAKEUP_PLANNED']);
            })->count(),
            'sample_group' => count($groupedSessions) > 0 ? [
                'schedules_count' => count($groupedSessions[0]['schedules']),
                'first_schedule_id' => $groupedSessions[0]['schedules'][0]->id ?? null,
                'first_status' => $groupedSessions[0]['schedules'][0]->status ?? null,
            ] : null,
        ]);
        
        // Đếm theo groups (buổi học) thay vì từng schedule
        $stats = [
            'taught' => collect($groupedSessions)->filter(function($group) {
                // Vì các tiết trong cùng buổi học thường cùng status,
                // nên chỉ cần kiểm tra tiết đầu tiên trong group
                $firstSchedule = $group['schedules'][0];
                return in_array($firstSchedule->status, ['DONE', 'MAKEUP_DONE']);
            })->count(),
            
            'remaining' => collect($groupedSessions)->filter(function($group) {
                // Kiểm tra tiết đầu tiên trong group
                $firstSchedule = $group['schedules'][0];
                return in_array($firstSchedule->status, ['PLANNED', 'TEACHING', 'MAKEUP_PLANNED']);
            })->count(),
            
            // Đếm số buổi học có ít nhất 1 schedule có leave request approved
            'leave_count' => collect($groupedSessions)->filter(function($group) {
                foreach ($group['schedules'] as $schedule) {
                    // leaveRequests đã được filter với status APPROVED trong query
                    if ($schedule->leaveRequests->isNotEmpty()) {
                        return true;
                    }
                }
                return false;
            })->count(),
            
            // Đếm số buổi học có ít nhất 1 schedule dạy bù đã được dạy (status = MAKEUP_DONE)
            'makeup_count' => collect($groupedSessions)->filter(function($group) {
                foreach ($group['schedules'] as $schedule) {
                    // Chỉ đếm những buổi dạy bù đã được dạy (status = MAKEUP_DONE)
                    if ($schedule->status === 'MAKEUP_DONE') {
                        return true;
                    }
                }
                return false;
            })->count(),
        ];
        
        return response()->json([
            'data' => $stats,
            'semester' => [
                'id' => $currentSemester->id,
                'code' => $currentSemester->code,
                'name' => $currentSemester->name,
                'start_date' => $currentSemester->start_date->format('Y-m-d'),
                'end_date' => $currentSemester->end_date->format('Y-m-d'),
            ]
        ]);
    }
    
    /**
     * Group các schedules liền kề thành "buổi học"
     * Logic tương tự frontend: cùng môn, cùng lớp, cùng phòng, cùng ngày, cùng ca, cách nhau <= 60 phút
     */
    private function groupConsecutiveSchedules($schedules)
    {
        if ($schedules->isEmpty()) {
            return [];
        }
        
        $groups = [];
        $processed = [];
        
        foreach ($schedules as $index => $schedule) {
            if (in_array($index, $processed)) {
                continue;
            }
            
            $group = [$schedule];
            $processed[] = $index;
            
            // Tìm các schedules liền kề tiếp theo
            for ($j = $index + 1; $j < $schedules->count(); $j++) {
                if (in_array($j, $processed)) {
                    continue;
                }
                
                $next = $schedules[$j];
                
                // So sánh với schedule CUỐI CÙNG trong group (không phải schedule đầu tiên)
                $lastInGroup = $group[count($group) - 1];
                
                // Kiểm tra điều kiện gộp
                if ($this->canGroupSchedules($lastInGroup, $next)) {
                    $group[] = $next;
                    $processed[] = $j;
                } else {
                    break; // Không liền kề nữa, dừng lại
                }
            }
            
            $groups[] = [
                'schedules' => $group,
                'session_date' => $group[0]->session_date,
                'assignment_id' => $group[0]->assignment_id,
            ];
        }
        
        return $groups;
    }
    
    /**
     * Kiểm tra 2 schedules có thể gộp thành 1 buổi học không
     * Điều kiện (giống frontend):
     * - Cùng ngày (session_date)
     * - Cùng assignment (cùng môn học, cùng lớp)
     * - Cùng phòng (so sánh room name/code giống frontend)
     * - Cùng ca (morning/afternoon/evening) - nếu cả 2 đều null thì coi như cùng ca
     * - Thời gian liền kề (cách nhau <= 60 phút)
     */
    private function canGroupSchedules($schedule1, $schedule2): bool
    {
        // Phải cùng ngày (so sánh string để tránh vấn đề với Carbon)
        $date1 = $schedule1->session_date ? $schedule1->session_date->format('Y-m-d') : null;
        $date2 = $schedule2->session_date ? $schedule2->session_date->format('Y-m-d') : null;
        if ($date1 !== $date2) {
            return false;
        }
        
        // Phải cùng assignment (cùng môn, cùng lớp)
        if ($schedule1->assignment_id != $schedule2->assignment_id) {
            return false;
        }
        
        // Phải cùng phòng (so sánh room name/code giống frontend)
        // Frontend: room['name'] ?? room['code'] ?? '-'
        $room1 = $this->getRoomLabel($schedule1);
        $room2 = $this->getRoomLabel($schedule2);
        if ($room1 !== $room2) {
            return false;
        }
        
        // Phải cùng ca (morning/afternoon/evening)
        // Nếu cả 2 đều null, coi như cùng ca (cho phép group)
        $shift1 = $this->getShiftFromSchedule($schedule1);
        $shift2 = $this->getShiftFromSchedule($schedule2);
        if ($shift1 === null && $shift2 === null) {
            // Cả 2 đều null, tiếp tục check các điều kiện khác
        } elseif ($shift1 !== $shift2) {
            return false;
        }
        
        // Kiểm tra thời gian liền kề (cách nhau <= 60 phút)
        if (!$schedule1->timeslot || !$schedule2->timeslot) {
            return false;
        }
        
        if (!$schedule1->timeslot->end_time || !$schedule2->timeslot->start_time) {
            return false;
        }
        
        // Parse time với cùng ngày để tính gap chính xác
        $date = $schedule1->session_date ? $schedule1->session_date->format('Y-m-d') : date('Y-m-d');
        $end1 = \Carbon\Carbon::parse($date . ' ' . $schedule1->timeslot->end_time);
        $start2 = \Carbon\Carbon::parse($date . ' ' . $schedule2->timeslot->start_time);
        
        // Tính gap: start2 - end1 (phải >= 0 và <= 60 phút)
        // diffInMinutes trả về số âm nếu start2 > end1, nên ta tính thủ công
        $gapMinutes = round(($start2->timestamp - $end1->timestamp) / 60);
        
        // Nếu start2 < end1 (overlap hoặc sai thứ tự), gap sẽ âm → không group được
        if ($gapMinutes < 0) {
            return false;
        }
        
        // Gap phải >= 0 (không overlap) và <= 60 phút
        return $gapMinutes <= 60;
    }
    
    /**
     * Lấy room label từ schedule (giống frontend)
     * Frontend logic: room['name'] ?? room['code'] ?? '-'
     * Backend API trả về: room['name'] = code ?? building
     * Đảm bảo so sánh chính xác giống frontend
     */
    private function getRoomLabel($schedule): string
    {
        if (!$schedule->room) {
            return '-';
        }
        
        $room = $schedule->room;
        // Frontend: room['name'] ?? room['code'] ?? '-'
        // API response: room['name'] = code ?? building
        // Vậy frontend sẽ lấy: (code ?? building) ?? code ?? '-'
        // Đơn giản hóa: code ?? building ?? '-'
        $code = $room->code ?? null;
        $building = $room->building ?? null;
        $name = $code ?? $building;
        
        return trim($name ?? '-');
    }
    
    /**
     * Lấy ca (shift) từ schedule: morning, afternoon, evening
     */
    private function getShiftFromSchedule($schedule): ?string
    {
        if (!$schedule->timeslot) {
            return null;
        }
        
        // Parse period từ timeslot code (ví dụ: T2_CA5 -> period = 5)
        $code = $schedule->timeslot->code;
        if (preg_match('/CA(\d+)$/', $code, $matches)) {
            $period = (int) $matches[1];
            
            // Tiết 1-6: morning, 7-12: afternoon, 13-15: evening
            if ($period >= 1 && $period <= 6) {
                return 'morning';
            } elseif ($period >= 7 && $period <= 12) {
                return 'afternoon';
            } elseif ($period >= 13 && $period <= 15) {
                return 'evening';
            }
        }
        
        // Fallback: dựa vào start_time
        $startTime = $schedule->timeslot->start_time;
        $minutes = \Carbon\Carbon::parse($startTime)->hour * 60 + \Carbon\Carbon::parse($startTime)->minute;
        
        if ($minutes >= 420 && $minutes < 720) { // 07:00 - 12:00
            return 'morning';
        } elseif ($minutes >= 720 && $minutes < 1080) { // 12:00 - 18:00
            return 'afternoon';
        } elseif ($minutes >= 1080) { // >= 18:00
            return 'evening';
        }
        
        return null;
    }
}
