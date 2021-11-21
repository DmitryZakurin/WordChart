#ifndef FILEPROCESSING_H
#define FILEPROCESSING_H

#include <QObject>
#include <QThread>
#include <QString>
#include <QPointer>
#include <QUrl>

class FileProcessing;

class ParsingfThread : public QThread {
    Q_OBJECT
public:
    void run() override;
    ParsingfThread(const QString &fname,  QObject *parent = nullptr);

signals:
    void dataUpdating(int freq, QString word);
    void progress(int percentage);

private:
    QUrl m_fname;
};

class FileProcessing : public QObject
{
    Q_OBJECT
public:
    explicit FileProcessing(QObject *parent = nullptr);

signals:
    void processingComplete();
    void dataUpdating(int freq, QString word);
    void progress(int percentage);


public slots:
    void onFileChoosen(const QString &fname);

private:
    QPointer<ParsingfThread> m_thread;
};

#endif // FILEPROCESSING_H
