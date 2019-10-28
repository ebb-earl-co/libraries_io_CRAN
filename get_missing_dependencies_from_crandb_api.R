require(jsonlite)
require(neo4r)
neo4j_con <- neo4r::neo4j_api$new(
    user = "neo4j",
    url = "http://localhost:7474",
    password = Sys.getenv("GRAPHDBPASS")
)
projects_with_no_DEPENDS_ON_rels <- neo4r::call_neo4j(
  paste0("match (:Platform{name:'CRAN'})",
         "-[:HOSTS]->(p:Project)",
         "-[:IS_WRITTEN_IN]->(:Language{name:'R'}) ",
         "WHERE NOT EXISTS ",
         "((p)-[]->()-[:DEPENDS_ON]->(:Project)) ",
         "return p;"),
  neo4j_con
)
no_DEPENDS_ON_rel_project_names <- projects_with_no_DEPENDS_ON_rels$p$name
rm(projects_with_no_DEPENDS_ON_rels)

no_DEPENDS_ON_rel_projects_imports <- list()
for (i in seq_along(no_DEPENDS_ON_rel_project_names)) {
  name_ <- no_DEPENDS_ON_rel_project_names[[i]]
  package_ <- crandb::package(name_)
  imports_ <- package_$Imports
  if (is.null(imports_)) {
    next
  } else {
    contents <- list(name = name_, imports = names(imports_))
    no_DEPENDS_ON_rel_projects_imports[[i]] <- contents
  }
}

cat(jsonlite::toJSON(Filter(function(x) !is.null(x), no_DEPENDS_ON_rel_projects_imports), auto_unbox = T))

# Call supplementary_dependencies.cypher on the resulting JSON file
