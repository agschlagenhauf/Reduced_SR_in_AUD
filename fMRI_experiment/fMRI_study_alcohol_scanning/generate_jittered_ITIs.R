##### Generate jittered ITIs #####

# draw from a truncated exponential distribution with mean 3 s and range 2-5 s

generate_truncated_exponential_cdf <- function(rate, min_value, max_value, n) {
  # Calculate the CDF values at the min and max
  F_min <- 1 - exp(-rate * min_value)
  F_max <- 1 - exp(-rate * max_value)
  
  # Generate uniform values in the range of F_min to F_max
  u <- runif(n, F_min, F_max)
  
  # Invert the CDF to get the truncated exponential values
  values <- -log(1 - u) / rate
  values <- round(values, 2)

  return(values)
}

# Parameters
mean_value <- 3
rate <- 1 / mean_value  # Rate parameter for the exponential distribution
min_value <- 2
max_value <- 5
n <- 155

# Generate 300 truncated exponential values
result <- generate_truncated_exponential_cdf(rate, min_value, max_value, n)
print(result)
hist(result)
mean(result)
write.table(paste(result, collapse = ", "), file = "Reduced_SR_in_AUD/fMRI_experiment/fMRI_study_alcohol_scanning/ITIs.txt", sep=",", row.names = F, col.names = F)

