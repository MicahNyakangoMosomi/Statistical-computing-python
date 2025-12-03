# Statistical Computing Assignment - Folder Two: R Component
# Project: Quantifying the Post-2007 Election Impact on Kenya
# Task: Advanced Time-Series Regression Analysis using ARIMA.

# -----------------------------------------------------------------------------
# 1. SETUP AND DEPENDENCIES
# -----------------------------------------------------------------------------

# We will use the 'forecast' package for ARIMA modeling and 'ggplot2' for visualization.
# Note: Team members must install these packages in their R environment using:
# install.packages(c("forecast", "ggplot2", "tseries"))

library(forecast)
library(ggplot2)
library(tseries)
# The 'zoo' package is often useful for time-series, but we'll stick to base R 
# and 'forecast' objects for simplicity here.

# -----------------------------------------------------------------------------
# 2. DATA GENERATION (Simulating the Time Series)
# -----------------------------------------------------------------------------
# In a real scenario, this data would be loaded from a CSV prepared by the Python stage.
# For this demonstration, we simulate quarterly GDP growth data from 2000 Q1 to 2012 Q4.

# Time components
start_year <- 2000
end_year <- 2012
quarters <- seq(as.Date("2000/1/1"), as.Date("2012/10/1"), by="3 months")
n <- length(quarters)

# Base trend: steady economic growth (e.g., 5.5% annual growth)
base_growth <- 0.055 + cumsum(rnorm(n, 0, 0.005))

# The shock event: Post-Election Violence (PEV) shock occurs in late 2007/early 2008
# We model the PEV as a significant, sharp decline followed by a slow recovery.
shock_start_index <- which(format(quarters, "%Y-%m") == "2007-10")
shock_end_index <- which(format(quarters, "%Y-%m") == "2008-07")

# Create a permanent negative step/drop in growth rate (the "shock")
shock_magnitude <- 0.08 # Represents an 8 percentage point drop from the expected trend
shock_effect <- rep(0, n)
shock_effect[shock_start_index] <- -shock_magnitude # The initial plunge

# Model the slow recovery over the next 8 quarters (2 years)
recovery_quarters <- 8 
recovery_rate <- shock_magnitude / recovery_quarters 
for (i in 1:recovery_quarters) {
  # Gradual return to the pre-shock trajectory
  shock_effect[shock_start_index + i] <- shock_effect[shock_start_index + i - 1] + recovery_rate
}
# Cap the recovery effect at zero (meaning it returns to the original trajectory)
shock_effect[shock_effect > 0] <- 0

# Final Simulated Data: Base Trend + PEV Shock + Random Noise
set.seed(42)
gdp_data <- base_growth + shock_effect + rnorm(n, 0, 0.01)

# Convert to a time-series object (Quarterly data starting Q1 2000)
gdp_ts <- ts(gdp_data, start = c(2000, 1), frequency = 4)

# -----------------------------------------------------------------------------
# 3. EXPLORATORY TIME SERIES ANALYSIS
# -----------------------------------------------------------------------------

# Check for stationarity using the Augmented Dickey-Fuller (ADF) Test
# Null hypothesis (H0): The series is non-stationary (has a unit root).
cat("\n--- ADF Test for Stationarity ---\n")
adf_result <- adf.test(gdp_ts)
print(adf_result)
# If p-value is high, differencing (the 'I' in ARIMA) may be needed.

# Plot the Raw Time Series Data
plot_data <- data.frame(Time = as.numeric(time(gdp_ts)), GDP_Growth = as.numeric(gdp_ts))
shock_year <- 2008 # For visualization purposes

# Use ggplot2 to create a high-quality, publication-ready visualization
gdp_plot <- ggplot(plot_data, aes(x = Time, y = GDP_Growth)) +
  geom_line(color = "#3498db", linewidth = 1) +
  # Add a vertical line to highlight the shock period
  geom_vline(xintercept = shock_year, linetype = "dashed", color = "#e74c3c", linewidth = 1) +
  annotate("text", x = shock_year + 0.3, y = max(plot_data$GDP_Growth), 
           label = "PEV Shock (2007/08)", color = "#e74c3c", angle = 90, size = 4) +
  labs(
    title = "Simulated Quarterly GDP Growth Rate in Kenya (2000-2012)",
    subtitle = "Highlighting the Post-Election Violence Shock",
    x = "Year (Quarter)",
    y = "GDP Growth Rate"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold", hjust = 0.5), 
        axis.title = element_text(size = 10))

print(gdp_plot)

# -----------------------------------------------------------------------------
# 4. TIME SERIES MODELING (ARIMA)
# -----------------------------------------------------------------------------

# Use auto.arima to automatically select the best fitting ARIMA(p, d, q) model
# for the time series based on AIC/BIC criteria.
cat("\n--- Running Auto ARIMA Model Selection ---\n")
arima_model <- auto.arima(gdp_ts, trace = TRUE, stepwise = FALSE, approximation = FALSE)

# Print the model summary, including coefficients and fit statistics
cat("\n--- ARIMA Model Summary ---\n")
print(summary(arima_model))

# Interpretation: The coefficients (AR and MA terms) and the 'd' (integration) 
# term quantify the time-dependent structure of the data, which includes the shock.

# -----------------------------------------------------------------------------
# 5. FORECASTING & IMPACT ESTIMATION
# -----------------------------------------------------------------------------

# Forecast the next 8 quarters (2 years)
forecast_result <- forecast(arima_model, h = 8)

# Plot the forecast
cat("\n--- Forecast Plot ---\n")
# The plot.forecast method automatically uses the forecast and ggplot2 if available
plot(forecast_result)

# Final step: The difference between the actual post-shock data (which we simulated) 
# and the counterfactual forecast (if the shock hadn't happened) is the
# estimated quantifiable impact of the PEV. This is a core finding for the report.
cat("\nAnalysis complete. The ARIMA model provides quantifiable metrics (coefficients, residuals) to estimate the economic shock.")

# You can save the plot for your presentation using:
# ggsave("gdp_time_series_plot.png", plot = gdp_plot, width = 8, height = 5)
