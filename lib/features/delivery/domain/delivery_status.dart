/// Estados observáveis da entrega, sem inferir se houve leitura ou chegada.
enum DeliveryStatus { pending, opened, confirmed }

extension DeliveryStatusLabel on DeliveryStatus {
  String get label => switch (this) {
    DeliveryStatus.pending => 'Pendente',
    DeliveryStatus.opened => 'Conversa aberta',
    DeliveryStatus.confirmed => 'Envio confirmado pelo organizador',
  };
}

enum DeliveryConfirmationMethod { whatsapp, manual }
