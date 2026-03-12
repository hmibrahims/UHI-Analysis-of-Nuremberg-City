# UHI Analysis of Nuremberg City
**“Is My City Getting Hotter? A Remote Sensing Comparison of Urban Heat Patterns in Nuremberg and Adjacent Eastern Forests”**

**Abstract:**
This study investigates Surface Urban Heat Island (SUHI) dynamics in Nuremberg, Germany using Landsat 8 satellite imagery from 2013-2025. Vegetation and built-up areas were distinguished using NDVI and NDBI indices, while Land Surface Temperature (LST) was used to quantify SUHI intensity (ΔT). Results show that urban areas remain 5-8°C warmer than adjacent forested regions, with persistent hotspots concentrated in the urban core. Forested zones consistently demonstrate cooling effects. Despite inter-annual variability, SUHI values remain above 4°C, confirming persistent urban warming and demonstrating the effectiveness of remote sensing methods for monitoring UHI patterns across space and time.

**1. Introduction:** 

Urban Heat Islands (UHIs) are a well-documented consequence of urbanization and land-cover transformation. Dense built environments absorb and retain more heat than vegetated surfaces, leading to elevated surface temperatures in cities. Remote sensing provides a reliable approach for examining urban thermal patterns over time. In particular NDVI is negatively correlated with surface temperature, indicating cooling effects from vegetation. NDBI identifies built-up areas and often correlates positively with higher surface temperatures. This study analyzes SUHI dynamics in Nuremberg, Germany, comparing urban zones with nearby eastern forest regions used as a rural reference. The objective is to evaluate how urban land cover influences surface temperature patterns and how these patterns evolve between 2013 and 2025.

**2. Methodology:**

**Study Area:** The analysis focuses on Nuremberg, Bavaria, Germany, with surrounding eastern forest areas serving as a rural baseline due to their dense vegetation and minimal built-up structures. **Data:** The study uses 12 summer-season Landsat 8 scenes (2013–2025) obtained from USGS EarthExplorer. **Workflow:** The analysis followed a remote sensing workflow of
-	Satellite data acquisition
-	Pre-processing
-	Image unpacking
-	Cloud masking
-	Conversion to Top of Atmosphere (TOA) reflectance
-	Urban-rural classification
-	NDVI calculation
-	NDBI calculation
-	Thermal analysis
-	Brightness Temperature (BT) estimation
-	Land Surface Temperature (LST) calculation
-	SUHI estimation
-	SUHI intensity = Urban mean LST − Rural mean LST
-	Visualization and analysis
-	Temperature histograms
-	SUHI class maps
-	Time-series analysis

**Tools:**

-	R programming language
-	R packages: terra, dplyr, tidyr, ggplot2
-	GIS software: ArcGIS
-	Data source: USGS Landsat archive


**3. Results:**

SUHI Spatial Distribution: SUHI classification maps reveal clear spatial patterns of heat intensity across Nuremberg and nearby forest areas. Urban zones consistently display strong to very strong SUHI (>6°C), while forested and peripheral areas remain cooler (<2°C). The strongest SUHI intensities were observed in 2013 and 2017, with more than one third of the study area exceeding 7.5°C. In 2021, SUHI intensity decreased slightly, with expanded moderate zones (2-4°C). By 2025, hotspots re-emerged in the central urban region, confirming persistent urban heat patterns. Land Surface Temperature Distribution:  Histogram analysis of LST values shows clear thermal separation between urban and rural pixels; typical urban temperatures 25-40°C and forest/rural temperatures 22-28°C. This distribution demonstrates the strong thermal contrast responsible for SUHI formation. Area Distribution by SUHI Class: Across multiple years; strong to very Strong SUHI (>4°C), i.e., 30-45% of the area, no-UHI or cooling zones (≤0°C), i.e., ~35-40%, and moderate zones (2-4°C), i.e., remaining portion. These results highlight both persistent hotspots and stable cooling zones across the study period. Urban vs Rural Temperature Comparison: Urban surfaces remain consistently 5-8°C warmer than the surrounding forests. Peak urban temperatures were recorded in 2019 and 2022 (>35°C), while rural temperatures ranged between 20-30°C. However, the highest SUHI intensity occurred in 2013 (≈8°C), while the lowest occurred in 2024 (≈4.8°C). Despite fluctuations, SUHI intensity remained consistently above 4°C, confirming long-term urban heating.

**4. Discussion:**

The results demonstrate that Nuremberg exhibits a stable and persistent Surface Urban Heat Island effect. Key observations include persistent thermal hotspots in the city center, consistent cooling effects in adjacent forest regions, strong spatial correlation between built-up surfaces and higher temperatures, and stable cooling zones associated with dense vegetation. Urban–rural temperature differences remain relatively consistent due to the structured urban layout and vegetation distribution within the region. These findings confirm the value of remote sensing techniques for long-term urban climate monitoring.

**5. Conclusion:**

This research applied a remote sensing-based SUHI framework to examine spatial and temporal Urban Heat Island patterns in Nuremberg between 2013 and 2025. Key findings are: Urban areas remain 5-8°C warmer than surrounding forests, SUHI intensity remains consistently above 4°C, vegetation plays a major role in mitigating urban heat, remote sensing provides an effective method for monitoring urban climate dynamics, the study highlights the importance of urban green infrastructure and sustainable city planning to reduce future heat stress.

**Repository Structure:**

R_Script/               		# R scripts used for analysis
nuremberg_shapefile/    	# Area of Interest shapefile
analysis/               		# Processed outputs
indices/                		# NDVI and NDBI results
lst/                    		# Land Surface Temperature outputs
figures/              	 	# Visualizations and maps

**Author:**

Ibrahim Khalil,
Friedrich-Alexander-Universität Erlangen-Nürnberg (FAU)
