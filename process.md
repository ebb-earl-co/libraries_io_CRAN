1. Download tar.gz file from zenodo
2. Unzip, untar tar.gz file from Zenodo into CSVs
3. Extract CRAN data from CSVs:
    a. Rename and filter projects CSV
    b. Rename and filter dependencies CSV
    c. Rename and filter versions CSV
4. Start Neo4j, install Graph algorithms and APOC
5. Run `schema.cypher`
6. CREATE the CRAN `Platform`, the R `Language`, and create their relationship, `HAS_DEFAULT_LANGUAGE`
7. Run `projects_apoc.cypher`
8. Run `versions_apoc.cypher`
9. Run `dependencies_apoc.cypher`
10. Run `create_sqlite_db.py <sqlite_db_name>`
11. Run `initiate_sqlite_db_with_neo4j_project_names.py /path/to/sqlite_db_file.db`
12. Run `request_libraries_io_load_sqlite.py`
    a. Retrieve project names from SQLite–only the ones that have not queried API yet
        i. If there are none left, exit with code 1
        ii. Otherwise, go to step [b]
    b. Request Libraries.io API, project contributors endpoint for each project name
    c. Store the result of part [b] into SQLite (successful or not)
    d. Return to step [a]
13. Run `request_libraries_io_load_sqlite.py`, but querying for
records that have `api_has_been_queried=1 AND api_query_succeeded=0`.
Do as [12]
14. Use Cypher to run `set_merged_contributors_property.cypher`. This
script adds a `merged_contributors` property to every `R` `Project`
node, with the value -1. N.b.
  - The value -1 indicates that the particular node has not attempted
  to merge its `Contributor`s yet
  - The value is changed to the number of contributors merged successfully
15. Run `python merge_projects.py /path/to/SQLite.db -1 <batch_size>`, using SQLite
records in which `api_has_been_queried=1 AND api_query_succeeded=1`.
    a. Get all project names, contributors that represent `R` `Project`s on CRAN
	b. Batch the projects into chunks of length <batch_size> (for Neo4j periodic commit)
    c. For each project, make a `py2neo.Node` for each of its contributors
    d. For each contributor, MERGE that contributor then MERGE its relationship
    with the project
16. More than 70% of the `R` `Project` entities have no contributor data per the
Open Data dataset; this is because most `R` packages are hosted on CRAN, not GitHub,
where only the Author(s) and Maintainer are reported.
So, run `r -f /path/to/impute_cran_packages_without_contributors.R`. This script
does the following:
	a. Get all project names from /path/to/sqlite_db_file.db where `length(contributors)=2`;
	i.e. where the response from the Libraries.io API Contributors endpoint is just `[]`
	b. For each of these projects, query the CRANDB API using
	[the `crandb` package](https://github.com/r-hub/crandb)
	c. Extract the Maintainer information
	d. Use the Maintainer name as a `Contributor` to the `Project`; n.b. the other
	properties included in the Open Data dataset are not available, so even `uuid`
	is auto-populated by Neo4j.
17. Run the Cypher script `remove_merged_contributors_property.cypher` to remove
the `merged_contributors` property from all nodes. It was only necessary during
the previous operations, so can safely be unset.
18. _Finally_, run query for degree centrality to find the most influential contributor on CRAN
