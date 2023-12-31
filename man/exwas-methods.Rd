% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/01_AllMethods.R
\name{exwas}
\alias{exwas}
\title{Testing the association between an exposure and a phenotype of an
ExposomeSet}
\usage{
exwas(
  object,
  formula,
  filter,
  family,
  ...,
  baselevels,
  tef = TRUE,
  verbose = FALSE,
  warnings = TRUE,
  robust = FALSE
)
}
\arguments{
\item{object}{\code{ExposomeSet} that will be used for the ExWAS.}

\item{formula}{\code{formula} indicating the test to be done. If any
exposure is included it will be used as covariate. \code{exwas} metho will
perform the test for each exposure.}

\item{filter}{\code{expression} to be used to filter the individuals
included into the test.}

\item{family}{Family of the distribution followed by the health outcome to
be tested (gaussian, bionomal, ... check \link{glm}).}

\item{...}{NOT USED}

\item{baselevels}{(optional) If set, must be a labeled vector with the
default base level for categorical exposures.}

\item{tef}{(default \code{TRUE}) If \code{TRUE} it computed the
effective number of tests and the threhold for the effective
number of tests. Usually it needs imputed data.}

\item{verbose}{(default \code{FALSE}) If set o true messages along the
tests are shown.}

\item{warnings}{(default \code{TRUE}) If set to \code{FALSE} warnings will
not be displayed.}
}
\value{
An code{ExWAS} object with the result of the association study
}
\description{
The \code{exwas} method performs an "Exposome-Wide Association Study" (ExWAS)
using the exposures in \link{ExposomeSet} and one of its phenotype.
}
\examples{
data(exposome)
w1 <- exwas(expo[1:5, ], asthma~1, family = "binomial")
w2 <- exwas(expo[1:5, ], asthma~sex+age, family = "binomial")
w3 <- exwas(expo[1:5, ], asthma~age, family = "binomial", filter = sex=="boy")
}
\references{
An Environment-Wide Association Study (ExWAS) on Type 2 Diabetes
Mellitus. Chirag J. Patel, Jayanta Bhattacharya, Atul J. Butte. May 20, 2010
Plos One

Evaluating the effective numbers of independent tests and
significant p-value thresholds in commercial genotyping arrays and public
imputation reference datasets. Miao-Xin Li, Juilian M. Y. Yeung,
Stacey S. Cherny and Pak C. Sham. May 2012 Hum Genet.
}
\seealso{
\link{extract} to obtain a table with the result of the ExWAS,
\link{plotExwas} to plot the results of the ExWAS
}
