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

    m_radioCloud = new QRadioButton(QStringLiteral("Cloud"), widget());
    m_radioLocal = new QRadioButton(QStringLiteral("Local"), widget());
    m_sourceGroup = new QButtonGroup(widget());
    m_sourceGroup->addButton(m_radioCloud, 0);
    m_sourceGroup->addButton(m_radioLocal, 1);
    m_radioCloud->setChecked(true);

    auto *sourceLayout = new QHBoxLayout();
    sourceLayout->addWidget(m_radioCloud);
    sourceLayout->addWidget(m_radioLocal);
    sourceLayout->addStretch();
    form->addRow(QStringLiteral("Model Source:"), sourceLayout);

    m_cloudCombo = new QComboBox(widget());
    addCloudModelItems();
    form->addRow(QStringLiteral("Cloud Model:"), m_cloudCombo);

    m_customModelEdit = new QLineEdit(widget());
    m_customModelEdit->setPlaceholderText(QStringLiteral("e.g. glm-5.1:cloud, gemma4:26b"));
    m_customModelEdit->hide();
    form->addRow(QString(), m_customModelEdit);

    m_localCombo = new QComboBox(widget());
    m_localCombo->hide();
    form->addRow(QStringLiteral("Local Model:"), m_localCombo);

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

    connect(m_sourceGroup, &QButtonGroup::idToggled,
            this, &KcmAiAssistant::onSourceChanged);
    connect(m_cloudCombo, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &KcmAiAssistant::onCloudModelChanged);
    connect(m_localCombo, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, [this](int) { onChanged(); });
    connect(m_customModelEdit, &QLineEdit::textChanged,
            this, &KcmAiAssistant::onChanged);
    connect(m_launchModeGroup, &QButtonGroup::idToggled, this,
            [this](int, bool) { onChanged(); });
    connect(m_extraFlagsEdit, &QLineEdit::textChanged,
            this, &KcmAiAssistant::onChanged);
    connect(m_detectButton, &QPushButton::clicked,
            this, &KcmAiAssistant::onDetectInstalled);
}

void KcmAiAssistant::addCloudModelItems()
{
    m_cloudCombo->addItem(QStringLiteral("glm-5.1  (GLM, default)"), QStringLiteral("glm-5.1:cloud"));
    m_cloudCombo->addItem(QStringLiteral("minimax-m2.7  (MiniMax coding/agentic)"), QStringLiteral("minimax-m2.7:cloud"));
    m_cloudCombo->addItem(QStringLiteral("gemma4  (Google Gemma 4)"), QStringLiteral("gemma4:cloud"));
    m_cloudCombo->addItem(QStringLiteral("qwen3.5  (Qwen multimodal)"), QStringLiteral("qwen3.5:cloud"));
    m_cloudCombo->addItem(QStringLiteral("qwen3-coder-next  (Qwen coding)"), QStringLiteral("qwen3-coder-next:cloud"));
    m_cloudCombo->addItem(QStringLiteral("ministral-3  (Mistral edge)"), QStringLiteral("ministral-3:cloud"));
    m_cloudCombo->addItem(QStringLiteral("devstral-small-2  (Devstral 24B agent)"), QStringLiteral("devstral-small-2:cloud"));
    m_cloudCombo->addItem(QStringLiteral("nemotron-3-super  (NVIDIA 120B MoE)"), QStringLiteral("nemotron-3-super:cloud"));
    m_cloudCombo->addItem(QStringLiteral("qwen3-next  (Qwen 80B)"), QStringLiteral("qwen3-next:cloud"));
    m_cloudCombo->addItem(QStringLiteral("glm-5  (GLM 744B reasoning)"), QStringLiteral("glm-5:cloud"));
    m_cloudCombo->addItem(QStringLiteral("kimi-k2.5  (Moonshot multimodal)"), QStringLiteral("kimi-k2.5:cloud"));
    m_cloudCombo->addItem(QStringLiteral("rnj-1  (Essential AI 8B)"), QStringLiteral("rnj-1:cloud"));
    m_cloudCombo->addItem(QStringLiteral("nemotron-3-nano  (NVIDIA efficient)"), QStringLiteral("nemotron-3-nano:cloud"));
    m_cloudCombo->addItem(QStringLiteral("minimax-m2.5  (MiniMax productivity)"), QStringLiteral("minimax-m2.5:cloud"));
    m_cloudCombo->addItem(QStringLiteral("devstral-2  (Devstral 123B)"), QStringLiteral("devstral-2:cloud"));
    m_cloudCombo->addItem(QStringLiteral("cogito-2.1  (Cogito 671B)"), QStringLiteral("cogito-2.1:cloud"));
    m_cloudCombo->addItem(QStringLiteral("gemini-3-flash-preview  (Gemini 3 Flash)"), QStringLiteral("gemini-3-flash-preview:cloud"));
    m_cloudCombo->addItem(QStringLiteral("glm-4.7  (GLM coding)"), QStringLiteral("glm-4.7:cloud"));
    m_cloudCombo->addItem(QStringLiteral("deepseek-v3.2  (DeepSeek reasoning)"), QStringLiteral("deepseek-v3.2:cloud"));
    m_cloudCombo->addItem(QStringLiteral("minimax-m2  (MiniMax M2)"), QStringLiteral("minimax-m2:cloud"));
    m_cloudCombo->addItem(QStringLiteral("minimax-m2.1  (MiniMax multilingual)"), QStringLiteral("minimax-m2.1:cloud"));
    m_cloudCombo->addItem(QStringLiteral("kimi-k2-thinking  (Moonshot thinking)"), QStringLiteral("kimi-k2-thinking:cloud"));
    m_cloudCombo->addItem(QStringLiteral("mistral-large-3  (Mistral enterprise)"), QStringLiteral("mistral-large-3:cloud"));
    m_cloudCombo->addItem(QStringLiteral("gpt-oss  (OpenAI open-weight)"), QStringLiteral("gpt-oss:cloud"));
    m_cloudCombo->addItem(QStringLiteral("qwen3-vl  (Qwen vision)"), QStringLiteral("qwen3-vl:cloud"));
    m_cloudCombo->addItem(QStringLiteral("qwen3-coder  (Qwen agentic coding)"), QStringLiteral("qwen3-coder:cloud"));
    m_cloudCombo->addItem(QStringLiteral("deepseek-v3.1  (DeepSeek hybrid)"), QStringLiteral("deepseek-v3.1:cloud"));
    m_cloudCombo->addItem(QStringLiteral("glm-4.6  (GLM agentic)"), QStringLiteral("glm-4.6:cloud"));
    m_cloudCombo->addItem(QStringLiteral("kimi-k2  (Moonshot MoE)"), QStringLiteral("kimi-k2:cloud"));
    m_cloudCombo->addItem(QStringLiteral("gemma3  (Google Gemma 3)"), QStringLiteral("gemma3:cloud"));

    m_cloudCombo->insertSeparator(m_cloudCombo->count());
    m_cloudCombo->addItem(QStringLiteral("Custom..."), QStringLiteral("__custom__"));
}

void KcmAiAssistant::queryLocalModels()
{
    auto *mgr = new QNetworkAccessManager(this);
    QUrl url(QStringLiteral("http://localhost:11434/api/tags"));
    QNetworkReply *reply = mgr->get(QNetworkRequest(url));

    connect(reply, &QNetworkReply::finished, this, [this, reply, mgr]() {
        reply->deleteLater();
        mgr->deleteLater();

        m_localCombo->clear();
        m_localCombo->addItem(QStringLiteral("(no model selected)"), QString());

        if (reply->error() != QNetworkReply::NoError) {
            m_statusLabel->setText(QStringLiteral("Ollama not running. Start with: ollama serve"));
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
            if (!name.isEmpty()) {
                names << name;
                m_localCombo->addItem(name, name);
            }
        }
        m_statusLabel->setText(QStringLiteral("Found %1 local model(s)").arg(names.size()));
    });
}

void KcmAiAssistant::selectModelInCombos(const QString &model, const QString &source)
{
    if (source == QStringLiteral("local")) {
        m_radioLocal->setChecked(true);
        m_cloudCombo->hide();
        m_customModelEdit->hide();
        m_localCombo->show();
        m_customVisible = false;

        int idx = m_localCombo->findData(model);
        if (idx >= 0) {
            m_localCombo->setCurrentIndex(idx);
        } else {
            m_localCombo->addItem(model, model);
            m_localCombo->setCurrentIndex(m_localCombo->count() - 1);
        }
    } else {
        m_radioCloud->setChecked(true);
        m_localCombo->hide();
        m_cloudCombo->show();
        m_customVisible = false;

        int idx = m_cloudCombo->findData(model);
        if (idx >= 0) {
            m_cloudCombo->setCurrentIndex(idx);
            m_customModelEdit->hide();
        } else {
            int customIdx = m_cloudCombo->findData(QStringLiteral("__custom__"));
            if (customIdx >= 0) m_cloudCombo->setCurrentIndex(customIdx);
            m_customModelEdit->setText(model);
            m_customModelEdit->show();
            m_customVisible = true;
        }
    }
}

void KcmAiAssistant::loadConfig()
{
    QString model = QStringLiteral("glm-5.1:cloud");
    QString modelSource = QStringLiteral("cloud");
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
                else if (key == QStringLiteral("MODEL_SOURCE")) modelSource = val;
                else if (key == QStringLiteral("LAUNCH_MODE")) launchMode = val;
                else if (key == QStringLiteral("EXTRA_FLAGS")) extraFlags = val;
            }
        }
    }

    queryLocalModels();
    selectModelInCombos(model, modelSource);

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
    QString modelSource;

    if (m_radioLocal->isChecked()) {
        modelSource = QStringLiteral("local");
        model = m_localCombo->currentData().toString();
    } else {
        modelSource = QStringLiteral("cloud");
        if (m_cloudCombo->currentData().toString() == QStringLiteral("__custom__")) {
            model = m_customModelEdit->text().trimmed();
        } else {
            model = m_cloudCombo->currentData().toString();
        }
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
        "# Model to use (e.g. \"glm-5.1:cloud\", \"llama3.1:8b\")\n"
        "MODEL=%1\n"
        "\n"
        "# Model source: \"cloud\" or \"local\"\n"
        "MODEL_SOURCE=%2\n"
        "\n"
        "# Extra flags passed to opencode (e.g. \"--no-stream\", \"--debug\")\n"
        "EXTRA_FLAGS=%3\n"
        "\n"
        "# Launch mode: \"model\" = opencode --model <MODEL>, \"raw\" = opencode <EXTRA_FLAGS>, \"default\" = opencode with no flags\n"
        "LAUNCH_MODE=%4\n"
    ).arg(model, modelSource, extraFlags, launchMode);

    f.close();
    setNeedsSave(false);
}

void KcmAiAssistant::defaults()
{
    m_radioCloud->setChecked(true);
    m_cloudCombo->show();
    m_localCombo->hide();
    m_customModelEdit->hide();
    m_customVisible = false;

    int idx = m_cloudCombo->findData(QStringLiteral("glm-5.1:cloud"));
    if (idx >= 0) m_cloudCombo->setCurrentIndex(idx);
    m_customModelEdit->clear();
    m_radioModel->setChecked(true);
    m_extraFlagsEdit->clear();
    setNeedsSave(true);
}

void KcmAiAssistant::onSourceChanged(int id, bool checked)
{
    if (!checked) return;

    if (id == 0) {
        m_cloudCombo->show();
        m_localCombo->hide();
        if (m_customVisible) m_customModelEdit->show();
    } else {
        m_cloudCombo->hide();
        m_customModelEdit->hide();
        m_localCombo->show();
    }

    onChanged();
}

void KcmAiAssistant::onCloudModelChanged(int index)
{
    Q_UNUSED(index)

    QString data = m_cloudCombo->currentData().toString();
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
            m_statusLabel->setText(QStringLiteral("Ollama not running or not installed. Start with: ollama serve"));
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

        QString currentLocal = m_localCombo->currentData().toString();
        m_localCombo->clear();
        m_localCombo->addItem(QStringLiteral("(no model selected)"), QString());

        QStringList names;
        for (const auto &m : models) {
            QString name = m.toObject().value(QStringLiteral("name")).toString();
            if (!name.isEmpty()) {
                names << name;
                m_localCombo->addItem(name, name);
            }
        }

        if (!currentLocal.isEmpty()) {
            int idx = m_localCombo->findData(currentLocal);
            if (idx >= 0) m_localCombo->setCurrentIndex(idx);
        }

        m_statusLabel->setText(QStringLiteral("Found %1 local model(s)").arg(names.size()));
    });
}

void KcmAiAssistant::onChanged()
{
    unmanagedWidgetChangeState(true);
}

#include "kcm_ai_assistant.moc"