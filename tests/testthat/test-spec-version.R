context("test-spec_type.R")

schema_vega <- "https://vega.github.io/schema/vega/v3.json"
schema_vega_lite <- "https://vega.github.io/schema/vega-lite/v2.json"

vega <- list(library = "vega", version = "3")
vega_lite <- list(library = "vega_lite", version = "2")

test_that(".schema_type warns", {

  empty <- list(library = "", version = "")

  expect_warning(
    expect_identical(.schema_type("NULL"), empty),
    "NULL$"
  )

  expect_warning(
    expect_identical(.schema_type("foo"), empty),
    "foo$"
  )

})

test_that(".schema_type works", {

  expect_identical(.schema_type(schema_vega), vega)
  expect_identical(.schema_type(schema_vega_lite), vega_lite)

})

test_that("spec_version works", {

  expect_identical(spec_version(vw_ex_mtcars), vega_lite)

})