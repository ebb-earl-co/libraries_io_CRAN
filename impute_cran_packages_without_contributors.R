# Installing packages and masking functions ----
rm(list = ls())
packages_list <- c("neo4r", "parallel", "RSQLite")
new_packages <-
  packages_list[!(packages_list %in% installed.packages()[, "Package"])]
if (length(new_packages)) install.packages(new_packages, repos = "https://cloud.r-project.org")
if (!"crandb" %in% installed.packages()){
  devtools::install_github("r-hub/crandb", quiet = T, upgrade = "always", dependencies = T)
}
lapply(c(packages_list, "crandb"), require, character.only = TRUE)
rm(packages_list, new_packages)
# Set variables ----
URL <- "http://crandb.r-pkg.org/"
# DB <- "/path/to/sqlite.db"
DB <- "/Users/c/Projects/neo4j_certification/libraries_io_CRAN/cran.db"
QUERY <- "select project_name from project_names where length(contributors)=2;"
NEO4J_URI <- "http://localhost:7474"
NEO4J_USER <- "neo4j"
GRAPHDBPASS <- "GRAPHDBPASS"
cl <- parallel::makeCluster(parallel::detectCores() - 1)
# Define functions to be used ----
extract_maintainer <- function(string){
  stringr::str_trim(
    stringr::str_replace_all(
      stringr::str_replace_all(string, "\\<(.*?)\\>", ""),
      "\\((.*?)\\)", ""
    )
  )
}
craft_project_contributor_query <- function(project_name, contributor_name) {
  cn <- stringr::str_replace_all(
    stringr::str_replace_all(contributor_name, '"', ""),
    "'", "\'"
  )
  query1 <- 'MATCH (:Platform{name:"CRAN"})-[:HOSTS]->(p:Project{name:"'
  query2 <- '"})-[:IS_WRITTEN_IN]->(:Language{name:"R"}) WITH p '
  query3 <- 'MERGE (c:Contributor{name:"'
  query4 <- '"}) ON CREATE SET c.uuid = apoc.create.uuid() '
  query5 <- "MERGE (c)-[:CONTRIBUTES_TO{how:'maintainer'}]->(p);"
  paste0(query1, project_name, query2, query3, cn, query4, query5)
}
# Retrieve R package names from SQLite ----
db <- RSQLite::dbConnect(RSQLite::SQLite(), DB)
project_names <- RSQLite::dbGetQuery(db, QUERY)$project_name
RSQLite::dbDisconnect(db)
# Request CRAN metadata for R projects ----
crandb_packages <-  parallel::parSapplyLB(
  cl = cl,
  X = project_names,
  FUN = function(pn) crandb::package(pn),
  USE.NAMES = T
)
# Extract Maintainer object from crandb objects ----
crandb_packages_maintainer_objects <- parallel::parSapplyLB(
  cl = cl,
  X = crandb_packages,
  FUN = function(package) package$Maintainer,
  USE.NAMES = T
)

cran_projects_maintainers <- parallel::parSapplyLB(
  cl = cl,
  X = crandb_packages_maintainer_objects,
  FUN = extract_maintainer,
  USE.NAMES = T
)

# Free up memory
parallel::stopCluster(cl)
rm(project_names, crandb_packages, crandb_packages_maintainer_objects,
   db, DB, QUERY, URL, extract_maintainer, cl)
# Create vector of neo4r queries ----
match_project_merge_contributor_queries <- vector()
for (i in seq_along(cran_projects_maintainers)){
  match_project_merge_contributor_queries[i] <-
    craft_project_contributor_query(names(cran_projects_maintainers[i]),
                                    cran_projects_maintainers[[i]])
}
# Create Neo4j (HTTP) connection object ----
password <- Sys.getenv(GRAPHDBPASS)
neo4j_con <- neo4r::neo4j_api$new(
  url = NEO4J_URI,
  user = NEO4J_USER,
  password = password
)
# Query Neo4j for CRAN projects with no contributors ----
cran_r_projects_with_no_contributors <- neo4r::call_neo4j(
  paste0("match (:Platform{name:'CRAN'})-[:HOSTS]->(p:Project)",
		 "-[:IS_WRITTEN_IN]->(:Language{name:'R'}) ",
		 "where not exists((p)<-[:CONTRIBUTES_TO]-(:Contributor)) ",
		 "return count(p) as c"),
  neo4j_con
)$c[[1]]
writeLines(paste0("Number of CRAN R projects with no contributors: ",
				  cran_r_projects_with_no_contributors, "\n"),
           con = stderr())
# Send Neo4j MATCH/MERGE queries via HTTP ----
for (i in seq_along(match_project_merge_contributor_queries)){
  writeLines(paste0("Sending query ", i, " to ", neo4j_con$url, "..."),
             con = stderr())
  neo4r::call_neo4j(query = match_project_merge_contributor_queries[[i]],
                    con = neo4j_con)
}
print("Done.")

cran_r_projects_with_no_contributors <- neo4r::call_neo4j(
  paste0("match (:Platform{name:'CRAN'})-[:HOSTS]->(p:Project)",
		 "-[:IS_WRITTEN_IN]->(:Language{name:'R'}) ",
		 "where not exists((p)<-[:CONTRIBUTES_TO]-(:Contributor)) ",
		 "return count(p) as c"),
  neo4j_con
)$c[[1]]
writeLines(paste0("Number of CRAN R projects with no contributors: ",
                  cran_r_projects_with_no_contributors),
           con = stderr())
# There are 16 packages the Maintainer of which has an apostrophe
# in the name. Because neo4r only sends queries over HTTP, this is
# incorrectly parsed into the quotation already being used in the
# neo4j query, causing an error. Therefore, these queries will be
# returned to STDOUT in order to copy-and-paste into Neo4j Desktop
leftovers <- neo4r::call_neo4j(
    paste0("match (:Platform{name:'CRAN'})-[:HOSTS]->",
           "(p:Project)-[:IS_WRITTEN_IN]->(:Language{name:'R'}) ",
           "where NOT EXISTS ((p)<-[:CONTRIBUTES_TO]-(:Contributor)) ",
           "RETURN p.name as name"),
    neo4j_con
)
leftovers_maintainers <-
    sapply(
      X = sapply(
        X = sapply(
          X = leftovers$name[[1]], FUN = function(pn) crandb::package(pn), USE.NAMES = T
        ), FUN = function(package) package$Maintainer, USE.NAMES = T
      ), FUN = extract_maintainer, USE.NAMES = T
    )
leftovers_queries <- vector()
for (q in leftovers_queries){
  cat(q, sep = '\n')
}
