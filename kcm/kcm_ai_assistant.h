#pragma once

#include <KCModule>

class QComboBox;
class QRadioButton;
class QLineEdit;
class QButtonGroup;
class QLabel;
class QPushButton;

class KcmAiAssistant : public KCModule
{
    Q_OBJECT

public:
    explicit KcmAiAssistant(QObject *parent, const KPluginMetaData &data);

    void load() override;
    void save() override;
    void defaults() override;

private Q_SLOTS:
    void onModelChanged(int index);
    void onDetectInstalled();
    void onChanged();

private:
    void loadConfig();
    void addModelItems();
    void addSeparator();
    void addInstalledModels(const QStringList &models);

    QComboBox *m_modelCombo;
    QLineEdit *m_customModelEdit;
    QRadioButton *m_radioModel;
    QRadioButton *m_radioRaw;
    QRadioButton *m_radioDefault;
    QButtonGroup *m_launchModeGroup;
    QLineEdit *m_extraFlagsEdit;
    QPushButton *m_detectButton;
    QLabel *m_statusLabel;

    QString m_configPath;
    bool m_customVisible;

    static constexpr int CUSTOM_INDEX = 1000;
};