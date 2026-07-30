import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Permissão para Notificações concedida!")
            } else if let error = error {
                print("Erro ao pedir permissão para notificações: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleStreakReminder() {
        // Cancela lembretes antigos para não sobrecarregar
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "Sua ofensiva vai apagar! 🔥"
        content.body = "Você tem 5 minutos? Treine um pouco no Professor IA e mantenha seu Streak vivo!"
        content.sound = UNNotificationSound.default
        
        // Agendar para 24 horas a partir de agora
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false)
        
        let request = UNNotificationRequest(identifier: "streakReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erro ao agendar notificação: \(error.localizedDescription)")
            } else {
                print("Lembrete de Ofensiva agendado com sucesso para amanhã.")
            }
        }
    }
}
