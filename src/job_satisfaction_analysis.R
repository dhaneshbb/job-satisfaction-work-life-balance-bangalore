# Job satisfaction and work-life balance: statistical analysis and PNG charts.
# Usage: Rscript src/job_satisfaction_analysis.R [image-output-directory]
script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
if (length(script_arg) != 1L) stop("Run with Rscript or R --file.")
project_dir <- dirname(dirname(normalizePath(sub("^--file=", "", script_arg))))
args <- commandArgs(TRUE)
if (length(args) > 1L) stop("Supply at most one image-output directory.")
image_dir <- if (length(args)) args[1] else file.path(project_dir, "plots")
data_file <- file.path(project_dir, "data", "processed data", "processed_data.csv")

sections <- list(
  list(
    row = "Gender",
    column = "Years.Of.Experience",
    title = "Work Experience and Gender"
  ),
  list(
    row = "Gender",
    column = "Marital.status",
    title = "Marital Status and Gender"
  ),
  list(
    row = "Gender",
    column = "Average.Weekly.Remote.Work.Hours",
    title = "Remote Work Hours and Gender"
  ),
  list(
    row = "Gender",
    column = "Impact.of.Remote.Work.On.Productivity",
    title = "Remote Work Productivity and Gender"
  ),
  list(
    row = "Gender",
    column = "Work.Related.Illness",
    title = "Work Related Illness and Gender"
  ),
  list(
    row = "Gender",
    column = "Physical.Activity",
    title = "Physical Activity and Gender"
  ),
  list(
    row = "Gender",
    column = "Stress.Management.Approach",
    title = "Stress Management and Gender"
  ),
  list(
    row = "Gender",
    column = "Engaging.In.Professional.Development",
    title = "Engaging in Professional Development and Gender"
  ),
  list(
    row = "Gender",
    column = "Difficulty.Unplugging.From.Technology",
    title = "Difficulty Unplugging From Technology and Gender"
  ),
  list(
    row = "Gender",
    column = "Declining.Social.Engagements",
    title = "Declining Social Engagements and Gender"
  ),
  list(
    row = "Gender",
    column = "Satisfaction.Dependent.Care.Support",
    title = "Satisfaction of Dependent Care Support and Gender"
  ),
  list(
    row = "Gender",
    column = "Satisfaction.Current.Job",
    title = "Satisfaction of Current Job and Gender"
  ),
  list(
    row = "Gender",
    column = "Job.Dissatisfaction.Aspects",
    title = "Job Dissatisfaction Aspects and Gender"
  )
)


# Validate the dataset and category codes, without fixed report counts or p-values.
analysis_data <- read.csv(data_file, check.names = FALSE)
codebook <- read.csv(file.path(project_dir, "data", "codebook.csv"),
                     colClasses = "character")
required <- unique(unlist(lapply(sections, function(s) c(s$row, s$column))))
expected_columns <- c("Respondent_ID", required)
if (anyDuplicated(names(analysis_data)) ||
    !setequal(names(analysis_data), expected_columns)) {
  stop("Dataset must contain Respondent_ID and the documented analysis fields.")
}
if (nrow(analysis_data) == 0L || anyNA(analysis_data) ||
    any(vapply(analysis_data, function(x) any(trimws(as.character(x)) == ""), logical(1)))) {
  stop("The dataset is empty or contains missing/blank values.")
}
# IDs label response rows only; they are never used in statistical tables.
if (anyDuplicated(analysis_data$Respondent_ID) ||
    any(!grepl("^R[0-9]{3,}$", analysis_data$Respondent_ID))) {
  stop("Respondent_ID must contain unique labels such as R001.")
}
if (!setequal(unique(analysis_data$Gender), c("Female", "Male"))) {
  stop("Expected Female and Male gender labels.")
}
for (field in required) {
  allowed <- codebook$code[codebook$field == field]
  if (!length(allowed) || !all(as.character(analysis_data[[field]]) %in% allowed)) {
    stop("Undocumented category value in ", field)
  }
}
tables <- lapply(sections, function(section) {
  table(Gender = factor(analysis_data$Gender, c("Female", "Male")),
        Response = analysis_data[[section$column]])
})
if (any(vapply(tables, ncol, integer(1)) < 2L)) {
  stop("Each response needs at least two observed categories for association tests.")
}

run_and_print <- function(label, expr) {
  cat("\n", label, "\n", sep = "")
  result <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        cat("Warning: ", conditionMessage(w), "\n", sep = "")
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) {
      stop(label, ": ", conditionMessage(e), call. = FALSE)
    }
  )

  if (!is.null(result)) {
    print(result)
  }

  invisible(result)
}

run_fisher_test <- function(tbl) {
  result <- tryCatch(
    fisher.test(tbl, workspace = 2e8),
    error = function(e) {
      cat("Exact Fisher test failed: ", conditionMessage(e), "\n", sep = "")
      cat("Using simulated Fisher p-value with B = 100000.\n")
      set.seed(20260506)
      fisher.test(tbl, simulate.p.value = TRUE, B = 100000)
    }
  )

  print(result)
  invisible(result)
}

run_proportion_test <- function(tbl) {
  # Only binary outcomes have a single, clearly defined success category.
  if (!identical(dim(tbl), c(2L, 2L))) return(invisible(NULL))
  if (all(c("Female", "Male") %in% rownames(tbl))) {
    binary <- tbl[c("Female", "Male"), , drop = FALSE]
  } else {
    binary <- t(tbl[, c("Female", "Male"), drop = FALSE])
  }
  cat("\nBinary proportion comparison: outcome ", colnames(binary)[1],
      "; groups Female, Male.\n", sep = "")
  run_and_print("Proportion test (secondary)", prop.test(binary))
}

run_odds_ratio <- function(tbl) {
  if (!identical(dim(tbl), c(2L, 2L))) return(invisible(NULL))
  # Fisher's estimate uses an explicit orientation: female versus male,
  # first coded outcome versus second coded outcome.
  binary <- if (all(c("Female", "Male") %in% rownames(tbl))) {
    tbl[c("Female", "Male"), , drop = FALSE]
  } else {
    t(tbl[, c("Female", "Male"), drop = FALSE])
  }
  fit <- fisher.test(binary)
  cat("\nConditional odds ratio: Female versus Male; outcome ",
      colnames(binary)[1], " versus ", colnames(binary)[2], "\n", sep = "")
  print(c(estimate = unname(fit$estimate), lower_95 = fit$conf.int[1], upper_95 = fit$conf.int[2]))
}

# Use a consistent system font for PNG text.
if (!capabilities("cairo")) stop("PNG export requires an R build with Cairo support.")
font_family <- Sys.getenv("PLOT_FONT_FAMILY", "Liberation Serif")
# Relocated Conda builds can carry a stale fontconfig prefix. Use the system
# font definitions and a writable per-run cache without changing user config.
if (!nzchar(Sys.getenv("FONTCONFIG_FILE")) && file.exists("/etc/fonts/fonts.conf")) {
  cache_dir <- file.path(tempdir(), "font-cache")
  dir.create(cache_dir, showWarnings = FALSE)
  font_config <- file.path(tempdir(), "plot-fontconfig.conf")
  writeLines(c('<?xml version="1.0"?>', '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">',
               '<fontconfig>', paste0('<cachedir>', cache_dir, '</cachedir>'),
               '<include ignore_missing="yes">/etc/fonts/fonts.conf</include>',
               '</fontconfig>'), font_config)
  Sys.setenv(FONTCONFIG_FILE = font_config)
}
fontconfig <- Sys.which("fc-match")
if (nzchar(fontconfig)) {
  resolved <- system2(fontconfig, c("--format=%{family}", shQuote(font_family)), stdout = TRUE)
  available <- trimws(unlist(strsplit(paste(resolved, collapse = ""), ",")))
  if (!tolower(font_family) %in% tolower(available)) {
    stop("Font '", font_family, "' is not installed. Install it or set PLOT_FONT_FAMILY to an installed family.")
  }
}

# Appearance is fixed; every plotted count comes directly from the CSV tables.
plot_colours <- c("#DF536B", "#61D04F", "#2297E6", "#28E2E5", "#CD0BBC",
                  "#F5C710", "#9E9E9E", "#000000", "#DF536B", "#61D04F")
save_plot <- function(section, tbl, index) {
  filename <- sprintf("%02d_%s.png", index,
                      tolower(gsub("[^[:alnum:]]+", "_", section$title)))
  path <- file.path(image_dir, filename)
  # Seven inches at 300 dpi is suitable for inserting into a research document.
  png(path, width = 7, height = 7, units = "in", res = 300,
      type = "cairo", family = font_family, pointsize = 12, bg = "white")
  on.exit(dev.off(), add = TRUE)
  par(mar = c(5.1, 4.1, 4.1, 2.1), family = font_family,
      font.main = 2, cex.main = 1.1, cex.lab = 1)
  if (section$column == "Marital.status") {
    names(dimnames(tbl)) <- c("Gender", "Marital status")
    fourfoldplot(tbl, color = c("#99CCFF", "#6699CC"),
                 conf.level = 0.95, std = "margins", margin = c(1, 2),
                 space = 0.12, main = section$title)
  } else {
    response_label <- sub(" and Gender$", "", section$title)
    mosaicplot(tbl, color = plot_colours, main = section$title,
               xlab = "Gender", ylab = response_label, cex.axis = 0.66)
  }
  invisible(path)
}

run_section_tests <- function(section, tbl) {
  cat("\n============================================================\n")
  cat(section$title, "\n")
  cat("============================================================\n")
  cat("\nContingency table\n")
  print(tbl)
  cat("\nPercent within gender\n")
  print(round(prop.table(tbl, margin = 1) * 100, 2))
  cat("\nPercent of total\n")
  print(round(prop.table(tbl) * 100, 2))
  chi <- suppressWarnings(chisq.test(tbl, correct = FALSE))
  run_and_print("Cramer's V (uncorrected Pearson statistic)",
                sqrt(unname(chi$statistic) / (sum(tbl) * min(dim(tbl) - 1))))
  cat("Expected cells below 5: ", sum(chi$expected < 5),
      " of ", length(tbl), "\n", sep = "")
  pearson <- run_and_print("Pearson chi-square test", chisq.test(tbl))
  cat("\nFisher exact test\n")
  fisher <- run_fisher_test(tbl)
  run_proportion_test(tbl)
  run_odds_ratio(tbl)
  list(pearson_p = pearson$p.value, fisher_p = fisher$p.value)
}

if (!dir.exists(image_dir) && !dir.create(image_dir, recursive = TRUE)) {
  stop("Cannot create image output directory: ", image_dir)
}
cat("Dataset:", normalizePath(data_file), "\n")
cat("Rows:", nrow(analysis_data), " Columns:", ncol(analysis_data), "\n")
results <- lapply(seq_along(sections), function(i) {
  result <- run_section_tests(sections[[i]], tables[[i]])
  path <- save_plot(sections[[i]], tables[[i]], i)
  cat("Saved image:", normalizePath(path), "\n")
  result
})
fisher_p <- vapply(results, `[[`, numeric(1), "fisher_p")
cat("\nFisher tests with Holm adjustment across all comparisons\n")
print(data.frame(section = vapply(sections, `[[`, character(1), "title"),
                 pearson_p = vapply(results, `[[`, numeric(1), "pearson_p"),
                 fisher_p = fisher_p, holm_p = p.adjust(fisher_p, "holm")),
      row.names = FALSE)

cat("\nDescriptive findings for the observed respondents\n")
counts <- c(
  "Remote work under 10 hours" = sum(analysis_data$Average.Weekly.Remote.Work.Hours == 1),
  "Positive remote productivity impact" = sum(analysis_data$Impact.of.Remote.Work.On.Productivity == 1),
  "Work-related illness" = sum(analysis_data$Work.Related.Illness == 1),
  "Job satisfaction at least 7/10" = sum(analysis_data$Satisfaction.Current.Job >= 7)
)
for (label in names(counts)) {
  cat(sprintf("%s: %d/%d (%.1f%%)\n", label, counts[[label]], nrow(analysis_data),
              100 * counts[[label]] / nrow(analysis_data)))
}
cat("\nSaved", length(sections), "PNG charts to", normalizePath(image_dir), "\n")
