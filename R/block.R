#' Create gist to use as block
#'
#' These functions require that [**fs**](https://cran.r-project.org/package=fs)
#' and  [**gistr**](https://cran.r-project.org/package=gistr) be installed.
#' If you want to include a thumbnail or preview image, you will need the
#' [**magick**](https://cran.r-project.org/package=magick) package,
#' [**webdriver**](https://cran.r-project.org/package=webdriver) package,
#' and PhantomJS installed.
#'
#' These functions do the same thing: create a gist; they differ only in what
#' they return. `vw_create_block()` returns a copy of `spec` so that it can be
#' used in a pipe; `vw_create_block_gistid()` returns a list of information
#' about the newly-created gist.
#'
#' In addition to having the **gistr** package installed, you will need a
#' GitHub Personal Access Token (PAT) stored in an environment variable
#' called `GITHUB_PAT`. See [Happy Git with R](http://happygitwithr.com/github-pat.html)
#' for more information on how to acquire and store a PAT.
#'
#' The default versions of the Vega JavaScript libraries are this package's
#' supported versions. To use the major (current) versions instead, use
#' `version = vega_version(major = TRUE)`.
#'
#' @inheritParams vegawidget
#' @param .block       `character`, YAML text for the `.block` file -
#'   use the helper function [vw_block_config()] to specify block-configuration
#' @param version       named `list` of `character`:
#'   names refer to JavaScript libraries `vega`, `vega_lite`, `vega_embed`,
#'   values are the tags for the versions to use in the block - use the
#'   helper function [vega_version()] with `major = TRUE` to use the current
#'   major versions rather than the versions supported in this package
#' @param description   `character`, description for the gist - if `NULL`,
#'   looks for a description field in `spec`.
#' @param readme        `character`, single line, path to a markdown file;
#'   multiple lines, markdown text
#' @param use_thumbnail `logical`, indicates to include a thumbnail image
#' @param use_preview   `logical`, indicates to include a preview image
#' @param endpoint      `character`, base endpoint for GitHub API, defaults to
#'   `"https://api.github.com"`; useful to specify with GitHub Enterprise,
#'   e.g. `"https://github.acme.com/api/v3"`
#'   (not yet implemented)
#' @param git_method    `character`, use `"ssh"` or `"https"`
#' @param env_pat       `character`, name of environment variable that contains
#'   a GitHub PAT (Personal Access Token), defaults to `"GITHUB_PAT"`;
#'   Useful to specify with GitHub Enterprise, e.g. `"GITHUB_ACME_PAT"`
#'   (not yet implemented)
#' @param block_host    `character`, hostname of blocks server,
#'   defaults to `bl.ocks.org`
#' @param quiet          `logical`, indicates to supress messages
#' @param browse         `logical`, indicates to open browser to blocks web-page
#'   when complete
#'
#' @return Called for side effects
#' \describe{
#'   \item{`create_block()`}{returns an invisible copy of `spec`}
#'   \item{`create_block_gistid()`}{returns a list with elements:
#'     \describe{
#'       \item{`endpoint`}{`character`, git API endpiont}
#'       \item{`id`}{`character`, gist id}
#'     }
#'   }
#' }
#' @examples
#' \dontrun{
#'   # use supported versions
#'   vw_create_block(spec_mtcars)
#'   # use major versions
#'   vw_create_block(spec_mtcars, version = vega_version(major = TRUE))
#'   # return gist information
#'   vw_create_block_gistid(spec_mtcars)
#' }
#'
#' @seealso [Blocks documentation](https://bl.ocks.org/-/about),
#'  [vw_retrieve_block()],
#'  [gistr::gist_create_git()], [vega_version()], [vw_block_config()]
#'
#' @export
#'
vw_create_block <- function(spec, embed = vega_embed(),
                            .block = vw_block_config(),
                            version = vega_version(major = FALSE),
                            description = NULL, readme = NULL,
                            use_thumbnail = TRUE, use_preview = TRUE,
                            git_method = c("ssh", "https"),
                            endpoint = NULL, env_pat = NULL,
                            block_host = NULL, quiet = FALSE,
                            browse = TRUE) {

  # pass along everything to .create_block()
  result <- do.call(.vw_create_block, args = as.list(environment()))

  invisible(result$spec)
}

#' @rdname vw_create_block
#' @export
#'
vw_create_block_gistid <- function(spec, embed = vega_embed(),
                                   .block = vw_block_config(),
                                   version = vega_version(major = FALSE),
                                   description = NULL, readme = NULL,
                                   use_thumbnail = TRUE, use_preview = TRUE,
                                   git_method = c("ssh", "https"),
                                   endpoint = NULL, env_pat = NULL,
                                   block_host = NULL, quiet = FALSE,
                                   browse = TRUE) {

  # pass along everything to .create_block()
  result <- do.call(.vw_create_block, args = as.list(environment()))

  result[c("endpoint", "id")]
}

.vw_create_block <- function(spec, embed = vega_embed(),
                             .block = vw_block_config(),
                             version = vega_version(major = FALSE),
                             description = NULL, readme = NULL,
                             use_thumbnail = TRUE, use_preview = TRUE,
                             git_method = c("ssh", "https"),
                             endpoint = NULL, env_pat = NULL,
                             block_host = NULL, quiet = FALSE,
                             browse = TRUE) {
  # validate
  assert_packages("fs", "gistr")

  # create temporary directory
  dir_temp <- fs::path(tempdir(), glue::glue("block-{as.numeric(Sys.time())}"))
  fs::dir_create(dir_temp)

  # doing this here so we can access the description
  spec <- as_vegaspec(spec)

  # compose a temp directory to contain the gist files
  vw_block_build_directory(
    dir_temp,
    spec = spec,
    embed = embed,
    version = version,
    .block = .block,
    readme = readme,
    use_thumbnail = use_thumbnail,
    use_preview = use_preview
  )

  # create the gist based on the temp directory
  files <- fs::dir_ls(dir_temp, all = TRUE) # ensures we include .block
  description <- description %||% spec$description %||% ""

  gst <- suppressMessages(
    gistr::gist_create_git(
      files,
      description = description,
      browse = FALSE,
      git_method = git_method
    )
  )

  # result
  block_host <- block_host %||% "bl.ocks.org"
  result <- list(
    spec = spec,
    endpoint = gsub("^(.*)(/gists/.*)$", "\\1", gst$url),
    id = gst$id,
    url_gist = gst$html_url,
    url_block = glue::glue("https://{block_host}/{gst$id}")
  )

  # if indicated, message the gist URL and the blocks URL
  if (!quiet) {
    message(glue::glue("block url: {result$url_block}"))
    message(glue::glue(" gist url: {result$url_gist}"))
  }

  # if indicated, open the browser
  if (browse) {
    utils::browseURL(result$url_block)
  }

  # delete temporary directory
  unlink(dir_temp)

  invisible(result)
}

#' Retrieve vegaspec from block
#'
#' You can use this function to retrieve a `vegaspec` from
#' blocks (gists) where the spec is in its own JSON file.
#' As well, this function requires that
#' [**gistr**](https://cran.r-project.org/package=gistr) be installed.
#'
#' In addition to having the **gistr** package installed, you will need a
#' GitHub Personal Access Token (PAT) stored in an environment variable
#' called `GITHUB_PAT`. See [Happy Git with R](http://happygitwithr.com/github-pat.html)
#' for more information on how to acquire and store a PAT.
#'
#' The `file` argument accepts a regular expression for the name of the JSON file
#' within the gist. If you don't provide a `file`, it will return the first file
#' in the gist with a `.json` extension (not case sensitive). Don't worry about
#' escaping the dots in `file`, it will likely not make a difference.
#'
#' @param id      `character` block id
#' @param file    `character` filename within block,
#'   `NULL` will retrieve first JSON file
#' @inheritParams vw_create_block
#'
#' @return S3 object of class `vegaspec`
#' @examples
#' \dontrun{
#'   # https://bl.ocks.org/domoritz/455e1c7872c4b38a58b90df0c3d7b1b9
#'   spec_bars <-
#'     vw_retrieve_block("455e1c7872c4b38a58b90df0c3d7b1b9")
#'   spec_bars <-
#'     vw_retrieve_block("dmoritz/455e1c7872c4b38a58b90df0c3d7b1b9")
#'   spec_bars <-
#'     vw_retrieve_block(
#'       "455e1c7872c4b38a58b90df0c3d7b1b9",
#'       file = "bar.vl.json"
#'     )
#' }
#' @seealso [Blocks documentation](https://bl.ocks.org/-/about),
#'  [vw_create_block()], [gistr::gist()]
#' @export
#'
vw_retrieve_block <- function(id, file = NULL, endpoint = NULL, env_pat = NULL,
                           quiet = FALSE) {

  assert_packages("gistr")

  # defaults
  endpoint <- endpoint %||% "https://api.github.com"
  file <- file %||% "\\.json$"

  # get gist
  gist <- gistr::gist(id)

  # get gist files - determine what matches the regex
  gist_files <- names(gist$files)
  match <- grepl(file, gist_files, ignore.case = TRUE)
  gist_files_match <- gist_files[match]

  # no matches
  assertthat::assert_that(
    length(gist_files_match) > 0,
    msg = paste(
      glue::glue("no matching files in gist {id}:"),
      paste(" ", gist_files, collapse = "\n"),
      sep = "\n"
    )
  )

  # more than one match
  if (length(gist_files_match) > 1) {
    warning(
      paste(
        glue::glue("mutiple matching files in gist {id}:"),
        paste(" ", gist_files, collapse = "\n"),
        sep = "\n"
      ),
      call. = FALSE
    )
  }

  # take first match
  gist_file <- gist_files_match[1]

  if (!quiet) {
    message(glue::glue("retrieving `{gist_file}` from gist {id}"))
  }

  # extract file information for the "chosen" file
  file_info <- gist$files[[gist_file]]

  # get result
  result <- file_info$content
  if (file_info$truncated) {
    result <- file_info$raw_url
  }

  # coerce to vegaspec
  spec <- as_vegaspec(result)

  spec
}



