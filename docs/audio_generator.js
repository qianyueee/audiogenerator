let audioContext;
let oscillators = [];
let gainNodes = [];
let vibratoOscillators = [];

function initAudio() {
  audioContext = new (window.AudioContext || window.webkitAudioContext)();
}

function generateAndPlaySineWave(harmonics, harmonicVolumes, dampingFactors, bpmValues, vibratoDepth, vibratoSpeed) {
  if (!audioContext) initAudio();
  
  stopOscillators();

  const currentTime = audioContext.currentTime;
  
  harmonics.forEach((frequency, index) => {
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    const vibratoOscillator = audioContext.createOscillator();
    const vibratoGain = audioContext.createGain();
    
    oscillator.type = 'sine';
    oscillator.frequency.setValueAtTime(frequency, currentTime);
    
    vibratoOscillator.type = 'sine';
    vibratoOscillator.frequency.setValueAtTime(vibratoSpeed, currentTime);
    vibratoGain.gain.setValueAtTime(frequency * vibratoDepth, currentTime);
    
    vibratoOscillator.connect(vibratoGain);
    vibratoGain.connect(oscillator.frequency);
    
    const volume = harmonicVolumes[index];
    const dampingFactor = dampingFactors[index];
    const bpm = bpmValues[index];

    if (dampingFactor === 0 || bpm === 0) {
      gainNode.gain.setValueAtTime(volume, currentTime);
    } else {
      const cycleDuration = 60 / bpm;
      const attackTime = 0.01;

      for (let i = 0; i < 100; i++) {
        const cycleStart = currentTime + i * cycleDuration;
        gainNode.gain.setValueAtTime(0, cycleStart);
        gainNode.gain.linearRampToValueAtTime(volume, cycleStart + attackTime);
        gainNode.gain.setTargetAtTime(0.0001, cycleStart + attackTime, 1 / dampingFactor);
      }
    }
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    oscillator.start();
    vibratoOscillator.start();
    oscillators.push(oscillator);
    gainNodes.push(gainNode);
    vibratoOscillators.push(vibratoOscillator);
  });
}

function stopOscillators() {
  oscillators.forEach(osc => osc.stop());
  vibratoOscillators.forEach(osc => osc.stop());
  oscillators = [];
  gainNodes = [];
  vibratoOscillators = [];
}

function updateOscillators(harmonics, harmonicVolumes, dampingFactors, bpmValues, vibratoDepth, vibratoSpeed) {
  const currentTime = audioContext.currentTime;

  oscillators.forEach((oscillator, index) => {
    const frequency = harmonics[index];
    oscillator.frequency.setValueAtTime(frequency, currentTime);
    
    const gainNode = gainNodes[index];
    const volume = harmonicVolumes[index];
    const dampingFactor = dampingFactors[index];
    const bpm = bpmValues[index];

    gainNode.gain.cancelScheduledValues(currentTime);

    if (dampingFactor === 0 || bpm === 0) {
      gainNode.gain.setValueAtTime(volume, currentTime);
    } else {
      const cycleDuration = 60 / bpm;
      const attackTime = 0.01;

      for (let i = 0; i < 100; i++) {
        const cycleStart = currentTime + i * cycleDuration;
        gainNode.gain.setValueAtTime(0, cycleStart);
        gainNode.gain.linearRampToValueAtTime(volume, cycleStart + attackTime);
        gainNode.gain.setTargetAtTime(0.0001, cycleStart + attackTime, 1 / dampingFactor);
      }
    }

    const vibratoOscillator = vibratoOscillators[index];
    vibratoOscillator.frequency.setValueAtTime(vibratoSpeed, currentTime);
    vibratoOscillator.connect(audioContext.createGain()).gain.setValueAtTime(frequency * vibratoDepth, currentTime);
  });
}