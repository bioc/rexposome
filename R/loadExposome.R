#' Creation of an ExposomeSet from \code{data.frames}
#'
#' Given three \code{data.frames} that defines the exposome (measures
#' of exposome, exposome description and individuals phentype) it loads
#' them and creates an object of type \link{ExposomeSet}.
#'
#' The rows of the exposure's \code{data.frames}, that corresponds to samples'
#' names, must be the same than the phenotype's \code{data.frames}. In the
#' same way, the columns in exposure's \code{data.frames} must be the same
#' in description \code{data.frame}.
#'
#' @param exposures \code{data.frame} of exposures.
#' @param description \code{data.frame} with the description of the exposures
#' (relation between exposures and exposure-family).
#' @param phenotype \code{data.frame} with the phenotypes of interest.
#' @param description.famCol (default \code{"family"}) Index where the family's
#' name (per exposures) if found in file "description". It can be both numeric
#' or character.
#' @param exposures.asFactor (default \code{5}) The exposures with more
#' than this number of unique items will be considered as "continuous" while
#' the exposures with less or equal number of items will be considered as
#' "factor".
#' @param warnings (default \code{TRUE}) If \code{TRUE} shows useful
#' information/warnings from the process of loading the exposome.
#' @return An object of class \link{ExposomeSet}.
#' @note \link{ExposomeSet}'s \code{fData} will contain some inner columns
#' called \code{.std}, \code{.trn}, \code{.fct} and \code{.type} in order to
#' trace the transformations an exposure suffers and to know, at eny moment, if
#' an exposure is categorical or continuous. The "description" file can
#' contains a column called \code{type} with values \code{"factor"} and
#' \code{"numeric"} to speficy how an exposure needs to be understood. If
#' given, this column will be renamed to \code{.type}. If not given, it will
#' be created using \code{exposures.asFactor} value.
#' @export loadExposome
#' @seealso \link{ExposomeSet} for class description,
#' \link{readExposome} for constructor from txt/csv
#' files.
#' @examples
#' path <- file.path(path.package("rexposome"), "extdata")
#' description <- file.path(path, "description.csv")
#' phenotype <- file.path(path, "phenotypes.csv")
#' exposures <- file.path(path, "exposures.csv")
#' dd <- read.csv(description, header=TRUE)
#' ee <- read.csv(exposures, header=TRUE)
#' pp <- read.csv(phenotype, header=TRUE)
#' rownames(dd) <- dd[, 2]
#' dd <- dd[ , -2]
#' rownames(ee) <- ee[ , 1]
#' ee <- ee[ , -1]
#' rownames(pp) <- pp[ , 1]
#' pp <- pp[ , -1]
#' exp <- loadExposome(
#' exposures = ee,
#' description = dd,
#' phenotype = pp,
#' description.famCol = "Family"
#' )
loadExposome <- function(exposures, description, phenotype,
        description.famCol = "family", exposures.asFactor = 5,
        warnings = TRUE) {

    ## Order the colmuns on description
    ##   rownames <- exposures
    ##   column  1 must be the family
    if(class(description.famCol) %in% c("integer", "numeric")) {
        description.famCol <- colnames(description)[description.famCol]
    }

    if(!description.famCol %in% colnames(description)) {
        stop("Invalid value for 'description.famCol' ('", description.famCol,
             "').")
    }

    description <- description[ , c(description.famCol,
                      colnames(description)[colnames(description) != description.famCol]), drop=FALSE]
    colnames(description)[1] <- "Family"
    ## ------------------------------------------------------------------------

    ## Check for inner names on description
    if(".std" %in% colnames(description)) {
        stop("Given descriptiion dat contains '.std' as name of a column. ",
             "Name '.std' cannot be used in 'ExposmeSet'.")
    }

    if(".trn" %in% colnames(description)) {
        stop("Given descriptiion dat contains '.trn' as name of a column. ",
             "Name '.trn' cannot be used in 'ExposmeSet'.")
    }

    if(".fct" %in% colnames(description)) {
        stop("Given descriptiion dat contains '.fct' as name of a column. ",
             "Name '.fct' cannot be used in 'ExposmeSet'.")
    }

    if(".imp" %in% colnames(description)) {
        stop("Given descriptiion dat contains '.imp' as name of a column. ",
             "Name '.imp' cannot be used in 'ExposmeSet'.")
    }

    if(".type" %in% colnames(description)) {
        stop("Given descriptiion dat contains '.type' as name of a column. ",
             "Name '.type' cannot be used in 'ExposmeSet'.")
    }
    ## ------------------------------------------------------------------------

    ## Check that the exposures and the samples from the three dataframes
    ## are the same
    exp.col <- colnames(exposures)
    exp.col <- exp.col[order(exp.col)]
    exp.row <- rownames(exposures)
    exp.row <- exp.row[order(exp.row), drop=FALSE]
    exposures <- exposures[exp.row, exp.col, drop=FALSE]

    des.row <- rownames(description)
    des.row <- des.row[order(des.row)]
    description <- description[des.row, , drop=FALSE]

    phe.row <- rownames(phenotype)
    phe.row <- phe.row[order(phe.row)]
    phenotype <- phenotype[phe.row, , drop=FALSE]

    if(!identical(exp.col, des.row)) {
        stop("Exposures's names in exposures and in description files ",
             "don't match.")
    }
    if(!identical(exp.row, phe.row)) {
        stop("Samples's names in exposures and in phenotype files don't match.")
    }
    rm(exp.col, exp.row, des.row, phe.row)
    
    ## ------------------------------------------------------------------------
    # Check that the exposure names on exposures and description file are valid,
    # if not, use function base::make.names to create valid names
    valid_exposure_names <- make.names(colnames(exposures))
    if(!identical(valid_exposure_names, colnames(exposures))){
        warning("Some exposure names were not valid R names, all the non valid characters
                will be changed for a point [.]. Please use the function exposureNames()
                on the created object to check the updated names.")
        colnames(exposures) <- valid_exposure_names
        rownames(description) <- valid_exposure_names
    }
    ## ------------------------------------------------------------------------

    ## Need to create _status
    description$`.fct` <- ""
    description$`.trn` <- ""
    description$`.std` <- ""
    description$`.imp` <- ""
    ## ------------------------------------------------------------------------

    ## Need to create and fill _type of description
    if("type" %in% colnames(description)) {
        if(warnings) {
            warning("Found colname 'type' in description file. It will be ",
                "used to check for exposures' type. Then it will be droped.")
        }
        description$type <- gsub(" ", "", as.character(description$type))
        if(sum(! unique(description$type) %in% c("numeric", "factor")) != 0) {
            stop("In 'type' column of description file only 'factor' or ",
                 "'numeric' calues can be used.")
        }
        description$`.type` <- description$type
        description <- description[ , -which(colnames(description) == "type"),
                                    drop=FALSE]
    } else {
        description$`.type` <- vapply(rownames(description), function(ex) {
            ifelse(length(unique(exposures[ , ex])) > exposures.asFactor,
                   "numeric", "factor")
        }, FUN.VALUE = character(1))
    }
    ## ------------------------------------------------------------------------

    ## Exposures must be saved as numeric-matrix
    exposures <- (as.matrix(exposures))
    ## ------------------------------------------------------------------------

    ## Create and validate ExposomeSet
    exposome <- new("ExposomeSet",
                    assayData = assayDataNew("environment", exp = t(exposures)),
                    phenoData = AnnotatedDataFrame(phenotype),
                    featureData = AnnotatedDataFrame(description)
    )

    validObject(exposome)
    ## ------------------------------------------------------------------------

    return(exposome)
}
