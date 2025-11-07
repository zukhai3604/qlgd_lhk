<?php

namespace App\Http\Controllers\Api\TrainingDepartment;

use App\Http\Controllers\Controller;
use App\Models\LeaveRequest;
use App\Models\MakeupRequest;
use Illuminate\Http\Request;

class RequestController extends Controller
{
    /**
     * GET /api/training_department/requests?type=leave|makeup&status=...&per_page=...
     * Return requests for Training Department to review, with nested info for UI.
     */
    public function index(Request $request)
    {
        $type = strtolower($request->query('type', 'leave'));
        $status = $request->query('status'); // PENDING | APPROVED | REJECTED | CANCELED
        $perPage = (int) ($request->query('per_page', 20));
        $perPage = $perPage > 0 && $perPage <= 200 ? $perPage : 20;

        if ($type === 'makeup') {
            $q = MakeupRequest::query()
                ->with([
                    'leave.schedule.assignment.subject',
                    'leave.schedule.assignment.classUnit',
                    'leave.schedule.timeslot',
                    'leave.lecturer.user',
                ])
                ->orderByDesc('id');
            if ($status) { $q->where('status', $status); }
            // Use simplePaginate to avoid expensive COUNT(*) on large tables
            $p = $q->simplePaginate($perPage);

            $data = [];
            foreach ($p->items() as $it) {
                $leave = $it->leave;
                $schedule = optional($leave)->schedule;
                $assignment = optional($schedule)->assignment;
                $lecturer = optional($leave)->lecturer;

                $data[] = [
                    'id' => $it->id,
                    'status' => $it->status,
                    'suggested_date' => optional($it->suggested_date)->format('Y-m-d'),
                    'lecturer' => [ // provide top-level lecturer for UI convenience
                        'id' => $lecturer?->id,
                        'name' => optional($lecturer?->user)->name,
                    ],
                    'leave_request' => [
                        'id' => $leave?->id,
                        'status' => $leave?->status,
                        'lecturer' => [
                            'id' => $lecturer?->id,
                            'name' => optional($lecturer?->user)->name,
                        ],
                        'schedule' => [
                            'id' => $schedule?->id,
                            'session_date' => optional($schedule?->session_date)->format('Y-m-d'),
                            'timeslot' => $schedule?->timeslot ? [
                                'id' => $schedule->timeslot->id,
                                'start_time' => $schedule->timeslot->start_time,
                                'end_time' => $schedule->timeslot->end_time,
                            ] : null,
                            'assignment' => $assignment ? [
                                'id' => $assignment->id,
                                'subject' => $assignment->subject ? [
                                    'id' => $assignment->subject->id,
                                    'name' => $assignment->subject->name,
                                ] : null,
                                'class_unit' => $assignment->classUnit ? [
                                    'id' => $assignment->classUnit->id,
                                    'name' => $assignment->classUnit->name,
                                ] : null,
                            ] : null,
                        ],
                    ],
                ];
            }

            return response()->json([
                'data' => $data,
                'meta' => [
                    // simplePaginate doesn't compute total; exposing lightweight meta
                    'per_page' => $p->perPage(),
                    'current_page' => $p->currentPage(),
                    'next_page_url' => $p->nextPageUrl(),
                    'prev_page_url' => $p->previousPageUrl(),
                ],
            ]);
        }

        // default: leave
        $q = LeaveRequest::query()
            ->with([
                'schedule.assignment.subject',
                'schedule.assignment.classUnit',
                'schedule.timeslot',
                'lecturer.user',
            ])
            ->orderByDesc('id');
        if ($status) { $q->where('status', $status); }
    // Use simplePaginate to avoid expensive COUNT(*) on large tables
    $p = $q->simplePaginate($perPage);

        $data = [];
        foreach ($p->items() as $it) {
            $schedule = optional($it)->schedule;
            $assignment = optional($schedule)->assignment;
            $lecturer = optional($it)->lecturer;

            $data[] = [
                'id' => $it->id,
                'status' => $it->status,
                'lecturer' => [
                    'id' => $lecturer?->id,
                    'name' => optional($lecturer?->user)->name,
                ],
                'schedule' => [
                    'id' => $schedule?->id,
                    'session_date' => optional($schedule?->session_date)->format('Y-m-d'),
                    'timeslot' => $schedule?->timeslot ? [
                        'id' => $schedule->timeslot->id,
                        'start_time' => $schedule->timeslot->start_time,
                        'end_time' => $schedule->timeslot->end_time,
                    ] : null,
                    'assignment' => $assignment ? [
                        'id' => $assignment->id,
                        'subject' => $assignment->subject ? [
                            'id' => $assignment->subject->id,
                            'name' => $assignment->subject->name,
                        ] : null,
                        'class_unit' => $assignment->classUnit ? [
                            'id' => $assignment->classUnit->id,
                            'name' => $assignment->classUnit->name,
                        ] : null,
                    ] : null,
                ],
            ];
        }

        return response()->json([
            'data' => $data,
            'meta' => [
                // simplePaginate doesn't compute total; exposing lightweight meta
                'per_page' => $p->perPage(),
                'current_page' => $p->currentPage(),
                'next_page_url' => $p->nextPageUrl(),
                'prev_page_url' => $p->previousPageUrl(),
            ],
        ]);
    }
}
