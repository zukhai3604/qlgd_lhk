<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\TrainingStaff;
use App\Models\User;

class TrainingStaffSeeder extends Seeder
{
    public function run(): void
    {
        $staff = User::where('role', 'DAO_TAO')->get(['id','email']);

        foreach ($staff as $u) {
            $position = $u->email === 'dao_tao@qlgd.test' ? 'TRUONG_PHONG' : 'CAN_BO_DAO_TAO';

            TrainingStaff::updateOrCreate(
                ['user_id' => $u->id],
                [
                    'gender' => 'Nam',
                    'date_of_birth' => '1986-06-15',
                    'position' => $position,
                    'avatar_url' => null,
                ]
            );
        }
    }
}

