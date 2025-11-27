/* eslint-disable */

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
admin.initializeApp();

// Trigger: cuando cambia un documento de ticket
exports.notifyStatusChange = onDocumentUpdated(
  "qr_codes/{ticketId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    // Si no hay cambios válidos
    if (!before || !after || before.status === after.status) return null;

    const status = after.status;
    const fcmToken = after.fcmToken; // token del cliente o valet

    if (!fcmToken) {
      console.log("No hay FCM token, no se envía push.");
      return null;
    }

    let title = "";
    let body = "";

    switch (status) {
      case "solicitado_cliente":
        title = "Solicitud enviada al valet";
        body = "Tu solicitud ha sido enviada, pronto recibirás tu vehículo.";
        break;

      case "entregado":
        title = "Vehículo entregado";
        body = "Tu vehículo ha sido entregado por el valet.";
        break;

      case "cerrado_cliente":
        title = "Servicio finalizado";
        body = "¡Gracias por usar nuestro servicio!";
        break;

      default:
        return null;
    }

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: { title, body },
      });
      console.log("Notificación enviada a:", fcmToken);
    } catch (err) {
      console.error("Error enviando notificación:", err);
    }

    return null;
  }
);
