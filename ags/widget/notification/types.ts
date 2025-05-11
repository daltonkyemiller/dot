import Notifd from "gi://AstalNotifd";

export type NotificationData = {
  id: number;
  setup(): void;
  onHoverLost(): void;
  notification: Notifd.Notification;
};
