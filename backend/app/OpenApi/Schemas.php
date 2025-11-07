<?php

namespace App\OpenApi;

use OpenApi\Annotations as OA;

/**
 * @OA\Schema(
 *   schema="ErrorResponse",
 *   @OA\Property(property="message", type="string", example="Thông tin xác thực không hợp lệ."),
 *   @OA\Property(property="errors", type="object", nullable=true)
 * )
 *
 * @OA\Schema(
 *   schema="UserResource",
 *   required={"id","name","email","role"},
 *   @OA\Property(property="id", type="integer", example=12),
 *   @OA\Property(property="name", type="string", example="Nguyễn Văn A"),
 *   @OA\Property(property="email", type="string", format="email", example="giangvien@qlgd.test"),
 *   @OA\Property(property="role", type="string", example="GIANG_VIEN"),
 *   @OA\Property(property="is_active", type="boolean", example=true)
 * )
 *
 * @OA\Schema(
 *   schema="PaginationMeta",
 *   @OA\Property(property="current_page", type="integer", example=1),
 *   @OA\Property(property="per_page", type="integer", example=15),
 *   @OA\Property(property="total", type="integer", example=120)
 * )
 *
 * @OA\Schema(
 *   schema="PaginatedUsers",
 *   @OA\Property(
 *     property="data",
 *     type="array",
 *     @OA\Items(ref="#/components/schemas/UserResource")
 *   ),
 *   @OA\Property(property="links", type="object"),
 *   @OA\Property(property="meta", ref="#/components/schemas/PaginationMeta")
 * )
 *
 * @OA\Schema(
 *   schema="ScheduleItem",
 *   @OA\Property(property="id", type="integer", example=345),
 *   @OA\Property(property="session_date", type="string", format="date", example="2025-10-21"),
 *   @OA\Property(property="status", type="string", example="PLANNED"),
 *   @OA\Property(property="start_time", type="string", example="07:00"),
 *   @OA\Property(property="end_time", type="string", example="08:45"),
 *   @OA\Property(
 *     property="assignment",
 *     type="object",
 *     @OA\Property(property="semester_label", type="string", example="2025-2026 HK1"),
 *     @OA\Property(
 *       property="subject",
 *       type="object",
 *       @OA\Property(property="id", type="integer", example=50),
 *       @OA\Property(property="code", type="string", example="CT101"),
 *       @OA\Property(property="name", type="string", example="Cấu trúc dữ liệu")
 *     ),
 *     @OA\Property(
 *       property="classUnit",
 *       type="object",
 *       @OA\Property(property="id", type="integer", example=88),
 *       @OA\Property(property="code", type="string", example="LHP01"),
 *       @OA\Property(property="name", type="string", example="Lớp HP 01")
 *     )
 *   ),
 *   @OA\Property(
 *     property="room",
 *     type="object",
 *     nullable=true,
 *     @OA\Property(property="id", type="integer", example=12),
 *     @OA\Property(property="code", type="string", example="B3-201"),
 *     @OA\Property(property="name", type="string", example="Phòng B3-201")
 *   )
 * )
 *
 * @OA\Schema(
 *   schema="LecturerProfile",
 *   @OA\Property(property="id", type="integer", example=7),
 *   @OA\Property(property="user_id", type="integer", example=12),
 *   @OA\Property(property="full_name", type="string", example="Nguyễn Văn A"),
 *   @OA\Property(property="date_of_birth", type="string", format="date", nullable=true, example="1990-05-12"),
 *   @OA\Property(property="gender", type="string", nullable=true, example="Nam"),
 *   @OA\Property(property="phone", type="string", nullable=true, example="0901123456"),
 *   @OA\Property(property="email", type="string", example="giangvien@qlgd.test"),
 *   @OA\Property(property="department", type="string", nullable=true, example="Bộ môn Hệ thống Thông tin"),
 *   @OA\Property(property="faculty", type="string", nullable=true, example="Khoa Công nghệ Thông tin"),
 *   @OA\Property(property="avatar_url", type="string", nullable=true, example="https://cdn.qlgd.test/avatars/12.png")
 * )
 *
 * @OA\Schema(
 *   schema="LeaveRequestResource",
 *   @OA\Property(property="id", type="integer", example=100),
 *   @OA\Property(property="schedule_id", type="integer", example=345),
 *   @OA\Property(property="lecturer_id", type="integer", example=7),
 *   @OA\Property(property="reason", type="string", example="Ốm đột xuất"),
 *   @OA\Property(property="status", type="string", example="PENDING"),
 *   @OA\Property(property="approved_by", type="integer", nullable=true, example=2),
 *   @OA\Property(property="approved_at", type="string", format="date-time", nullable=true),
 *   @OA\Property(property="note", type="string", nullable=true),
 *   @OA\Property(
 *     property="schedule",
 *     ref="#/components/schemas/ScheduleItem"
 *   )
 * )
 *
 * @OA\Schema(
 *   schema="MakeupRequestResource",
 *   @OA\Property(property="id", type="integer", example=200),
 *   @OA\Property(property="leave_request_id", type="integer", example=100),
 *   @OA\Property(property="suggested_date", type="string", format="date", example="2025-10-28"),
 *   @OA\Property(property="timeslot_id", type="integer", example=4),
 *   @OA\Property(property="room_id", type="integer", nullable=true, example=8),
 *   @OA\Property(property="status", type="string", example="PENDING"),
 *   @OA\Property(property="note", type="string", nullable=true),
 *   @OA\Property(property="decided_at", type="string", format="date-time", nullable=true),
 *   @OA\Property(property="decided_by", type="integer", nullable=true)
 * )
 *
 * @OA\Schema(
 *   schema="NotificationResource",
 *   @OA\Property(property="id", type="integer", example=501),
 *   @OA\Property(property="type", type="string", example="LEAVE_RESPONSE"),
 *   @OA\Property(property="title", type="string", example="Đơn nghỉ đã được duyệt"),
 *   @OA\Property(property="body", type="string", example="Phòng Đào tạo đã duyệt đơn nghỉ ngày 21/10."),
 *   @OA\Property(property="status", type="string", example="UNREAD"),
 *   @OA\Property(property="created_at", type="string", format="date-time", example="2025-10-20T14:00:00+07:00")
 * )
 *

 *
 * @OA\Schema(
 *   schema="TeachingSessionResource",
 *   @OA\Property(property="id", type="integer", example=345),
 *   @OA\Property(property="session_date", type="string", format="date", example="2025-10-21"),
 *   @OA\Property(property="status", type="string", example="PLANNED"),
 *   @OA\Property(property="note", type="string", nullable=true),
 *   @OA\Property(property="start_time", type="string", example="07:00"),
 *   @OA\Property(property="end_time", type="string", example="08:45"),
 *   @OA\Property(property="attendance_locked", type="boolean", example=false),
 *   @OA\Property(
 *     property="assignment",
 *     type="object",
 *     @OA\Property(property="semester_label", type="string", example="2025-2026 HK1"),
 *     @OA\Property(property="subject_name", type="string", example="Cấu trúc dữ liệu"),
 *     @OA\Property(property="class_name", type="string", example="Lớp HP 01")
 *   )
 * )
 *
 * @OA\Schema(
 *   schema="AttendancePayloadItem",
 *   required={"student_id","status"},
 *   @OA\Property(property="student_id", type="integer", example=1001),
 *   @OA\Property(property="status", type="string", example="PRESENT"),
 *   @OA\Property(property="note", type="string", nullable=true)
 * )
 *
 * @OA\Schema(
 *   schema="TeachingStat",
 *   @OA\Property(property="total_hours", type="number", format="float", example=120.5),
 *   @OA\Property(property="total_sessions", type="integer", example=48),
 *   @OA\Property(property="year", type="string", example="2025-2026"),
 *   @OA\Property(property="semester", type="string", example="HK1")
 * )
 */
class Schemas
{
}
