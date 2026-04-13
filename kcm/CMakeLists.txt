cmake_minimum_required(VERSION 3.16)

set(QT_MIN_VERSION "6.5.0")
set(KF6_MIN_VERSION "6.0.0")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)

project(kcm_ai_assistant)

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDECMakeSettings)

find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED Core Widgets Network)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    CoreAddons
    KCMUtils
    ConfigWidgets
)

set(kcm_ai_assistant_SRCS
    kcm_ai_assistant.cpp
)

qt6_add_resources(kcm_ai_assistant_SRCS resources.qrc)

kcoreaddons_add_plugin(kcm_ai_assistant
    INSTALL_NAMESPACE "plasma/kcms/systemsettings"
    SOURCES ${kcm_ai_assistant_SRCS}
)

target_link_libraries(kcm_ai_assistant PRIVATE
    Qt6::Core
    Qt6::Widgets
    Qt6::Network
    KF6::KCMUtils
    KF6::CoreAddons
    KF6::ConfigWidgets
)

kcmutils_generate_desktop_file(kcm_ai_assistant)