% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/check.R
\name{check_dprimary}
\alias{check_dprimary}
\title{Check if a function is a valid bounded probability density function (PDF)}
\usage{
check_dprimary(dprimary, pwindow, dprimary_args = list(), tolerance = 0.001)
}
\arguments{
\item{dprimary}{Function to generate the probability density function
(PDF) of primary event times. This function should take a value \code{x} and a
\code{pwindow} parameter, and return a probability density. It should be
normalized to integrate to 1 over [0, pwindow]. Defaults to a uniform
distribution over [0, pwindow]. Users can provide custom functions or use
helper functions like \code{dexpgrowth} for an exponential growth distribution.
See \code{primary_dists.R} for examples.}

\item{pwindow}{Primary event window}

\item{dprimary_args}{List of additional arguments to be passed to
dprimary. For example, when using \code{dexpgrowth}, you would
pass \code{list(min = 0, max = pwindow, r = 0.2)} to set the minimum, maximum,
and rate parameters.}

\item{tolerance}{The tolerance for the integral to be considered close to 1}
}
\value{
NULL. The function will stop execution with an error message if
dprimary is not a valid PDF.
}
\description{
This function tests whether a given function behaves like a valid PDF by
checking if it integrates to approximately 1 over the specified range
and if it takes the arguments min and max.
}
\examples{
check_dprimary(dunif, pwindow = 1)
}
\seealso{
Distribution checking functions
\code{\link{check_pdist}()}
}
\concept{check}
