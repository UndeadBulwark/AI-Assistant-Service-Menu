#include "kcm_ai_assistant.h"

#include <KPluginFactory>
#include <KPluginMetaData>

#include <QComboBox>
#include <QFormLayout>
#include <QRadioButton>
#include <QLineEdit>
#include <QButtonGroup>
#include <QLabel>
#include <QPushButton>
#include <QStandardPaths>
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDir>

K_PLUGIN_CLASS_WITH_JSON(KcmAiAssistant, "kcm_ai_assistant.json")

KcmAiAssistant::KcmAiAssistant(QObject *parent, const KPluginMetaData &data)
    : KCModule(parent, data)
    , m_customVisible(false)
{
    setButtons(Apply | Default);

    auto *form = new QFormLayout(widget());
    form->setHorizontalSpacing(20);
    form->setVerticalSpacing(12);

    m_modelCombo = new QComboBox(widget());
    addModelItems();
    form->addRow(QStringLiteral("Model:"), m_modelCombo);

    m_customModelEdit = new QLineEdit(widget());
    m_customModelEdit->setPlaceholderText(QStringLiteral("e.g. glm-5.1:cloud, llama3.1:8b"));
    m_customModelEdit->hide();
    form->addRow(QString(), m_customModelEdit);

    m_detectButton = new QPushButton(QStringLiteral("Detect Installed Ollama Models"), widget());
    form->addRow(QString(), m_detectButton);

    m_statusLabel = new QLabel(widget());
    m_statusLabel->setWordWrap(true);
    form->addRow(QString(), m_statusLabel);

    m_radioModel = new QRadioButton(QStringLiteral("opencode --model <MODEL>"), widget());
    m_radioRaw = new QRadioButton(QStringLiteral("opencode <EXTRA_FLAGS>"), widget());
    m_radioDefault = new QRadioButton(QStringLiteral("opencode (no flags)"), widget());
    m_launchModeGroup = new QButtonGroup(widget());
    m_launchModeGroup->addButton(m_radioModel, 0);
    m_launchModeGroup->addButton(m_radioRaw, 1);
    m_launchModeGroup->addButton(m_radioDefault, 2);
    form->addRow(QStringLiteral("Launch Mode:"), m_radioModel);
    form->addRow(QString(), m_radioRaw);
    form->addRow(QString(), m_radioDefault);

    m_extraFlagsEdit = new QLineEdit(widget());
    m_extraFlagsEdit->setPlaceholderText(QStringLiteral("e.g. --no-stream --debug"));
    form->addRow(QStringLiteral("Extra Flags:"), m_extraFlagsEdit);

    m_configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation)
                   + QStringLiteral("/ai-assistant-menu/config.conf");

    connect(m_modelCombo, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &KcmAiAssistant::onModelChanged);
    connect(m_customModelEdit, &QLineEdit::textChanged,
            this, &KcmAiAssistant::onChanged);
    connect(m_launchModeGroup, &QButtonGroup::idToggled, this,
            [this](int, bool) { onChanged(); });
    connect(m_extraFlagsEdit, &QLineEdit::textChanged,
            this, &KcmAiAssistant::onChanged);
    connect(m_detectButton, &QPushButton::clicked,
            this, &KcmAiAssistant::onDetectInstalled);
}

void KcmAiAssistant::addModelItems()
{
    m_modelCombo->addItem(QStringLiteral("Cloud Models"), QString());
    m_modelCombo->addItem(QStringLiteral("  glm-5.1:cloud  (GLM, default)"), QStringLiteral("glm-5.1:cloud"));
    m_modelCombo->addItem(QStringLiteral("  gpt-4o  (OpenAI)"), QStringLiteral("gpt-4o"));
    m_modelCombo->addItem(QStringLiteral("  gpt-4o-mini  (OpenAI)"), QStringLiteral("gpt-4o-mini"));
    m_modelCombo->addItem(QStringLiteral("  o1  (OpenAI)"), QStringLiteral("o1"));
    m_modelCombo->addItem(QStringLiteral("  o3-mini  (OpenAI)"), QStringLiteral("o3-mini"));
    m_modelCombo->addItem(QStringLiteral("  claude-sonnet-4-20250514  (Anthropic)"), QStringLiteral("claude-sonnet-4-20250514"));
    m_modelCombo->addItem(QStringLiteral("  claude-haiku-4-20250514  (Anthropic)"), QStringLiteral("claude-haiku-4-20250514"));
    m_modelCombo->addItem(QStringLiteral("  gemini-2.5-pro  (Google)"), QStringLiteral("gemini-2.5-pro"));
    m_modelCombo->addItem(QStringLiteral("  gemini-2.5-flash  (Google)"), QStringLiteral("gemini-2.5-flash"));
    m_modelCombo->addItem(QStringLiteral("  deepseek-chat  (DeepSeek)"), QStringLiteral("deepseek-chat"));
    m_modelCombo->addItem(QStringLiteral("  deepseek-reasoner  (DeepSeek)"), QStringLiteral("deepseek-reasoner"));

    addSeparator();

    m_modelCombo->addItem(QStringLiteral("Popular Local Models"), QString());
    m_modelCombo->addItem(QStringLiteral("  llama3.1:8b  (~4.7 GB)"), QStringLiteral("llama3.1:8b"));
    m_modelCombo->addItem(QStringLiteral("  llama3.1:70b  (~40 GB)"), QStringLiteral("llama3.1:70b"));
    m_modelCombo->addItem(QStringLiteral("  llama3.2:3b  (~2.0 GB)"), QStringLiteral("llama3.2:3b"));
    m_modelCombo->addItem(QStringLiteral("  llama3.3:70b  (~40 GB)"), QStringLiteral("llama3.3:70b"));
    m_modelCombo->addItem(QStringLiteral("  mistral:7b  (~4.1 GB)"), QStringLiteral("mistral:7b"));
    m_modelCombo->addItem(QStringLiteral("  mistral-nemo:12b  (~7.2 GB)"), QStringLiteral("mistral-nemo:12b"));
    m_modelCombo->addItem(QStringLiteral("  phi3:mini  (~2.3 GB)"), QStringLiteral("phi3:mini"));
    m_modelCombo->addItem(QStringLiteral("  gemma2:9b  (~5.4 GB)"), QStringLiteral("gemma2:9b"));
    m_modelCombo->addItem(QStringLiteral("  qwen2.5:7b  (~4.4 GB)"), QStringLiteral("qwen2.5:7b"));
    m_modelCombo->addItem(QStringLiteral("  codestral:22b  (~12 GB)"), QStringLiteral("codestral:22b"));

    addSeparator();

    m_modelCombo->addItem(QStringLiteral("Coding Local Models"), QString());
    m_modelCombo->addItem(QStringLiteral("  codellama:13b  (General code)"), QStringLiteral("codellama:13b"));
    m_modelCombo->addItem(QStringLiteral("  codellama:34b  (General code, large)"), QStringLiteral("codellama:34b"));
    m_modelCombo->addItem(QStringLiteral("  deepseek-coder-v2:16b  (DeepSeek code)"), QStringLiteral("deepseek-coder-v2:16b"));
    m_modelCombo->addItem(QStringLiteral("  starcoder2:7b  (StarCoder2)"), QStringLiteral("starcoder2:7b"));
    m_modelCombo->addItem(QStringLiteral("  qwen2.5-coder:7b  (Qwen code)"), QStringLiteral("qwen2.5-coder:7b"));
    m_modelCombo->addItem(QStringLiteral("  qwen2.5-coder:32b  (Qwen code, large)"), QStringLiteral("qwen2.5-coder:32b"));
    m_modelCombo->addItem(QStringLiteral("  codegemma:7b  (Gemma code)"), QStringLiteral("codegemma:7b"));

    addSeparator();

    m_modelCombo->addItem(QStringLiteral("Custom..."), QStringLiteral("__custom__"));
}

void KcmAiAssistant::addSeparator()
{
    m_modelCombo->insertSeparator(m_modelCombo->count());
}

void KcmAiAssistant::addInstalledModels(const QStringList &models)
{
    int customIdx = m_modelCombo->findData(QStringLiteral("__custom__"));
    if (customIdx < 0) return;

    for (int i = m_modelCombo->count() - 1; i >= 0; --i) {
        QString d = m_modelCombo->itemData(i).toString();
        if (d.startsWith(QStringLiteral("installed:")))
            m_modelCombo->removeItem(i);
    }

    int sepIdx = customIdx;
    for (int i = 0; i < m_modelCombo->count(); ++i) {
        if (m_modelCombo->itemData(i).toString() == QStringLiteral("__custom__")) {
            sepIdx = i;
            break;
        }
    }

    if (!models.isEmpty()) {
        m_modelCombo->insertSeparator(sepIdx);
        for (const auto &model : models) {
            m_modelCombo->insertItem(sepIdx, QStringLiteral("  %1  (installed)").arg(model),
                                     QStringLiteral("installed:%1").arg(model));
            ++sepIdx;
        }
    }
}

void KcmAiAssistant::loadConfig()
{
    QString model = QStringLiteral("glm-5.1:cloud");
    QString launchMode = QStringLiteral("model");
    QString extraFlags;

    QFile f(m_configPath);
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&f);
        QRegularExpression re(QStringLiteral(R"(^(\w+)\s*=\s*(.*)$)"));
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) continue;
            auto match = re.match(line);
            if (match.hasMatch()) {
                QString key = match.captured(1);
                QString val = match.captured(2).trimmed();
                if (key == QStringLiteral("MODEL")) model = val;
                else if (key == QStringLiteral("LAUNCH_MODE")) launchMode = val;
                else if (key == QStringLiteral("EXTRA_FLAGS")) extraFlags = val;
            }
        }
    }

    int idx = m_modelCombo->findData(model);
    if (idx >= 0) {
        m_modelCombo->setCurrentIndex(idx);
        m_customModelEdit->hide();
        m_customVisible = false;
    } else {
        int customIdx = m_modelCombo->findData(QStringLiteral("__custom__"));
        if (customIdx >= 0) m_modelCombo->setCurrentIndex(customIdx);
        m_customModelEdit->setText(model);
        m_customModelEdit->show();
        m_customVisible = true;
    }

    if (launchMode == QStringLiteral("raw"))
        m_radioRaw->setChecked(true);
    else if (launchMode == QStringLiteral("default"))
        m_radioDefault->setChecked(true);
    else
        m_radioModel->setChecked(true);

    m_extraFlagsEdit->setText(extraFlags);

    setNeedsSave(false);
}

void KcmAiAssistant::load()
{
    loadConfig();
}

void KcmAiAssistant::save()
{
    QString model;
    if (m_modelCombo->currentData().toString() == QStringLiteral("__custom__")) {
        model = m_customModelEdit->text().trimmed();
    } else {
        QString d = m_modelCombo->currentData().toString();
        if (d.startsWith(QStringLiteral("installed:")))
            d = d.mid(QStringLiteral("installed:").length());
        model = d;
    }

    if (model.isEmpty()) model = QStringLiteral("glm-5.1:cloud");

    QString launchMode = QStringLiteral("model");
    if (m_radioRaw->isChecked()) launchMode = QStringLiteral("raw");
    else if (m_radioDefault->isChecked()) launchMode = QStringLiteral("default");

    QString extraFlags = m_extraFlagsEdit->text().trimmed();

    QDir().mkpath(QFileInfo(m_configPath).absolutePath());

    QFile f(m_configPath);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        m_statusLabel->setText(QStringLiteral("Error: cannot write %1").arg(m_configPath));
        return;
    }

    QTextStream out(&f);
    out << QStringLiteral(
        "# AI Assistant Service Menu configuration\n"
        "# Edited via KCM or manually\n"
        "\n"
        "# Model to use (e.g. \"glm-5.1:cloud\", \"llama3.1:8b\", \"codellama:13b\")\n"
        "MODEL=%1\n"
        "\n"
        "# Extra flags passed to opencode (e.g. \"--no-stream\", \"--debug\")\n"
        "EXTRA_FLAGS=%2\n"
        "\n"
        "# Launch mode: \"model\" = opencode --model <MODEL>, \"raw\" = opencode <EXTRA_FLAGS>, \"default\" = opencode with no flags\n"
        "LAUNCH_MODE=%3\n"
    ).arg(model, extraFlags, launchMode);

    f.close();
    setNeedsSave(false);
}

void KcmAiAssistant::defaults()
{
    int idx = m_modelCombo->findData(QStringLiteral("glm-5.1:cloud"));
    if (idx >= 0) m_modelCombo->setCurrentIndex(idx);
    m_customModelEdit->clear();
    m_customModelEdit->hide();
    m_customVisible = false;
    m_radioModel->setChecked(true);
    m_extraFlagsEdit->clear();
    setNeedsSave(true);
}

void KcmAiAssistant::onModelChanged(int index)
{
    Q_UNUSED(index)

    QString data = m_modelCombo->currentData().toString();
    bool isCustom = (data == QStringLiteral("__custom__"));

    if (isCustom && !m_customVisible) {
        m_customModelEdit->show();
        m_customVisible = true;
        m_customModelEdit->setFocus();
    } else if (!isCustom && m_customVisible) {
        m_customModelEdit->hide();
        m_customVisible = false;
    }

    onChanged();
}

void KcmAiAssistant::onDetectInstalled()
{
    m_detectButton->setEnabled(false);
    m_statusLabel->setText(QStringLiteral("Querying Ollama..."));

    auto *mgr = new QNetworkAccessManager(this);
    QUrl url(QStringLiteral("http://localhost:11434/api/tags"));
    QNetworkReply *reply = mgr->get(QNetworkRequest(url));

    connect(reply, &QNetworkReply::finished, this, [this, reply, mgr]() {
        reply->deleteLater();
        mgr->deleteLater();
        m_detectButton->setEnabled(true);

        if (reply->error() != QNetworkReply::NoError) {
            m_statusLabel->setText(QStringLiteral("Ollama not running or not installed. Start it with: ollama serve"));
            return;
        }

        QJsonParseError err;
        QJsonDocument doc = QJsonDocument::fromJson(reply->readAll(), &err);
        if (err.error != QJsonParseError::NoError || !doc.isObject()) {
            m_statusLabel->setText(QStringLiteral("Error parsing Ollama response"));
            return;
        }

        QJsonArray models = doc.object().value(QStringLiteral("models")).toArray();
        if (models.isEmpty()) {
            m_statusLabel->setText(QStringLiteral("No models installed. Pull one with: ollama pull <model>"));
            return;
        }

        QStringList names;
        for (const auto &m : models) {
            QString name = m.toObject().value(QStringLiteral("name")).toString();
            if (!name.isEmpty()) names << name;
        }

        addInstalledModels(names);
        m_statusLabel->setText(QStringLiteral("Found %1 installed model(s)").arg(names.size()));
    });
}

void KcmAiAssistant::onChanged()
{
    unmanagedWidgetChangeState(true);
}

#include "kcm_ai_assistant.moc"