#include "agingwidget.h"
#include <QVBoxLayout>
#include <QGridLayout>
#include <QDateTime>
#include <QDir>
#include <QCoreApplication>
#include <QStandardPaths>
#include <QMessageBox>
#include <QTimer>
#include <QRegularExpression>
#include <QTextCursor>
#include <QTextBlock>
#include <QScrollBar>
#include <unistd.h>

AgingWidget::AgingWidget(QWidget *parent) : QWidget(parent), process(new QProcess(this)),
    decoder(QTextCodec::codecForName("UTF-8")->makeDecoder()) {
    auto *layout = new QVBoxLayout(this);
    auto *hint = new QLabel(QStringLiteral("每项独立测试 2 小时，满足标准后仅该项显示通过。\n再次点击可停止；提前停止不算通过。"), this);
    hint->setWordWrap(true);
    layout->addWidget(hint);
    const QStringList names = {QStringLiteral("memtester"), QStringLiteral("stressapptest"),
        QStringLiteral("DDR 自动调频"), QStringLiteral("stressapptest + memtester"),
        QStringLiteral("stressapptest + memtester + DDR 自动调频")};
    auto *grid = new QGridLayout;
    for (int i = 0; i < 5; ++i) {
        auto *name = new QLabel(QString::number(i + 1) + ". " + names[i], this);
        name->setWordWrap(true);
        grid->addWidget(name, i, 0);
        buttons[i] = new QPushButton(QStringLiteral("开始"), this);
        buttons[i]->setObjectName(QStringLiteral("agingMode%1").arg(i + 1));
        buttons[i]->setMinimumSize(65, 40);
        grid->addWidget(buttons[i], i, 1);
        results[i] = new QLabel(QStringLiteral("未测试"), this);
        results[i]->setObjectName(QStringLiteral("agingResult%1").arg(i + 1));
        results[i]->setMinimumWidth(48);
        grid->addWidget(results[i], i, 2);
        setItemResult(i, QStringLiteral("未测试"), "#666666");
        connect(buttons[i], &QPushButton::clicked, this, [this, i]() {
            if (active == i) stopTest(); else startTest(i);
        });
    }
    grid->setColumnStretch(0, 1);
    grid->setVerticalSpacing(10);
    layout->addLayout(grid);
    state = new QLabel(QStringLiteral("等待测试；只需运行所需项目，各项结果独立。"), this);
    state->setObjectName("agingStatus");
    state->setWordWrap(true);
    state->setTextInteractionFlags(Qt::TextSelectableByMouse);
    layout->addWidget(state);
    elapsedLabel = new QLabel(QStringLiteral("耗时：00:00:00 / 02:00:00"), this);
    layout->addWidget(elapsedLabel);
    output = new QPlainTextEdit(this);
    output->setObjectName("agingOutput");
    output->setReadOnly(true);
    output->setMaximumBlockCount(2000);
    layout->addWidget(output, 1);
    auto *timer = new QTimer(this);
    connect(timer, &QTimer::timeout, this, [this]() {
        if (active < 0) return;
        const qint64 seconds = elapsed.elapsed() / 1000;
        elapsedLabel->setText(QStringLiteral("耗时：%1:%2:%3 / 02:00:00")
            .arg(seconds / 3600, 2, 10, QChar('0'))
            .arg(seconds / 60 % 60, 2, 10, QChar('0'))
            .arg(seconds % 60, 2, 10, QChar('0')));
    });
    timer->start(1000);
    process->setProcessChannelMode(QProcess::MergedChannels);
    connect(process, &QProcess::readyReadStandardOutput, this, &AgingWidget::consumeOutput);
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &AgingWidget::finished);
    connect(process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart) {
            renderOutput(process->errorString() + '\n');
            finished(-1, QProcess::CrashExit);
        }
    });
}

void AgingWidget::setItemResult(int mode, const QString &text, const QString &color) {
    results[mode]->setText(text);
    results[mode]->setStyleSheet("color: " + color + "; font-weight: bold;");
}

void AgingWidget::consumeOutput() {
    const QByteArray bytes = process->readAllStandardOutput();
    if (bytes.isEmpty()) return;
    if (log.isOpen()) { log.write(bytes); log.flush(); }
    renderOutput(decoder->toUnicode(bytes));
    pendingLines += bytes;
    int newline;
    static const QRegularExpression resultPattern(
        "^ARMSOM_AGING_RESULT mode=([1-5]) status=(PASS|FAIL|STOPPED) duration=([0-9]+) elapsed=([0-9]+)$");
    while ((newline = pendingLines.indexOf('\n')) >= 0) {
        const auto match = resultPattern.match(QString::fromLatin1(pendingLines.left(newline)).trimmed());
        if (match.hasMatch()) {
            resultMode = match.captured(1).toInt() - 1;
            finalResult = match.captured(2);
            resultDuration = match.captured(3).toLongLong();
            resultElapsed = match.captured(4).toLongLong();
        }
        pendingLines.remove(0, newline + 1);
    }
    if (pendingLines.size() > 65536) pendingLines = pendingLines.right(65536);
}

void AgingWidget::renderOutput(const QString &text) {
    auto *bar = output->verticalScrollBar();
    const bool follow = bar->value() >= bar->maximum() - 2;
    QTextCursor cursor(output->document()->lastBlock());
    cursor.movePosition(QTextCursor::Right, QTextCursor::MoveAnchor,
                        qMin(terminalColumn, cursor.block().text().size()));
    cursor.beginEditBlock();
    for (int i = 0; i < text.size();) {
        const QChar ch = text[i];
        if (escapeState) {
            if (escapeState == 1) escapeState = (ch == '[') ? 2 : 0;
            else if (ch.unicode() >= 0x40 && ch.unicode() <= 0x7e) {
                if (ch == 'K') { cursor.movePosition(QTextCursor::EndOfBlock, QTextCursor::KeepAnchor); cursor.removeSelectedText(); }
                escapeState = 0;
            }
            ++i; continue;
        }
        if (ch.unicode() == 0x1b) { escapeState = 1; ++i; }
        else if (ch == '\b') { if (cursor.positionInBlock()) cursor.movePosition(QTextCursor::Left); ++i; }
        else if (ch == '\r') { cursor.movePosition(QTextCursor::StartOfBlock); ++i; }
        else if (ch == '\n') { cursor.movePosition(QTextCursor::EndOfBlock); cursor.insertBlock(); ++i; }
        else if (ch.unicode() < 0x20 && ch != '\t') { ++i; }
        else {
            int end = i + 1;
            while (end < text.size() && (text[end].unicode() >= 0x20 || text[end] == '\t')) ++end;
            const QString run = text.mid(i, end - i);
            const int replace = qMin(run.size(), cursor.block().text().size() - cursor.positionInBlock());
            cursor.movePosition(QTextCursor::Right, QTextCursor::KeepAnchor, replace);
            cursor.insertText(run);
            i = end;
        }
    }
    terminalColumn = cursor.positionInBlock();
    cursor.endEditBlock();
    if (follow) bar->setValue(bar->maximum());
}

void AgingWidget::startTest(int mode) {
    if (active >= 0) return;
    QString script = QCoreApplication::applicationDirPath() + "/shell/aging.sh";
    if (!QFile::exists(script)) script = "/opt/armsomtest/shell/aging.sh";
    if (!QFile::exists(script)) {
        QMessageBox::warning(this, QStringLiteral("老化测试"), QStringLiteral("找不到脚本：") + script);
        return;
    }
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppLocalDataLocation) + "/aging";
    if (!QDir().mkpath(dir)) {
        QMessageBox::warning(this, QStringLiteral("老化测试"), QStringLiteral("无法创建日志目录：") + dir);
        return;
    }
    log.setFileName(dir + "/mode" + QString::number(mode + 1) + "-" + QDateTime::currentDateTime().toString("yyyyMMdd-HHmmss-zzz") + ".log");
    if (!log.open(QIODevice::WriteOnly)) {
        QMessageBox::warning(this, QStringLiteral("老化测试"), log.errorString()); return;
    }
    active = mode;
    stopping = false;
    finalResult.clear(); resultMode = -1; resultDuration = 0; resultElapsed = 0;
    pendingLines.clear(); terminalColumn = 0; escapeState = 0;
    decoder.reset(QTextCodec::codecForName("UTF-8")->makeDecoder());
    elapsed.start();
    elapsedLabel->setText(QStringLiteral("耗时：00:00:00 / 02:00:00"));
    output->clear();
    setItemResult(mode, QStringLiteral("运行中"), "#1565c0");
    for (int i = 0; i < 5; ++i) buttons[i]->setEnabled(i == mode);
    buttons[mode]->setText(QStringLiteral("停止"));
    state->setText(QStringLiteral("模式 %1 运行中，目标 2 小时；日志：").arg(mode + 1) + log.fileName());
    emit runningChanged(true);
    if (geteuid() == 0)
        process->start("/bin/bash", {script, QString::number(mode + 1)});
    else
        process->start("sudo", {"-n", "/bin/bash", script, QString::number(mode + 1)});
}

void AgingWidget::stopTest() {
    if (active < 0 || stopping) return;
    stopping = true;
    buttons[active]->setEnabled(false);
    state->setText(QStringLiteral("正在停止并恢复 DDR 调频策略…"));
    process->closeWriteChannel();
}

void AgingWidget::finished(int code, QProcess::ExitStatus status) {
    if (active < 0) return;
    consumeOutput();
    const bool normal = status == QProcess::NormalExit;
    const bool passed = normal && code == 0 && resultMode == active && finalResult == "PASS"
                        && resultDuration == 7200 && resultElapsed >= 7200;
    const bool stopped = normal && code == 130 && resultMode == active && finalResult == "STOPPED";
    const QString verdict = passed ? QStringLiteral("测试通过") : stopped ? QStringLiteral("已停止（未通过）") : QStringLiteral("测试失败");
    setItemResult(active, passed ? QStringLiteral("通过") : stopped ? QStringLiteral("已停止") : QStringLiteral("失败"),
                  passed ? "#168038" : stopped ? "#a65e00" : "#c62828");
    state->setText(QStringLiteral("模式 %1：").arg(active + 1) + verdict
                   + (passed || stopped ? QString() : QStringLiteral("（退出码 %1，请检查日志）").arg(code))
                   + QStringLiteral("；日志：") + log.fileName());
    const qint64 seconds = qMax(resultElapsed, elapsed.elapsed() / 1000);
    elapsedLabel->setText(QStringLiteral("耗时：%1:%2:%3 / 02:00:00")
        .arg(seconds / 3600, 2, 10, QChar('0')).arg(seconds / 60 % 60, 2, 10, QChar('0')).arg(seconds % 60, 2, 10, QChar('0')));
    if (log.isOpen()) { log.write(("\n" + state->text() + "\n").toUtf8()); log.close(); }
    buttons[active]->setText(QStringLiteral("开始"));
    active = -1;
    stopping = false;
    for (auto *button : buttons) button->setEnabled(true);
    emit runningChanged(false);
}
