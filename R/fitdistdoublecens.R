#' Fit a distribution to doubly censored data
#'
#' This function wraps the custom approach for fitting distributions to doubly
#' censored data using fitdistrplus and primarycensoreddist.
#'
#' @details
#' This function temporarily assigns and then removes functions from the global
#' environment in order to work with fitdistr. Users should be aware of this
#' behaviour, especially if they have existing functions with the same names in
#' their global environment.
#'
#' @param censdata A data frame with columns 'left' and 'right' representing
#' the lower and upper bounds of the censored observations. Unlike
#' [fitdistrplus::fitdistcens()] `NA` is not supported for either the
#' upper or lower bounds.
#'
#' @param distr A character string naming the distribution to be fitted.
#'
#' @inheritParams pprimarycensoreddist
#'
#' @param ... Additional arguments to be passed to [fitdistrplus::fitdist()].
#'
#' @return An object of class "fitdist" as returned by fitdistrplus::fitdist.
#'
#' @export
#' @family modelhelpers
#' @examples
#' # Example with normal distribution
#' set.seed(123)
#' n <- 1000
#' true_mean <- 5
#' true_sd <- 2
#' pwindow <- 2
#' swindow <- 2
#' D <- 10
#' samples <- rprimarycensoreddist(
#'   n, rnorm,
#'   mean = true_mean, sd = true_sd,
#'   pwindow = pwindow, swindow = swindow, D = D
#' )
#'
#' delay_data <- data.frame(
#'   left = samples,
#'   right = samples + swindow
#' )
#'
#' fit_norm <- fitdistdoublecens(
#'   delay_data,
#'   distr = "norm",
#'   start = list(mean = 0, sd = 1),
#'   D = D, pwindow = pwindow
#' )
#'
#' summary(fit_norm)
fitdistdoublecens <- function(censdata, distr,
                              pwindow = 1, D = Inf,
                              dprimary = stats::dunif,
                              dprimary_args = list(), ...) {
  # Check if fitdistrplus is available
  if (!requireNamespace("fitdistrplus", quietly = TRUE)) {
    stop(
      "Package 'fitdistrplus' is required but not installed for this function."
    )
  }

  if (!all(c("left", "right") %in% names(censdata))) {
    stop("censdata must contain 'left' and 'right' columns")
  }

  # Get the distribution functions
  pdist <- get(paste0("p", distr))

  swindows <- censdata$right - censdata$left

  # Create the function definition with named arguments for dpcens
  dpcens_dist <- function() {
    args <- as.list(environment())
    do.call(.dpcens, c(
      args,
      list(
        swindows = swindows,
        pdist = pdist,
        pwindow = pwindow,
        D = D,
        dprimary = dprimary,
        dprimary_args = dprimary_args
      )
    ))
  }
  formals(dpcens_dist) <- formals(get(paste0("d", distr)))

  # Create the function definition with named arguments for ppcens
  ppcens_dist <- function() {
    args <- as.list(environment())
    do.call(.ppcens, c(
      args,
      list(
        pdist = pdist,
        pwindow = pwindow,
        D = D,
        dprimary = dprimary,
        dprimary_args = dprimary_args
      )
    ))
  }
  formals(ppcens_dist) <- formals(pdist)

  assign("d.pcens_dist", dpcens_dist, envir = .GlobalEnv)
  assign("p.pcens_dist", ppcens_dist, envir = .GlobalEnv)

  # Fit the distribution
  fit <- fitdistrplus::fitdist(
    censdata$left,
    distr = ".pcens_dist",
    ...
  )
  rm(dpcens_dist, ppcens_dist)
  return(fit)
}

#' Define a fitdistrplus compatible wrapper around dprimarycensoreddist
#' @inheritParams dprimarycensoreddist
#'
#' @param swindows A numeric vector of secondary window sizes corresponding to
#' each element in x
#' @keywords internal
.dpcens <- function(x, swindows, pdist, pwindow, D, dprimary,
                    dprimary_args, ...) {
  tryCatch(
    {
      if (length(unique(swindows)) == 1) {
        dprimarycensoreddist(
          x, pdist,
          pwindow = pwindow, swindow = swindows[1], D = D, dprimary = dprimary,
          dprimary_args = dprimary_args, ...
        )
      } else {
        # Group x and swindows by unique swindow values
        unique_swindows <- unique(swindows)
        result <- numeric(length(x))

        for (sw in unique_swindows) {
          mask <- swindows == sw
          result[mask] <- dprimarycensoreddist(
            x[mask], pdist,
            pwindow = pwindow, swindow = sw, D = D,
            dprimary = dprimary, dprimary_args = dprimary_args, ...
          )
        }

        result
      }
    },
    error = function(e) {
      rep(NaN, length(x))
    }
  )
}

#' Define a fitdistrplus compatible wrapper around pprimarycensoreddist
#' @inheritParams pprimarycensoreddist
#' @keywords internal
.ppcens <- function(q, pdist, pwindow, D, dprimary, dprimary_args, ...) {
  tryCatch(
    {
      pprimarycensoreddist(
        q, pdist,
        pwindow = pwindow,
        D = D, dprimary = dprimary, dprimary_args = dprimary_args, ...
      )
    },
    error = function(e) {
      rep(NaN, length(q))
    }
  )
}
