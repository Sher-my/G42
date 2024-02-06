import pandas as pd
import random
import os
# 随机抽取的子区间函数
def generate_random_subrange(start, end, length):
    try:
        subrange_start = random.randint(start, end - length + 1)
        subrange_end = subrange_start + length - 1
    except:
        subrange_start = start
        subrange_end = start + 150
    return subrange_start, subrange_end

# 提取位置文件中的相关列并创建筛选函数
def count_peaks_in_ranges(df_cr, df_peak):
    df_cr['range1_count'] = 0
    df_cr['range2_count'] = 0
    df_cr['range3_count'] = 0

    for _, cr_row in df_cr.iterrows():

        chr_cr = cr_row['chr']
        start_cr = cr_row['cr_start_in_chr']
        chr_start_cr = cr_row['chr_start']
        chr_stop_cr = cr_row['chr_stop'] ###for seq datas
        

        # 计算三个筛选范围
        range1_start, range1_stop = max(0, start_cr - 150), start_cr
        range2_start, range2_stop = start_cr, start_cr + 150
        range3_start, range3_stop = generate_random_subrange(chr_start_cr, chr_stop_cr, 150)
        # 统计每个范围内的peak数量
        df_cr.loc[df_cr.index == cr_row.name, 'range1_count'] = df_peak[(df_peak['chr_peak'] == chr_cr) & 
                                                                    ((df_peak['peak_start'] >= range1_start) & 
                                                                     (df_peak['peak_stop'] <= range1_stop))].shape[0] ###for m6A
        
        # df_cr.loc[df_cr.index == cr_row.name, 'range1_count'] = df_peak[(df_peak['chr_peak'] == chr_cr) & 
        #                                                             ((df_peak['peak_start'] >= range1_start) & 
        #                                                              (df_peak['peak_start'] <= range1_stop))].shape[0] ###for G4
        
        df_cr.loc[df_cr.index == cr_row.name, 'range2_count'] = df_peak[(df_peak['chr_peak'] == chr_cr) & 
                                                                    ((df_peak['peak_start'] >= range2_start) & 
                                                                     (df_peak['peak_stop'] <= range2_stop))].shape[0] ###for m6A

        # df_cr.loc[df_cr.index == cr_row.name, 'range2_count'] = df_peak[(df_peak['chr_peak'] == chr_cr) & 
        #                                                             ((df_peak['peak_start'] >= range2_start) & 
        #                                                              (df_peak['peak_start'] <= range2_stop))].shape[0] ###for G4

        df_cr.loc[df_cr.index == cr_row.name, 'range3_count'] += df_peak[(df_peak['chr_peak'] == chr_cr) & 
                                                                      ((df_peak['peak_start'] >= range3_start) & 
                                                                       (df_peak['peak_stop'] <= range3_stop))].shape[0] ###for m6A
        
        # df_cr.loc[df_cr.index == cr_row.name, 'range3_count'] += df_peak[(df_peak['chr_peak'] == chr_cr) & 
        #                                                                 ((df_peak['peak_start'] >= range3_start) & 
        #                                                                 (df_peak['peak_start'] <= range3_stop))].shape[0] ###for G4
        

    return df_cr[['chr', 'range1_count', 'range2_count', 'range3_count']]

# 定义文件路径
base_dir_ref = "C:/summary/ref/"
# peak_file_path = "C:/summary/G4/peaks/" ###for rG4-seq
peak_file_path = "C:/summary/m6A/peaks/" ###for MeRIP-seq

types = ['4DTV2']
# types = ['statistical']
# types = ['MS', 'ribo', 'statistical']

peaks = ['IFN', 'Mock', 'U205_m7G', 'Alt_IP', 'Ref_IP_rep1', 'AS_IP'] ###for MeRIP-seq
# peaks = ['10ng', '30ng', '50ng', '100ng', '250ng', '500ng'] ###for rG4-seq

for t in types:
    # file = os.path.join(base_dir_ref, t + '_CR_add.csv_updated.csv')
    file = os.path.join(base_dir_ref, t + '.bed')
    # 读取位置文件和peak文件
    df = pd.read_csv(file, sep='\t', header=0)

    for p in peaks:
        peak_df = pd.read_csv(peak_file_path + p + "_summits.bed", sep='\t', header=None, names=['chr_peak', 'peak_start', 'peak_stop', 'peak_name', 'value'])
        # 分别处理三个位置文件并统计peak数
        counts = count_peaks_in_ranges(df, peak_df)
        random_sample = counts.sample(n=200, replace=False)
        random_sample.to_csv(peak_file_path + t + '_' + p + 'peak_counts.csv', columns=['chr', 'range1_count', 'range2_count', 'range3_count'], index=False)