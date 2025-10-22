<?php
namespace App\Http\Controllers\Lecturer;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use OpenApi\Annotations as OA;

/** @OA\Tag(name="Lecturer - Profile", description="Hồ sơ giảng viên") */
class ProfileController extends Controller
{
    /** @OA\Get(
     *  path="/api/lecturer/profile", tags={"Lecturer - Profile"}, summary="Xem hồ sơ",
     *  security={{"bearerAuth":{}}},
     *  @OA\Response(response=200, description="OK")
     * ) */
    public function show(Request $request)
    {
        return Auth::user()->lecturer()->with('faculty', 'department')->first();
    }
}
