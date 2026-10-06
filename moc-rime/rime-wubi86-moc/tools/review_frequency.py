"""维护用词频比较：来源内排名，缺失未知，不使用字典排序权重。"""
from bisect import bisect_left,bisect_right


def relative_rarity(sources,texts):
    """同一词长参考集内的稀有分位，越接近1越低频。

    参考集为所有来源共同收录的当前中文词条，按单字/二字/三字/四字及以上
    分组。每个来源独立排名；并列取中点，缺失为None。任一来源的值按正数
    等比例缩放，结果不变。英文单独采用英文排名，不混入中文参考集。
    此结果只用于发现待审内容，不能直接等同于日常输入概率或删除理由。
    """
    texts={t for t in texts if not t.isascii()}
    if not sources:raise ValueError('缺少词频来源')
    for counts in sources.values():
        if any(not isinstance(c,int) or isinstance(c,bool) or c<0 for c in counts.values()):
            raise ValueError('词频必须为非负整数统计值')
    reference=set.intersection(texts,*(set(f) for f in sources.values()))
    band=lambda t:min(len(t),4)
    samples={key:{b:sorted(f[t] for t in reference if band(t)==b) for b in [1,2,3,4]}
             for key,f in sources.items()}
    result={}
    for text in texts:
        result[text]={}
        for key,counts in sources.items():
            values=samples[key][band(text)];n=len(values)
            if text not in counts or not n:
                result[text][key]=None
            else:
                value=counts[text]
                result[text][key]=(n-(bisect_left(values,value)+bisect_right(values,value))/2)/n
    return result
