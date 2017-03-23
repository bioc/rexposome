#' @describeIn imExposomeSet Returns an \code{\link{ExposomeSet}} with ethe given imputation.
setMethod(
    f = "toES",
    signature = "imExposomeSet",
    definition = function(object, rid=1) {
        if(rid > -1) {
            if(rid > object@nimputation) {
                stop("Given 'rid' with imputation number is too large.")
            }
            ee <- object@assayData[object@assayData$`.imp` == rid, -1, drop=FALSE]
            pp <- object@phenoData[object@phenoData$`.imp` == rid, -1, drop=FALSE]

            rownames(ee) <- ee[ , 1]
            rownames(pp) <- pp[ , 1]
            load_exposome(
                exposures = ee[ , -1],
                description = object@featureData[ , -ncol(object@featureData)],
                phenotype = pp[ , -1]
            )
        } else {
            stop("'rid' sould be larger or equall to 1.")
        }
    }
)