<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    public function index()
    {
        return User::query()->orderByDesc('id')->paginate(20);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'  => ['required','string','max:150'],
            'email' => ['required','email','max:190','unique:users,email'],
            'phone' => ['nullable','string','max:30'],
            'password' => ['required','string','min:8'],
            'role'  => ['required', Rule::in(['ADMIN','DAO_TAO','GIANG_VIEN'])],
            'is_active' => ['boolean']
        ]);

        $data['password'] = bcrypt($data['password']);
        $data['is_active'] = $data['is_active'] ?? true;

        $user = User::create($data);
        return response()->json($user, 201);
    }

    public function show(User $user)
    {
        return $user;
    }

    public function update(Request $request, User $user)
    {
        $data = $request->validate([
            'name'  => ['sometimes','string','max:150'],
            'email' => ['sometimes','email','max:190', Rule::unique('users','email')->ignore($user->id)],
            'phone' => ['nullable','string','max:30'],
            'password' => ['nullable','string','min:8'],
            'role'  => ['sometimes', Rule::in(['ADMIN','DAO_TAO','GIANG_VIEN'])],
            'is_active' => ['boolean']
        ]);

        if (!empty($data['password'])) {
            $data['password'] = bcrypt($data['password']);
        } else {
            unset($data['password']);
        }

        $user->update($data);
        return $user->refresh();
    }

    public function destroy(User $user)
    {
        $user->delete();
        return response()->json(['message' => 'Deleted']);
    }
}
