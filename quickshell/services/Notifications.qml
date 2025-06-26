pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../config" as Config

Singleton {
    id: root

    property list<Notif> notifications

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;
            const notifObj = notif_component.createObject(root, {
                notification: notification
            });
            root.notifications.push(notifObj);
        }
    }

    component Notif: QtObject {
        id: notif
        required property Notification notification

        readonly property string summary: notification.summary
        readonly property string body: notification.body
        readonly property string appIcon: notification.appIcon
        readonly property string appName: notification.appName
        readonly property string image: notification.image
        readonly property int urgency: notification.urgency

        function remove() {
            const idx = root.notifications.indexOf(notif);
            if (idx !== -1) {
                root.notifications.splice(idx, 1);
            }
        }

        readonly property Timer timer: Timer {
            running: true
            interval: {
                if (notif.notification.expireTimeout > 0) {
                    return notif.notification.expireTimeout;
                }
                if (notif.urgency === NotificationUrgency.Critical) {
                    return Config.Notification.defaultUrgentTimeoutMs;
                }
                return Config.Notification.defaultTimeoutMs;
            }
            onTriggered: {
                notif.remove();
            }
        }

        readonly property Connections conn: Connections {
            target: notif.notification.Retainable
            function onDropped(): void {
                const idx = root.notifications.indexOf(notif);
                if (idx !== -1) {
                    root.notifications.splice(idx, 1);
                }
            }
            function onAboutToDestroy(): void {
                notif.destroy();
            }
        }
    }

    Component {
        id: notif_component
        Notif {}
    }
}
