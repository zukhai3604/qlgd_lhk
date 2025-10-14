<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Notification;
use App\Models\User;

class NotificationSeeder extends Seeder
{
    public function run(): void
    {
        $from = User::where('email','dungkt@tlu.edu.vn')->first();
        $to   = User::where('role','DAO_TAO')->first();

        if($from && $to){
            Notification::create([
                'from_user_id' => $from->id,
                'to_user_id' => $to->id,
                'title' => 'Đơn xin nghỉ dạy',
                'body' => 'Xin nghỉ buổi Công nghệ Web ngày 2025-09-26 ca CA2',
                'type' => 'LEAVE_REQUEST',
                'status' => 'UNREAD',
                'created_at' => now()
            ]);
        }
    }
}
