# install.packages(tidyverse)
library(tidyverse)
# install.packages(
#   c("arrow", "babynames", "curl", "duckdb", "gapminder",
#     "ggrepel", "ggridges", "ggthemes", "hexbin", "janitor", "Lahman",
#     "leaflet", "maps", "nycflights13", "openxlsx", "palmerpenguins",
#     "repurrrsive", "tidymodels", "writexl")
# )
# library(ggrepel)
library(palmerpenguins)
library(ggthemes)
library(magrittr)

View(penguins)
ggplot(data = penguins,
       # map the variables in dataset to visual properties (aesthetics) of the plot
       mapping = aes(x = flipper_length_mm,
                     y = body_mass_g)
       ) + #defining a plot object
  # add layers to this object
  geom_point()

