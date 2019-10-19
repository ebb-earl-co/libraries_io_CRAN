# Finding the Most Influential CRAN Contributor using Neo4j and Libraries.io Open Data
__For the first part of this project, to do with PyPi, see [here](https://github.com/ebb-earl-co/libraries_io)__

As a graduate student in statistics, I used `R` a lot. In fact, entire
semester-long courses were dedicated to learning how to harness some of
`R`'s single-purpose (read: esoteric) packages for statistical modeling.

But when it came time for my capstone project, the data manipulation was
daunting... _until_ I discovered [`dyplr`](https://dplyr.tidyverse.org/).
Moreover, I was completely taken by the paradigm outlined by `dyplr`'s author,
Hadley Wickham, in the
[Split-Apply-Combine](https://vita.had.co.nz/papers/plyr.pdf) paper that he
wrote, introducing what would become the guiding principle of the Tidyverse.

Since then, the Tidyverse has exploded in popularity, becoming the
[de facto standard](https://www.r-bloggers.com/why-learn-the-tidyverse/) for data
manipulation in `R`, and Hadley Wickham's veneration among `R` users has only
increased— and for good reason: now Python and `R` are the two most-used languages
in data science.

So, the motivation for this project is akin to that of the aforementioned PyPi
contributors investigation: is Hadley Wickham the most influential `R` contributor?
To answer this question, we will analyze the `R` packages uploaded to
[CRAN](https://cran.r-project.org); specifically:
  * The `R` packages themselves
  * What packages depend on what other packages
  * Who contributes to what packages

Using these items, we will use the
[degree centrality algorithm](https://en.wikipedia.org/wiki/Centrality#Degree_centrality)
from graph theory to find the most influential node in the graph of `R` packages,
dependencies, and contributors.
## Summary of Results
After constructing the graph (including imputing more than 2/3 of the `R` packages
from Libraries.io Open Data dataset) and
[analyzing the degree centrality](https://neo4j.com/docs/graph-algorithms/current/algorithms/degree-centrality/),
Hadley Wickham is indeed the most influential `R` contributor according to the
data from Libraries.io and CRAN.
## The Approach
### Libraries.io Open Data
[CRAN](https://cran.r-project.org) is the repository for `R` packages that developers
know and love. Analogously to CRAN, other programming languages have their respective package
managers, such as PyPi for Python. As a natural exercise in abstraction,
[Libraries.io](https://libraries.io) is a meta-repository for
package managers. From [their website](https://libraries.io/data):

> Libraries.io gathers data from **36** package managers and **3** source code repositories.
We track over **2.7m** unique open source packages, **33m** repositories and **235m**
interdependencies between [sic] them. This gives Libraries.io a unique understanding of
open source software. An understanding that we want to share with **you**.

#### Using Open Data Snapshot to Save API Calls
Libraries.io has an easy-to-use [API](https://libraries.io/api), but
given that CRAN has 15,000+ packages in the Open Data dataset,
the number of API calls to various endpoints to collate
the necessary data is not appealing (also, Libraries.io rate limits to 60 requests
per minute). Fortunately, [Jeremy Katz on Zenodo](https://zenodo.org/record/2536573)
maintains snapshots of the Libraries.io Open Data source. The most recent
version is a snapshot from 22 December 2018, and contains the following CSV files:
  1. Projects (3 333 927 rows)
  2. Versions (16 147 579 rows)
  3. Tags (52 506 651 rows)
  4. Dependencies (105 811 885 rows)
  5. Repositories (34 061 561 rows)
  6. Repository dependencies (279 861 607 rows)
  7. Projects with Related Repository Fields (3 343 749 rows)

More information about these CSVs is in the `README` file included in the Open
Data tar.gz, copied [here](https://github.com/ebb-earl-co/libraries_io_CRAN/blob/master/data/README).
There is a substantial reduction in the data when subsetting these CSVs just
to the data pertaining to CRAN; find the code used to subset them and the
size comparisons [here](https://github.com/ebb-earl-co/libraries_io_CRAN/blob/master/data/cran_subsetting.md).

**WARNING**: The tar.gz file that contains these data is 13 GB itself, and
once downloaded takes quite a while to un`tar`; once uncompressed, the data
take up 64 GB on disk!

![untar time](images/untar_tar_gz_file_time.png)

### Graph Databases, Starring Neo4j
