# Python Code for Exploratory Data Analysis (EDA) - Post-2007 Kenya Election Impact

# Purpose: Data acquisition, cleaning checks, and visualization of the time series
#          to identify the shock associated with the 2007-2008 post-election crisis.

import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# --- 1. Data Generation (Simulating Quarterly GDP Growth) ---
# In a real-world scenario, we would use pandas.read_csv() or an API call 
# to load actual data from KNBS, World Bank, or CBK.
print("Generating dummy Quarterly GDP Growth Data...")

# Create a sequence of dates from 2005 Q1 to 2010 Q4
dates = pd.date_range(start='2005-01-01', end='2010-12-31', freq='QS')
n_points = len(dates)

# Establish a baseline healthy growth rate (e.g., 5.0%)
baseline_growth = np.random.normal(5.0, 0.5, n_points)

# Simulate the 2007-2008 shock event
# The political shock happens around late 2007, impacting economic data in 2008 Q1/Q2.
shock_period_start = np.where(dates == pd.to_datetime('2008-01-01'))[0][0]
shock_period_end = np.where(dates == pd.to_datetime('2009-01-01'))[0][0]

# Apply a strong negative shock during the relevant quarters
baseline_growth[shock_period_start:shock_period_end] -= 4.5 

# Create the final DataFrame
df = pd.DataFrame({
    'Date': dates,
    # Add slight random noise to the growth rate
    'GDP_Growth_Rate': baseline_growth + np.random.normal(0, 0.3, n_points) 
})
df = df.set_index('Date')
print(f"DataFrame created with {len(df)} quarterly observations.")

# --- 2. Data Cleaning and Pre-processing Checks ---
print("\n--- Descriptive Statistics (GDP Growth Rate) ---")
print(df['GDP_Growth_Rate'].describe())

# Check for any missing values (should be 0 in dummy data)
print(f"\nMissing values check: {df.isnull().sum().sum()}")
print(f"Index type check: The data is time-series indexed: {isinstance(df.index, pd.DatetimeIndex)}")


# --- 3. Exploratory Data Visualization (Time-Series Plot) ---

# Set a professional style for the plot
plt.style.use('seaborn-v0_8-darkgrid')
plt.figure(figsize=(12, 6))

# Plot the primary time series data
plt.plot(df.index, df['GDP_Growth_Rate'], 
         label='Quarterly GDP Growth (%)', 
         color='#1f77b4', linewidth=2, marker='o', markersize=4)

# Highlight the shock event period visually using a shaded area
event_start = pd.to_datetime('2007-12-01')
event_end = pd.to_datetime('2009-06-01')
plt.axvspan(event_start, event_end, color='red', alpha=0.1, label='Post-Election Crisis Period')

# Add a vertical line for the election date for precision
plt.axvline(pd.to_datetime('2007-12-27'), color='red', linestyle='--', linewidth=1, label='Election Date (Dec 2007)')

plt.title('Time Series EDA: Kenya GDP Growth Rate (2005-2010)', fontsize=16, fontweight='bold')
plt.xlabel('Date (Quarterly)', fontsize=12)
plt.ylabel('GDP Growth Rate (%)', fontsize=12)
plt.legend(loc='lower left')
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

print("\nEDA complete. The visualization clearly shows the simulated shock and recovery period, ready for deeper statistical modeling in R.")
