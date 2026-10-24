"""Generate original game feedback and rain with mathematical synthesis."""
import math, random, struct, wave
from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
sr = 22050
sequences = {
    'construction': [170, 230, 170], 'harvest': [523.25, 659.25, 783.99],
    'purchase': [880, 1174.66], 'levelup': [523.25, 659.25, 783.99, 1046.5],
    'quest': [659.25, 783.99, 1046.5, 1318.5], 'plant': [392, 523.25]
}
for name, notes in sequences.items():
    output = []
    for i in range(int(sr * len(notes) * 0.11)):
        t = i / sr
        note = min(len(notes)-1, int(t / 0.11))
        envelope = math.exp(-(t % 0.11)*28)
        value = 0.18 * envelope * math.sin(2*math.pi*notes[note]*t)
        output.append(struct.pack('<h', int(value*32767)))
    with wave.open(str(root / (name+'.wav')), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(b''.join(output))
random.seed(45)
output = []; filtered = 0.0
for i in range(sr*12):
    filtered = filtered*0.65 + random.uniform(-1, 1)*0.35
    output.append(struct.pack('<h', int(filtered*8000)))
with wave.open(str(root / 'rain.wav'), 'wb') as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(sr); w.writeframes(b''.join(output))
print('Generated original feedback and rain audio')
