import SwiftUI

struct SongsterrPlayerView: View {
    let songId: Int
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            SongsterrWebView(songId: songId)
                .ignoresSafeArea(edges: .bottom) // Deixa a tablatura ocupar toda a tela
            
            // Botão de voltar nativo sobreposto
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}
