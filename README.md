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
Because of the interconnected nature of software packages (dependencies,
versions, contributors, etc.), finding the most influential "item" in that web
of data make [graph databases](https://db-engines.com/en/ranking/graph+dbms) and
[graph theory](https://medium.freecodecamp.org/i-dont-understand-graph-theory-1c96572a1401)
the ideal tools for this type of analysis. [Neo4j](https://neo4j.com/product/)
is the most popular graph database according to [DB engines](https://neo4j.com/product/),
and is the one that we will use for the analysis. Part of the reason for its popularity
is that its query language, [Cypher](https://neo4j.com/developer/cypher-query-language/),
is expressive and simple:

![example graph](images/example_graph.png)

Terminology that will be useful going forward:
  - `Jane Doe` and `John Smith` are __nodes__ (equivalently: __vertexes__)
  - The above two nodes have __label__ `Person`, with __property__ `name`
  - The line that connects the nodes is an __relationship__ (equivalently: __edge__)
  - The above relationship is of __type__ `KNOWS`
  - `KNOWS`, and all Neo4j relationships, are __directed__; i.e. `Jane Doe`
  knows `John Smith`, but not the converse

On MacOS, the easiest way to use Neo4j is via the Neo4j Desktop app, available
as the [`neo4j` cask on Homebrew](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/neo4j.rb).
Neo4j Desktop is a great IDE for Neo4j, allowing simple installation of different
versions of Neo4j as well as plugins that are optional
(e.g. [`APOC`](https://neo4j.com/docs/labs/apoc/current/)) but
are really the best way to interact with the graph database. Moreover, the
screenshot above is taken from the Neo4j Browser, a nice interactive
database interface as well as query result visualization tool.
#### Neo4j Configuration
Before we dive into the data model and how the data are loaded, Neo4j's
default configuration isn't going to cut it for the packages and approach
that we are going to use, so the customized configuration file can be found
[here](https://github.com/ebb-earl-co/libraries_io_CRAN/blob/master/data/neo4j.conf),
corresponding to Neo4j version 3.5.7.
### Making a Graph of Libraries.io Open Data
[Importing from CSV](https://neo4j.com/docs/cypher-manual/3.5/clauses/load-csv/)
is the most common way to populate a Neo4j graph, and is how we will
proceed given that the Open Data snapshot un`tar`s into CSV files. However,
first a data model is necessary— what the entities that will be
represented as labeled nodes with properties and the relationships
among them are going to be. Moreover, some settings of Neo4j
will have to be customized for proper and timely import from CSV.
#### Data Model
Basically, when translating a data paradigm into graph data form, the nouns
become nodes and how the nouns interact (the verbs) become the relationships.
In the case of the Libraries.io data, the following is the data model:

![data model](images/graph.png)

So, a `Platform` `HOSTS` a `Project`, which `IS_WRITTEN_IN` a `Language`,
and `HAS_VERSION` `Version`. Moreover, a `Project` `DEPENDS_ON` other
`Project`s, and `Contributor`s `CONTRIBUTE_TO` `Project`s. With respect to
`Version`s, the diagram communicates a limitation of the Libraries.io
Open Data: that `Project` nodes are linked in the dependencies CSV to other
`Project` nodes, despite the fact that different versions of a project
depend on varying versions of other projects. Take, for example, this row
from the [dependencies CSV](https://github.com/ebb-earl-co/libraries_io_CRAN/blob/master/data/cran_subsetting.md#dependencies):

|ID|Project\_Name|Project\_ID|Version\_Number|Version\_ID|Dependency\_Name|Dependency\_Kind|Optional\_Dependency|Dependency\_Requirements|Dependency\_Project\_ID|
|---|---|---|---|---|---|---|---|---|---|
29033435|archivist|687281|1.0|7326353|RCurl|imports|false|\*|688429|

I.e.; `Version` 1.0 of `Project` `archivist` depends on `Project` `RCurl`.
There is no demarcation of __which__ version of `RCurl` it is that
version 1.0 of `archivist` depends on, other than `*` which forces the
modeling decision of `Project`s depending on other `Project`s, not `Version`s.
#### Contributors, the Missing Data
It is impossible to answer the question of what contributor to CRAN is
most influential without, obviously, data on contributors. However, the
Open Data dataset lacks this information. In order to connect the Open
Data dataset with contributors data will require calls to the
[Libraries.io API](https://libraries.io/api). As mentioned above, there
is a rate limit of 60 requests per minute. If there are

```bash
$ mlr --csv filter '$Platform == "CRAN"' then uniq -n -g "ID" projects-1.4.0-2018-12-22.csv
 14455
```
Python-language Pypi packages, each of which sends one request to the
[Contributors endpoint](https://libraries.io/api#project-contributors)
of the Libraries.io API, at "maximum velocity", it will require

![packages time to request](images/cran_packages_time_to_request.png)

to get contributor data for each project.

Following the example of
[this blog](https://tbgraph.wordpress.com/2018/06/28/finding-alternative-routes-in-california-road-network-with-neo4j/),
it is possible to use the aforementioned APOC utilities for Neo4j to
[load data from web APIs](https://neo4j.com/docs/labs/apoc/current/import/web-apis/),
but I found it to be unwieldy and difficult to monitor. So, I used
Python's `requests` and `SQLite` packages to send requests to the
endpoint and store the responses in a long-running Bash process
(code for this [here](https://github.com/ebb-earl-co/libraries_io_CRAN/blob/master/python/request_libraries_io_load_sqlite.py)).
#### Database Constraints
Analogously to the unique constraint in a relational database, Neo4j has a
[uniqueness constraint](https://neo4j.com/docs/cypher-manual/3.5/schema/constraints/#query-constraint-unique-nodes)
which is very useful in constraining the number of nodes created. Basically,
it isn't useful, and hurts performance, to have two different nodes representing the
platform Pypi (or the language Python, or the project `pipenv`, ...) because
it is a unique entity. Moreover, uniqueness constraints enable
[more performant queries](https://neo4j.com/docs/cypher-manual/3.5/clauses/merge/#query-merge-using-unique-constraints).
The following
[Cypher commands](https://github.com/ebb-earl-co/libraries_io/blob/master/cypher/schema.cypher)
add uniqueness constraints on the properties of the nodes that should be unique
in this data paradigm:
```cypher
CREATE CONSTRAINT on (platform:Platform) ASSERT platform.name IS UNIQUE;
CREATE CONSTRAINT ON (project:Project) ASSERT project.name IS UNIQUE;
CREATE CONSTRAINT ON (project:Project) ASSERT project.ID IS UNIQUE;
CREATE CONSTRAINT ON (version:Version) ASSERT version.ID IS UNIQUE;
CREATE CONSTRAINT ON (language:Language) ASSERT language.name IS UNIQUE;
CREATE CONSTRAINT ON (contributor:Contributor) ASSERT contributor.uuid IS UNIQUE;
```
All of the `ID` properties come from the first column of the CSVs and are
ostensibly primary key values. The `name` property of `Project` nodes is
also constrained to be unique so that queries seeking to match nodes on
the property name— the way that we think of them— are performant as well.
## Populating the Graph
With the constraints, plugins, and configuration of Neo4j in place,
the Libaries.io Open Data dataset can be loaded.  Loading CSVs to Neo4j
can be done with the default
[`LOAD CSV` command](https://neo4j.com/docs/cypher-manual/current/clauses/load-csv/),
but in the APOC plugin there is an improved version,
[`apoc.load.csv`](https://neo4j.com/docs/labs/apoc/current/import/load-csv/#load-csv),
which iterates over the CSV rows as map objects instead of arrays;
when coupled with
[periodic execution](https://neo4j.com/docs/labs/apoc/current/import/load-csv/#_transaction_batching)
(a.k.a. batching), loading CSVs can be done in parallel, as well.
### Creating `R` and CRAN Nodes
As all projects that are to be loaded are hosted on CRAN, the first
node to be created in the graph is the CRAN `Platform` node itself:
```cypher
CREATE (p:Platform {name: 'CRAN'});
```
Not all projects hosted on CRAN are written in `R`, but those are
the focus of this analysis, so we need a `R` `Language` node:
```cypher
CREATE (l:Language {name: 'R'});
```
With these two, we create the first relationship of the graph:
```cypher
MATCH (p:Platform {name: 'CRAN'})
MATCH (l:Language {name: 'R'})
CREATE (p)-[:HAS_DEFAULT_LANGUAGE]->(l);
```
Now we can load the rest of the entities in our graph, connecting them
to these as appropriate, starting with `Project`s.
### Neo4j's `MERGE` Operation
The key operation when loading data to Neo4j is the
[MERGE clause](https://neo4j.com/docs/cypher-manual/current/clauses/merge/#query-merge-using-unique-constraints).
Using the property specified in the query, MERGE either MATCHes the node/relationship
with the property, and, if it doesn't exist, duly CREATEs the node/relationship.
If the property in the query has a uniqueness constraint, Neo4j can thus iterate
over possible duplicates of the "same" node/relationship, only creating it once,
and "attaching" nodes to the uniquely-specified node on the go.

This is a double-edged sword, though, in the situation of creating relationships
between unique nodes; if the participating nodes are not specified exactly, to
MERGE a relationship between them will create __new__ node(s) that are duplicates.
This is undesirable from an ontological perspective, as well as a database
efficiency perspective. So, all this to say that, to create unique
node-relationship-node entities requires _three_ passes over a CSV: the first
to MERGE the first node type, the second to MERGE the second node type, and
the third to MATCH node type 1, MATCH node type 2, and MERGE the relationship
between them.

Lastly, for the same reason as the above, it is necessary to create "base" nodes
before creating nodes that "stem" from them. For example, if we had not created
the `R` `Language` node above (with unique property `name`), for every `R`
project MERGED from the projects CSV, Neo4j would create a new `Language` node
with name 'R' and a relationship between it and the R `Project` node.
This duplication can be useful in some data models, but in the interest of
parsimony, we will load data in the following order:
  1. `Project`s
  2. `Version`s
  3. Dependencies among `Project`s and `Version`s
  4. `Contributor`s
#### Loading `Project`s
First up is the `Project` nodes. The source CSV for this type of node is
[cran\_projects.csv](https://github.com/ebb-earl-co/libraries_io_CRAN/blob/master/data/cran_subsetting.md#projects)
and the queries are in
[this file](https://github.com/ebb-earl-co/libraries_io_CRAN/blob/master/cypher/projects_apoc.cypher).
Neo4j loads the CSVs data following the instructions of the file with the
[`apoc.cypher.runFile`](https://neo4j.com/docs/labs/apoc/current/cypher-execution/) command; i.e.
```
CALL apoc.cypher.runFile('/path/to/libraries_io/cypher/projects_apoc.cypher') yield row, result return 0;
```
The result of this set of queries is that the following portion of our graph
is populated:

![post-projects\_apoc](images/projects_apoc-cypher_result.png)
