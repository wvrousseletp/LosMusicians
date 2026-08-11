import SwiftUI

struct TunerView: View {
    @StateObject private var tuner = TunerService()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.08)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                HStack {
                    Text("Afinador")
                        .font(.title.weight(.black))
                        .foregroundColor(.white)
                    Spacer()
                    if tuner.isRunning {
                        HStack(spacing: 4) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text("Captação Ativa")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Nota Detectada
                Text(tuner.closestNote)
                    .font(.system(size: 100, weight: .black, design: .rounded))
                    .foregroundColor(isTuned ? .green : .white)
                    .animation(.spring(), value: tuner.closestNote)
                
                Text(String(format: "%.1f Hz", tuner.currentPitch))
                    .font(.title3.monospacedDigit())
                    .foregroundColor(.gray)
                
                // Medidor Visual (Gauge)
                ZStack(alignment: .bottom) {
                    // Arco de fundo
                    Circle()
                        .trim(from: 0.5, to: 1.0)
                        .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 250, height: 250)
                    
                    // Zona de acerto (Tuned zone) no meio
                    Circle()
                        .trim(from: 0.73, to: 0.77)
                        .stroke(Color.green.opacity(0.4), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 250, height: 250)
                    
                    // Ponteiro
                    let rotation = Double(tuner.centsDistance) * 0.9 // Mapeia -50/50 cents para -45/45 graus
                    
                    Rectangle()
                        .fill(isTuned ? Color.green : (tuner.centsDistance < 0 ? Color.red : Color.orange))
                        .frame(width: 4, height: 130)
                        .offset(y: -65)
                        .rotationEffect(.degrees(rotation))
                        .animation(.linear(duration: 0.1), value: rotation)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                }
                .padding(.top, 40)
                
                HStack(spacing: 60) {
                    Text("Muito Grave")
                        .font(.caption.bold())
                        .foregroundColor(tuner.centsDistance < -5 ? .red : .gray)
                    
                    Text("Muito Agudo")
                        .font(.caption.bold())
                        .foregroundColor(tuner.centsDistance > 5 ? .orange : .gray)
                }
                
                Spacer()
            }
        }
        .onAppear {
            tuner.start()
        }
        .onDisappear {
            tuner.stop()
        }
    }
    
    private var isTuned: Bool {
        abs(tuner.centsDistance) <= 5.0 && tuner.closestNote != "-"
    }
}
