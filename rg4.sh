##index
STAR  \
--runMode genomeGenerate \
--genomeDir 00ref \
--runThreadN 10 \
--genomeFastaFiles /disk/yt/ref/hg38.fa \
--sjdbGTFfile /disk/yt/ref/hg38.gtf \
--sjdbOverhang 149

cat SRR_Acc_List.txt | while read i
do
	mv ${wkd}/${i}/* ${wkd}/01rawdata
	rmdir ${wkd}/${i}/
done

mkdir 02cleandata
cat SRR_Acc_List.txt | while read i
do
	nohup trim_galore --paired --quality 20 --length 20 -o 02cleandata/ 01rawdata/${i}_1.fastq.gz 01rawdata/${i}_2.fastq.gz &
done

mkdir 03QC
cat SRR_Acc_List.txt | while read i
do
	fastqc -o 03QC/ -t 16 02cleandata/${i}_trimmed.fastq.gz
done

mkdir 05map_res
cat SRR_Acc_List.txt | while read i
do
	STAR --runThreadN 20 --readFilesCommand zcat --genomeDir 00ref/ --readFilesIn 02cleandata/${i}_1_val_1.fq.gz 02cleandata/${i}_2_val_2.fq.gz --outSAMtype BAM SortedByCoordinate --outFileNamePrefix 05map_res/${i}
	samtools index 05map_res/${i}Aligned.sortedByCoord.out.bam
	bamCoverage -b 05map_res/${i}Aligned.sortedByCoord.out.bam -o 05map_res/${i}.bw --binSize 10 --normalizeUsing RPGC --effectiveGenomeSize 2913022398
	bigWigToWig 05map_res/${i}.bw 05map_res/${i}.wig
done

##macs2
macs2 callpeak -t ../05map_res/SRR14510891Aligned.sortedByCoord.out.bam -c ../05map_res/SRR14510883Aligned.sortedByCoord.out.bam --nomodel -g 2.7e9 -n 10ng_rep1 -f BAM --verbose 3
macs2 callpeak -t ../05map_res/SRR14510892Aligned.sortedByCoord.out.bam -c ../05map_res/SRR14510883Aligned.sortedByCoord.out.bam --nomodel -g 2.7e9 -n 10ng_rep2 -f BAM --verbose 3

###if don't have CR_position:
python get_CR_position_from_ref0.py
python get_CR_position_from_ref2.py

###count_peak
python count_peak.py

###drop_box
Rscript boxplot.R
