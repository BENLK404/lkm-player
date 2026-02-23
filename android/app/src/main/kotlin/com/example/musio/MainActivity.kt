package com.example.musio

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity: AudioServiceActivity() {
    // Cette classe doit hériter de AudioServiceActivity
    // au lieu de FlutterActivity pour une intégration parfaite.
}