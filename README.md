# Finding the Most Influential CRAN Contributor using Neo4j and Libraries.io Open Data
__For the first part of this project, to do with PyPi, see [here](https://github.com/ebb-earl-co/libraries_io)__
As a graduate student in statistics, I used `R` a lot. In fact, entire semester-long courses were dedicated to learning how to harness some of `R`'s single-purpose (read: esoteric) packages for statistical modeling.

But when it came time for my capstone project, the data manipulation was daunting... _until_ I discovered [`dyplr`](https://dplyr.tidyverse.org/) (this was before the `tidyverse` was a concept). Moreover, I was completely taken by the paradigm outlined by `dyplr`'s author, Hadley Wickham, in the [Split-Apply-Combine](https://vita.had.co.nz/papers/plyr.pdf) paper that he wrote, introducing what would become the guiding principle of the Tidyverse.

Since then, the Tidyverse has exploded in popularity, becoming the de facto standard for data manipulation in `R`, and Hadley Wickham's veneration among `R` users has only increased— and for good reason: now Python and `R` are the two most-used languages in data science.

So, the motivation for this project is akin to that of the aforementioned PyPi contributors investigation: is Hadley Wickham the most influential `R` contributor? To answer this question, we will analyze the `R` packages uploaded to [CRAN](https://cran.r-project.org); specifically:
  * The `R` packages themselves
  * What packages depend on what other packages
  * Who contributes to what packages
Using these items, we will use the [degree centrality algorithm](https://en.wikipedia.org/wiki/Centrality#Degree_centrality) from graph theory to find the most influential node in the graph of `R` packages, dependencies, and contributors.
## Summary of Results
After constructing the graph (including imputing almost 2/3 of the `R` packages
from Libraries.io Open Data dataset) and
[analyzing the degree centrality](https://neo4j.com/docs/graph-algorithms/current/algorithms/degree-centrality/),
Hadley Wickham is indeed the most influential `R` contributor according to the
data from Libraries.io and CRAN.
