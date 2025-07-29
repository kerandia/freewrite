# Speech-to-Text Feature Guide

## Overview
Freewrite now supports speech-to-text functionality, allowing you to dictate your journal entries instead of typing them. This creates a smooth "dictionary that translates speaking to text" experience.

## How to Use

### Starting Dictation
1. **Click the microphone button** in the bottom navigation bar
2. **Or press ⌘⇧S** (Command + Shift + S) keyboard shortcut
3. Grant microphone permission when prompted (first time only)

### While Dictating
- The microphone icon turns **red** and scales up slightly
- Placeholder text changes to "**Listening... Speak now!**"
- Your spoken words appear in real-time in the text editor
- Speak naturally - the system handles punctuation and formatting

### Stopping Dictation
1. **Click the microphone button again**
2. **Or press ⌘⇧S** again
3. The transcribed text will be finalized in your journal entry

## Visual Indicators

- **Gray microphone**: Ready to start dictation
- **Red microphone (larger)**: Currently listening and transcribing
- **Disabled gray**: Permissions not granted or speech recognition unavailable

## Permissions Required

The app requires two permissions:
- **Microphone access**: To capture your voice
- **Speech recognition**: To convert speech to text

These permissions are requested automatically when you first try to use the feature.

## Tips for Best Results

1. **Speak clearly** and at a normal pace
2. **Minimize background noise** for better accuracy
3. **Use the keyboard shortcut** for hands-free operation
4. **Combine with typing** - you can switch between speech and typing seamlessly
5. **Try different speaking styles** - the system adapts to your voice over time

## Troubleshooting

- If the microphone appears grayed out, check System Preferences > Security & Privacy > Microphone
- If speech recognition fails, ensure you have an internet connection
- If accuracy is poor, try speaking more slowly or adjusting your distance from the microphone

## Technical Details

- Uses Apple's native Speech framework for high accuracy
- Requires macOS with Speech Recognition support
- Real-time transcription with partial results
- Automatic error handling and recovery
- Seamless integration with existing text editing features