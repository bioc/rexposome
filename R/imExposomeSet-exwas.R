#' @describeIn imExposomeSet Performs an EXposome-Wide Association Study
#' @param object An object of class \code{\link{imExposomeSet}}
#' @param formula Formula, not including exposures, to be tested.
#' @param filter Expression to be used to filter \code{\link{ExposomeSet}}
#' @param family Family descriving the nature of the health outcome
#' @param ... Other used arguments
#' @param baselevels Labeled vector with the base-level of the
#' categorical exposures
#' @param tef If set to \code{TRUE} the threshold for effective
#' test is computed.
#' @param verbose If set to \code{TRUE} it shows messages on progression.
#' @param warnings If set to \code{TRUE} it shows warnings on progession.

setMethod(
    f = "exwas",
    signature = "imExposomeSet",
    definition = function(object, formula, filter, family, ..., baselevels,
                          tef = TRUE, verbose = FALSE, warnings = TRUE) {
        if(missing(family)) {
            stop("Missing argument 'family'.")
        }

        dta <- data.frame(expos( object ), pData(object)[ , -c(1:2)])

        nmis <- apply(dta[dta$`.imp` == 0, ], 2, function(x) sum(is.na(x)))
        dta <- dta[dta$`.imp` != 0, ]
        dta <- dta[ , -2]

        if(!missing(filter)) {
            sel <- eval(substitute(filter), as.data.frame(dta))
            dta <- dta[sel, ]
        }

        if(class(formula) == "character") {
            formula <- formula(formula)
        }

        if( sum( ! all.vars(formula) %in% colnames(dta) ) != 0 ) {
            sel <- all.vars(formula)[ ! all.vars(formula) %in% colnames(dta) ]
            stop("Not all variables (", paste( sel, collapse = ", " ), ") exists in given 'imExposomeSet'.")
        }

        # form <- as.character(formula)
        cL <- ifelse(missing(baselevels), FALSE, TRUE)

        ne <- list()
        items <- list()
        ex_names <- vector()
        for(ex in exposureNames(object)) {
            if(verbose) {
                message("Processing '", ex, "'.")
            }

            # frm <- as.formula(paste0(form[2], "~", ex, "+", form[3]))
            frm <- update(formula, formula(paste("~ +", ex, "+ .")))

            # check if relevel is necessary
            if(cL) {
                if(ex %in% names(baselevels)) {
                    dta[ , ex] <- stats::relevel(dta[ , ex], baselevels[ex])
                }
            }
            # /

            tbl <- sapply(all.vars(frm), function(x) length(table( dta[ , x, drop = FALSE])))
            if(sum(!sapply(tbl, ">", 1)) != 0) {
                warning("When testing for '", ex, "', at last one covariate ",
                        "is constant (",
                        paste(paste(names(tbl), tbl, sep=": "), collapse=", "),
                        ")")
                items[[ex]] <- c(NULL, NULL, NULL, NULL)
            } else {
                tryCatch({
                    typ <- fData(object)[ ex, ".type" ]
                    typ <- ifelse( typ != "factor", FALSE, length( levels( dta[ , ex ] ) ) > 2 )

                    ## TEST
                    fit_glm <- lapply(seq(object@nimputation), function(ii) {
                        dtai <- dta[dta[, 1] == ii, -1]
                        stats::glm(family=family, formula = frm, data = dtai)
                    })
                    mira_glm <- list(
                        call = NULL,
                        call1 = NULL,
                        nmis = nmis,
                        analyses = fit_glm
                    )
                    class(mira_glm) <- "mira"

                    #tst <- rexposome:::pool_glm(mira_glm, ex = ex)
                    tst <- mice::mipo(mira_glm)

                    dt <- summary(tst, conf.int = TRUE)
                    if( typ ) {
                        mod0 <- lapply(seq(object@nimputation), function(ii) {
                            dtai <- dta[dta[, 1] == ii, -1]
                            stats::glm(family=family, formula = formula, data = dtai)
                        })
                        mira_mod0 <- list(
                            call = NULL,
                            call1 = NULL,
                            nmis = nmis,
                            analyses = mod0
                        )
                        class(mira_mod0) <- "mira"
                        p <- mice::pool.compare(mira_glm, mira_mod0)$pvalue

                        rn2 <- paste( ex, levels( dta[ , ex ] ), sep = "$" )[ seq( 2, length( levels( dta[ , ex ] ) ) ) ]
                        # browser()
                        # items[[ex]] <- rbind(cbind(as.numeric(dt[startsWith(rownames(dt), ex), c(2, 7, 8, 6)]), rn2), c(NA, NA, NA, p, ex))
                        items[[ex]] <- rbind(cbind(dt[startsWith(as.character(dt[,1]), ex), c(2, 7, 8, 6)], rn2), c(NA, NA, NA, p, ex))
                        rownames(items[[ex]]) <- items[[ex]][ , 5]
                        ex_names <- c(ex_names, rownames(items[[ex]]))
                        colnames(items[[ex]]) <- c("effect", "x2.5","x97.5", "pvalue", "name")
                    } else {
                        # browser()
                        items[[ex]] <- c(as.numeric(dt[2, c(2, 7, 8, 6)]), ex)
                        ex_names <- c(ex_names, ex)
                        names(items[[ex]]) <- c("effect", "x2.5","x97.5", "pvalue", "name")
                    }

                }, error = function(e) {
                    if(verbose) {
                        message("\tProcess of '", ex, "' failed.", e)
                    }
                    ne[[ex]] <- e
                    items[[ex]] <- c(NULL, NULL, NULL, NULL, ex)
                })
            }
        }

        # message( "A" )

        if(length(ne) != 0) {
            warning("The association of some exposures (", length(ne), ") could not be evaluated. Their effect and p-value were set to NULL.")
        }
        # browser()
        items <- data.frame(do.call(rbind, items))
        colnames(items) <- c("effect", "2.5","97.5", "pvalue", "ex")
        rownames(items) <- ex_names # exposureNames(object)

        ## Compute the threshold for effective tests
        if(tef) {
            cormat <- extract(correlation(toES(object, rid=1),
                use="pairwise.complete.obs", method.cor = "pearson"))
            M <- ncol(cormat)
            lambdas <- base::eigen(cormat)$values
            Vobs <- sum(((lambdas - 1)^2)) / (M - 1)
            Meff <- M - sum((lambdas>1)*(lambdas-1))
            alpha_corrected <- 1 - (1 - 0.05)^(1 / Meff)
        } else {
            alpha_corrected <- -1
        }
        ## /

        new("ExWAS",
            effective = alpha_corrected,
            comparison = S4Vectors::DataFrame(items),
            description = fData(object),
            formula = formula
        )
    }
)
