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
    void onSourceChanged(int id, bool checked);
    void onCloudModelChanged(int index);
    void onDetectInstalled();
    void onChanged();

private:
    void loadConfig();
    void addCloudModelItems();
    void queryLocalModels();
    void selectModelInCombos(const QString &model, const QString &source);

    QButtonGroup *m_sourceGroup;
    QRadioButton *m_radioCloud;
    QRadioButton *m_radioLocal;

    QComboBox *m_cloudCombo;
    QLineEdit *m_customModelEdit;
    QComboBox *m_localCombo;

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