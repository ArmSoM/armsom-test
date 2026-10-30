#ifndef AGINGWIDGET_H
#define AGINGWIDGET_H
#include <QWidget>
#include <QProcess>
#include <QPushButton>
#include <QPlainTextEdit>
#include <QLabel>
#include <QFile>
#include <QElapsedTimer>
#include <QTextCodec>
#include <memory>
class AgingWidget : public QWidget {
    Q_OBJECT
public:
    explicit AgingWidget(QWidget *parent = nullptr);
    bool isRunning() const { return active >= 0; }
    void stopTest();
signals:
    void runningChanged(bool running);
private:
    void startTest(int mode);
    void finished(int code, QProcess::ExitStatus status);
    void consumeOutput();
    void renderOutput(const QString &text);
    void setItemResult(int mode, const QString &text, const QString &color);
    QProcess *process;
    QPushButton *buttons[5];
    QLabel *results[5];
    QLabel *state;
    QLabel *elapsedLabel;
    QPlainTextEdit *output;
    QFile log;
    QElapsedTimer elapsed;
    std::unique_ptr<QTextDecoder> decoder;
    QByteArray pendingLines;
    QString finalResult;
    int resultMode = -1;
    qint64 resultDuration = 0;
    qint64 resultElapsed = 0;
    int terminalColumn = 0;
    int escapeState = 0;
    int active = -1;
    bool stopping = false;
};
#endif
