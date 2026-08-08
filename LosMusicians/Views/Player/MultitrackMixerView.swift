import SwiftUI

struct TrackMixerItem: Identifiable {
    let id: String
    let name: String
    let instrument: InstrumentType
    var volume: Float // 0.0 a 1.0
    var isMuted: Bool
    var isSolo: Bool
}

struct MultitrackMixerView: View {
    let song: Song
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var synth = GuitarSynthEngine.shared
    
    @State private var tracks: [TrackMixerItem] = []
    @State private var metronomeVolume: Float = 0.8
    @State private var isMetronomeMuted: Bool = false
    
    var body: some View {
        ZStack {
            Color(red: 0.08, green: 0.08, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header Sheet
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                
                HStack {
                    Image(systemName: "slider.vertical.3")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mixer Multitrack")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        Text("Controle Mute, Solo e Volume de cada instrumento")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                
                // Presets Rápidos do Mixer (Backing Track / Banda Completa / Solo)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        MixerPresetButton(title: "🎸 Banda Completa", isSelected: false) {
                            resetAllTracks()
                        }
                        
                        MixerPresetButton(title: "🥁 Backing Track (Muta Solo)", isSelected: false) {
                            applyBackingTrackPreset()
                        }
                        
                        MixerPresetButton(title: "🔍 Isolar Guitarra (Solo)", isSelected: false) {
                            isolateLeadGuitarPreset()
                        }
                        
                        MixerPresetButton(title: "⚡ Apenas Base & Baixo", isSelected: false) {
                            rhythmSectionPreset()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 4)
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.horizontal, 20)
                
                // Lista de Pistas / Instrumentos
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(tracks.indices, id: \.self) { idx in
                            TrackMixerRow(
                                item: $tracks[idx],
                                onVolumeChanged: { newVol in
                                    synth.setVolume(for: tracks[idx].instrument.rawValue, volume: newVol)
                                },
                                onMuteToggled: { muted in
                                    synth.setMuted(for: tracks[idx].instrument.rawValue, isMuted: muted)
                                },
                                onSoloToggled: { solo in
                                    for i in tracks.indices {
                                        if i != idx { tracks[i].isSolo = false }
                                    }
                                    synth.setSolo(for: solo ? tracks[idx].instrument.rawValue : nil, isSolo: solo)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            initializeTracks()
        }
    }
    
    private func initializeTracks() {
        var items: [TrackMixerItem] = []
        for track in song.tracks {
            let instKey = track.instrument.rawValue
            let vol = synth.getVolume(for: instKey)
            let muted = synth.isMuted(instrument: instKey)
            let solo = synth.isSolo(instrument: instKey)
            items.append(TrackMixerItem(
                id: track.id,
                name: track.name,
                instrument: track.instrument,
                volume: vol,
                isMuted: muted,
                isSolo: solo
            ))
        }
        
        // Garante que haja pelo menos Bateria e Baixo como faixas virtuais do mixer se a música só tiver guitarra
        if !items.contains(where: { $0.instrument == .bass }) {
            items.append(TrackMixerItem(
                id: "virt_bass",
                name: "Baixo de Acompanhamento",
                instrument: .bass,
                volume: synth.getVolume(for: "Baixo"),
                isMuted: synth.isMuted(instrument: "Baixo"),
                isSolo: synth.isSolo(instrument: "Baixo")
            ))
        }
        if !items.contains(where: { $0.instrument == .drums }) {
            items.append(TrackMixerItem(
                id: "virt_drums",
                name: "Bateria / Percussão",
                instrument: .drums,
                volume: synth.getVolume(for: "Bateria"),
                isMuted: synth.isMuted(instrument: "Bateria"),
                isSolo: synth.isSolo(instrument: "Bateria")
            ))
        }
        
        self.tracks = items
    }
    
    private func resetAllTracks() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        for i in tracks.indices {
            tracks[i].isMuted = false
            tracks[i].isSolo = false
            tracks[i].volume = 1.0
            synth.setVolume(for: tracks[i].instrument.rawValue, volume: 1.0)
            synth.setMuted(for: tracks[i].instrument.rawValue, isMuted: false)
        }
        synth.setSolo(for: nil, isSolo: false)
    }
    
    private func applyBackingTrackPreset() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        for i in tracks.indices {
            if tracks[i].instrument == .leadGuitar {
                tracks[i].isMuted = true
                synth.setMuted(for: tracks[i].instrument.rawValue, isMuted: true)
            } else {
                tracks[i].isMuted = false
                synth.setMuted(for: tracks[i].instrument.rawValue, isMuted: false)
            }
            tracks[i].isSolo = false
        }
        synth.setSolo(for: nil, isSolo: false)
    }
    
    private func isolateLeadGuitarPreset() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let leadIdx = tracks.firstIndex(where: { $0.instrument == .leadGuitar }) {
            for i in tracks.indices {
                tracks[i].isSolo = (i == leadIdx)
            }
            synth.setSolo(for: tracks[leadIdx].instrument.rawValue, isSolo: true)
        }
    }
    
    private func rhythmSectionPreset() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        for i in tracks.indices {
            if tracks[i].instrument == .leadGuitar {
                tracks[i].isMuted = true
                synth.setMuted(for: tracks[i].instrument.rawValue, isMuted: true)
            } else {
                tracks[i].isMuted = false
                synth.setMuted(for: tracks[i].instrument.rawValue, isMuted: false)
            }
            tracks[i].isSolo = false
        }
        synth.setSolo(for: nil, isSolo: false)
    }
}

// MARK: - Botão de Preset Rápido do Mixer
struct MixerPresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isSelected ? .black : .cyan)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? Color.cyan : Color.cyan.opacity(0.12))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Linha do Canal do Instrumento
struct TrackMixerRow: View {
    @Binding var item: TrackMixerItem
    let onVolumeChanged: (Float) -> Void
    let onMuteToggled: (Bool) -> Void
    let onSoloToggled: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Ícone do instrumento
                Image(systemName: item.instrument.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(Int(item.volume * 100))% volume")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Botão MUTE (M)
                Button(action: {
                    item.isMuted.toggle()
                    onMuteToggled(item.isMuted)
                }) {
                    Text("M")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .frame(width: 32, height: 32)
                        .background(item.isMuted ? Color.red : Color.white.opacity(0.08))
                        .foregroundColor(item.isMuted ? .white : .gray)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(item.isMuted ? Color.red : Color.clear, lineWidth: 1.5)
                        )
                }
                
                // Botão SOLO (S)
                Button(action: {
                    item.isSolo.toggle()
                    onSoloToggled(item.isSolo)
                }) {
                    Text("S")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .frame(width: 32, height: 32)
                        .background(item.isSolo ? Color.yellow : Color.white.opacity(0.08))
                        .foregroundColor(item.isSolo ? .black : .gray)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(item.isSolo ? Color.yellow : Color.clear, lineWidth: 1.5)
                        )
                }
            }
            
            // Slider de Volume Estilo DAW
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Slider(
                    value: Binding(
                        get: { Double(item.volume) },
                        set: { newVol in
                            item.volume = Float(newVol)
                            onVolumeChanged(Float(newVol))
                        }
                    ),
                    in: 0.0...1.0
                )
                .accentColor(.cyan)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(item.isSolo ? Color.yellow.opacity(0.5) : (item.isMuted ? Color.red.opacity(0.3) : Color.white.opacity(0.05)), lineWidth: 1)
                )
        )
    }
}
