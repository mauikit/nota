QT *= qml \
     quick \
     sql

CONFIG += ordered
CONFIG += c++17

TARGET = nota
TEMPLATE = app

linux:unix:!android {

    message(Building for Linux KDE)
    QT += webengine
    LIBS += -lMauiKit

} else:android {

    message(Building for Android)
    QMAKE_LINK += -nostdlib++
    ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android_files

    DEFINES *= \
        COMPONENT_FM \
        COMPONENT_TAGGING \
        COMPONENT_EDITOR \
        MAUIKIT_STYLE \
        ANDROID_OPENSSL

    include($$PWD/3rdparty/kirigami/kirigami.pri)
    include($$PWD/3rdparty/mauikit/mauikit.pri)

    DEFINES += STATIC_KIRIGAMI

} else {
    message("Unknown configuration")
}

DEFINES += QT_DEPRECATED_WARNINGS

SOURCES += \
        $$PWD/src/main.cpp \
        $$PWD/src/models/documentsmodel.cpp

HEADERS += \
        $$PWD/src/models/documentsmodel.h

RESOURCES += \
    $$PWD/src/qml.qrc \
    $$PWD/assets/img_assets.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
