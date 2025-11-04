<?php

namespace App\Http\Resources\Lecturer;

use Illuminate\Http\Resources\Json\JsonResource;

class MakeupRequestResource extends JsonResource
{
    public function toArray($request)
    {
        $mr = $this->resource;
        
        if (!$mr) {
            return [];
        }
        
        try {
            // Đơn giản hóa: Controller đã eager load tất cả relationships, chỉ cần truy cập trực tiếp
            $leave = $mr->leave;
            $schedule = $leave?->schedule ?? null;
            $timeslot = $mr->timeslot ?? null;
            $room = $mr->room ?? null;
            
            $assignment = $schedule?->assignment ?? null;
            $subject = $assignment?->subject ?? null;
            $classUnit = $assignment?->classUnit ?? null;
            $originalTimeslot = $schedule?->timeslot ?? null;
            
            return [
                'id' => $mr->id,
                'leave_request_id' => $mr->leave_request_id,
                'suggested_date' => $mr->suggested_date?->format('Y-m-d'),
                'makeup_date' => $mr->suggested_date?->format('Y-m-d'), // Alias cho frontend
                'timeslot_id' => $mr->timeslot_id,
                'room_id' => $mr->room_id,
                'note' => $mr->note,
                'status' => $mr->status,
                'decided_by' => $mr->decided_by,
                'decided_at' => optional($mr->decided_at)->toDateTimeString(),
                
                // Thông tin môn học từ leave request -> schedule -> assignment
                'subject' => $subject?->name ?? '',
                'subject_name' => $subject?->name ?? '',
                'subject_code' => $subject?->code ?? '',
                'class_name' => $classUnit?->name ?? '',
                'class_code' => $classUnit?->code ?? '',
                
                // Thông tin khung giờ
                'start_time' => $timeslot?->start_time ?? '',
                'end_time' => $timeslot?->end_time ?? '',
                'timeslot' => $timeslot ? [
                    'id' => $timeslot->id,
                    'code' => $timeslot->code ?? '',
                    'start_time' => $timeslot->start_time ?? '',
                    'end_time' => $timeslot->end_time ?? '',
                ] : ($mr->timeslot_id ? [
                    'id' => $mr->timeslot_id,
                    'code' => '',
                    'start_time' => '',
                    'end_time' => '',
                ] : null),
                
                // Thông tin phòng
                'room' => $room ? [
                    'id' => $room->id,
                    'code' => $room->code ?? '',
                    'name' => $room->code ?? $room->building ?? '',
                ] : null,
                'room_name' => $room ? ($room->code ?? $room->building ?? '') : '',
                
                // Thông tin buổi học gốc (buổi học nghỉ)
                'leave' => $leave ? [
                    'id' => $leave->id,
                    'schedule_id' => $leave->schedule_id,
                    'reason' => $leave->reason ?? '',
                    'original_date' => $schedule?->session_date?->format('Y-m-d') ?? '',
                    'original_time' => $originalTimeslot ? [
                        'start_time' => $originalTimeslot->start_time ?? '',
                        'end_time' => $originalTimeslot->end_time ?? '',
                    ] : null,
                    // Include nested schedule data for frontend extraction
                    'schedule' => $schedule ? [
                        'id' => $schedule->id,
                        'session_date' => $schedule->session_date?->format('Y-m-d') ?? '',
                        'assignment' => $assignment ? [
                            'subject' => $subject ? [
                                'id' => $subject->id,
                                'code' => $subject->code ?? '',
                                'name' => $subject->name ?? '',
                            ] : null,
                            'classUnit' => $classUnit ? [
                                'id' => $classUnit->id,
                                'code' => $classUnit->code ?? '',
                                'name' => $classUnit->name ?? '',
                            ] : null,
                        ] : null,
                        'timeslot' => ($originalTimeslot ?? null) ? [
                            'id' => $originalTimeslot->id ?? null,
                            'code' => $originalTimeslot->code ?? '',
                            'start_time' => $originalTimeslot->start_time ?? '',
                            'end_time' => $originalTimeslot->end_time ?? '',
                        ] : null,
                        'room' => ($schedule && ($schedule->room ?? null) ? [
                            'id' => $schedule->room->id ?? null,
                            'code' => $schedule->room->code ?? '',
                            'name' => $schedule->room->code ?? $schedule->room->building ?? '',
                        ] : null),
                    ] : null,
                ] : ($mr->leave_request_id ? [
                    // Nếu không load được leave, vẫn trả về basic structure với ID
                    'id' => $mr->leave_request_id,
                    'schedule_id' => null,
                    'reason' => '',
                    'original_date' => '',
                    'original_time' => null,
                    'schedule' => null,
                ] : null),
                'original_date' => $schedule?->session_date?->format('Y-m-d') ?? '',
                'original_start_time' => $originalTimeslot?->start_time ?? '',
                'original_end_time' => $originalTimeslot?->end_time ?? '',
                'leave_reason' => $leave?->reason ?? '',
            ];
        } catch (\Exception $e) {
            \Log::error('MakeupRequestResource::toArray error', [
                'id' => $mr->id ?? null,
                'error' => $e->getMessage(),
                'file' => $e->getFile(),
                'line' => $e->getLine(),
            ]);
            
            // Fallback: return basic data
            return [
                'id' => $mr->id ?? null,
                'leave_request_id' => $mr->leave_request_id ?? null,
                'suggested_date' => $mr->suggested_date?->format('Y-m-d'),
                'makeup_date' => $mr->suggested_date?->format('Y-m-d'),
                'timeslot_id' => $mr->timeslot_id ?? null,
                'room_id' => $mr->room_id ?? null,
                'note' => $mr->note ?? null,
                'status' => $mr->status ?? null,
                'subject' => '',
                'subject_name' => '',
                'class_name' => '',
                'start_time' => '',
                'end_time' => '',
                'timeslot' => null,
                'room' => null,
                'leave' => null,
                'original_date' => '',
                'original_start_time' => '',
                'original_end_time' => '',
                'leave_reason' => '',
            ];
        }
    }
}


