# Econ Daily Draft

1. 从官方数据接口提供的数据下载灯光数据集，一般为tiff或者geotiff格式；并下载最新的中国省市县区级行政边界1：400 shapefile文件(一定要是最新的，不然某些海岸线会发生变化）
2. 在Arcgis Pro中，添加数据 -- 打开图层，得到一个栅格数据文件（灯光数据），一个要素图层文件（城市边界）。然后对SNPP-VIIRS的栅格要素裁剪到城市图层上来，并及时保存裁剪的栅格数据。

    1） 在工具栏中搜索 -- 裁剪栅格，输入SNPP-VIIRS光源地图，依据地级市城市的边界进行裁剪（√）
    
    2） 右击已经创建完毕的图层 -- 导出栅格，选择合适的地理边界对它进行导出(当然也可以不选择这么做)


3. 调整投影坐标系与重采样。在工具栏里输入 -- “投影” 或 “投影栅格”，选中灯光栅格数据，将原先的图层投影到WGS 1984上（√）
   
   1） 如果X轴与y轴的像元不为整数，可以同时调整x与y像元的大小，例如将416改为500，方法选择“最近邻法”便于计算（当然也可以不选择这么做）

   2） Arcgis Pro使用的世界地形底图投影坐标系为WGS 1984 Web Mercator (auxiliary sphere)，EPSG:3587；而Payne Institute提供的无云DNB数据集的坐标轴投影参考为WGS 1984，EPSG:4326；中国的区县边界地图坐标轴投影参考多为WGS 1984 Asia_North_Albers_Equal_Area_Conic，EPSG:102025。在不需要使用底图做其他地理统计分析的情况下，实际上只需要保证地级市边界与灯光数据集的范围一致即可(例如WGS 1984)。
   
   3） 右击图层的“属性”选项卡，查看投影参考坐标与xy轴像素大小（√）
   
   4）如果需要对像元进行四舍五入，或者对像元值进行缩放分级，需要在工具箱 -- 重采样，划定采样的分级与方法（因为DMSP的图像为64级，如需要将SNPP-VIIRS与DMSP进行匹配，则可能需要转换标度）
   
4. 异常值处理。需要注意的是这一步仅能识别一些统计范围内可能存在的信源异常值，例如<0，过大的局部值等；而卫星型号，云层，水域反射，数据跨年可比性等问题不会在这一步得到解决。可选择的办法有：

   1） 直接对数据在区域内以像元为单位进行截断，统计每一个地理区块内部的所有像元值异常分位数，截取1% - 99%分位数内的数据（X）
     
   2） 参考GLND数据库对SNPP-VIIRS数据的处理方法，提取当前时间段"北京","上海"，"广州"范围内的像元最大值为全国的"有效最大值"。利用栅格计算器将全图的像元最大值替换为“有效最大值”（√）
   
   3） 由于Payne Institute提供的处理产品已经消除了杂散光的影响，且我们并未有与DMSP相互校正的需求，这里并未与DMSP做掩膜提取。而是直接参照一些其他文献的方法，将<0的像元值视为异常值全部替换为0。
     

5.  对栅格的pixel value由浮点型转换成整型（pixel value不是整型在栅格的拼接上会出现问题，但与要素的连接不会，这一步可以不做）：

    1） 打开Arcgis Pro的工具箱 -- “栅格计算器”，在命令行输入计算表达式：
      `Con((RoundUp("NPP_VIIRS_202011.tif")- 
      "NPP_VIIRS_202011.tif")>0.5,RoundDown("NPP_VIIRS_202011.tif"),RoundUp("NPP_VIIRS_202011.tif"))`，这是做四舍五入的操作。当然如果pixel value过小，则应当先全部放大乘于整数后再转换成整型，在空间分区统计之后再转换成原先的大小

    2） 在工具栏里输入 -- “转为整型”并搜索，导入经过四舍五入转换过后的整数浮点值，可以直接转换成整型
     
6. 在工具栏里输入 -- “以表格显示分区统计”，将行政边界文件输入“要素区域数据”，将栅格文件输入“赋值栅格”，计算得到一张以地方区县界为统计单元的表，其中会提供一系列的统计信息。`count`代表落在该区域内的像元个数，`area`代表区域面积，`sum`代表区域内的像元值加总，`mean`代表区域的像元值加总除以总面积。

# 示例处理过程 -- SNPP-VIIRS 201903
1）导入由Clorado Payne Institute下载的原始数据文件`SVDNB_npp_20190301-20190331_75N060E_vcmcfg_v10_c201904071900.avg_rade9h.tif`, 其显示东亚半区的所有图像，像元值范围从-0.82到48754.1，"avg_rade9h" 代表其显示的是平均辐射度四舍五入到百分位

2）依据上述方法与中国的省市边界裁剪后得到中国全域灯光图，像元值范围从-0.57到2869.97

3）先做一次"以表格显示分区统计"以获得基本统计数据，2019年3月的北京最大亮度栅格为271.890015，上海最大亮度栅格为284.109985，广州为306.600006，那么将全地图像元值大于306.6的像元值全部替换成306.6--`Con(("SVDNB_npp_2019030120190_Clip1">306.6),306.6,"SVDNB_npp_2019030120190_Clip1")`。同时将小于0的像元值全部替换为0-- `Con(("con_raste"<0),0,"con_raste")`. 我们得到一个像元值在0-306.6的中国灯光地图。

<div align=center><image src= "https://user-images.githubusercontent.com/82168423/215340056-edd644e4-ebef-4dab-acd9-42bcb20e0170.png" /></div>

   同时我们分别展示像元值大于0.5，像元值大于1，像元值大于5的掩膜地图(以0与1表示数值范围，顺序由上到下)

<div align=center><image src="https://user-images.githubusercontent.com/82168423/215341989-34a647c4-c54c-4b9e-8b1b-2bdb9a78be33.png" /></div>
   
<div align=center><image src="https://user-images.githubusercontent.com/82168423/215342040-959e1431-f6e6-4e63-a1a2-c634ed26beb1.png" /></div>

<div align=center><image src="https://user-images.githubusercontent.com/82168423/215342147-57758ab1-4b1a-4409-85b1-5dff0fc916c1.png" /></div>

4）再次运行"以表格显示分区统计"(只计算有像元值地区),得到数据集201903_light.csv, 一般选用其中的`mean`作为`DNvalue`的替代指标。




# Robust Check of Generate Way
1. 由于对原始数据集不同的处理方法导致灯光pixel的标度不一，我们同时寻找一些国内外地理测绘使用的经过转换后的SNPP-VIIRS数据集，观察归一化后中国各个主要城市的DNvalue的差异情况，如果各份数据集之间的差异并不大，则说明其处理效果良好。
   
   1）与GNLD处理数据集的结果相比，整体上有baseline 光源被加1了的情况，数据内部的峰度与偏度并没有太大改变，推测是他们对负值进行掩膜处理的时候直接加上了1
   
   2）与中国矿业大学课题组提供的处理后数据完全一致


# BERT使用meanpool与CLS作为representation的异同

在BERT中，[CLS]符号被用作序列的开头，并且最后一层的[CLS]表示被用来代表整个句子的向量表示。这是因为BERT在预训练时使用的任务是“Next Sentence Prediction”，即判断两个句子是否是连续的。在这个任务中，BERT需要学习将两个句子的信息结合起来，并生成一个表示整个句子对的向量。因此，BERT将最后一层的[CLS]表示作为整个句子的向量表示，该表示将两个句子的信息结合起来，因此通常被认为是较好的句子向量表示。

另外，BERT的每个单词的表示都考虑了该单词在上下文中的信息，因此使用BERT的[CLS]表示作为句子向量，能够捕捉整个句子的上下文信息，相对于简单的词向量加权平均的句子向量表示更加具有表征性。

# H & P(2016) 的做法

1）如何找出对应的新行业：包含某些特定产品词的行业，为我们需要的固定类别归属的行业

2）如何确定最佳的新行业的个数：在第42页，作者提到了使用信息准则（如AIC和BIC）来确定最佳行业数量的方法。具体而言，作者发现AIC得分在大约300个行业时达到最小值。作者还指出，这个最小值周围只有一个缓慢的斜坡。因此，作者得出结论，SIC和NAICS使用的粒度程度（大约300个行业）是合理的，并且也是10-K基于行业的信息的一个很好的基准。

当前衡量聚类优秀程度以确定聚类个数的方式，往往不再基于WCSS或者轮廓系数等等，硬性判断向量空间紧密程度的指标，而是使用R方，AIC, BIC等等简单的统计量，控制FE跑一个回归，因变量是某些要研究的对象，例如利润率，资本水平，销售额等等能表现不同行业差异的变量，自变量是不同的聚类对象，例如张任宇Demand Prediction in Retail——A Practical Guide to Leverage Data and Predictive Analytics。简而言之，某些情况下，聚类应该更“具有解释性”而不是“在空间上更紧密“，尤其是高维向量几乎完全抹去了文本的本来意义时。

3）如何构造每个行业的特征词向量，并利用这个向量对新行业进行分类：首先计算每个行业的词汇使用向量。每个向量都是基于1997年出现在所有公司中不到25%的词汇。向量由给定行业中使用给定单词的公司数量填充，然后将这个向量归一化，使其具有单位长度(当然这是由于H&P计算公司成对相似度的方法与之一致)。这种归一化确保了使用更多单词的行业不会根据规模获得奖励，而是仅根据相似度获得奖励。对于想要分类的给定公司，只需计算它与所有候选行业的相似度，然后将该公司分配到与它最相似的行业。企业与行业的相似度就是企业的归一化词向量与行业的归一化词向量的点积。类似于：行业0中A公司使用2次饮料，2次矿泉水，B公司一次矿泉水，那么向量中只有饮料与矿泉水的位置有归一化的值，这就是行业的特征向量，通过比较不同企业与之的相似度，来决定日后的其他企业应该分配到哪个相似度最高的类。当然，我们也可以获取加权后的TF-IDF高频词作为行业的代表，同时，我们也可以使用Kmenas的质心，比较不同行业间的聚类，对新的企业进行行业分类。

