library(ggplot2)
setwd("C:/summary/G4/peaks/")
# 获取该目录下所有csv文件名
csv_files <- list.files(pattern = "*.csv", full.names = TRUE)
# 创建一个空列表用来存储箱型图的数据和结果
boxplot_data <- list()
results <- list()
# 循环处理每个csv文件
for (file in csv_files) {
  # 读取当前文件
  current_data <- read.csv(file, sep = ",", header = TRUE)
  
  # 提取ID列和其他三列数据
  id_column <- current_data[,1]  # 假设第一列是ID列
  data_to_plot <- current_data[, -1]  # 取除第一列以外的所有列
  
  # 将数据添加到boxplot_data列表中以备后续绘图
  boxplot_data[[basename(file)]] <- data_to_plot
  
  # 显著性分析
  for (i in 1:(ncol(data_to_plot)-1)) {
    for (j in (i+1):ncol(data_to_plot)) {
      test_result <- wilcox.test(data_to_plot[, i], data_to_plot[, j])
      
      # 结果存入results列表中，键值由文件名和列名组成
      comparison_key <- paste0(basename(file), "_", colnames(data_to_plot)[i], "_vs_", colnames(data_to_plot)[j])
      results[[comparison_key]] <- list(test_result$p.value)
    }
  }
}

# 创建一个函数来绘制并保存箱型图
save_boxplot_pdf <- function(data_name, data_for_boxplot) {
  p <- ggplot(data_for_boxplot, aes(x = factor(column_name), y = value)) +
    geom_boxplot(outlier.shape = NA) +
    labs(x = "Columns", y = "Value") +
    ggtitle(paste0("Boxplot of Data from ", data_name)) +
    theme(plot.title = element_text(hjust = 0.5))
  
  # 设置输出路径和文件名
  output_file <- paste0("C:/summary/G4/peaks/boxplots/", gsub(".csv", ".pdf", basename(data_name)), "_boxplot.pdf")
  
  # 绘制图形并保存为PDF
  ggsave(output_file, plot = p, width = 11, height = 8.5, units = "in")
}

# 循环处理每个文件并保存对应的箱型图
for (data_name in names(boxplot_data)) {
  
  # 将箱型图数据转换成适合ggplot使用的格式，并添加合适的列名
  data_for_boxplot <- as.data.frame(t(boxplot_data[[data_name]]))
  column_names <- paste0("Column_", seq_len(nrow(data_for_boxplot)))
  data_for_boxplot$column_name <- column_names
  data_for_boxplot$value <- as.vector(data_for_boxplot[, 1])
  
  save_boxplot_pdf(data_name, data_for_boxplot)
}
results
