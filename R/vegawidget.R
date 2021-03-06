#' Create a Vega/Vega-Lite htmlwidget
#'
#' The main use of this package is to render a `vegawidget`,
#' which is also an `htmlwidget`. This function builds a `vegawidget`
#' using a `vegaspec`.
#'
#' If `embed` is `NULL`, `vegawidget()` uses:
#'
#' - `getOption("vega.embed")`, if that is NULL:
#' - an empty call to [vega_embed()]
#'
#' The most-important arguments to [vega_embed()] are:
#'
#' - `renderer`, to specify `"canvas"` (default) or `"svg"`
#' - `actions`,  to specify action-links
#'    for `export`, `source`, `compiled`, and `editor`
#'
#' If either `width` or `height` is specified, the `autosize()` function
#' is used to override the width and height of the `spec`. There are some
#' important provisions:
#'
#' - Specifying `width` and `height` is
#' [effective only for single-view charts and layered charts](
#' https://vega.github.io/vega-lite/docs/size.html#limitations).
#' It will not work for contatenated, faceted, or repeated charts.
#'
#' - In the `spec`, the default interpretation of width and height
#' is to describe the dimensions of the
#' **plotting rectangle**, not including the space used by the axes, labels,
#' etc. Here, `width` and `height` describe the dimensions
#' of the **entire** rendered chart, including axes, labels, etc.
#'
#' @inheritParams as_vegaspec
#' @inheritParams vw_autosize
#' @param embed   `list` to specify
#'   [vega-embed](https://github.com/vega/vega-embed#options) options,
#'   see **Details** on how this is set if `NULL`.
#' @param ... other arguments passed to [htmlwidgets::createWidget()]
#'
#' @return S3 object of class `vegawidget` and `htmlwidget`
#' @seealso [vega-embed options](https://github.com/vega/vega-embed#options),
#'   [vega_embed()], [vw_autosize()]
#' @examples
#'   vegawidget(spec_mtcars, width = 350, height = 350)
#'
#' @export
#'
vegawidget <- function(spec, embed = NULL, width = NULL, height = NULL, ...) {

  # if `embed` is NULL, check for option
  embed <- embed %||% getOption("vega.embed")

  # if `embed` is still NULL, set using empty call to vega_embed()
  embed <- embed %||% vega_embed()

  # autosize (if needed)
  spec <- vw_autosize(spec, width = width, height = height)

  # use internal methods here because spec has already been validated
  x <-
    .as_json(
      list(
        chart_spec = .as_list(spec),
        embed_options = embed
      )
    )

  vegawidget <-
    htmlwidgets::createWidget(
      "vegawidget",
      x,
      width = width,
      height = height,
      package = "vegawidget",
      ...
    )

  vegawidget
}

#' Shiny-output for vegawidget
#'
#' @inheritParams htmlwidgets::shinyWidgetOutput
#'
#' @export
#'
vegawidgetOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(
    outputId,
    "vegawidget",
    width,
    height,
    package = "vegawidget"
  )
}

#' Render shiny-output for vegawidget
#'
#' @inheritParams htmlwidgets::shinyRenderWidget
#'
#' @export
#'
renderVegawidget <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(
    expr,
    vegawidgetOutput,
    env,
    quoted = TRUE
  )
}
