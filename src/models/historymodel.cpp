#include "historymodel.h"
#ifdef STATIC_MAUIKIT
#include "utils.h"
#else
#include <MauiKit/utils.h>
#endif

static bool isTextDocument(const QUrl &url)
{
    return FMH::checkFileType(FMH::FILTER_TYPE::TEXT, FMH::getMime(url));
}

HistoryModel::HistoryModel(QObject *parent)
    : MauiList(parent)
{
}

const FMH::MODEL_LIST &HistoryModel::items() const
{
    return this->m_list;
}

void HistoryModel::append(const QUrl &url)
{
    auto urls = this->getHistory();
    if (urls.contains(url.toString()) || !isTextDocument(url))
        return;

    emit this->preItemAppended();
    this->m_list << FMH::getFileInfoModel(url);
    emit this->postItemAppended();

    urls << url;

    UTIL::saveSettings("URLS", QUrl::toStringList(urls), "HISTORY");
}

QList<QUrl> HistoryModel::getHistory()
{
    auto urls = UTIL::loadSettings("URLS", "HISTORY", QStringList()).toStringList();
    urls.removeDuplicates();
    auto res = QUrl::fromStringList(urls);
    res.removeAll(QString(""));
    return res;
}

void HistoryModel::setList()
{
    for (const auto &url : this->getHistory()) {
        if (!url.isLocalFile() || !FMH::fileExists(url) || !isTextDocument(url))
            continue;

        emit this->preItemAppended();
        this->m_list << FMH::getFileInfoModel(url);
        emit this->postItemAppended();
    }
}

void HistoryModel::componentComplete()
{
    this->setList();
}
