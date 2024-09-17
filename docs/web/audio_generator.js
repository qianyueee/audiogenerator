let audioContext;
let oscillators = [];
let gainNodes = [];

function initAudio() {
  audioContext = new (window.AudioContext || window.webkitAudioContext)();
}

function generateAndPlaySineWave(harmonics, harmonicVolumes, dampingFactors, bpmValues) {
  if (!audioContext) initAudio();
  
  // Stop any previously playing oscillators
  stopOscillators();

  const currentTime = audioContext.currentTime;
  
  // Calculate the total volume to use for normalization
  const totalVolume = harmonicVolumes.reduce((sum, volume) => sum + volume, 0);
  const normalizer = totalVolume > 0 ? 1 / totalVolume : 1;

  harmonics.forEach((frequency, index) => {
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(frequency, currentTime);
    
    const volume = harmonicVolumes[index] * normalizer; // Normalize the volume
    const dampingFactor = dampingFactors[index];
    const bpm = bpmValues[index];

    if (dampingFactor === 0 || bpm === 0) {
      // No damping or no repetition
      gainNode.gain.setValueAtTime(volume, currentTime);
    } else {
      const cycleDuration = 60 / bpm; // Duration of one cycle in seconds
      const attackTime = 0.01; // 10ms attack time

      // Create a periodic wave for the gain
      for (let i = 0; i < 100; i++) { // Schedule for 100 cycles (adjust as needed)
        const cycleStart = currentTime + i * cycleDuration;
        gainNode.gain.setValueAtTime(0, cycleStart);
        gainNode.gain.linearRampToValueAtTime(volume, cycleStart + attackTime);
        if (dampingFactor > 0) {
          gainNode.gain.setTargetAtTime(0.0001, cycleStart + attackTime, 1 / dampingFactor);
        }
      }
    }
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.start();
    oscillators.push(oscillator);
    gainNodes.push(gainNode);
  });
}

function stopOscillators() {
  oscillators.forEach(osc => osc.stop());
  oscillators = [];
  gainNodes = [];
}