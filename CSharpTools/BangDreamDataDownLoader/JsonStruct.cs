using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BangDreamDataDownLoader
{
    public class JsonStruct
    {

    }

    public class MusicJacketStruct0
    {
        public MusicJacketStruct1 Base;

        public static MusicJacketStruct0? DecodeToJacketData(string filePath)
        {
            if (!File.Exists(filePath))
            {
                Console.Write("[DecodeToJacketData]文件不存在:" + filePath);
                return null;
            }
            string jsonStr = File.ReadAllText(filePath);
            MusicJacketStruct0? jacktStruct = JsonConvert.DeserializeObject<MusicJacketStruct0>(jsonStr);
            return jacktStruct;
        }
    }


    public class MusicJacketStruct1
    {
        public string m_Name;
        public List<PreloadTableStruct> m_PreloadTable;
        public Dictionary<string, ContainerStruct> m_Container;
        public ContainerStruct m_MainAsset;
        public int m_RuntimeCompatibility;
        public string m_AssetBundleName;
        public bool m_IsStreamedSceneAssetBundle;
        public int m_ExplicitDataLayout;
        public int m_PathFlags;
    }

    public class PreloadTableStruct
    {
        public int m_FileID;
        public string m_PathID;
    }

    public class ContainerStruct
    {
        public int preloadIndex;
        public int preloadSize;
        public PreloadTableStruct asset;
    }

    public class MusicInfo
    {
        public string tag;
        public int bandId;
        public List<string> jacketImage;
        public Dictionary<int,DifficultInfo> difficulty;
    }

    public class DifficultInfo
    {
        public int playLevel;
    }
}
