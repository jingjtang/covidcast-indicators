% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/contingency_aggregate.R
\name{produce_aggregates}
\alias{produce_aggregates}
\title{Produce all desired aggregations.}
\usage{
produce_aggregates(df, aggregations, cw_list, params)
}
\arguments{
\item{df}{Data frame of individual response data.}

\item{aggregations}{Data frame with columns `name`, `var_weight`, `metric`,
`group_by`, `compute_fn`, `post_fn`. Each row represents one aggregate
to report. `name` is the aggregate's base column name; `var_weight` is the
column to use for its weights; `metric` is the column of `df` containing the
response value. `group_by` is a list of variables used to perform the
aggregations over. `compute_fn` is the function that computes
the aggregate response given many rows of data. `post_fn` is applied to the
aggregate data after megacounty aggregation, and can perform any final
calculations necessary.}

\item{cw_list}{Named list of geographic crosswalks, each of which maps a zip5
to a geographic level such as county or state. Aggregates will be produced
for each geographic level.}

\item{params}{Named list of configuration parameters.}
}
\value{
none
}
\description{
Writes the outputs directly to CSVs in the directory specified by `params`.
Produces output using all available data between `params$start_date` and
`params$end_date`, inclusive.
}
