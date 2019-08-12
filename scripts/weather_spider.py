# coding: utf-8

import sys
reload(sys)
sys.setdefaultencoding("utf-8")

import re,time,requests
import bs4,requests,pprint
import MySQLdb

def _sqlInit():
    connect = MySQLdb.connect(
            host = '127.0.0.1',
            user = 'root',
            passwd = '123456',
            db = 'weather_infos',
            port = 3306,
            charset = 'utf8'
        )

    return connect


def getHTMLText(url): # 抓取中国天气网官网天气数据
    try:
        res = requests.get(url,timeout=30)
        res.raise_for_status()
        res.encoding = res.apparent_encoding
        return res.text
    except:
        return 'error'

def getWeatherList(html, citycode, cityname):
    weatherSoup = bs4.BeautifulSoup(html,'html.parser')
    elems = weatherSoup.find('ul',attrs={'class':'t clearfix'})
    cswe = weatherSoup.find('div',attrs={'class':'crumbs fl'})
    telems = weatherSoup.find(id='curve')

    name1List = []
    name2List = []
    dateList = []
    weaList = []
    temList = []
    winList = []
    wList = []

    wd_list = []

    name1 = cswe.select('a')# 省市
    name2 = cswe.select('span')#县区
    date = elems.select('h1') # 日期
    weat = elems.select('.wea') # 天气
    temp = elems.select('.tem') # 温度
    wind = elems.select('.win') # 风力

    for i in name1:
        name1List.append(i.text)
    for i in name2:
        name2List.append(i.text)
    for i in date:
        dateList.append(i.text)
    for i in weat:
        weaList.append(i.text)
    for i in temp:
        temList.append(i.text.replace('\n',''))
    for i in wind:
        winList.append(i.text.replace('\n',''))

    cityname = name1List[1] + ' ' + cityname

    for i in range(len(dateList)):
        date = time.strftime('%Y-%m-%d', time.localtime(time.time() + (i * 24 * 60 * 60)))
        date_txt = dateList[i]
        weather = weaList[i]
        temperature = temList[i]
        wind_scale = winList[i]


        wList.append([citycode,date,cityname,date_txt,weather,temperature,wind_scale])

    return wList

def write_2_mysql(infos):
    connect = _sqlInit()
    _cur = connect.cursor()

    sql_fmt = '''INSERT INTO weather_records (
            citycode, date, cityname, date_txt, weather, temperature, wind_scale)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE cityname = values(cityname),
            date_txt = values(date_txt), weather = values(weather),
            temperature = values(temperature), wind_scale = values(wind_scale);'''


    _cur.executemany(sql_fmt, infos)
    connect.commit()

    connect.close()


def handler(citycode, cityname):
    print(str(citycode) + ': ' + cityname)
    url = 'http://www.weather.com.cn/weather/' + str(citycode) + '.shtml'
    html = getHTMLText(url)

    weaInfoList = getWeatherList(html, citycode, cityname)

    write_2_mysql(weaInfoList)


def queryCityList():
    connect = _sqlInit()
    _cur = connect.cursor()

    _q_sql = 'SELECT weather_code, city FROM citycode_infos;'

    try:
        _cur.execute(_q_sql)

        res = _cur.fetchall()

        return res
    except:
        print 'SQL Query error.'

    connect.close()


def _expire_clean():
    connect = _sqlInit()
    _cur = connect.cursor()

    _expire_date = time.strftime('%Y-%m-%d', time.localtime(time.time() - 60 * 60 * 24 * 3))

    _q_sql = 'DELETE FROM weather_records WHERE date <= "%s";' % (_expire_date)
    try:
        _cur.execute(_q_sql)

        connect.commit()
    except:
        print 'SQL DELETE error.'

    connect.close()

def _cache_flush():
    _url = 'http://127.0.0.1:8520/weather/v1/flush'
    _r = requests.get(_url)
    print(_r.content)


if __name__ == '__main__':
    print("***** START *****")
    start = time.time()

    # citylist
    _citylist = queryCityList()
    if _citylist :
        for row in _citylist:
            weather_code = row[0]
            city_name = row[1]

            if city_name.endswith('自治州'):
                city_name = city_name.replace('自治州', '')
            elif city_name.endswith('自治县'):
                city_name = city_name.replace('自治县', '')
            elif city_name.endswith('市'):
                city_name = city_name.replace('市', '')
            elif city_name.endswith('区'):
                city_name = city_name.replace('区', '')
            elif city_name.endswith('县'):
                city_name = city_name.replace('县', '')

            try:
                handler(weather_code, city_name)
            except Exception as err:
                print('get weather error, pass')
                continue

    # Clean the expired data
    _expire_clean()


    # Flush_all the cache data
    _cache_flush()

    print("***** END *****" + " waste time: ", (time.time() - start))

