docker compose exec workspace bash -lc 'cat > app/OpenApi/Schemas.php << "PHP"
<?php
use OpenApi\Annotations as OA;

/**
 * @OA\Schema(schema="User",
 *   @OA\Property(property="id", type="integer", example=1),
 *   @OA\Property(property="name", type="string", example="Nguyen Van A"),
 *   @OA\Property(property="email", type="string", format="email", example="lecturer@tlu.edu.vn"),
 *   @OA\Property(property="role", type="string", example="GIANG_VIEN")
 * )
 *
 * @OA\Schema(schema="Error",
 *   @OA\Property(property="message", type="string"),
 *   @OA\Property(property="errors", type="object", nullable=true)
 * )
 *
 * @OA\Schema(schema="PaginatedUsers",
 *   @OA\Property(property="data", type="array", @OA\Items(ref="#/components/schemas/User")),
 *   @OA\Property(property="links", type="object"),
 *   @OA\Property(property="meta", type="object")
 * )
 */
PHP'
