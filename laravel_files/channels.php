<?php

use Illuminate\Support\Facades\Broadcast;

/*
|--------------------------------------------------------------------------
| Broadcast Channels
|--------------------------------------------------------------------------
|
| Here you may register all of the event broadcasting channels that your
| application supports. The given channel authorization callbacks are
| used to check if an authenticated user can listen to the channel.
|
*/

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// Private consultation channel
Broadcast::channel('consultation.{sessionId}', function ($user, $sessionId) {
    $session = \App\Models\ConsultationSession::find($sessionId);
    
    if (!$session) {
        return false;
    }
    
    // Allow if user is the patient or the doctor
    if ($user->role === 'doctor') {
        $doctor = $user->doctor;
        return $doctor && $session->doctor_id === $doctor->id;
    }
    
    return $session->user_id === $user->id;
});
