<?php

namespace App\Http\Controllers\TrainingDepartment;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\{Subject, ClassUnit, Lecturer, Room};

class CatalogController extends Controller
{
    // SUBJECTS (Môn)
    public function subjectsIndex() { return Subject::orderBy('code')->paginate(50); }
    public function subjectsStore(Request $r){
        $r->validate([
            'code'=>['required','string','max:50','unique:subjects,code'],
            'name'=>['required','string','max:255'],
            'credit'=>['nullable','integer','min:0']
        ]);
        return response()->json(Subject::create($r->only('code','name','credit')),201);
    }
    public function subjectsUpdate(Request $r, int $id){
        $r->validate([
            'name'=>['sometimes','string','max:255'],
            'credit'=>['sometimes','integer','min:0']
        ]);
        $m = Subject::findOrFail($id); 
        $m->update($r->only('name','credit')); 
        return $m;
    }
    public function subjectsDestroy(int $id){ 
        Subject::findOrFail($id)->delete(); 
        return response()->noContent(); 
    }

    // CLASS UNITS (Lớp học phần)
    public function classesIndex() { return ClassUnit::orderBy('code')->paginate(50); }
    public function classesStore(Request $r){
        $r->validate([
            'code'=>['required','string','max:50','unique:class_units,code'],
            'name'=>['required','string','max:255'],
            'capacity'=>['nullable','integer','min:1']
        ]);
        return response()->json(ClassUnit::create($r->only('code','name','capacity')),201);
    }
    public function classesUpdate(Request $r, int $id){
        $r->validate([
            'name'=>['sometimes','string','max:255'],
            'capacity'=>['sometimes','integer','min:1']
        ]);
        $c = ClassUnit::findOrFail($id); 
        $c->update($r->only('name','capacity')); 
        return $c;
    }
    public function classesDestroy(int $id){ 
        ClassUnit::findOrFail($id)->delete(); 
        return response()->noContent(); 
    }

    // LECTURERS (Giảng viên)
    public function lecturersIndex(){ return Lecturer::orderBy('name')->paginate(50); }
    public function lecturersStore(Request $r){
        $r->validate([
            'name'=>['required','string','max:255'],
            'email'=>['required','email','unique:lecturers,email'],
            'dept'=>['nullable','string','max:255'],
        ]);
        return response()->json(Lecturer::create($r->only('name','email','dept')),201);
    }
    public function lecturersUpdate(Request $r, int $id){
        $r->validate([
            'name'=>['sometimes','string','max:255'],
            'email'=>['sometimes','email','unique:lecturers,email,'.$id],
            'dept'=>['sometimes','string','max:255'],
        ]);
        $l = Lecturer::findOrFail($id); 
        $l->update($r->only('name','email','dept')); 
        return $l;
    }
    public function lecturersDestroy(int $id){ 
        Lecturer::findOrFail($id)->delete(); 
        return response()->noContent(); 
    }

    // ROOMS (Phòng)
    public function roomsIndex(){ return Room::orderBy('code')->paginate(50); }
    public function roomsStore(Request $r){
        $r->validate([
            'code'=>['required','string','max:50','unique:rooms,code'],
            'name'=>['nullable','string','max:255'],
            'type'=>['nullable','string','max:50'],
            'size'=>['nullable','integer','min:1']
        ]);
        return response()->json(Room::create($r->only('code','name','type','size')),201);
    }
    public function roomsUpdate(Request $r, int $id){
        $r->validate([
            'name'=>['sometimes','string','max:255'],
            'type'=>['sometimes','string','max:50'],
            'size'=>['sometimes','integer','min:1']
        ]);
        $room = Room::findOrFail($id); 
        $room->update($r->only('name','type','size')); 
        return $room;
    }
    public function roomsDestroy(int $id){ 
        Room::findOrFail($id)->delete(); 
        return response()->noContent(); 
    }
}
