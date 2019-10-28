CALL apoc.load.json("supplementary_CRAN_dependencies_from_crandb_api.json") YIELD value
WITH value.name AS name, value
UNWIND value.dependencies AS dependence
MATCH (:Platform{name:'CRAN'})-[:HOSTS]->(dependee:Project{name:name})-[:IS_WRITTEN_IN]->(:Language{name:'R'})
WITH dependee, dependence
MATCH (:Platform{name:'CRAN'})-[:HOSTS]->(dependent:Project{name:dependence})-[:IS_WRITTEN_IN]->(:Language{name:'R'})
WITH dependee, dependent
MATCH (v:Version {ID:"a5b55550-03f8-4341-847f-f462e7d356b9"})
// number: "NONE"; special version for no version data in order to keep algo.degree query the same
MERGE (dependent)-[:HAS_VERSION]->(v)
MERGE (v)-[:DEPENDS_ON]->(dependee);
