# WCGNA is in CRAN but depends on several packages not in cran (impute, GO.db,
# AnnotationDbi), which is something that really should not happen with a sane
# repository.
# Anyway, that's why it is installed here
required.packages <- c("WGCNA", "impute", "multtest", "CGHbase", "CGHtest",
                                           "CGHtestpar", "edgeR", "snpStats", "preprocessCore",
                                           "GO.db", "AnnotationDbi", "QDNAseq");

 install.packages("BiocManager", repos=Sys.getenv("CRAN_MIRROR"));

missing.packages <- function(required) {
        return(required[
                !(required %in% installed.packages()[,"Package"])]);
}
new.packages <- missing.packages(required.packages);
if (!length(new.packages))
        q();

bioclite.packages <-
                intersect(new.packages, c("impute", "multtest", "CGHbase", "edgeR",
                                                                  "snpStats", "preprocessCore", "GO.db",
                                                                  "AnnotationDbi", "QDNAseq"));
if (length(bioclite.packages))
        BiocManager::install(bioclite.packages);
# 1.10.0 version contains an important fix.
# We still need to install the old package with biocLite first to install all dependencies.
# For some reasons below installations does not take care of installing dependencies first.
download.file(
                url="http://bioconductor.org/packages/release/bioc/src/contrib/QDNAseq_1.22.0.tar.gz",
                dest="/tmp/QDNAseq_1.22.0.tar.gz", method="internal");

install.packages(c("future", "future.apply"), repos=Sys.getenv("CRAN_MIRROR"));

install.packages("/tmp/QDNAseq_1.22.0.tar.gz",
                repos=NULL, type="source");

if (length(intersect(new.packages, c("CGHtest")))) {
        download.file(
                        url="http://files.thehyve.net/CGHtest_1.1.tar.gz",
                        dest="/tmp/CGHtest_1.1.tar.gz", method="internal");
        install.packages("/tmp/CGHtest_1.1.tar.gz",
                        repos=NULL, type="source")
}
if (length(intersect(new.packages, c("CGHtestpar")))) {
        download.file(
                        url="http://files.thehyve.net/CGHtestpar_0.0.tar.gz",
                        dest="/tmp/CGHtestpar_0.0.tar.gz", method="internal");
        install.packages("/tmp/CGHtestpar_0.0.tar.gz",
                        repos=NULL, type="source")
}
if (length(intersect(new.packages, c("WGCNA")))) {
        BiocManager::install("WGCNA");
}

if (length(missing.packages(required.packages))) {
        print("Failed packages...")
        failed.packages <- missing.packages(required.packages)
        print(failed.packages)
        warning('Some packages not installed');
        quit("no");
}
