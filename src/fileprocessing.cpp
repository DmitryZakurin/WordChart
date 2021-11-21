#include "fileprocessing.h"
#include <QDebug>
#include <QFile>
#include <QMap>
#include <QList>
#include <QStringList>
#include <QByteArray>
#include <QVector>
#include <map>
#include <functional>

constexpr static uint8_t TOP_MAX = 15;

FileProcessing::FileProcessing(QObject *parent) : QObject(parent)
{

}

void
FileProcessing::onFileChoosen(const QString &fname)
{
    if (!m_thread.isNull())
        return;
    m_thread = new ParsingfThread(fname, this);
    connect(m_thread.data(), &QThread::finished, [this]() {
        m_thread.clear();
        emit processingComplete();
    });
    connect(m_thread.data(), &ParsingfThread::dataUpdating,
            this, &FileProcessing::dataUpdating);
    connect(m_thread.data(), &ParsingfThread::progress,
            this, &FileProcessing::progress);
    m_thread->start();
}


ParsingfThread::ParsingfThread(const QString &fname, QObject *parent) :
    QThread(parent),
    m_fname(fname)
{
}

void ParsingfThread::run()
{

    QFile file(m_fname.toLocalFile());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qDebug() << "Couldn't open file " << file.fileName() << " with error " << file.errorString();
        return;
    }

    QMap<QString, uint32_t> wordDict;
    qsizetype bytesProcessed = 0;
    while (!file.atEnd()) {
        {
            //Read a line from the file
            QByteArray line = file.readLine();

            bytesProcessed += line.size();
            emit progress( bytesProcessed  * 100 / file.size() );

            auto list = line.simplified().split(' ');
            for(auto l : list)
                if (!l.isEmpty())
                    wordDict[QString(l)]++;
        }
        //Arrange the words by usage frequncy
        QVector<QStringList> freqVect;
        for(auto it = wordDict.cbegin(); it != wordDict.cend(); ++it) {
            if(it.value() == 0) {
                qDebug() << "WTF: word " << it.key() << " with 0 frequency!";
                continue;
            }
            if((int)it.value() > freqVect.size())
                freqVect.resize(it.value());
            freqVect[it.value()-1].append(it.key());
        }

        //Update only TOP_MAX highest occurrences
        int max = TOP_MAX;
        for(int i = freqVect.size(); i > 0; --i) {
            QStringList& list = freqVect[i-1];
            if (list.isEmpty())
                continue;
            if (max <= 0)
                break;
            for(const auto& l : list) {
                if((--max) < 0)
                    break;
                emit dataUpdating(i, l);
            }
        }
    }
}

