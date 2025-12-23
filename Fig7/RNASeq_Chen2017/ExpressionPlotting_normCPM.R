# edgeR TMM workflow -> log2-CPM, ready for ggplot (replace the DESeq2 block)
library(ggplot2)
library(reshape2)
library(edgeR)

# Read in data from Chen 2017, Development paper (GSE69185 Count Data)
data <- read.delim("GSE69185_Count.txt", header=TRUE, stringsAsFactors=FALSE)

# Define columns that represent count data, and report if any missing
count_cols <- c("HH6_count","X3ss_count","X5.6ss_count",
                "X8.9ss_count","X11.12ss_count")
if(!all(count_cols %in% colnames(data))){
  stop("Missing count columns. Available columns: ", 
       paste(colnames(data), collapse=", "))
}

# build count matrix and ensure numeric
counts_mat <- as.matrix(data[, count_cols])
rownames(counts_mat) <- data$external_gene_id
storage.mode(counts_mat) <- "numeric"

# If there are duplicated gene names, aggregate by summing counts (recommended)
if(any(duplicated(rownames(counts_mat)))){
  counts_df <- as.data.frame(counts_mat, stringsAsFactors = FALSE)
  counts_df$gene <- rownames(counts_df)
  counts_agg_df <- aggregate(. ~ gene, data = counts_df, FUN = sum)
  rownames(counts_agg_df) <- counts_agg_df$gene
  counts_agg_df$gene <- NULL
  counts_mat <- as.matrix(counts_agg_df)
  storage.mode(counts_mat) <- "numeric"
}

# create DGEList
y <- DGEList(counts = counts_mat)

# filter lowly expressed genes (adjust threshold as desired)
# here we keep genes with CPM > 1 in at least 1 sample (be more strict if you prefer: >=2)
keep <- rowSums(cpm(y) > 1) >= 1
y <- y[keep, , keep.lib.sizes = FALSE]

# TMM normalization and log2-CPM
y <- calcNormFactors(y)
logcpm <- cpm(y, log = TRUE, prior.count = 1)  # log2-CPM (TMM normalized)

# Define gene sets to examine
otic_genes <- c("APOD","PAX2", "ETV4", "SOX8", "SOX10")
fgf_genes <- c("APOD", "FGF8", "FGF10", "ETV4", "MKP3", "PAX2")
# Specify which we'll plot
genes_to_plot <- fgf_genes

# subset to genes of interest (case-insensitive) and reshape for ggplot
sel_idx <- which(toupper(rownames(logcpm)) %in% toupper(genes_to_plot))
if(length(sel_idx) == 0) stop("No genes matched genes_to_plot after normalization.")
plot_df <- data.frame(external_gene_id = rownames(logcpm)[sel_idx],
                      logcpm[sel_idx, , drop = FALSE],
                      stringsAsFactors = FALSE)

data_melt <- reshape2::melt(plot_df, id.vars = "external_gene_id",
                            variable.name = "variable", value.name = "value")

# relabel stages and genes (value is log2-CPM; do NOT log again)
data_melt$variable <- factor(data_melt$variable, levels = count_cols,
                             labels = c("HH6","3ss","5-6ss","8-9ss","11-12ss"))
# keep gene ordering consistent with the user's desired order (genes_to_plot)
data_melt$external_gene_id <- factor(data_melt$external_gene_id, 
                                     levels = rev(genes_to_plot))

# Plot data (y axis shows log2-CPM, TMM normalized)
ggplot(data_melt, aes(x=variable, y=value, 
                      color=external_gene_id, group=external_gene_id)) +
  geom_line(size=1) + 
  geom_point(size = 2.5) +
  labs(x="Stage", y="log2-CPM (TMM normalized)", 
       title="Expression in the Otic Placode Domain") +
  scale_color_brewer(palette="Dark2") +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),    # remove major gridlines
    panel.grid.minor = element_blank(),    # remove minor gridlines
    axis.line.x = element_line(size = 0.5, colour = "black"),   # thicker X axis bar
    axis.line.y = element_line(size = 0.5, colour = "black"),   # thicker Y axis bar
    axis.ticks = element_line(size = 0.8),                     # thicker ticks
    axis.text = element_text(size = 12, colour = "black"),
    axis.title = element_text(size = 13, colour = "black"),
    legend.title = element_blank(),
    legend.text = element_text(face = "italic")
  )
