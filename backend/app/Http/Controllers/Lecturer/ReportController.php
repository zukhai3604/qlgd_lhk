<?php
namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Schedule;
use OpenApi\Annotations as OA;

/** @OA\Tag(name="Lecturer - Report", description="Báo cáo/bút ký buổi học") */
class ReportController extends Controller
{
    /** @OA\Post(
     *  path="/api/lecturer/schedule/{id}/report", tags={"Lecturer - Report"}, summary="Nộp báo cáo",
     *  security={{"bearerAuth":{}}},
     *  @OA\Parameter(name="id", in="path", required=true, @OA\Schema(type="integer")),
     *  @OA\RequestBody(required=true, @OA\JsonContent(
     *    required={"content"},
     *    @OA\Property(property="content", type="string", description="Nội dung chính đã dạy"),
     *    @OA\Property(property="note", type="string", nullable=true, description="Ghi chú thêm")
     *  )),
     *  @OA\Response(response=201, description="Created")
     * ) */
    public function store(Request $request, Schedule $schedule)
    {
        // Logic lưu báo cáo
    }
}
