from PyQt6.QtWidgets import (QWidget, QApplication, QVBoxLayout, QHBoxLayout, QPushButton,
                             QLabel, QGridLayout, QSlider, QColorDialog, QFrame, QStackedLayout,
                             QScrollArea, QFontDialog, QCheckBox, QMenu, QSystemTrayIcon, QMessageBox)

from PyQt6.QtCore import (QSettings, Qt, QPoint, pyqtSignal, QObject, QSize, QUrl, QTimer, QRectF, QRect)

from PyQt6.QtGui import (QPainter, QLinearGradient, QBrush, QColor, QFont, QIcon, QPixmap, QDesktopServices,
                         QPen)
import sys
import datetime
import calendar
import os
import winreg
import ctypes
from ctypes import wintypes


# ______________________________DESKTOP WINDOW HANDLE________
def get_desktop_window_handle():
    progman = ctypes.windll.user32.FindWindowW("Progman", None)

    # Send message to Progman to spawn WorkerW behind desktop icons
    result = ctypes.wintypes.DWORD()
    ctypes.windll.user32.SendMessageTimeoutW(
        progman,
        0x052C,
        0,
        0,
        0,
        1000,
        ctypes.byref(result)
    )

    workerw_handle = []

    @ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    def enum_windows_proc(hwnd, lParam):
        shellview = ctypes.create_unicode_buffer(255)
        ctypes.windll.user32.GetClassNameW(hwnd, shellview, 255)
        if shellview.value == "WorkerW":
            workerw_handle.append(hwnd)
        return True

    ctypes.windll.user32.EnumWindows(enum_windows_proc, 0)

    return workerw_handle[0] if workerw_handle else progman


# ______________________________AUTO START____________________
APP_NAME = "Everlastimer"


def add_to_startup():
    try:
        app_path = os.path.realpath(sys.argv[0])
        reg_key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_SET_VALUE
        )
        winreg.SetValueEx(reg_key, APP_NAME, 0, winreg.REG_SZ, f'"{app_path}" --autostart')
        winreg.CloseKey(reg_key)
    except:
        pass  # Silent fail


def is_in_startup():
    try:
        reg_key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run"
        )
        _, _ = winreg.QueryValueEx(reg_key, APP_NAME)
        winreg.CloseKey(reg_key)
        return True
    except:
        return False


def remove_from_startup():
    try:
        reg_key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_ALL_ACCESS
        )
        winreg.DeleteValue(reg_key, APP_NAME)
        winreg.CloseKey(reg_key)
    except:
        pass


# _____________________________PC SAVER_________________

from datetime import datetime as dt


def get_current_minutes():
    """Returns the current minutes of the hour (0-59) as an integer"""
    return dt.now().minute


def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and for PyInstaller """
    try:
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)


# _______________________________SIGNALS________________________

class SignalEmitter(QObject):
    color_selected = pyqtSignal(QColor)
    gradient_selected = pyqtSignal(list)
    transparency_changed = pyqtSignal(int)
    font_changed = pyqtSignal(QFont)
    text_color_changed = pyqtSignal(QColor)


# ______________________________TOGGLE BUTTON______________________
class PyToggle(QCheckBox):
    def __init__(
            self,
            width=60,
            bg_color="#777",
            circle_color="#d5cbec",
            active_color="#6d4ed7"
    ):
        QCheckBox.__init__(self)

        # Set default parameters
        self.setFixedSize(width, 28)
        self.setCursor(Qt.CursorShape.PointingHandCursor)

        # Colors
        self._bg_color = bg_color
        self._circle_color = circle_color
        self._active_color = active_color

        # Connect state changed (removed debug connection)
        self.stateChanged.connect(self.update)

    def hitButton(self, pos: QPoint):
        return self.contentsRect().contains(pos)

    def paintEvent(self, event):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        p.setPen(Qt.PenStyle.NoPen)

        rect = QRect(0, 0, self.width(), self.height())

        if not self.isChecked():
            p.setBrush(QColor(self._bg_color))
            p.drawRoundedRect(0, 0, rect.width(), self.height(), self.height() / 2, self.height() / 2)
            p.setBrush(QColor(self._circle_color))
            p.drawEllipse(3, 3, 22, 22)
        else:
            p.setBrush(QColor(self._active_color))
            p.drawRoundedRect(0, 0, rect.width(), self.height(), self.height() / 2, self.height() / 2)
            p.setBrush(QColor(self._circle_color))
            p.drawEllipse(self.width() - 26, 3, 22, 22)

        p.end()


# _____________________________TIME CALCULATION FUNCTIONS__________________________________________________
def days_left_in_year():
    today = datetime.date.today()
    year = today.year
    total_days = 366 if calendar.isleap(year) else 365
    return int(total_days - today.timetuple().tm_yday)


def hours_left_in_year():
    now = datetime.datetime.now()
    year = now.year
    total_hours = 366 * 24 if calendar.isleap(year) else 365 * 24
    hours_passed = (now.timetuple().tm_yday - 1) * 24 + now.hour
    return int(total_hours - hours_passed)


def months_left():
    current_time = datetime.datetime.now()
    return int(12 - current_time.month)


def percentage_of_year_passed():
    today = datetime.date.today()
    year = today.year
    total_days = 366 if calendar.isleap(year) else 365
    start_of_year = datetime.date(year, 1, 1)
    days_passed = (today - start_of_year).days + 1
    # return f"{int((days_passed / total_days) * 100)}%"
    return int((days_passed / total_days) * 100)


def weeks_left_in_year():
    today = datetime.date.today()
    year = today.year
    total_days = 366 if calendar.isleap(year) else 365
    days_left = total_days - today.timetuple().tm_yday
    return int(days_left // 7)


# ______________________________PROGRESS BAR______________________________
class CircularProgressBar(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setMinimumSize(400, 400)  # minimum size
        self.value = percentage_of_year_passed()  # Value Setter
        self.start_angle = 90  # Start at top (90 degrees in Qt)
        self.bg_color = QColor(20, 20, 60)  # Dark blue background
        self.progress_color = QColor(170, 85, 255)  # Purple/pink color
        self.text_color = QColor(0, 0, 0)  # Black text

    def setvalue(self, value):
        self.value = max(0, min(100, value))  # Ensure value is between 0-100
        self.update()  # Trigger repaint

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        # Calculate sizes
        width = self.width()
        height = self.height()
        size = min(width, height) - 20

        # Create rectangle for the circle
        rect = QRectF((width - size) / 2, (height - size) / 2, size, size)
        inner_rect = QRectF((width - size * 0.8) / 2, (height - size * 0.8) / 2, size * 0.8, size * 0.8)

        # Draw background circle
        painter.setPen(Qt.PenStyle.NoPen)
        painter.setBrush(QBrush(self.bg_color))
        painter.drawEllipse(rect)

        # Draw progress arc
        pen = QPen(self.progress_color)
        pen.setWidth(int(size * 0.1))  # Thickness of the arc
        painter.setPen(pen)

        # Calculate span angle - negative because Qt draws clockwise
        span_angle = -3.6 * self.value

        # Draw arc (empty inside)
        painter.setBrush(Qt.BrushStyle.NoBrush)
        start_angle_16 = int(self.start_angle * 16)
        span_angle_16 = int(span_angle * 16)
        painter.drawArc(rect, start_angle_16, span_angle_16)

        # Draw white inner circle
        painter.setPen(Qt.PenStyle.NoPen)
        painter.setBrush(QBrush(Qt.GlobalColor.white))
        painter.drawEllipse(inner_rect)

        # Draw percentage text
        font = QFont("Arial", int(size / 8), QFont.Weight.Bold)
        painter.setFont(font)
        painter.setPen(self.text_color)
        text_rect = inner_rect.toRect()
        painter.drawText(text_rect, Qt.AlignmentFlag.AlignCenter, f"{self.value}%")


# ________________________________________WIDGET___________________________________
class FloatingTimer(QWidget):
    def __init__(self, parent=None):
        super().__init__()
        self.old_pos = None
        self.bg_color = QColor(100, 100, 100, 200)
        self.font_color = QColor(255, 255, 255)
        self.timer_font = QFont("Arial", 20)
        self.use_gradient = False
        self.gradient_colors = [QColor(100, 100, 100, 200), QColor(200, 200, 200, 200)]

        self.setWindowFlags(Qt.WindowType.FramelessWindowHint |
                            Qt.WindowType.WindowStaysOnBottomHint |
                            Qt.WindowType.WindowDoesNotAcceptFocus |
                            Qt.WindowType.BypassWindowManagerHint)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self.setAttribute(Qt.WidgetAttribute.WA_ShowWithoutActivating)

        layout = QVBoxLayout(self)
        layout.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.timer_label = QLabel(self.get_time_text(), self)
        self.timer_label.setFont(self.timer_font)
        self.update_label_style()
        layout.addWidget(self.timer_label)

        settings = QSettings("BitekoiLabs", "Everlastimer")
        pos = settings.value("widget_pos")
        if pos:
            self.move(QPoint(pos))

        self.is_locked = False

        settings = QSettings("BitekoiLabs", "Everlastimer")

        # Restore transparency
        alpha = int(settings.value("panel_transparency", 200))

        # Restore font color
        font_color = QColor(settings.value("font_color", "#FFFFFF"))
        self.font_color = font_color

        # Restore font
        font_family = settings.value("font_family", "Arial")
        font_size = int(settings.value("font_size", 20))
        self.timer_font = QFont(font_family, font_size)

        # Restore background or gradient
        if settings.contains("gradient_color_1") and settings.contains("gradient_color_2"):
            self.gradient_colors = [
                QColor(settings.value("gradient_color_1")),
                QColor(settings.value("gradient_color_2"))
            ]
            for color in self.gradient_colors:
                color.setAlpha(alpha)
            self.use_gradient = True
        else:
            bg_color = QColor(settings.value("bg_color", "#646464C8"))
            bg_color.setAlpha(alpha)
            self.bg_color = bg_color
            self.use_gradient = False

        self.update()
        self.update_label_style()

        self.update_timer = QTimer(self)
        self.update_timer.timeout.connect(self._update_timer)
        self.update_timer.start(60000)

    def contextMenuEvent(self, event):
        menu = QMenu(self)

        # Show "Unlock" if already locked
        lock_label = "Unlock Position" if self.is_locked else "Lock Position"
        lock_action = menu.addAction(lock_label)
        remove_action = menu.addAction("Remove Widget")


        action = menu.exec(event.globalPos())

        if action == lock_action:
            self.is_locked = not self.is_locked
        elif action == remove_action:
            self.hide()




    def _update_timer(self):
        """Updates the text on the floating timer label."""
        self.timer_label.setText(self.get_time_text())

    @staticmethod
    def get_time_text():
        return f"{months_left()}M   {days_left_in_year()}D   {hours_left_in_year()}H"

    def update_label_style(self):
        self.timer_label.setFont(self.timer_font)
        self.timer_label.setStyleSheet(f"color: {self.font_color.name()};")

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing)

        if self.use_gradient and len(self.gradient_colors) >= 2:
            gradient = QLinearGradient(0, 0, self.width(), self.height())
            step = 1.0 / (len(self.gradient_colors) - 1)
            for i, color in enumerate(self.gradient_colors):
                gradient.setColorAt(i * step, color)
            painter.setBrush(QBrush(gradient))
        else:
            brush = QBrush(self.bg_color)
            painter.setBrush(brush)

        painter.setPen(Qt.PenStyle.NoPen)
        painter.drawRoundedRect(self.rect(), 20, 20)
        painter.end()

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton and not getattr(self, 'is_locked', False):
            self.old_pos = event.globalPosition().toPoint()

    def mouseMoveEvent(self, event):
        if hasattr(self, 'old_pos') and not getattr(self, 'is_locked', False):
            delta = event.globalPosition().toPoint() - self.old_pos
            self.move(self.x() + delta.x(), self.y() + delta.y())
            self.old_pos = event.globalPosition().toPoint()

    def mouseReleaseEvent(self, event):
        if hasattr(self, 'old_pos'):
            del self.old_pos

        settings = QSettings("BitekoiLabs", "Everlastimer")
        settings.setValue("widget_pos", self.pos())

    def closeEvent(self, event):
        settings = QSettings("BitekoiLabs", "Everlastimer")
        settings.setValue("widget_pos", self.pos())
        event.accept()
# _____________________________CONTAINER__________________________________________
class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint)
        self.setAttribute(Qt.WidgetAttribute.WA_DeleteOnClose)  # Ensure proper cleanup

        # Load the background image
        background_image_path = resource_path("assets/background/background_image.jpg")
        self.background = QPixmap(background_image_path)

        # fixing size for the background
        self.setWindowTitle('EVERLASTIMER')
        self.setFixedSize(600, 400)

        # Track if window is minimized
        self.is_minimized = False

        # Initialize the old position for window dragging
        self.old_pos = QPoint()

        self.stack = QStackedLayout(self)

        self.home_page = HomePage(self)
        self.settings_page = SettingsPage(self)
        # self.settings_page.recreate_toggle_with_timer()
        self.donate_page = DonatePage(self)
        self.social_page = SocialPage(self)
        self.faq_page = FaqPage(self)

        self.floating_timer = FloatingTimer(self)
        self.floating_timer.show()

        self.settings_page.floating_timer = self.floating_timer
        self.floating_timer.open_main_app_callback = self.settings_page.show_main_app

        # Changed order to match request. Settings  now index 0.
        self.stack.addWidget(self.settings_page)
        self.stack.addWidget(self.donate_page)
        self.stack.addWidget(self.social_page)
        self.stack.addWidget(self.faq_page)
        self.stack.addWidget(self.home_page)

        self.stack.setCurrentIndex(4)  # Show HomePage first

        # SETTINGS UP THE ICON FOT THE APP
        app_icon_path = resource_path("assets/logos/primary_logo.ico")  # Adjust path and filename as needed
        self.setWindowIcon(QIcon(app_icon_path))

        # SETTING UP THE SYSTEM TRAY ICON
        self.tray_icon = None  # Initialize to None

        if QSystemTrayIcon.isSystemTrayAvailable():
            self.tray_icon = QSystemTrayIcon(self)

            # 1. Set the icon for the system tray
            tray_icon_path = resource_path("assets/logos/secondary_logo.ico")
            self.tray_icon.setIcon(QIcon(tray_icon_path))
            self.tray_icon.setToolTip("Everlastimer")

            # 2. Create a context menu for the tray icon (right-click options)
            tray_menu = QMenu()

            show_action = tray_menu.addAction("Show Everlastimer")
            show_action.triggered.connect(self.showNormal)  # to show the main window

            hide_action = tray_menu.addAction("Hide Everlastimer")
            hide_action.triggered.connect(self.hide)  # to hide the main window

            # Add a separator
            tray_menu.addSeparator()

            quit_action = tray_menu.addAction("Quit")
            quit_action.triggered.connect(QApplication.instance().quit)  # to quit the app

            self.tray_icon.setContextMenu(tray_menu)

            # 3. Handle activation (e.g., single click to show/hide)
            self.tray_icon.activated.connect(self.on_tray_icon_activated)

            # Show the tray icon
            self.tray_icon.show()

        else:
            QMessageBox.warning(self, "System Tray Unavailable",
                                "The system tray (notification area) is not available on your system. "
                                "Some features, like minimizing to tray, may not work as expected.")

    def on_tray_icon_activated(self, reason):
        if reason == QSystemTrayIcon.ActivationReason.Trigger:
            if self.isVisible():
                self.hide()
            else:
                self.showNormal()
                self.activateWindow()

    def paintEvent(self, event):
        """Override paintEvent to draw the background image"""
        if hasattr(self, 'background') and self.background and not self.background.isNull():
            painter = QPainter(self)
            # Scale the image to fit the window while maintaining aspect ratio
            scaled_bg = self.background.scaled(
                self.size(),
                Qt.AspectRatioMode.KeepAspectRatioByExpanding,
                Qt.TransformationMode.SmoothTransformation
            )
            painter.drawPixmap(self.rect(), scaled_bg)
            painter.end()

        # Call the parent paintEvent to ensure proper widget painting
        super().paintEvent(event)

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self.old_pos = event.globalPosition().toPoint()

    def mouseMoveEvent(self, event):
        if event.buttons() == Qt.MouseButton.LeftButton:
            delta = event.globalPosition().toPoint() - self.old_pos
            self.move(self.x() + delta.x(), self.y() + delta.y())
            self.old_pos = event.globalPosition().toPoint()

    def closeEvent(self, event):
        """
        Handles the window close event.
        - If the tray icon is available, it minimizes the app to the tray.
        - Otherwise, it ensures all child widgets are closed for a clean shutdown.
        """
        # This conditional logic is from your first implementation
        if self.tray_icon and self.tray_icon.isVisible():
            # Instead of closing, hide the window and show a notification
            event.ignore()  # This prevents the application from closing
            self.hide()
            self.tray_icon.showMessage("Everlastimer", "Application minimized to tray.",
                                       QSystemTrayIcon.MessageIcon.Information, 2000)
        else:
            # This cleanup logic is from your second implementation
            # It runs only when the app is actually meant to close.
            for i in range(self.stack.count()):
                widget = self.stack.widget(i)
                if widget:
                    # Specifically find and close the floating timer if it exists
                    if hasattr(widget, 'floating_timer') and widget.floating_timer:
                        widget.floating_timer.close()
                    widget.close()

            # Finally, accept the close event to terminate the application
            event.accept()

    def showMinimized(self):
        # Properly minimize the window
        self.is_minimized = True
        super().showMinimized()

    def showNormal(self):
        # Restore window from minimized state
        self.is_minimized = False
        super().showNormal()

    def recreate_toggle_with_timer(self):
        # Recreate and update toggle based on actual floating_timer visibility
        toggle = self.create_toggle()
        group = self.findChild(QFrame)  # Find the panel containing the toggles
        if group:
            layout = group.layout()
            for i in range(layout.count()):
                item_layout = layout.itemAt(i)
                if isinstance(item_layout, QVBoxLayout):
                    label_widget = item_layout.itemAt(0).widget()
                    if isinstance(label_widget, QLabel) and label_widget.text() == "Display label":
                        # Remove old toggle and insert new one
                        old_toggle = item_layout.itemAt(1).widget()
                        if old_toggle:
                            item_layout.removeWidget(old_toggle)
                            old_toggle.deleteLater()
                        item_layout.insertWidget(1, toggle)
                        break


# _______________________________DONATE PAGE________________________________________
class DonatePage(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.parent_widget = parent
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint)
        self.setAttribute(Qt.WidgetAttribute.WA_DeleteOnClose)
        self.resize(600, 400)
        self.old_pos = self.pos()
        self.floating_timer = None  # Initialize to None for safe access

        self.setStyleSheet("background-color: transparent;")

        # Create components
        self.emitter = SignalEmitter()
        self.init_ui()
        # self.setup_connections()

    # main layout and close and minibize buttons
    def init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(4, 4, 4, 4)
        layout.setSpacing(0)

        # Title bar
        title_bar = QHBoxLayout()
        title_bar.setContentsMargins(10, 0, 10, 0)
        title = QLabel("EVERLASTIMER")
        title_bar.addWidget(title)
        title_bar.addStretch()

        minimize_btn = QPushButton("-")
        minimize_btn.setFixedSize(30, 30)
        minimize_btn.clicked.connect(self.minimize_window)
        title_bar.addWidget(minimize_btn)

        close_btn = QPushButton("×")
        close_btn.setFixedSize(30, 30)
        close_btn.setStyleSheet("color: #ff4545  ; background: transparent; font-size: 18px;")
        close_btn.clicked.connect(self.close_window)
        title_bar.addWidget(close_btn)

        layout.addLayout(title_bar)

        # Timer controls frame
        controls_frame = QFrame()
        controls_layout = QVBoxLayout(controls_frame)
        controls_layout.setContentsMargins(10, 10, 10, 10)

        # Add timer controls
        self.create_timer_controls(controls_layout)

        layout.addWidget(controls_frame)
        layout.addStretch()

    def minimize_window(self):
        # Properly minimize the main window
        if self.parent_widget:
            self.parent_widget.showMinimized()
        else:
            self.showMinimized()

    def close_window(self):
        # Properly close the main window
        if self.parent_widget:
            self.parent_widget.close()
        else:
            self.close()

    def create_timer_controls(self, layout):
        # Create a horizontal layout to hold both menu and right panel
        main_hbox = QHBoxLayout()

        menu_container = QVBoxLayout()
        menu_container.setAlignment(Qt.AlignmentFlag.AlignTop)

        right_panel = QVBoxLayout()
        right_panel.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignTop)
        right_panel.setContentsMargins(0, 115, 245, 0)  # Right margin for spacing

        menu = QPushButton()
        menu.setFixedSize(50, 50)
        menu_icon_path = resource_path("assets/menu/menu_icon.png")
        menu_icon = QIcon(menu_icon_path)
        menu.setIcon(menu_icon)
        menu.setIconSize(QSize(50, 50))
        menu.setStyleSheet("background-color: transparent; border: none;")

        home = QPushButton()
        home.setVisible(False)
        home.setFixedSize(50, 50)
        home_icon_path = resource_path("assets/menu/home_icon.png")
        home_icon = QIcon(home_icon_path)
        home.setIcon(home_icon)
        home.setIconSize(QSize(50, 50))
        home.setStyleSheet("background-color: transparent; border: none;")

        settings = QPushButton()
        settings.setVisible(False)
        settings.setFixedSize(50, 50)
        settings_icon_path = resource_path("assets/menu/settings_icon.png")
        settings_icon = QIcon(settings_icon_path)
        settings.setIcon(settings_icon)
        settings.setIconSize(QSize(50, 50))
        settings.setStyleSheet("background-color: transparent; border: none;")

        social = QPushButton()
        social.setVisible(False)
        social.setFixedSize(50, 50)
        social_icon_path = resource_path("assets/menu/social.png")
        social_icon = QIcon(social_icon_path)
        social.setIcon(social_icon)
        social.setIconSize(QSize(50, 50))
        social.setStyleSheet("background-color: transparent; border: none;")

        faq = QPushButton()
        faq.setVisible(False)
        faq.setFixedSize(50, 50)
        faq_icon_path = resource_path("assets/menu/faq_icon.png")
        faq_icon = QIcon(faq_icon_path)
        faq.setIcon(faq_icon)
        faq.setIconSize(QSize(50, 50))
        faq.setStyleSheet("background-color: transparent; border: none;")

        donate_menu_button = QPushButton()
        donate_menu_button.setVisible(False)
        donate_menu_button.setFixedSize(50, 50)
        donate_icon_path = resource_path("assets/menu/donate_icon.png")
        donate_icon = QIcon(donate_icon_path)
        donate_menu_button.setIcon(donate_icon)
        donate_menu_button.setIconSize(QSize(50, 50))
        donate_menu_button.setStyleSheet("background-color: transparent; border: none;")

        menu_container.addWidget(menu)
        menu_container.addWidget(home)
        menu_container.addWidget(settings)
        menu_container.addWidget(social)
        menu_container.addWidget(faq)
        menu_container.addWidget(donate_menu_button)

        home.clicked.connect(self.goto_home)
        donate_menu_button.clicked.connect(self.goto_donate)
        social.clicked.connect(self.goto_social)
        faq.clicked.connect(self.goto_faq)
        settings.clicked.connect(self.goto_settings)

        # menu button connections
        menu.clicked.connect(lambda: home.setVisible(not home.isVisible()))
        menu.clicked.connect(lambda: social.setVisible(not social.isVisible()))
        menu.clicked.connect(lambda: faq.setVisible(not faq.isVisible()))
        menu.clicked.connect(lambda: donate_menu_button.setVisible(not donate_menu_button.isVisible()))
        menu.clicked.connect(lambda: settings.setVisible(not settings.isVisible()))

        donate_link_button = QPushButton()
        donate_link_button.setFixedSize(100, 100)

        donate_link_button_icon_path = resource_path("assets/menu/donate_link_icon.png")
        donate_link_button_icon = QIcon(donate_link_button_icon_path)
        donate_link_button.setIcon(donate_link_button_icon)
        donate_link_button.setIconSize(QSize(400, 400))
        donate_link_button.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        donate_link_button.clicked.connect(
            lambda: QDesktopServices.openUrl(QUrl("https://linktr.ee/student_success_hq")))

        right_panel.addWidget(donate_link_button, alignment=Qt.AlignmentFlag.AlignCenter)
        right_panel.addStretch()

        main_hbox.addLayout(menu_container)
        main_hbox.addStretch()
        main_hbox.addLayout(right_panel)

        # Add the main horizontal layout to the controls layout
        layout.addLayout(main_hbox)

    def closeEvent(self, event):
        if hasattr(self, 'floating_timer') and self.floating_timer:
            self.floating_timer.close()
        event.accept()

    # page movement
    def goto_home(self):
        if self.parent_widget and self.parent_widget.stack.count() > 4:
            self.parent_widget.stack.setCurrentIndex(4)

    def goto_donate(self):
        if self.parent_widget and self.parent_widget.stack.count() > 1:
            self.parent_widget.stack.setCurrentIndex(1)

    def goto_settings(self):
        if self.parent_widget and self.parent_widget.stack.count() > 0:
            self.parent_widget.stack.setCurrentIndex(0)

    def goto_social(self):
        if self.parent_widget and self.parent_widget.stack.count() > 2:
            self.parent_widget.stack.setCurrentIndex(2)

    def goto_faq(self):
        if self.parent_widget and self.parent_widget.stack.count() > 3:
            self.parent_widget.stack.setCurrentIndex(3)


# __________________________________SOCIAL PAGE_____________________________________
class SocialPage(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.parent_widget = parent
        # setting up the window
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint)
        self.setAttribute(Qt.WidgetAttribute.WA_DeleteOnClose)
        self.resize(600, 400)
        self.old_pos = self.pos()
        self.floating_timer = None

        self.setStyleSheet("background-color: transparent;")

        # Create components
        self.emitter = SignalEmitter()
        self.init_ui()
        # self.setup_connections()

    # main layout and close and minimize buttons
    def init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(4, 4, 4, 4)
        layout.setSpacing(0)

        # Title bar
        title_bar = QHBoxLayout()
        title_bar.setContentsMargins(10, 0, 10, 0)
        title = QLabel("EVERLASTIMER")
        title_bar.addWidget(title)
        title_bar.addStretch()

        minimize_btn = QPushButton("-")
        minimize_btn.setFixedSize(30, 30)
        minimize_btn.clicked.connect(self.minimize_window)
        title_bar.addWidget(minimize_btn)

        close_btn = QPushButton("×")
        close_btn.setFixedSize(30, 30)
        close_btn.setStyleSheet("color: #ff4545  ; background: transparent; font-size: 18px;")
        close_btn.clicked.connect(self.close_window)
        title_bar.addWidget(close_btn)

        layout.addLayout(title_bar)

        # Timer controls frame
        controls_frame = QFrame()
        controls_layout = QVBoxLayout(controls_frame)
        controls_layout.setContentsMargins(10, 10, 10, 10)

        # Add timer controls
        self.create_timer_controls(controls_layout)

        layout.addWidget(controls_frame)
        layout.addStretch()

    def minimize_window(self):
        # Properly minimize the main window
        if self.parent_widget:
            self.parent_widget.showMinimized()
        else:
            self.showMinimized()

    def close_window(self):
        # Properly close the main window
        if self.parent_widget:
            self.parent_widget.close()
        else:
            self.close()

    def create_timer_controls(self, layout):
        main_hbox = QHBoxLayout()

        menu_container = QVBoxLayout()
        menu_container.setAlignment(Qt.AlignmentFlag.AlignTop)

        right_panel = QVBoxLayout()
        right_panel.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignTop)
        right_panel.setContentsMargins(0, 115, 245, 0)  # Right margin for spacing

        menu = QPushButton()
        menu.setFixedSize(50, 50)
        menu_icon_path = resource_path("assets/menu/menu_icon.png")
        menu_icon = QIcon(menu_icon_path)
        menu.setIcon(menu_icon)
        menu.setIconSize(QSize(50, 50))
        menu.setStyleSheet("background-color: transparent; border: none;")

        home = QPushButton()
        home.setVisible(False)
        home.setFixedSize(50, 50)
        home_icon_path = resource_path("assets/menu/home_icon.png")
        home_icon = QIcon(home_icon_path)
        home.setIcon(home_icon)
        home.setIconSize(QSize(50, 50))
        home.setStyleSheet("background-color: transparent; border: none;")

        settings = QPushButton()
        settings.setVisible(False)
        settings.setFixedSize(50, 50)
        settings_icon_path = resource_path("assets/menu/settings_icon.png")
        settings_icon = QIcon(settings_icon_path)
        settings.setIcon(settings_icon)
        settings.setIconSize(QSize(50, 50))
        settings.setStyleSheet("background-color: transparent; border: none;")

        social = QPushButton()
        social.setVisible(False)
        social.setFixedSize(50, 50)
        social_icon_path = resource_path("assets/menu/social.png")
        social_icon = QIcon(social_icon_path)
        social.setIcon(social_icon)
        social.setIconSize(QSize(50, 50))
        social.setStyleSheet("background-color: transparent; border: none;")

        faq = QPushButton()
        faq.setVisible(False)
        faq.setFixedSize(50, 50)
        faq_icon_path = resource_path("assets/menu/faq_icon.png")
        faq_icon = QIcon(faq_icon_path)
        faq.setIcon(faq_icon)
        faq.setIconSize(QSize(50, 50))
        faq.setStyleSheet("background-color: transparent; border: none;")

        donate_menu_button = QPushButton()
        donate_menu_button.setVisible(False)
        donate_menu_button.setFixedSize(50, 50)
        donate_icon_path = resource_path("assets/menu/donate_icon.png")
        donate_icon = QIcon(donate_icon_path)
        donate_menu_button.setIcon(donate_icon)
        donate_menu_button.setIconSize(QSize(50, 50))
        donate_menu_button.setStyleSheet("background-color: transparent; border: none;")

        menu_container.addWidget(menu)
        menu_container.addWidget(home)
        menu_container.addWidget(settings)
        menu_container.addWidget(social)
        menu_container.addWidget(faq)
        menu_container.addWidget(donate_menu_button)

        home.clicked.connect(self.goto_home)
        donate_menu_button.clicked.connect(self.goto_donate)
        social.clicked.connect(self.goto_social)
        faq.clicked.connect(self.goto_faq)
        settings.clicked.connect(self.goto_settings)

        # menu button connections
        menu.clicked.connect(lambda: home.setVisible(not home.isVisible()))
        menu.clicked.connect(lambda: social.setVisible(not social.isVisible()))
        menu.clicked.connect(lambda: faq.setVisible(not faq.isVisible()))
        menu.clicked.connect(lambda: donate_menu_button.setVisible(not donate_menu_button.isVisible()))
        menu.clicked.connect(lambda: settings.setVisible(not settings.isVisible()))

        social_link_button = QPushButton()
        social_link_button.setFixedSize(100, 100)
        social_link_button_icon_path = resource_path("assets/menu/social_link_icon.png")
        social_link_button_icon = QIcon(social_link_button_icon_path)
        social_link_button.setIcon(social_link_button_icon)
        social_link_button.setIconSize(QSize(400, 400))
        social_link_button.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        social_link_button.clicked.connect(
            lambda: QDesktopServices.openUrl(QUrl("https://www.instagram.com/bitekoi.labs")))

        right_panel.addWidget(social_link_button, alignment=Qt.AlignmentFlag.AlignCenter)
        right_panel.addStretch()

        main_hbox.addLayout(menu_container)
        main_hbox.addStretch()
        main_hbox.addLayout(right_panel)

        # Adding the main horizontal layout to the controls layout
        layout.addLayout(main_hbox)

    def closeEvent(self, event):
        if hasattr(self, 'floating_timer') and self.floating_timer:
            self.floating_timer.close()
        event.accept()

    # page movement
    def goto_home(self):
        if self.parent_widget and self.parent_widget.stack.count() > 4:
            self.parent_widget.stack.setCurrentIndex(4)

    def goto_donate(self):
        if self.parent_widget and self.parent_widget.stack.count() > 1:
            self.parent_widget.stack.setCurrentIndex(1)

    def goto_settings(self):
        if self.parent_widget and self.parent_widget.stack.count() > 0:
            self.parent_widget.stack.setCurrentIndex(0)

    def goto_social(self):
        if self.parent_widget and self.parent_widget.stack.count() > 2:
            self.parent_widget.stack.setCurrentIndex(2)

    def goto_faq(self):
        if self.parent_widget and self.parent_widget.stack.count() > 3:
            self.parent_widget.stack.setCurrentIndex(3)


# __________________________________FAQ PAGE______________________________________
class FaqPage(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.parent_widget = parent
        # setting up the window
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint)
        self.setAttribute(Qt.WidgetAttribute.WA_DeleteOnClose)
        self.resize(600, 400)
        self.old_pos = self.pos()
        self.floating_timer = None

        self.setStyleSheet("background-color: transparent;")

        # Create components
        self.emitter = SignalEmitter()
        self.init_ui()

    # main layout and close and mininize buttons
    def init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(4, 4, 4, 4)
        layout.setSpacing(0)

        # Title bar
        title_bar = QHBoxLayout()
        title_bar.setContentsMargins(10, 0, 10, 0)
        title = QLabel("EVERLASTIMER")
        title_bar.addWidget(title)
        title_bar.addStretch()

        minimize_btn = QPushButton("-")
        minimize_btn.setFixedSize(30, 30)
        minimize_btn.clicked.connect(self.minimize_window)
        title_bar.addWidget(minimize_btn)

        close_btn = QPushButton("×")
        close_btn.setFixedSize(30, 30)
        close_btn.setStyleSheet("color: #ff4545  ; background: transparent; font-size: 18px;")
        close_btn.clicked.connect(self.close_window)
        title_bar.addWidget(close_btn)

        layout.addLayout(title_bar)

        # Timer controls frame
        controls_frame = QFrame()
        controls_layout = QVBoxLayout(controls_frame)
        controls_layout.setContentsMargins(10, 10, 10, 10)

        # Add timer controls
        self.create_timer_controls(controls_layout)

        layout.addWidget(controls_frame)
        layout.addStretch()

    def minimize_window(self):
        # Properly minimize the main window
        if self.parent_widget:
            self.parent_widget.showMinimized()
        else:
            self.showMinimized()

    def close_window(self):
        # Properly close the main window
        if self.parent_widget:
            self.parent_widget.close()
        else:
            self.close()

    def create_timer_controls(self, layout):
        main_hbox = QHBoxLayout()

        menu_container = QVBoxLayout()
        menu_container.setAlignment(Qt.AlignmentFlag.AlignTop)

        right_panel = QVBoxLayout()
        right_panel.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignTop)
        right_panel.setContentsMargins(0, 0, 10, 10)  # Right margin for spacing

        menu = QPushButton()
        menu.setFixedSize(50, 50)
        menu_icon_path = resource_path("assets/menu/menu_icon.png")
        menu_icon = QIcon(menu_icon_path)
        menu.setIcon(menu_icon)
        menu.setIconSize(QSize(50, 50))
        menu.setStyleSheet("background-color: transparent; border: none;")

        home = QPushButton()
        home.setVisible(False)
        home.setFixedSize(50, 50)
        home_icon_path = resource_path("assets/menu/home_icon.png")
        home_icon = QIcon(home_icon_path)
        home.setIcon(home_icon)
        home.setIconSize(QSize(50, 50))
        home.setStyleSheet("background-color: transparent; border: none;")

        settings = QPushButton()
        settings.setVisible(False)
        settings.setFixedSize(50, 50)
        settings_icon_path = resource_path("assets/menu/settings_icon.png")
        settings_icon = QIcon(settings_icon_path)
        settings.setIcon(settings_icon)
        settings.setIconSize(QSize(50, 50))
        settings.setStyleSheet("background-color: transparent; border: none;")

        social = QPushButton()
        social.setVisible(False)
        social.setFixedSize(50, 50)
        social_icon_path = resource_path("assets/menu/social.png")
        social_icon = QIcon(social_icon_path)
        social.setIcon(social_icon)
        social.setIconSize(QSize(50, 50))
        social.setStyleSheet("background-color: transparent; border: none;")

        faq = QPushButton()
        faq.setVisible(False)
        faq.setFixedSize(50, 50)
        faq_icon_path = resource_path("assets/menu/faq_icon.png")
        faq_icon = QIcon(faq_icon_path)
        faq.setIcon(faq_icon)
        faq.setIconSize(QSize(50, 50))
        faq.setStyleSheet("background-color: transparent; border: none;")

        donate_menu_button = QPushButton()
        donate_menu_button.setVisible(False)
        donate_menu_button.setFixedSize(50, 50)
        donate_icon_path = resource_path("assets/menu/donate_icon.png")
        donate_icon = QIcon(donate_icon_path)
        donate_menu_button.setIcon(donate_icon)
        donate_menu_button.setIconSize(QSize(50, 50))
        donate_menu_button.setStyleSheet("background-color: transparent; border: none;")

        menu_container.addWidget(menu)
        menu_container.addWidget(home)
        menu_container.addWidget(settings)
        menu_container.addWidget(social)
        menu_container.addWidget(faq)
        menu_container.addWidget(donate_menu_button)

        home.clicked.connect(self.goto_home)
        donate_menu_button.clicked.connect(self.goto_donate)
        social.clicked.connect(self.goto_social)
        faq.clicked.connect(self.goto_faq)
        settings.clicked.connect(self.goto_settings)

        # menu button connections
        menu.clicked.connect(lambda: home.setVisible(not home.isVisible()))
        menu.clicked.connect(lambda: social.setVisible(not social.isVisible()))
        menu.clicked.connect(lambda: faq.setVisible(not faq.isVisible()))
        menu.clicked.connect(lambda: donate_menu_button.setVisible(not donate_menu_button.isVisible()))
        menu.clicked.connect(lambda: settings.setVisible(not settings.isVisible()))

        self.setStyleSheet('''
        QScrollArea, QWidget #contentWidget {
            background-color: #2d1b66;
            color: white;
            border: none;
        }
            QPushButton {
                background-color: #191627;
                border-radius: 20px;
                min-width: 40px;
                min-height: 40px;
                max-width: 40px;
                max-height: 40px;
                margin: 10px 0px;
            }
            QLabel {
                color: white;
            }


        ''')
        scroll_area = QScrollArea()
        scroll_area.setWidgetResizable(True)
        content_widget = QWidget()
        content_widget.setObjectName("contentWidget")
        content_layout = QVBoxLayout(content_widget)

        patch_notes_header = QLabel("Patch Notes:")
        patch_notes_header.setFont(QFont("Arial", 16))
        content_layout.addWidget(patch_notes_header)

        # Add release notes content
        release_notes = QLabel("""
                <h3>Everlastimer v1.00 Release Notes</h3>
                <p><strong>Initial Release</strong></p>
                <p>We're excited to introduce the first official version of Everlastimer! This release marks the beginning of our journey to help you track time meaningfully.</p>

                <h3>Known Issues</h3>
                <p>As this is our initial release, you may encounter some bugs or unexpected behavior. Our team is committed to improving the user experience with each update.</p>

                <h3>How to Report Issues</h3>
                <p>If you experience any problems, please help us improve by reporting them to our support team:</p>
                <p>Email: <a href="mailto:zekernex@gmail.com" style="color: #6d4ed7;">zekernex@gmail.com</a></p>
                <p>Please include:</p>
                <ul>
                    <li>Description of the issue</li>
                    <li>Steps to reproduce</li>
                    <li>Screenshots (if applicable)</li>
                    <li>Your system specifications</li>
                </ul>

                <p>Thank You!</p>
                <p>We sincerely appreciate you choosing Everlastimer. Your feedback is invaluable as we work to enhance the application in future updates.</p>

                <h3>What's Next?</h3>
                <p>Stay tuned for upcoming features and improvements in future versions. We're already working on:</p>
                <ul>
                    <li>Enhanced customization options</li>
                    <li>Additional time tracking metrics</li>
                    <li>Improved performance</li>
                </ul>
                """)
        release_notes.setTextFormat(Qt.TextFormat.RichText)
        release_notes.setWordWrap(True)
        release_notes.setOpenExternalLinks(True)
        content_layout.addWidget(release_notes)

        # Set the scroll widget
        scroll_area.setWidget(content_widget)

        right_panel.addWidget(scroll_area)

        main_hbox.addLayout(menu_container)
        main_hbox.addStretch()
        main_hbox.addLayout(right_panel)

        # Adding the main horizontal layout to the controls layout
        layout.addLayout(main_hbox)

    def closeEvent(self, event):
        if hasattr(self, 'floating_timer') and self.floating_timer:
            self.floating_timer.close()
        event.accept()

    # page movement
    def goto_home(self):
        if self.parent_widget and self.parent_widget.stack.count() > 4:
            self.parent_widget.stack.setCurrentIndex(4)

    def goto_donate(self):
        if self.parent_widget and self.parent_widget.stack.count() > 1:
            self.parent_widget.stack.setCurrentIndex(1)

    def goto_settings(self):
        if self.parent_widget and self.parent_widget.stack.count() > 0:
            self.parent_widget.stack.setCurrentIndex(0)

    def goto_social(self):
        if self.parent_widget and self.parent_widget.stack.count() > 2:
            self.parent_widget.stack.setCurrentIndex(2)

    def goto_faq(self):
        if self.parent_widget and self.parent_widget.stack.count() > 3:
            self.parent_widget.stack.setCurrentIndex(3)


# __________________________________HOME PAGE______________________________________
class HomePage(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.parent_widget = parent
        # setting up the window
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint)
        self.setAttribute(Qt.WidgetAttribute.WA_DeleteOnClose)
        self.resize(600, 400)
        self.old_pos = self.pos()
        self.floating_timer = None

        self.setStyleSheet("background-color: transparent;")

        self.counter_labels = {}

        # Create components
        self.emitter = SignalEmitter()
        self.init_ui()
        self.update_timer = QTimer(self)
        self.update_timer.timeout.connect(self._update_counters)
        self.update_timer.start(1000)

    # main layout and close and minibize buttons
    def init_ui(self):
        layout = QVBoxLayout(self)
        layout.setContentsMargins(4, 4, 4, 4)
        layout.setSpacing(0)

        # Title bar
        title_bar = QHBoxLayout()
        title_bar.setContentsMargins(10, 0, 10, 0)
        title = QLabel("EVERLASTIMER")
        title_bar.addWidget(title)
        title_bar.addStretch()

        minimize_btn = QPushButton("-")
        minimize_btn.setFixedSize(30, 30)
        minimize_btn.clicked.connect(self.minimize_window)
        title_bar.addWidget(minimize_btn)

        close_btn = QPushButton("×")
        close_btn.setFixedSize(30, 30)
        close_btn.setStyleSheet("color: #ff4545  ; background: transparent; font-size: 18px;")
        close_btn.clicked.connect(self.close_window)
        title_bar.addWidget(close_btn)

        layout.addLayout(title_bar)

        # Timer controls frame
        controls_frame = QFrame()
        controls_layout = QVBoxLayout(controls_frame)
        controls_layout.setContentsMargins(10, 10, 10, 10)

        # Add timer controls
        self.create_timer_controls(controls_layout)

        layout.addWidget(controls_frame)
        layout.addStretch()

    def minimize_window(self):
        # Properly minimize the main window
        if self.parent_widget:
            self.parent_widget.showMinimized()
        else:
            self.showMinimized()

    def close_window(self):
        # Properly close the main window
        if self.parent_widget:
            self.parent_widget.close()
        else:
            self.close()

    def create_timer_controls(self, layout):

        main_hbox = QHBoxLayout()

        menu_container = QVBoxLayout()
        menu_container.setAlignment(Qt.AlignmentFlag.AlignTop)

        # Menu buttons
        menu = QPushButton()
        menu.setFixedSize(50, 50)
        menu_icon_path = resource_path("assets/menu/menu_icon.png")
        menu_icon = QIcon(menu_icon_path)
        menu.setIcon(menu_icon)
        menu.setIconSize(QSize(50, 50))
        menu.setStyleSheet("background-color: transparent; border: none;")

        home = QPushButton()
        home.setVisible(False)
        home.setFixedSize(50, 50)
        home_icon_path = resource_path("assets/menu/home_icon.png")
        home_icon = QIcon(home_icon_path)
        home.setIcon(home_icon)
        home.setIconSize(QSize(50, 50))
        home.setStyleSheet("background-color: transparent; border: none;")

        settings = QPushButton()
        settings.setVisible(False)
        settings.setFixedSize(50, 50)
        settings_icon_path = resource_path("assets/menu/settings_icon.png")
        settings_icon = QIcon(settings_icon_path)
        settings.setIcon(settings_icon)
        settings.setIconSize(QSize(50, 50))
        settings.setStyleSheet("background-color: transparent; border: none;")

        social = QPushButton()
        social.setVisible(False)
        social.setFixedSize(50, 50)
        social_icon_path = resource_path("assets/menu/social.png")
        social_icon = QIcon(social_icon_path)
        social.setIcon(social_icon)
        social.setIconSize(QSize(50, 50))
        social.setStyleSheet("background-color: transparent; border: none;")

        faq = QPushButton()
        faq.setVisible(False)
        faq.setFixedSize(50, 50)
        faq_icon_path = resource_path("assets/menu/faq_icon.png")
        faq_icon = QIcon(faq_icon_path)
        faq.setIcon(faq_icon)
        faq.setIconSize(QSize(50, 50))
        faq.setStyleSheet("background-color: transparent; border: none;")

        donate_menu_button = QPushButton()
        donate_menu_button.setVisible(False)
        donate_menu_button.setFixedSize(50, 50)
        donate_icon_path = resource_path("assets/menu/donate_icon.png")
        donate_icon = QIcon(donate_icon_path)
        donate_menu_button.setIcon(donate_icon)
        donate_menu_button.setIconSize(QSize(50, 50))
        donate_menu_button.setStyleSheet("background-color: transparent; border: none;")

        menu_container.addWidget(menu)
        menu_container.addWidget(home)
        menu_container.addWidget(settings)
        menu_container.addWidget(social)
        menu_container.addWidget(faq)
        menu_container.addWidget(donate_menu_button)

        home.clicked.connect(self.goto_home)
        donate_menu_button.clicked.connect(self.goto_donate)
        social.clicked.connect(self.goto_social)
        faq.clicked.connect(self.goto_faq)
        settings.clicked.connect(self.goto_settings)

        # Menu button connections
        menu.clicked.connect(lambda: home.setVisible(not home.isVisible()))
        menu.clicked.connect(lambda: social.setVisible(not social.isVisible()))
        menu.clicked.connect(lambda: faq.setVisible(not faq.isVisible()))
        menu.clicked.connect(lambda: donate_menu_button.setVisible(not donate_menu_button.isVisible()))
        menu.clicked.connect(lambda: settings.setVisible(not settings.isVisible()))

        # Creating center content layout with progress bar
        center_content = QVBoxLayout()
        center_content.setAlignment(Qt.AlignmentFlag.AlignCenter)
        center_content.setContentsMargins(0, 20, 70, 0)

        # Progress bar
        self.progress_bar = CircularProgressBar()
        self.progress_bar.setFixedSize(180, 180)
        center_content.addWidget(self.progress_bar, 1, Qt.AlignmentFlag.AlignCenter)

        # right, vetical, left, up
        center_content.addSpacing(15)  # Adding space between progress bar and counters

        # Timer counters grid
        counters_grid = QGridLayout()
        counters_grid.setHorizontalSpacing(35)  # Space between columns
        counters_grid.setVerticalSpacing(5)  # Space between rows

        label_colors = {
            "MONTHS": "#d5cbec",  # Orange-red
            "WEEKS": "#b9b0cc",  # Green
            "DAYS": "#b4abca",  # Blue
            "HOURS": "#a49cb6"  # Purple
        }

        counters = [
            {"value": str(months_left()), "label": "MONTHS".strip()},
            {"value": str(weeks_left_in_year()), "label": "WEEKS".strip()},
            {"value": str(days_left_in_year()), "label": "DAYS".strip()},
            {"value": str(hours_left_in_year()), "label": "HOURS".strip()}
        ]

        for col, counter in enumerate(counters):
            # Creating circle widget with counter value
            circle_widget = QWidget()
            circle_widget.setFixedSize(60, 60)
            circle_widget.setStyleSheet("""
                background-color: #d5cbec;
                border-radius: 30px;
            """)

            # Adding centered value inside circle
            self.counter_labels[counter["label"]] = QLabel(counter["value"])
            counter_label = self.counter_labels[counter["label"]]
            counter_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            counter_label.setStyleSheet("""
                font-size: 18px;
                font-weight: bold;
                color: black;
            """)

            circle_layout = QVBoxLayout(circle_widget)
            circle_layout.addWidget(counter_label)

            # Creating unit label with color from dictionary
            unit_label = QLabel(counter["label"])
            unit_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
            unit_label.setStyleSheet(f"""
                font-size: 18px;
                color: {label_colors[counter["label"]]};
                font: Anton;
                font-weight: 1000;
                margin-top: 5px;
            """)
            # Adding to grid
            counters_grid.addWidget(circle_widget, 0, col)
            counters_grid.addWidget(unit_label, 1, col)
        # Adding counters grid to center content
        center_content.addLayout(counters_grid)

        # Adding layouts to main horizontal layout
        main_hbox.addLayout(menu_container)
        main_hbox.addStretch(1)
        main_hbox.addLayout(center_content)
        main_hbox.addStretch(1)

        # Adding the main horizontal layout to the controls layout
        layout.addLayout(main_hbox)

    def closeEvent(self, event):
        if hasattr(self, 'floating_timer') and self.floating_timer:
            self.floating_timer.close()
        event.accept()

    # page movement
    def goto_home(self):
        if self.parent_widget and self.parent_widget.stack.count() > 4:
            self.parent_widget.stack.setCurrentIndex(4)

    def goto_donate(self):
        if self.parent_widget and self.parent_widget.stack.count() > 1:
            self.parent_widget.stack.setCurrentIndex(1)

    def goto_settings(self):
        if self.parent_widget and self.parent_widget.stack.count() > 0:
            self.parent_widget.stack.setCurrentIndex(0)

    def goto_social(self):
        if self.parent_widget and self.parent_widget.stack.count() > 2:
            self.parent_widget.stack.setCurrentIndex(2)

    def goto_faq(self):
        if self.parent_widget and self.parent_widget.stack.count() > 3:
            self.parent_widget.stack.setCurrentIndex(3)

    def _update_counters(self):
        """Recalculates time values and updates the UI."""
        self.counter_labels["MONTHS"].setText(str(months_left()))
        self.counter_labels["WEEKS"].setText(str(weeks_left_in_year()))
        self.counter_labels["DAYS"].setText(str(days_left_in_year()))
        self.counter_labels["HOURS"].setText(str(hours_left_in_year()))

        # updating the CircularProgressBar
        if hasattr(self, 'progress_bar'):
            self.progress_bar.setvalue(percentage_of_year_passed())


# _____________________________SETTINGS PAGE__________________________________________
class SettingsPage(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.parent_widget = parent
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint)
        self.setAttribute(Qt.WidgetAttribute.WA_DeleteOnClose)
        self.resize(600, 400)
        self.old_pos = self.pos()
        # self.floating_timer = FloatingTimer()

        self.floating_timer = None
        self.setStyleSheet("background-color: transparent;")
        self.emitter = SignalEmitter()
        self.init_ui()
        self.setup_connections()

        self.settings = QSettings("BitekoiLabs", "Everlastimer")
        # self.floating_timer.open_main_app_callback = self.show_main_app

    def init_ui(self):
        # Main layout - Standardized to match other pages
        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(4, 4, 4, 4)
        main_layout.setSpacing(0)

        # Title bar (same as other pages)
        title_bar = QHBoxLayout()
        title_bar.setContentsMargins(10, 0, 10, 0)

        title = QLabel("EVERLASTIMER")
        title_bar.addWidget(title)
        title_bar.addStretch()

        minimize_btn = QPushButton("-")
        minimize_btn.setFixedSize(30, 30)
        minimize_btn.clicked.connect(self.minimize_window)
        title_bar.addWidget(minimize_btn)

        close_btn = QPushButton("×")
        close_btn.setFixedSize(30, 30)
        close_btn.setStyleSheet("color: #ff4545; background: transparent; font-size: 18px;")
        close_btn.clicked.connect(self.close_window)
        title_bar.addWidget(close_btn)

        main_layout.addLayout(title_bar)

        # Controls Frame - Standardized to match other pages
        controls_frame = QFrame()
        controls_frame.setStyleSheet("background-color: transparent;")
        controls_layout = QVBoxLayout(controls_frame)
        controls_layout.setContentsMargins(10, 10, 10, 10)
        controls_layout.setSpacing(0)

        # Create the main content (menu + settings panel)
        self.create_main_content(controls_layout)

        main_layout.addWidget(controls_frame)
        main_layout.addStretch()

    def create_main_content(self, layout):
        """Creates and adds the main hbox (menu + settings) to the provided layout."""
        # Main content layout
        main_hbox = QHBoxLayout()
        main_hbox.setContentsMargins(0, 0, 0, 0)
        main_hbox.setSpacing(0)

        # --- Left side: Menu container ---
        menu_container = QVBoxLayout()
        menu_container.setAlignment(Qt.AlignmentFlag.AlignTop)

        # Menu button
        menu = QPushButton()
        menu.setFixedSize(50, 50)
        menu_icon_path = resource_path("assets/menu/menu_icon.png")
        menu_icon = QIcon(menu_icon_path)
        menu.setIcon(menu_icon)
        menu.setIconSize(QSize(50, 50))
        menu.setStyleSheet("background-color: transparent; border: none;")

        home = QPushButton()
        home.setVisible(False)
        home.setFixedSize(50, 50)
        home_icon_path = resource_path("assets/menu/home_icon.png")
        home_icon = QIcon(home_icon_path)
        home.setIcon(home_icon)
        home.setIconSize(QSize(50, 50))
        home.setStyleSheet("background-color: transparent; border: none;")

        settings_btn = QPushButton()
        settings_btn.setVisible(False)
        settings_btn.setFixedSize(50, 50)
        settings_icon_path = resource_path("assets/menu/settings_icon.png")
        settings_icon = QIcon(settings_icon_path)
        settings_btn.setIcon(settings_icon)
        settings_btn.setIconSize(QSize(50, 50))
        settings_btn.setStyleSheet("background-color: transparent; border: none;")

        social = QPushButton()
        social.setVisible(False)
        social.setFixedSize(50, 50)
        social_icon_path = resource_path("assets/menu/social.png")
        social_icon = QIcon(social_icon_path)
        social.setIcon(social_icon)
        social.setIconSize(QSize(50, 50))
        social.setStyleSheet("background-color: transparent; border: none;")

        faq = QPushButton()
        faq.setVisible(False)
        faq.setFixedSize(50, 50)
        faq_icon_path = resource_path("assets/menu/faq_icon.png")
        faq_icon = QIcon(faq_icon_path)
        faq.setIcon(faq_icon)
        faq.setIconSize(QSize(50, 50))
        faq.setStyleSheet("background-color: transparent; border: none;")

        donate_menu_button = QPushButton()
        donate_menu_button.setVisible(False)
        donate_menu_button.setFixedSize(50, 50)
        donate_icon_path = resource_path("assets/menu/donate_icon.png")
        donate_icon = QIcon(donate_icon_path)
        donate_menu_button.setIcon(donate_icon)
        donate_menu_button.setIconSize(QSize(50, 50))
        donate_menu_button.setStyleSheet("background-color: transparent; border: none;")

        # Add buttons to menu container
        menu_container.addWidget(menu)
        menu_container.addWidget(home)
        menu_container.addWidget(settings_btn)
        menu_container.addWidget(social)
        menu_container.addWidget(faq)
        menu_container.addWidget(donate_menu_button)
        menu_container.addStretch()  # Pushes buttons to the top

        # Connect navigation
        home.clicked.connect(self.goto_home)
        donate_menu_button.clicked.connect(self.goto_donate)
        social.clicked.connect(self.goto_social)
        faq.clicked.connect(self.goto_faq)
        settings_btn.clicked.connect(self.goto_settings)

        # Connect menu toggle
        menu.clicked.connect(lambda: home.setVisible(not home.isVisible()))
        menu.clicked.connect(lambda: social.setVisible(not social.isVisible()))
        menu.clicked.connect(lambda: faq.setVisible(not faq.isVisible()))
        menu.clicked.connect(lambda: donate_menu_button.setVisible(not donate_menu_button.isVisible()))
        menu.clicked.connect(lambda: settings_btn.setVisible(not settings_btn.isVisible()))

        # --- Right side: Settings panel ---
        settings_panel = QScrollArea()
        settings_panel.setWidgetResizable(True)

        settings_content = QWidget()
        settings_content.setObjectName("settings_content")
        settings_layout = QVBoxLayout(settings_content)
        settings_layout.setContentsMargins(20, 0, 40, 20)
        settings_layout.setSpacing(20)

        # Panel Settings
        panel_group = self.create_settings_group(
            "Panel Settings",
            [
                ("Panel Color", self.create_color_buttons()),
                ("Panel Transparency", self.create_slider())
            ]
        )
        settings_layout.addWidget(panel_group)

        # Timer Settings
        timer_group = self.create_settings_group(
            "Timer Settings",
            [
                ("Timer Color", self.create_color_button("Select Color")),
                ("Timer Font", self.create_color_button("Select Font")),
                ("Display label", self.create_toggle())
            ]
        )
        settings_layout.addWidget(timer_group)

        settings_layout.addStretch()
        settings_panel.setWidget(settings_content)

        # --- Adding to main HBox and then to the main VBox layout ---
        main_hbox.addLayout(menu_container)
        main_hbox.addWidget(settings_panel)

        layout.addLayout(main_hbox)

    @staticmethod
    def create_settings_group(title, items):
        group = QFrame()
        group.setStyleSheet("background-color: transparent; border: none;")  # Ensure group is transparent
        layout = QVBoxLayout(group)
        layout.setContentsMargins(15, 15, 15, 15)
        layout.setSpacing(15)

        # Title
        title_label = QLabel(title)
        title_label.setStyleSheet("""
            QLabel {
                color: white;
                font-size: 18px;
                font-weight: bold;
            }
        """)
        layout.addWidget(title_label)

        # Items
        for item in items:
            label, widget = item
            item_layout = QVBoxLayout()
            item_layout.setSpacing(5)

            # Label
            item_label = QLabel(label)
            item_label.setStyleSheet("""
                QLabel {
                    color: #d5cbec;
                    font-size: 14px;
                }
            """)
            item_layout.addWidget(item_label)

            # Widget
            item_layout.addWidget(widget)

            layout.addLayout(item_layout)

        return group

    def create_color_buttons(self):
        container = QWidget()
        layout = QHBoxLayout(container)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)

        # Static Color Button
        static_btn = QPushButton("Solid")
        static_btn.setFixedSize(120, 40)
        static_btn.setStyleSheet("""
                QPushButton {
                    background-color: #6d4ed7;
                    color: white;
                    border-radius: 5px;
                    padding: 5px;
                }
                QPushButton:hover {
                    background-color: #7d5ee7;
                }
            """)
        static_btn.clicked.connect(self.select_panel_color)
        layout.addWidget(static_btn)

        # Gradient Color Button
        gradient_btn = QPushButton("Gradient")
        gradient_btn.setFixedSize(120, 40)
        gradient_btn.setStyleSheet("""
               QPushButton {
                   background-color: #6d4ed7;
                   color: white;
                   border-radius: 5px;
                   padding: 5px;
               }
               QPushButton:hover {
                   background-color: #7d5ee7;
               }
           """)
        gradient_btn.clicked.connect(self.pick_custom_gradient)

        layout.addWidget(gradient_btn)

        # Reset to Default Button
        default_btn = QPushButton("Reset")
        default_btn.setFixedSize(120, 40)
        default_btn.setStyleSheet("""
                QPushButton {
                    background-color: #6d4ed7;
                    color: white;
                    border-radius: 5px;
                    padding: 5px;
                }
                QPushButton:hover {
                    background-color: #7d5ee7;
                }
            """)
        default_btn.clicked.connect(self.reset_panel_defaults)
        layout.addWidget(default_btn)

        return container

    def pick_custom_gradient(self):
        color1 = QColorDialog.getColor(title="Select First Gradient Color")
        if not color1.isValid():
            return

        color2 = QColorDialog.getColor(title="Select Second Gradient Color")
        if not color2.isValid():
            return

        alpha = 100
        color1.setAlpha(alpha)
        color2.setAlpha(alpha)

        self.emitter.gradient_selected.emit([color1, color2])

    def create_slider(self):
        slider = QSlider(Qt.Orientation.Horizontal)
        slider.setRange(0, 100)
        slider.setValue(100)
        slider.setStyleSheet("""
            QSlider::groove:horizontal {
                height: 8px;
                background: #555;
                border-radius: 4px;
            }
            QSlider::handle:horizontal {
                width: 18px;
                height: 18px;
                background: #aaa;
                border-radius: 9px;
                margin: -5px 0;
            }
            QSlider::sub-page:horizontal {
                background: #6d4ed7;
                border-radius: 4px;
            }
        """)
        slider.valueChanged.connect(lambda val: self.emitter.transparency_changed.emit(val))
        return slider

    def create_color_button(self, text):
        btn = QPushButton(text)
        btn.setFixedSize(120, 40)
        btn.setStyleSheet("""
            QPushButton {
                background-color: #6d4ed7;
                color: white;
                border-radius: 5px;
                padding: 5px;
            }
            QPushButton:hover {
                background-color: #7d5ee7;
            }
        """)

        if text == "Select Color":
            btn.clicked.connect(self.select_timer_color)
        elif text == "Select Font":
            btn.clicked.connect(self.select_timer_font)

        return btn

    def create_toggle(self):
        toggle = PyToggle()
        toggle.setChecked(bool(self.floating_timer and self.floating_timer.isVisible()))
        toggle.toggled.connect(self.toggle_timer_visibility)
        return toggle

    def toggle_timer_visibility(self, state):
        """Toggle the floating timer visibility based on toggle state"""
        if state:  # If toggle is on
            self.floating_timer.show()
        else:  # If toggle is off
            self.floating_timer.hide()

    def select_timer_color(self):
        color = QColorDialog.getColor()
        if color.isValid():
            self.emitter.text_color_changed.emit(color)

    def select_timer_font(self):
        font, ok = QFontDialog.getFont()
        if ok:
            self.emitter.font_changed.emit(font)

    def minimize_window(self):
        if self.parent_widget:
            self.parent_widget.showMinimized()
        else:
            self.showMinimized()

    def close_window(self):
        if self.parent_widget:
            self.parent_widget.close()
        else:
            self.close()

    def goto_home(self):
        if self.parent_widget and self.parent_widget.stack.count() > 4:
            self.parent_widget.stack.setCurrentIndex(4)

    def goto_donate(self):
        if self.parent_widget and self.parent_widget.stack.count() > 1:
            self.parent_widget.stack.setCurrentIndex(1)

    def goto_settings(self):
        if self.parent_widget and self.parent_widget.stack.count() > 0:
            self.parent_widget.stack.setCurrentIndex(0)

    def goto_social(self):
        if self.parent_widget and self.parent_widget.stack.count() > 2:
            self.parent_widget.stack.setCurrentIndex(2)

    def goto_faq(self):
        if self.parent_widget and self.parent_widget.stack.count() > 3:
            self.parent_widget.stack.setCurrentIndex(3)

    def setup_connections(self):
        def handle_transparency(value):
            alpha = int(value / 100 * 255)
            self.settings.setValue("panel_transparency", alpha)
            if self.floating_timer.use_gradient:
                updated_colors = []
                for color in self.floating_timer.gradient_colors:
                    new_color = QColor(color.red(), color.green(), color.blue(), alpha)
                    updated_colors.append(new_color)
                self.floating_timer.gradient_colors = updated_colors
            else:
                old = self.floating_timer.bg_color
                self.floating_timer.bg_color = QColor(old.red(), old.green(), old.blue(), alpha)
            self.floating_timer.update()

        self.emitter.transparency_changed.connect(handle_transparency)

        self.emitter.color_selected.connect(lambda color: (
            self.settings.setValue("bg_color", color.name(QColor.NameFormat.HexArgb)),
            setattr(self.floating_timer, 'bg_color', color),
            setattr(self.floating_timer, 'use_gradient', False),
            self.floating_timer.update()
        ))

        self.emitter.gradient_selected.connect(lambda colors: (
            self.settings.setValue("gradient_color_1", colors[0].name(QColor.NameFormat.HexArgb)),
            self.settings.setValue("gradient_color_2", colors[1].name(QColor.NameFormat.HexArgb)),
            setattr(self.floating_timer, 'gradient_colors', colors),
            setattr(self.floating_timer, 'use_gradient', True),
            self.floating_timer.update()
        ))

        self.emitter.text_color_changed.connect(lambda color: (
            self.settings.setValue("font_color", color.name()),
            setattr(self.floating_timer, 'font_color', color),
            self.floating_timer.update_label_style()
        ))

        self.emitter.font_changed.connect(lambda font: (
            self.settings.setValue("font_family", font.family()),
            self.settings.setValue("font_size", font.pointSize()),
            setattr(self.floating_timer, 'timer_font', font),
            self.floating_timer.timer_label.setFont(font)
        ))

    def select_panel_color(self):
        color = QColorDialog.getColor()
        if color.isValid():
            self.emitter.color_selected.emit(color)

    def reset_panel_defaults(self):
        self.emitter.text_color_changed.emit(QColor(255, 255, 255))  # Reset text color
        default_color = QColor(100, 100, 100, 200)
        self.emitter.color_selected.emit(default_color)
        self.emitter.transparency_changed.emit(80)

    def show_main_app(self):
        self.show()  # Bringing main app window to front


# __________________________EXIT___________________________________________
if __name__ == "__main__":
    if not is_in_startup():
        add_to_startup()

    app = QApplication(sys.argv)

    autostart_mode = "--autostart" in sys.argv

    if autostart_mode:
        # Start only the floating widget
        floating_timer = FloatingTimer()
        floating_timer.show()
    else:
        # Start full application
        main_window = MainWindow()
        main_window.show()

    sys.exit(app.exec())


