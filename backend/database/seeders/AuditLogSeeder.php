<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\AuditLog;
use App\Models\User;

class AuditLogSeeder extends Seeder
{
    /**
     * Seed sample audit logs
     */
    public function run(): void
    {
        $users = User::limit(5)->get();

        if ($users->isEmpty()) {
            $this->command->info('⚠️ No users found to create audit logs');
            return;
        }

        $actions = ['created', 'updated', 'deleted', 'viewed', 'exported'];
        $entities = ['User', 'Schedule', 'Assignment', 'LeaveRequest', 'ClassUnit'];

        // Tạo 20 audit log mẫu
        for ($i = 0; $i < 20; $i++) {
            AuditLog::create([
                'actor_id'     => $users->random()->id,
                'action'       => $actions[array_rand($actions)],
                'entity_type'  => $entities[array_rand($entities)],
                'entity_id'    => rand(1, 50),
                'payload'      => json_encode([
                    'description' => 'Sample audit log entry',
                    'ip_address'  => '192.168.1.' . rand(1, 255),
                    'user_agent'  => 'Mozilla/5.0',
                ]),
                'created_at'   => now()->subDays(rand(0, 30)),
            ]);
        }

        $this->command->info('✅ Created 20 sample audit logs');
    }
}
