import SwiftUI
import UniformTypeIdentifiers

struct AddRiffView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    
    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var bpm: Int = 120
    @State private var difficulty: String = "Médio"
    @State private var selectedInstrument: InstrumentType = .leadGuitar
    @State private var isPublic: Bool = true
    @State private var isFilePickerPresented: Bool = false
    @State private var uploadedFileName: String? = nil
    
    let difficulties = ["Fácil", "Médio", "Difícil", "Insano"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.07, green: 0.07, blue: 0.10)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Criar ou Enviar Riff / Solo")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        // Upload File Button
                        VStack(spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.cyan)
                            
                            Text(uploadedFileName ?? "Upload de Arquivo Guitar Pro (.gp, .gpx)")
                                .font(.headline)
                                .foregroundColor(uploadedFileName != nil ? .green : .white)
                            
                            Text("Selecione um arquivo de tablatura do seu dispositivo")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Button(action: {
                                isFilePickerPresented = true
                            }) {
                                Text("Escolher Arquivo")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.cyan.opacity(0.3))
                                    .cornerRadius(12)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.white.opacity(0.04))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [6]))
                        )
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        // Form fields
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Detalhes da Música")
                                .font(.headline)
                                .foregroundColor(.cyan)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Título do Riff / Solo").font(.caption).foregroundColor(.gray)
                                TextField("Ex: Solo de Eruption", text: $title)
                                    .padding(12)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Artista / Banda").font(.caption).foregroundColor(.gray)
                                TextField("Ex: Van Halen", text: $artist)
                                    .padding(12)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("BPM (Andamento)").font(.caption).foregroundColor(.gray)
                                    Stepper("\(bpm) BPM", value: $bpm, in: 40...300)
                                        .padding(8)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(10)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Dificuldade").font(.caption).foregroundColor(.gray)
                                    Picker("Dificuldade", selection: $difficulty) {
                                        ForEach(difficulties, id: \.self) { diff in
                                            Text(diff).tag(diff)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(8)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(10)
                                    .foregroundColor(.cyan)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Instrumento Principal").font(.caption).foregroundColor(.gray)
                                Picker("Instrumento", selection: $selectedInstrument) {
                                    ForEach(InstrumentType.allCases) { inst in
                                        Text(inst.rawValue).tag(inst)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            Toggle("Tornar público na comunidade", isOn: $isPublic)
                                .foregroundColor(.white)
                                .padding(.top, 6)
                        }
                        
                        Button(action: {
                            saveRiff()
                        }) {
                            Text("SALVAR E PUBLICAR RIFF")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(16)
                        }
                        .padding(.top, 10)
                    }
                    .padding(20)
                }
            }
            .navigationBarItems(leading: Button("Cancelar") {
                presentationMode.wrappedValue.dismiss()
            }.foregroundColor(.gray))
            .sheet(isPresented: $isFilePickerPresented) {
                DocumentPicker(uploadedFileName: $uploadedFileName)
            }
        }
    }
    
    private func saveRiff() {
        let newSong = Song(
            id: UUID().uuidString,
            title: title.isEmpty ? "Novo Riff" : title,
            artist: artist.isEmpty ? (authManager.currentUser?.name ?? "Você") : artist,
            difficulty: difficulty,
            bpm: bpm,
            tracks: [InstrumentTrack(id: UUID().uuidString, name: selectedInstrument.rawValue, instrument: selectedInstrument)],
            isPublic: isPublic,
            authorName: authManager.currentUser?.name ?? "Você"
        )
        
        FirestoreManager.shared.saveSong(song: newSong) { success in
            authManager.addPracticeTime(minutes: 5) // Recompensa por criar um Riff!
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var uploadedFileName: String?
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        init(_ parent: DocumentPicker) { self.parent = parent }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.uploadedFileName = url.lastPathComponent
            }
        }
    }
}
