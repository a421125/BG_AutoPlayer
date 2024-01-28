// See https://aka.ms/new-console-template for more information
using System.Net;
using System.Text;
using Newtonsoft.Json;
using BangDreamDataDownLoader;
using System;
using System.Reflection.Emit;
using System.Reflection;

string rootPath = "E:\\BangDream相关";
string soundInfoPath = rootPath + "\\SoundInfo_Json";
string musicInfoPath = "E:\\BangDream相关\\SoundList.json";
string soundListUrl = "https://bestdori.com/api/songs/all.7.json";
string soundInfoUrlPattern = "https://bestdori.com/api/charts/{0}/{1}.json";
string soundListFilePath = "SoundList.json";

string musicJacketUrl = "https://bestdori.com/assets/cn/musicjacket/musicjacket{0}_rip/musicjacket-musicjacket{1}.bundle";

//0为musicjacket100
string musicJacketImageUrl = "https://bestdori.com/assets/cn/musicjacket/{0}_rip/{1}";
string musicJacketSavePath = "E:\\BangDream相关\\musicJacket_Json";
string musicJacketStatisticInfoPath = "E:\\BangDream相关\\musicJacketStatisticInfo.txt";
string musicJacketImageSavePath = "E:\\BangDream相关\\musicJacket_Image";

string[] musicLevelNameList = new string[5] { "easy", "normal", "hard", "expert", "special" };



DownLoadSoundList();
DownLoadSoundInfo();
//JsonToLua.ConvertJson2Format();
//JsonToLua.ConvertToLua();


//DownLoadMusicJacketInfo();

//StatisticJacketData();

//DownLoadAllMusicJacketImage();

//下载musicJacket信息
void DownLoadMusicJacketInfo()
{
    List<int> jacketList = new List<int>();
    jacketList.Add(10010);
    for (int i = 0; i <= 55; i++)
        jacketList.Add(i * 10);

    for(int i = 0;i < jacketList.Count; i++)
    {
        int index = jacketList[i];
        string url = string.Format(musicJacketUrl, index, index);
        string savePath = string.Format(musicJacketSavePath + "\\musicJacket{0}.json", index);
        GetRequest(url, savePath);
    }

    for (int i = 0; i < jacketList.Count; i++)
    {
        string savePath = string.Format(musicJacketSavePath + "\\musicJacket{0}.json", jacketList[i]);
        if (!File.Exists(savePath))
            continue;
        string allText = File.ReadAllText(savePath);
        if (!allText.StartsWith("{\"Base\":"))
        {
            Console.WriteLine("[下载JacketInfo]删除错误数据:" + savePath);
            File.Delete(savePath);
        }
    }

    StatisticJacketData();
}

//读取musicJacket文件信息 提取音乐路径
void StatisticJacketData()
{
    if(!Directory.Exists(musicJacketSavePath))
    {
        Console.WriteLine("[整理Jacket信息] 文件夹不存在:" + musicJacketSavePath);
        return;
    }

    if (File.Exists(musicJacketStatisticInfoPath))
        File.Delete(musicJacketStatisticInfoPath);

    FileStream fs = new FileStream(musicJacketStatisticInfoPath, FileMode.Create, FileAccess.ReadWrite);
    StreamWriter sw = new StreamWriter(fs);

    DirectoryInfo dirInfo = new DirectoryInfo(musicJacketSavePath);
    FileInfo[] allFiles = dirInfo.GetFiles();
    for(int i = 0; i < allFiles.Length; i++)
    {
        MusicJacketStruct0? jacketStruct = MusicJacketStruct0.DecodeToJacketData(allFiles[i].FullName);
        if(jacketStruct == null)
        {
            Console.WriteLine("[整理Jacket信息] 解析json失败:" + allFiles[i].FullName);
            continue;
        }

        foreach(KeyValuePair<string, ContainerStruct> pair in jacketStruct.Base.m_Container)
        {
            if (!pair.Key.EndsWith("png"))
                Console.WriteLine("[整理Jacket信息] 记录数据错误:" + pair.Key);
            else
                sw.WriteLine(pair.Key);
        }
    }

    sw.Close();
    fs.Close();

    Console.WriteLine("[整理Jacket信息] 解析完成");
}

//下载所有的jacket的歌曲图片
void DownLoadAllMusicJacketImage()
{
    if(!File.Exists(musicJacketStatisticInfoPath))
    {
        Console.WriteLine("[下载Jacket图片] 文件不存在:" + musicJacketStatisticInfoPath);
        return;
    }

    string allText = File.ReadAllText(musicJacketStatisticInfoPath);
    string[] lineStrList = allText.Split(Environment.NewLine);
    for(int i = 0; i < lineStrList.Length; i++)
    {
        string curLineStr = lineStrList[i];
        if (string.IsNullOrEmpty(curLineStr))
            continue;

        string[] splitStr = curLineStr.Split("/");
        string jacketIndexStr = null;
        for(int index = 0; index < splitStr.Length; index++)
        {
            string curSplitStr = splitStr[index];
            if(curSplitStr.StartsWith("musicjacket") && curSplitStr != "musicjacket")
            {
                jacketIndexStr = curSplitStr;
                break;
            }
        }

        bool isThumbImage = false;
        string lastSpiltStr = splitStr[splitStr.Length - 1];
        if (lastSpiltStr == "thumb.png")
            isThumbImage = true;

        if (jacketIndexStr == null)
        {
            Console.WriteLine("[下载Jacket图片] 行中找不到index信息:" + curLineStr);
            continue;
        }

        curLineStr = curLineStr.Replace("/","-");
        string imageUrl = string.Format(musicJacketImageUrl, jacketIndexStr, curLineStr);

        string imageSavePath = musicJacketImageSavePath + "\\" + (isThumbImage ? "thumb" : "jacket") + "\\" + splitStr[splitStr.Length - 2] + ".png";
        DownLoadImage(imageUrl, imageSavePath);
    }

    Console.WriteLine("[下载Jacket图片] 完成");
}

//下载歌曲信息列表
void DownLoadSoundList()
{
    if (File.Exists(musicInfoPath))
        File.Delete(musicInfoPath);

    GetRequest(soundListUrl, musicInfoPath);
}
//下载所有歌曲信息
void DownLoadSoundInfo()
{
    if (Directory.Exists(soundInfoPath))
        Directory.Delete(soundInfoPath, true);
    Directory.CreateDirectory(soundInfoPath);

    Dictionary<int, MusicInfo> musicInfoDic = ReadMusicInfoList();

    foreach(KeyValuePair<int,MusicInfo> pair in musicInfoDic)
    {
        int difficultCount = pair.Value.difficulty.Count;
        for(int i = 0; i < difficultCount; i++)
        {
            string soundInfoUrl = string.Format(soundInfoUrlPattern, pair.Key, musicLevelNameList[i]);
            string downloadPath = string.Format("{0}\\{1}_{2}.json", soundInfoPath, pair.Key, i);
            GetRequest(soundInfoUrl, downloadPath);
        }
    }
}

void GetRequest(string url,string savePath)
{
    try
    {
        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
        request.Method = "GET";
        request.ContentType = "application/json";

        HttpWebResponse response = (HttpWebResponse)request.GetResponse();
        Stream rs = response.GetResponseStream();
        StreamReader sr = new StreamReader(rs, Encoding.UTF8);
        string data = sr.ReadToEnd();

        File.WriteAllText(savePath, data);
        Console.WriteLine("下载完成:" + url);
    }
    catch(Exception e)
    {
        Console.WriteLine("获取数据报错:" + url + " message:" + e.Message);
    }
}

void DownLoadImage(string url, string path)
{
    try
    {
        WebClient wc = new WebClient();
        wc.DownloadFileAsync(new Uri(url), path);
    }
    catch (Exception e)
    {
        Console.WriteLine("[下载图片失败]:" + e.Message);
    }
}

void LoadImage(string filePath)
{
    Image<Rgba32> image = Image.Load<Rgba32>(filePath);
    if (image == null)
    {
        Console.WriteLine("读取图片为null");
        return;
    }

    Rgba32 curColor = image[100, 100];
}

#region 取所有歌曲特征颜色
string allJacketPath = "E:\\BangDream相关\\musicJacket_Image\\jacket_476";
int defaultImageSizeX = 476;
int defaultImageSizeY = 477;
string colorWriteFilePath = "E:\\BangDream相关\\JacketColor.lua";

List<Rectangle> rectList = new List<Rectangle>() {
    new Rectangle(1, 1, 3, 3),      //左上取9个颜色
    new Rectangle(472, 1, 3, 3),    //右上取9个颜色
    new Rectangle(472, 473, 3, 3),  //右下取9个颜色
    new Rectangle(1, 473, 3, 3),    //左下取9个颜色
};

string singleRangeStr = "[{0}] = {{1},{2},{3}}";

void GenerateAllJacketColorInfo()
{
    if (!Directory.Exists(allJacketPath))
    {
        Console.WriteLine("[取歌曲特征颜色] 失败 文件夹不存在:" + allJacketPath);
        return;
    }

    Dictionary<int, MusicInfo> musicInfoDic = ReadMusicInfoList();

    FileStream fs = new FileStream(colorWriteFilePath, FileMode.Create, FileAccess.ReadWrite);
    StreamWriter sw = new StreamWriter(fs);

    sw.WriteLine("local jacketColorList = {");

    DirectoryInfo dirInfo = new DirectoryInfo(allJacketPath);
    FileInfo[] allImage = dirInfo.GetFiles();

    StringBuilder sb = new StringBuilder(1024);

    for(int i=0; i<allImage.Length; i++)
    {
        FileInfo curFile = allImage[i];
        if (curFile.Extension != ".png")
            continue;

        string fileName = curFile.Name.Substring(0, curFile.Name.Length - 4);
        //string musicName = fileName;
        //if (musicName.EndsWith("_1"))
        //    musicName = musicName.Substring(0, musicName.Length - 2);

        int musicIndex = GetMusicJacketIndex(musicInfoDic, fileName);
        if(musicIndex == -1)
        {
            Console.WriteLine("[jacket找不到musicId] jacket名字为:" + fileName);
            continue;
        }

        sw.WriteLine("\t[\"" + fileName + "\"] = {");

        Image<Rgba32> image = Image.Load<Rgba32>(allImage[i].FullName);
        for(int rectIndex = 0;rectIndex < rectList.Count; rectIndex++)
        {
            sb.Clear();
            sb.Append("\t\t[").Append(rectIndex + 1).Append("] = {");
            Rectangle curRect = rectList[rectIndex];
            for(int x =0;x<curRect.Width;x++)
            {
                for(int y = 0; y < curRect.Height; y++)
                {
                    Rgba32 curColor = image[curRect.X + x, curRect.Y + y];
                    int colorIndex = y * curRect.Width + x + 1;
                    sb.Append("[").Append(colorIndex).Append("] = {").
                        Append(curColor.R).Append(",").
                        Append(curColor.G).Append(",").
                        Append(curColor.B).Append("},");
                }
            }
            sb.Append("},");

            sw.WriteLine(sb.ToString());
        }

        sw.WriteLine("\t\t[\"musicIndex\"] = " + musicIndex + ",");
        sw.WriteLine("\t},");
    }

    sw.WriteLine("}\nreturn jacketColorList;");

    sw.Close();
    fs.Close();
}

Dictionary<int, MusicInfo> ReadMusicInfoList()
{
    if (!File.Exists(musicInfoPath))
    {
        Console.WriteLine("[读取MusicInfo失败] 文件不存在:" + musicInfoPath);
        return null;
    }
    Dictionary<int, MusicInfo>? musicInfoDic = JsonConvert.DeserializeObject<Dictionary<int, MusicInfo>>(File.ReadAllText(musicInfoPath));

    foreach(KeyValuePair<int,MusicInfo> pair in musicInfoDic)
    {
        List<string> jacketStrList = pair.Value.jacketImage;
        for (int i = 0; i < jacketStrList.Count; i++)
            jacketStrList[i] = jacketStrList[i].ToLower();
    } 

    return musicInfoDic;
}

int GetMusicJacketIndex(Dictionary<int, MusicInfo> musicInfoDic,string musicName)
{
    musicName = musicName.ToLower();
    foreach (KeyValuePair<int,MusicInfo> pair in musicInfoDic)
    {
        List<string> jacketList = pair.Value.jacketImage;
        for(int i=0;i < jacketList.Count; i++)
        {
            if (jacketList[i] == musicName)
                return pair.Key;
        }
    }

    return -1;
}

//GenerateAllJacketColorInfo();

#endregion


Console.WriteLine("[完成]");
Console.ReadLine();